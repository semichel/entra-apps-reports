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

#= Validate required report files before starting Graph collection
function Assert-ReportPrerequisites {
    foreach ($relativePath in @('Report.Render.ps1', 'Report.Rules.ps1', 'Report.Evidence.ps1', 'templates/report.html', 'templates/check-statistics.js', 'templates/report-filters.js', 'templates/graph-overview.js', 'templates/application-details.js', 'templates/saab-logo.png', 'templates/brand.css')) {
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
        return Invoke-MgGetAll ($Uri + '&$expand=owners($select=id,displayName,userPrincipalName)')
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

#= Extract credential metadata; configured rules evaluate dates after collection
function Convert-Credential {
    param($Credential, [string]$Kind, [string]$Source)
    $start = Get-Str $Credential 'startDateTime'
    $end = Get-Str $Credential 'endDateTime'
    return [ordered]@{
        source = $Source; kind = $Kind; keyId = Get-Str $Credential 'keyId'
        displayName = Get-Str $Credential 'displayName'; usage = Get-Str $Credential 'usage'
        startDateTime = $start; endDateTime = $end
        daysRemaining = $null; lifetimeDays = $null; maximumDays = $null; status = 'UNKNOWN'
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
    $assignmentRequired = Get-Val $Principal 'appRoleAssignmentRequired'
    return [ordered]@{
        displayName = Get-Str $Principal 'displayName'; servicePrincipalId = Get-Str $Principal 'id'
        appId = Get-Str $Principal 'appId'; accountEnabled = Get-Val $Principal 'accountEnabled'
        protocol = $protocol; preferredSingleSignOnMode = $mode; status = 'UNKNOWN'
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
        credentials = $credentials; findings = @()
    }
}

#= Read saved report data without contacting Graph
function Read-ReportDatabase {
    param([Parameter(Mandatory)][string]$Path)
    $report = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable -Depth 100
    if ($report -isnot [Collections.IDictionary]) { throw 'Report data must contain a JSON object.' }
    if ((Get-Str $report 'schemaVersion') -notin @('2.0','3.0')) { throw 'Unsupported report schema. Expected 2.0 or 3.0.' }
    foreach ($key in @('applications','registrations')) {
        if ($report[$key] -isnot [array]) { throw "Report data must contain a $key array." }
    }
    return $report
}

#= Store JSON data and render HTML; manual export helpers remain available
function Export-AppReport {
    param($Report, [string]$OutputDirectory)
    Update-ReportGovernance $Report
    . (Join-Path $PSScriptRoot 'Report.Render.ps1')
    $Report['schemaVersion'] = '3.0'
    $Report['reportView'] = Get-ReportResults $Report
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    Write-ReportLog 'Writing report.json.'
    $Report | ConvertTo-Json -Depth 100 -EscapeHandling EscapeHtml -WarningAction Stop | Set-Content -LiteralPath (Join-Path $OutputDirectory 'report.json') -Encoding utf8
    . (Join-Path $PSScriptRoot 'Report.Render.ps1')
    Write-ReportLog 'Rendering the interactive HTML report with PowerShell.'
    Export-ReportHtml $Report (Join-Path $OutputDirectory 'report.html')
    foreach ($legacyFile in @('findings.csv','owners.csv','assignments.csv','credentials.csv')) {
        $legacyPath = Join-Path $OutputDirectory $legacyFile
        if (Test-Path -LiteralPath $legacyPath -PathType Leaf) { Remove-Item -LiteralPath $legacyPath }
    }
}

#= Load owners and assignments for one enterprise application
function Get-LiveAppReport {
    param($Principal, [System.Collections.IDictionary]$RegistrationByApp)
    $id = Get-Str $Principal 'id'
    $appId = Get-Str $Principal 'appId'
    $ownerEvidence = Get-ExpandedOwnerEvidence $Principal
    $owners = @(if ($null -ne $ownerEvidence) { Get-Val $ownerEvidence 'items' } else { Invoke-MgGetAll ("https://graph.microsoft.com/v1.0/servicePrincipals/{0}/owners?`$select=id,displayName,userPrincipalName" -f $id) })
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

#= Validate report settings and the reader IDs supplied by the workflow
function Read-ReportDeployment {
    param(
        [string]$Path,
        [string]$TenantId = $env:AZURE_TENANT_ID,
        [string]$ClientId = $env:AZURE_CLIENT_ID
    )
    $config = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable
    $config['ruleConfiguration'] = Get-ReportRuleConfiguration $config
    $config['tenantId'] = $TenantId
    $config['clientId'] = $ClientId
    foreach ($field in @('tenantId', 'clientId')) {
        $parsed = [guid]::Empty
        if (-not [guid]::TryParse((Get-Str $config $field), [ref]$parsed) -or $parsed -eq [guid]::Empty) { throw "Supply valid TenantId and ClientId parameters, or AZURE_TENANT_ID and AZURE_CLIENT_ID environment values ($field is missing or invalid)." }
    }
    if ([string]::IsNullOrWhiteSpace((Get-Str $config 'tenantDisplayName'))) { throw 'Fill tenantDisplayName with the production tenant name.' }
    return $config
}

#= Match the reader identity before making any production inventory request
function Assert-ReportDeploymentContext {
    param($Context, [System.Collections.IDictionary]$Config)
    if ((Get-Str $Context 'TenantId') -ne (Get-Str $Config 'tenantId') -or (Get-Str $Context 'Environment') -ne 'Global') { throw 'Graph tenant/cloud does not match production configuration. No Graph requests made.' }
    if ((Get-Str $Context 'ClientId') -ne (Get-Str $Config 'clientId')) { throw 'Graph client does not match the configured production reader. No Graph requests made.' }
}

. (Join-Path $PSScriptRoot 'Report.Rules.ps1')
