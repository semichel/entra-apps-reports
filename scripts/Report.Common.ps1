Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#= Dictionary-safe Graph values
function Get-Val {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

#= Nullable string values
function Get-Str {
    param($Object, [string]$Name)
    $value = Get-Val $Object $Name
    if ($null -eq $value) { return $null }
    if ($value -is [DateTime]) { return $value.ToUniversalTime().ToString('o') }
    if ($value -is [DateTimeOffset]) { return $value.ToUniversalTime().ToString('o') }
    return [string]$value
}

#= Validate local rendering prerequisites before starting a long Graph collection
function Assert-ReportPrerequisites {
    foreach ($relativePath in @('Report.Render.ps1', 'templates/report.html')) {
        if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $relativePath) -PathType Leaf)) { throw "Missing report file: $relativePath. Copy the complete project before running; no inventory requests have been made." }
    }
}

#= Phase logging
function Write-ReportLog {
    param([string]$Message, [ConsoleColor]$Color = 'Cyan')
    Write-Host ('[{0:HH:mm:ss}] {1}' -f [DateTimeOffset]::Now, $Message) -ForegroundColor $Color
    try {
        Add-Content -LiteralPath $script:LogPath -Value ("{0:o} {1}" -f [DateTimeOffset]::UtcNow, $Message)
    }
    catch {
        Write-Warning 'Could not write the report log. Collection continues; progress is still shown in the console.'
    }
}

#= Show the current item within a collection phase
function Write-CollectionProgress {
    param([string]$Activity, [int]$Index, [int]$Total, [string]$Name)
    $percent = if ($Total -gt 0) { [Math]::Max(0, [Math]::Min(100, [int](100 * ($Index - 1) / $Total))) } else { 0 }
    $status = '{0}/{1}: {2}' -f $Index, $Total, $Name
    Write-Progress -Id 1 -Activity $Activity -Status $status -PercentComplete $percent
    Write-ReportLog ('{0} - {1}' -f $Activity, $status)
}

#= Read Graph with bounded throttling retries
function Invoke-ReportGet {
    param([string]$Uri)
    $parsed = [uri]$Uri
    if ($parsed.Scheme -ne 'https' -or $parsed.Host -ne 'graph.microsoft.com') {
        throw 'Graph URL must use https://graph.microsoft.com.'
    }
    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        try {
            Write-Progress -Id 2 -Activity 'Microsoft Graph request' -Status ('GET {0} (attempt {1}/5)' -f $parsed.AbsolutePath, ($attempt + 1))
            return Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType Hashtable
        }
        catch {
            $response = Get-Val $_.Exception 'Response'
            $status = Get-Val $response 'StatusCode'
            if ([int]$status -notin @(429, 503, 504) -or $attempt -eq 4) { throw }
            $delay = [Math]::Min(30, [Math]::Pow(2, $attempt + 1))
            Write-ReportLog ('Graph HTTP {0} at {1}; waiting {2}s before retry {3}/5.' -f [int]$status, $parsed.AbsolutePath, $delay, ($attempt + 2)) Yellow
            Write-Progress -Id 2 -Activity 'Microsoft Graph request' -Status ('Waiting {0}s before retry: {1}' -f $delay, $parsed.AbsolutePath)
            Start-Sleep -Seconds $delay
        }
        finally {
            Write-Progress -Id 2 -Activity 'Microsoft Graph request' -Completed
        }
    }
}

#= Explicit Graph pagination
function Invoke-MgGetAll {
    param([string]$Uri)
    $items = [System.Collections.Generic.List[object]]::new()
    $visited = [System.Collections.Generic.HashSet[string]]::new()
    $pageNumber = 0
    $resourcePath = ([uri]$Uri).AbsolutePath
    while ($Uri) {
        if (-not $visited.Add($Uri)) { throw 'Repeated Graph nextLink detected.' }
        $page = Invoke-ReportGet $Uri
        foreach ($item in @(Get-Val $page 'value')) {
            if ($null -ne $item) { $items.Add($item) }
        }
        $Uri = Get-Str $page '@odata.nextLink'
        $pageNumber++
        if ($Uri -or $pageNumber -gt 1) { Write-ReportLog ('Graph {0}: page {1}, {2} records collected.' -f $resourcePath, $pageNumber, $items.Count) }
    }
    return $items.ToArray()
}

#= Read an inventory with owners expanded, retaining a full per-object fallback
function Get-InventoryWithOwners {
    param([string]$Uri)
    try {
        return Invoke-MgGetAll ($Uri + '&$expand=owners($select=id,displayName)')
    }
    catch {
        $status = Get-Val (Get-Val $_.Exception 'Response') 'StatusCode'
        if ([int]$status -notin @(400, 501)) { throw }
        Write-ReportLog 'Graph rejected expanded owners; reading the inventory normally and collecting owners separately.' Yellow
        return Invoke-MgGetAll $Uri
    }
}

#= Accept expanded owners only when the collection is demonstrably below the expansion limit
function Get-ExpandedOwnerEvidence {
    param($Object)
    if ($Object -isnot [System.Collections.IDictionary] -or -not $Object.Contains('owners')) { return $null }
    $owners = @((Get-Val $Object 'owners') | Where-Object { $null -ne $_ })
    if ($owners.Count -ge 20 -or (Get-Str $Object 'owners@odata.nextLink')) { return $null }
    return [ordered]@{ status = 'AVAILABLE'; items = $owners; reason = $null }
}

#= Exclude first-party Microsoft apps by their owning organization, never their display name
function Test-MicrosoftOwnedPrincipal {
    param($Principal)
    $ownerTenant = Get-Str $Principal 'appOwnerOrganizationId'
    return $ownerTenant -in @('f8cdef31-a31e-4b4a-93e4-5f571e91255a', '72f988bf-86f1-41af-91ab-2d7cd011db47')
}

#= Report findings
function New-Finding {
    param([string]$Rule, [string]$Status, [string]$Evidence)
    return [ordered]@{ rule = $Rule; status = $Status; evidence = $Evidence }
}

#= Credential metadata only (no secrets or certificate bytes)
function Get-CredentialSummary {
    param($Object, [string]$Source)
    foreach ($kind in @('passwordCredentials', 'keyCredentials')) {
        foreach ($credential in @(Get-Val $Object $kind)) {
            if ($null -ne $credential) { Convert-Credential $credential $kind $Source }
        }
    }
}

#= Credential dates and policy evaluation
function Convert-Credential {
    param($Credential, [string]$Kind, [string]$Source)
    $start = Get-Str $Credential 'startDateTime'
    $end = Get-Str $Credential 'endDateTime'
    $limit = if ($Kind -eq 'passwordCredentials') { 90 } else { 365 }
    $status = 'UNKNOWN'
    $days = $null
    $lifetime = $null
    if ($start -and $end) {
        $startDate = [DateTimeOffset]::Parse($start)
        $endDate = [DateTimeOffset]::Parse($end)
        $days = [Math]::Floor(($endDate - [DateTimeOffset]::UtcNow).TotalDays)
        $lifetime = [Math]::Ceiling(($endDate - $startDate).TotalDays)
        $status = if ($days -lt 0 -or $lifetime -gt $limit) { 'FAIL' } elseif ($days -le 30) { 'WARN' } else { 'PASS' }
    }
    return [ordered]@{
        source = $Source; kind = $Kind; keyId = Get-Str $Credential 'keyId'
        displayName = Get-Str $Credential 'displayName'; usage = Get-Str $Credential 'usage'
        startDateTime = $start; endDateTime = $end
        daysRemaining = $days; lifetimeDays = $lifetime; maximumDays = $limit; status = $status
    }
}

#= Build an application report from inventory
function New-AppReport {
    param($Principal, $Registration, $Owners, $Assignments)
    $mode = Get-Str $Principal 'preferredSingleSignOnMode'
    $protocol = if ($mode -eq 'saml') { 'SAML' } elseif ($mode -eq 'oidc') { 'OIDC' } else { 'UNKNOWN' }
    $ownerList = @($Owners)
    $assignmentList = @($Assignments)
    $credentials = @(Get-CredentialSummary $Principal 'EnterpriseApplication') + @(Get-CredentialSummary $Registration 'AppRegistration')
    $web = Get-Val $Registration 'web'
    $redirects = @(Get-Val $web 'redirectUris') + @(Get-Val (Get-Val $Registration 'spa') 'redirectUris') + @(Get-Val (Get-Val $Registration 'publicClient') 'redirectUris')
    if ($protocol -eq 'SAML') { $redirects = @(Get-Val $Principal 'replyUrls') }
    $redirects = @($redirects | Where-Object { $null -ne $_ } | Select-Object -Unique)
    $badUrls = @($redirects | Where-Object {
        $url = $null
        -not [uri]::TryCreate([string]$_, [UriKind]::Absolute, [ref]$url) -or
        ($url.Scheme -ne 'https' -and -not ($url.Scheme -eq 'http' -and $url.Host -in @('localhost', '127.0.0.1', '[::1]')))
    })
    $findings = [System.Collections.Generic.List[object]]::new()
    $assignmentRequired = Get-Val $Principal 'appRoleAssignmentRequired'
    $assignmentStatus = if ($null -eq $assignmentRequired) { 'UNKNOWN' } elseif ($assignmentRequired -eq $true) { 'PASS' } else { 'FAIL' }
    $findings.Add((New-Finding 'AssignmentRequired' $assignmentStatus ("Configured value: {0}" -f $assignmentRequired)))
    $humanOwners = @($ownerList | Where-Object { (Get-Str $_ '@odata.type') -eq '#microsoft.graph.user' })
    $ownerStatus = if ($humanOwners.Count -ge 2) { 'PASS' } else { 'FAIL' }
    $findings.Add((New-Finding 'TwoHumanOwners' $ownerStatus ("Human owners: {0}; total owners: {1}. Automation owners are preserved." -f $humanOwners.Count, $ownerList.Count)))
    $urlStatus = if ($badUrls.Count -gt 0) { 'FAIL' } elseif ($redirects.Count -eq 0) { 'UNKNOWN' } else { 'PASS' }
    $findings.Add((New-Finding 'RedirectUriSecurity' $urlStatus ("Non-HTTPS/non-localhost URIs: {0}. Native-app custom schemes need separate review." -f ($badUrls -join ', '))))
    $credentialStatus = if (@($credentials | Where-Object { (Get-Str $_ 'status') -eq 'FAIL' }).Count) { 'FAIL' } elseif (@($credentials | Where-Object { (Get-Str $_ 'status') -eq 'UNKNOWN' }).Count) { 'UNKNOWN' } elseif (@($credentials | Where-Object { (Get-Str $_ 'status') -eq 'WARN' }).Count) { 'WARN' } elseif ($credentials.Count) { 'PASS' } else { 'MANUAL' }
    $findings.Add((New-Finding 'CredentialDates' $credentialStatus 'Policy: secrets <=90 days; certificates <=365 days; warning at <=30 days remaining. Retired keys may still be listed.'))
    $groups = @($assignmentList | Where-Object { (Get-Str $_ 'principalType') -eq 'Group' })
    $users = @($assignmentList | Where-Object { (Get-Str $_ 'principalType') -eq 'User' })
    $findings.Add((New-Finding 'GroupAssignmentsPreferred' $(if ($groups.Count) { 'PASS' } else { 'WARN' }) ("Groups: {0}; direct users: {1}. Nested membership is not evaluated." -f $groups.Count, $users.Count)))
    $findings.Add((New-Finding 'ProtocolConfirmation' 'MANUAL' ("Graph SSO hint: {0}. A missing hint does not prove absence of OIDC." -f $mode)))
    $findings.Add((New-Finding 'AuthenticationAndClaims' 'MANUAL' 'Test assigned/unassigned users, emitted claims, assertion validation, token lifetime, redirects, and logout in the actual application.'))
    $findings.Add((New-Finding 'SamlVerificationAndEncryption' $(if ($protocol -in @('SAML', 'UNKNOWN')) { 'MANUAL' } else { 'NOT_APPLICABLE' }) 'Verify request-signature enforcement, active signing certificate, claim mappings, metadata and encryption requirement against the delivery form. UNKNOWN protocol still requires protocol review.'))
    $findings.Add((New-Finding 'OperationsAndDocumentation' 'MANUAL' 'Review sign-in evidence, Conditional Access, TLS configuration, approval, business/support contacts and delivery form.'))
    $statuses = @($findings | ForEach-Object { Get-Str $_ 'status' })
    $overall = if ($statuses -contains 'FAIL') { 'FAIL' } elseif ($statuses -contains 'UNKNOWN') { 'UNKNOWN' } elseif ($statuses -contains 'WARN') { 'WARN' } else { 'MANUAL' }
    return [ordered]@{
        displayName = Get-Str $Principal 'displayName'; servicePrincipalId = Get-Str $Principal 'id'
        appId = Get-Str $Principal 'appId'; accountEnabled = Get-Val $Principal 'accountEnabled'
        protocol = $protocol; preferredSingleSignOnMode = $mode; status = $overall
        registrationAvailable = ($null -ne $Registration); assignmentRequired = $assignmentRequired
        owners = $ownerList; assignments = $assignmentList; redirectUris = $redirects
        identifierUris = @(Get-Val $Registration 'identifierUris')
        samlEntityIdentifiers = @(Get-Val $Principal 'servicePrincipalNames')
        samlSettings = Get-Val $Principal 'samlSingleSignOnSettings'
        loginUrl = Get-Str $Principal 'loginUrl'; logoutUrl = Get-Str $Principal 'logoutUrl'
        tokenEncryptionKeyId = Get-Str $Principal 'tokenEncryptionKeyId'
        preferredTokenSigningKeyThumbprint = Get-Str $Principal 'preferredTokenSigningKeyThumbprint'
        optionalClaims = Get-Val $Registration 'optionalClaims'
        implicitGrantSettings = Get-Val $web 'implicitGrantSettings'
        credentials = $credentials; findings = $findings.ToArray()
    }
}

#= Render escaped HTML, CSV and JSON artifacts
function Export-AppReport {
    param($Report, [string]$OutputDirectory)
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    Write-ReportLog 'Writing report.json and findings.csv.'
    $Report | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'report.json') -Encoding utf8
    $rows = @($Report.applications | ForEach-Object {
        $app = $_
        $app.findings | ForEach-Object {
            [pscustomobject]@{ Application = Convert-CsvText $app.displayName; AppId = $app.appId; ServicePrincipalId = $app.servicePrincipalId; Rule = $_.rule; Status = $_.status; Evidence = Convert-CsvText $_.evidence }
        }
    })
    if ($rows.Count) { $rows | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'findings.csv') -NoTypeInformation -Encoding utf8 }
    else { Set-Content -LiteralPath (Join-Path $OutputDirectory 'findings.csv') -Value '"Application","AppId","ServicePrincipalId","Rule","Status","Evidence"' }
    . (Join-Path $PSScriptRoot 'Report.Html.ps1')
    . (Join-Path $PSScriptRoot 'Report.Render.ps1')
    Write-ReportLog 'Rendering the interactive HTML report with PowerShell.'
    Export-ReportHtml $Report (Join-Path $OutputDirectory 'report.html')
    Write-ReportLog 'Exporting detailed evidence CSV files.'
    Export-DetailCsv $Report $OutputDirectory
}

#= Load owners and assignments for one enterprise application
function Get-LiveAppReport {
    param($Principal, [System.Collections.IDictionary]$RegistrationByApp)
    $id = Get-Str $Principal 'id'
    $appId = Get-Str $Principal 'appId'
    $ownerEvidence = Get-ExpandedOwnerEvidence $Principal
    $owners = @(if ($null -ne $ownerEvidence) { Get-Val $ownerEvidence 'items' } else { Invoke-MgGetAll ("https://graph.microsoft.com/v1.0/servicePrincipals/{0}/owners?`$select=id,displayName" -f $id) })
    $assignments = @(Invoke-MgGetAll ("https://graph.microsoft.com/v1.0/servicePrincipals/{0}/appRoleAssignedTo?`$select=id,principalId,principalDisplayName,principalType,appRoleId,resourceId" -f $id))
    $registration = Get-Val $RegistrationByApp $appId
    return New-AppReport $Principal $registration $owners $assignments
}

#= Protect spreadsheet text cells from formula interpretation
function Convert-CsvText {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return $null }
    if ($Value -match '^[=+@\-\t\r\n]') { return "'" + $Value }
    return $Value
}
