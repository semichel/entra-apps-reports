Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#= Escape inventory values for Markdown and inline HTML
function Convert-ReportCell {
    param($Value)
    if ($null -eq $Value) { return 'Not available' }
    return ([string]$Value).Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('|', '&#124;').Replace('[', '&#91;').Replace(']', '&#93;').Replace('`', '&#96;').Replace("`r", ' ').Replace("`n", ' ')
}

#= Markdown tables with a row collection that preserves single rows
function New-ReportSection {
    param([string]$Title, [string[]]$Headers, $Rows, [string]$Empty = 'No records in the available evidence.')
    $text = [System.Text.StringBuilder]::new()
    [void]$text.AppendLine("`n### $Title`n")
    if ($Rows.Count -eq 0) { [void]$text.AppendLine($Empty); return $text.ToString() }
    [void]$text.AppendLine('| ' + (($Headers | ForEach-Object { Convert-ReportCell $_ }) -join ' | ') + ' |')
    [void]$text.AppendLine('| ' + (($Headers | ForEach-Object { '---' }) -join ' | ') + ' |')
    foreach ($row in $Rows) {
        [void]$text.AppendLine('| ' + (($row | ForEach-Object { Convert-ReportCell $_ }) -join ' | ') + ' |')
    }
    return $text.ToString()
}

#= Normalize Graph timestamps and preserve unknown values
function Convert-ReportDate {
    param($Value)
    if (-not $Value) { return $null }
    if ($Value -is [DateTimeOffset]) { return $Value.ToUniversalTime() }
    if ($Value -is [DateTime]) { return [DateTimeOffset]$Value.ToUniversalTime() }
    $parsed = [DateTimeOffset]::MinValue
    if ([DateTimeOffset]::TryParse([string]$Value, [cultureinfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$parsed)) { return $parsed.ToUniversalTime() }
    return $null
}

#= Display dates explicitly in UTC
function Format-ReportDate {
    param($Value)
    $parsed = Convert-ReportDate $Value
    if ($null -eq $parsed) { return $Value }
    return $parsed.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
}

#= Calculate credential expiry at the rendering time
function Get-ReportExpiry {
    param($Credential, [DateTimeOffset]$Now)
    $end = Convert-ReportDate (Get-Val $Credential 'endDateTime')
    $start = Convert-ReportDate (Get-Val $Credential 'startDateTime')
    if ($null -eq $end) { return @{ state = 'Unknown expiry'; days = $null } }
    $days = [Math]::Floor(($end - $Now).TotalDays)
    $state = if ($end -le $Now) { 'Expired' } elseif ($null -ne $start -and $start -gt $Now) { 'Not yet valid' } elseif ($days -le 30) { 'Expires within 30 days' } elseif ($days -le 60) { 'Expires within 60 days' } elseif ($days -le 90) { 'Expires within 90 days' } else { 'Valid beyond 90 days' }
    return @{ state = $state; days = $days }
}

#= Raw configuration with a fence that cannot be closed by inventory text
function Convert-ReportEvidence {
    param($Value)
    $json = ConvertTo-Json -InputObject $Value -Depth 100
    $length = 3
    foreach ($match in [regex]::Matches($json, '`+')) {
        $length = [Math]::Max($length, $match.Length + 1)
    }
    $fence = '`' * $length
    return "`n" + $fence + "json`n" + $json + "`n" + $fence + "`n"
}

#= Build application sections from dictionary-safe inventory fields
function Get-ReportAppDetails {
    param($App, [DateTimeOffset]$Now, $ById, $ByAppId)
    $registration = Get-Val $App 'registration'
    $text = [System.Text.StringBuilder]::new()
    $rows = [Collections.Generic.List[object]]::new()
    $profile = [ordered]@{ 'Client ID' = 'appId'; 'Enterprise application ID' = 'servicePrincipalId'; 'Enabled' = 'accountEnabled'; 'SSO hint' = 'protocol'; 'Publisher' = 'publisherName'; 'Home tenant' = 'appOwnerOrganizationId'; 'Assignment required' = 'assignmentRequired'; 'Login URL' = 'loginUrl'; 'Logout URL' = 'logoutUrl' }
    foreach ($key in $profile.Keys) {
        $rows.Add(@($key, (Get-Val $App $profile[$key])))
    }
    $rows.Add(@('Sign-in audience', (Get-Val $registration 'signInAudience')))
    $rows.Add(@('Enterprise application Notes', (Get-Val $App 'notes')))
    $rows.Add(@('App registration description', (Get-Val $registration 'description')))
    [void]$text.Append((New-ReportSection 'Application profile' @('Property','Value') $rows))
    $rows.Clear()
    foreach ($source in @(@{ name = 'Enterprise application'; items = Get-Val $App 'owners' }, @{ name = 'App registration'; items = Get-Val (Get-Val $registration 'owners') 'items' })) {
        @($source.items) | Where-Object { $null -ne $_ } | ForEach-Object { $rows.Add(@($source.name, (Get-Val $_ 'displayName'), (Get-Val $_ 'userPrincipalName'), (Get-Val $_ 'userEmail'), (Get-Val $_ 'employeeId'), (Get-Val $_ 'contactMatchStatus'), ([string](Get-Val $_ '@odata.type')).Replace('#microsoft.graph.', ''), (Get-Val $_ 'id'))) }
    }
    [void]$text.Append((New-ReportSection 'Owners' @('Source','Name','Owner account','User email','Employee ID','Contact match','Type','Object ID') $rows 'No owners recorded in the available evidence.'))
    if ((Get-Str (Get-Val $registration 'owners') 'status') -eq 'UNAVAILABLE') { [void]$text.AppendLine('App registration owner evidence is unavailable.') }
    $rows.Clear()
    @((Get-Val $App 'credentials')) | Where-Object { $null -ne $_ } | ForEach-Object {
        $expiry = Get-ReportExpiry $_ $Now; $name = Get-Str $_ 'displayName'; if (-not $name) { $name = Get-Str $_ 'keyId' }
        $rows.Add(@($name, (Get-Val $_ 'source'), $(if ((Get-Str $_ 'kind') -eq 'keyCredentials') { 'Certificate' } else { 'Client secret' }), (Format-ReportDate (Get-Val $_ 'startDateTime')), (Format-ReportDate (Get-Val $_ 'endDateTime')), $expiry.days, $expiry.state, (Get-Val $_ 'lifetimeDays'), (Get-Val $_ 'status'), (Get-Val $_ 'keyId')))
    }
    [void]$text.Append((New-ReportSection 'Certificates and client secrets' @('Credential','Source','Type','Valid from UTC','Expires UTC','Days left','Expiry state','Lifetime days','Policy observation','Key ID') $rows 'No local credential metadata recorded. Credentials may live in an external home tenant.'))
    $rows.Clear()
    @((Get-Val (Get-Val $App 'applicationPermissionGrants') 'items')) | Where-Object { $null -ne $_ } | ForEach-Object {
        $grant = $_; $resourceId = Get-Str $grant 'resourceId'; $resource = Get-Val $ById $resourceId; $name = Get-Str $grant 'resourceDisplayName'; if (-not $name) { $name = Get-Str $resource 'displayName' }; if (-not $name) { $name = $resourceId }; $permission = Get-Str $grant 'permission'; if (-not $permission) { $permission = Get-Str $grant 'appRoleId' }
        $rows.Add(@($name, 'Application', $permission, 'App-only grant', (Get-Val $grant 'appRoleId')))
    }
    [void]$text.Append((New-ReportSection 'Granted API permissions' @('Resource API','Type','Granted permission','Consent / grant','Role or grant ID') $rows))
    foreach ($key in @('applicationPermissionGrants')) {
        if ((Get-Str (Get-Val $App $key) 'status') -ne 'AVAILABLE') { [void]$text.AppendLine($key + ': evidence unavailable.') }
    }
    $rows.Clear()
    @((Get-Val $registration 'requiredResourceAccess')) | Where-Object { $null -ne $_ } | ForEach-Object {
        $api = $_
        $resource = Get-Val $ByAppId (Get-Str $api 'resourceAppId'); $resourceId = Get-Str $resource 'servicePrincipalId'
        @((Get-Val $api 'resourceAccess')) | Where-Object { $null -ne $_ } | ForEach-Object {
            $requested = $_
            $kind = Get-Str $requested 'type'; $permissionId = Get-Str $requested 'id'; $definitionKey = if ($kind -eq 'Role') { 'appRoles' } else { 'oauth2PermissionScopes' }
            $definition = @((Get-Val $resource $definitionKey)) | Where-Object { (Get-Str $_ 'id') -eq $permissionId } | Select-Object -First 1
            $name = Get-Str $definition 'value'; if (-not $name) { $name = $permissionId }
            $grants = Get-Val $App 'applicationPermissionGrants'
            $matches = @((Get-Val $grants 'items')) | Where-Object { $resourceId -and (Get-Str $_ 'resourceId') -eq $resourceId -and (Get-Str $_ 'appRoleId') -eq $permissionId }
            $state = if ($kind -ne 'Role') { 'Delegated consent not collected' } elseif ((Get-Str $grants 'status') -ne 'AVAILABLE') { 'Grant evidence unavailable' } elseif (-not @($matches).Count) { 'No matching grant observed' } else { 'Granted' }
            $resourceName = Get-Str $resource 'displayName'; if (-not $resourceName) { $resourceName = Get-Str $api 'resourceAppId' }
            $rows.Add(@($resourceName, $(if ($kind -eq 'Role') { 'Application' } else { 'Delegated' }), $name, $state, $permissionId))
        }
    }
    [void]$text.Append((New-ReportSection 'Requested API permissions and consent' @('Resource API','Type','Requested permission','Consent evidence','Permission ID') $rows))
    $rows.Clear()
    @((Get-Val $App 'assignments')) | Where-Object { $null -ne $_ } | ForEach-Object { $rows.Add(@((Get-Val $_ 'principalDisplayName'), (Get-Val $_ 'principalType'), (Get-Val $_ 'principalId'), (Get-Val $_ 'appRoleId'))) }
    [void]$text.Append((New-ReportSection 'Assigned users and groups' @('Name','Type','Principal ID','Role ID') $rows))
    $rows.Clear()
    @((Get-Val $App 'redirectUris')) | Where-Object { $null -ne $_ } | ForEach-Object { $rows.Add(@($_)) }
    [void]$text.Append((New-ReportSection 'Redirect / callback URLs' @('URL') $rows))
    $rows.Clear()
    $federation = Get-Val $registration 'federatedIdentityCredentials'
    @((Get-Val $federation 'items')) | Where-Object { $null -ne $_ } | ForEach-Object { $rows.Add(@((Get-Val $_ 'name'), (Get-Val $_ 'issuer'), (Get-Val $_ 'subject'), (@((Get-Val $_ 'audiences')) -join '; '))) }
    $empty = if ((Get-Str $federation 'status') -eq 'AVAILABLE') { 'No federation records.' } else { 'Federation evidence unavailable or registration belongs to another tenant.' }
    [void]$text.Append((New-ReportSection 'Federated credentials' @('Name','Issuer','Subject','Audiences') $rows $empty))
    $rows.Clear()
    $icons = @{ PASS = '✅'; WARN = '⚠'; FAIL = '❌'; UNKNOWN = '❔'; NOT_APPLICABLE = '—'; SKIPPED = '⏭' }
    @((Get-Val $App 'findings')) | Where-Object { $null -ne $_ } | ForEach-Object { $status = Get-Str $_ 'status'; $rows.Add(@((Get-Val $_ 'rule'), ((Get-Val $icons $status) + ' ' + $status), (Get-Val $_ 'evidence'))) }
    [void]$text.Append((New-ReportSection 'Configuration checks' @('Check','Observation','Evidence') $rows))
    return $text.ToString()
}

#= Native report entry consumed by the bundled interface
function New-ReportEntry {
    param([int]$Index, [string]$Title, [string]$Result, [string]$Category, [string[]]$Tags, [string]$Content, [string]$Advanced)
    return @{
        Index = $Index; Id = ('APP.{0:0000}' -f $Index); Title = $Title; Name = $Title; HelpUrl = $null
        Severity = 'Info'; Tag = @($Tags); Result = $Result; ScriptBlock = ''; ScriptBlockFile = 'Collected Entra inventory'
        ErrorRecord = @(); Block = $Category; Duration = '00:00:00'
        ResultDetail = @{ TestTitle = $Title; TestResult = $Content; TestDescription = $Advanced; TestInvestigate = ($Result -eq 'Investigate'); Service = 'Microsoft Graph'; Severity = 'Info'; SkippedReason = $null; TestSkipped = '' }
    }
}

#= Count each application once per configuration check
function Get-ReportCheckStatistics {
    param($Apps)
    $checks = @{}
    $Apps | ForEach-Object {
        $seen = @{}
        @((Get-Val $_ 'findings')) | Where-Object { $null -ne $_ } | ForEach-Object {
            $rule = Get-Str $_ 'rule'
            if (-not $rule -or $seen.ContainsKey($rule)) { return }
            $seen[$rule] = $true
            if (-not $checks.ContainsKey($rule)) { $checks[$rule] = [ordered]@{ Check = $rule; PASS = 0; FAIL = 0; WARN = 0; UNKNOWN = 0; SKIPPED = 0; NOT_APPLICABLE = 0 } }
            $status = Get-Str $_ 'status'
            if ($status -notin @('PASS','FAIL','WARN','UNKNOWN','SKIPPED','NOT_APPLICABLE')) { $status = 'UNKNOWN' }
            $checks[$rule][$status]++
        }
    }
    return @($checks.Keys | Sort-Object | ForEach-Object { $checks[$_] })
}

#= Shared application entries and counters for HTML and Actions
function Get-ReportResults {
    param($Report, [DateTimeOffset]$Now = [DateTimeOffset]::UtcNow)
    Update-ReportGovernance $Report
    $apps = [Collections.Generic.List[object]]::new()
    @((Get-Val $Report 'applications')) | Where-Object { $null -ne $_ } | Sort-Object { Get-Str $_ 'displayName' } | ForEach-Object { $apps.Add($_) }
    $byId = @{}; $byAppId = @{}
    foreach ($app in $apps) {
        $id = Get-Str $app 'servicePrincipalId'; if ($id) { $byId[$id] = $app }; $id = Get-Str $app 'appId'; if ($id) { $byAppId[$id] = $app }
    }
    foreach ($registration in @((Get-Val $Report 'registrations')) | Where-Object { $null -ne $_ }) {
        if (-not $byAppId.ContainsKey([string](Get-Val $registration 'appId'))) { $apps.Add(@{ displayName = Get-Val $registration 'displayName'; appId = Get-Val $registration 'appId'; registration = $registration; credentials = Get-Val $registration 'credentials'; status = Get-Val $registration 'status'; findings = Get-Val $registration 'findings' }) }
    }
    $mode = Get-Str $Report 'mode'; if (-not $mode) { $mode = 'UNKNOWN' }
    $tests = [Collections.Generic.List[object]]::new()
    $apps | ForEach-Object {
        $app = $_
        $result = switch (Get-Str $app 'status') { 'FAIL' { 'Failed' } 'PASS' { 'Passed' } 'SKIPPED' { 'Skipped' } default { 'Investigate' } }
        $tags = [Collections.Generic.List[string]]::new()
        @((Get-Val $app 'findings')) | Where-Object { $null -ne $_ } | Sort-Object { Get-Str $_ 'rule' } | ForEach-Object {
            $tag = (Get-Str $_ 'rule') + ': ' + (Get-Str $_ 'status')
            if (-not $tags.Contains($tag)) { $tags.Add($tag) }
        }
        $category = if (Get-Val $app 'registration') { 'Local app registrations' } else { 'External / platform applications' }
        $title = Get-Str $app 'displayName'; if (-not $title) { $title = Get-Str $app 'appId' }
        $content = Get-ReportAppDetails $app $Now $byId $byAppId
        $tests.Add((New-ReportEntry ($tests.Count + 1) $title $result $category $tags.ToArray() $content ("`n### Complete application configuration`n" + (Convert-ReportEvidence $app))))
    }
    $rows = [Collections.Generic.List[object]]::new()
    $coverage = ''
    $configuration = Get-Val $Report 'ruleConfiguration'
    foreach ($key in $configuration.rules.Keys) {
        $rows.Add(@($key, (Get-Val $configuration.rules $key)))
    }
    $coverage += New-ReportSection 'Applied report rules' @('Rule setting','Value') $rows
    $rows.Clear()
    foreach ($exclusion in $configuration.exclusions) {
        $rows.Add(@((Get-Val $exclusion 'appId'), (@((Get-Val $exclusion 'checks')) -join ', '), (Get-Val $exclusion 'reason')))
    }
    $coverage += New-ReportSection 'Configured app exclusions' @('App ID','Checks','Reason') $rows 'No app exclusions configured.'
    $coverage += "`nDisabled checks: " + (Convert-ReportCell ($configuration.disabledChecks -join ', ')) + "`n"
    $tests.Add((New-ReportEntry ($tests.Count + 1) 'Report rules and scope' 'Investigate' 'Tenant evidence' @('Report scope') $coverage ("`n### Applied report configuration`n" + (Convert-ReportEvidence $configuration))))
    $blocks = [Collections.Generic.List[object]]::new()
    $tests | Group-Object Block | Sort-Object Name | ForEach-Object {
        $group = $_
        $block = @{ Name = $group.Name; Result = 'Investigate'; TotalCount = $group.Count; Tag = @() }
        foreach ($status in @('Failed','Passed','Error','Investigate','Skipped','NotRun')) {
            $block[$status + 'Count'] = @($group.Group | Where-Object { $_.Result -eq $status }).Count
        }
        if ($block.FailedCount) { $block.Result = 'Failed' }
        $blocks.Add($block)
    }
    $tenantName = Get-Str $Report 'tenantDisplayName'; if (-not $tenantName) { $tenantName = Get-Str $Report 'tenantId' }; if (-not $tenantName) { $tenantName = 'Entra tenant' }
    $executedAt = Format-ReportDate (Get-Val $Report 'generatedAtUtc'); if (-not $executedAt) { $executedAt = Format-ReportDate $Now }
    $results = @{
        Result = 'Investigate'; TotalCount = $tests.Count; ExecutedAt = $executedAt; TotalDuration = '00:00:00'
        UserDuration = '00:00:00'; DiscoveryDuration = '00:00:00'; FrameworkDuration = '00:00:00'
        TenantId = Get-Val $Report 'tenantId'; TenantName = $tenantName + ' · ' + $mode; TenantLogos = $null; Account = $null
        CurrentVersion = @{ Major = 1; Minor = 0; Build = 0; Revision = -1 }; LatestVersion = 'Unknown'
        SystemInfo = @{}; PowerShellInfo = @{}; LoadedModules = @(); InvokeCommand = 'Read-only Entra application inventory adapter'
        MgContext = $null; PesterConfig = $null; ReportConfig = $null; Tests = $tests.ToArray(); Blocks = $blocks.ToArray()
        CheckStatistics = @(Get-ReportCheckStatistics $apps)
        EndOfJson = 'EndOfJson'; OutputFiles = @{}
    }
    foreach ($status in @('Failed','Passed','Error','Investigate','Skipped','NotRun')) {
        $results[$status + 'Count'] = @($tests | Where-Object { $_.Result -eq $status }).Count
    }
    if ($results.FailedCount) { $results.Result = 'Failed' }
    return $results
}

#= Inject escaped JSON into the existing self-contained report interface
function Export-ReportHtml {
    param($Report, [string]$OutputPath)
    $template = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'templates/report.html'))
    $template = $template.Replace('(0,C7.jsx)(D0,{children:`Application evidence`}),', '')
    $logo = 'data:image/png;base64,' + [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'templates/saab-logo.png')))
    $logoPattern = 'is=`data:image/png;base64,[A-Za-z0-9+/=]+`'
    if ([regex]::Matches($template, $logoPattern).Count -ne 1) { throw 'Report template has no unique logo placeholder.' }
    $template = [regex]::Replace($template, $logoPattern, 'is=`' + $logo + '`')
    $template = [regex]::Replace($template, '<link rel="icon"[^>]+>', '<link rel="icon" type="image/png" href="' + $logo + '" />')
    $component = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'templates/check-statistics.js'))
    $component += "`n" + [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'templates/report-filters.js'))
    $tagAnchor = 'oe=[...new Set(D.Tests.flatMap(e=>e.Tag||[]))]'
    if ([regex]::Matches($template, [regex]::Escape($tagAnchor)).Count -ne 1) { throw 'Report template has no unique tag filter insertion point.' }
    $template = $template.Replace($tagAnchor, 'oe=EntraAvailableTags(D.Tests,a,s,d,e=>lHe(e,p),a.length>0&&a.length<b2.length)')
    $filterAnchor = 'return(0,z.jsxs)(t1,{children:[!e.isPrintView'
    if ([regex]::Matches($template, [regex]::Escape($filterAnchor)).Count -ne 1) { throw 'Report template has no unique tag selection insertion point.' }
    $template = $template.Replace($filterAnchor, '(0,y.useEffect)(()=>{const next=l.filter(tag=>oe.includes(tag));if(next.length!==l.length)u(next)},[oe.join("\u001f"),l]);' + $filterAnchor)
    $anchor = '(0,z.jsx)(uHe,{TestResults:e,selectedStatus:t,onStatusChange:n})'
    if ([regex]::Matches($template, [regex]::Escape($anchor)).Count -ne 1) { throw 'Report template has no unique statistics insertion point.' }
    $template = $template.Replace('function dHe(){', $component + "`nfunction dHe(){")
    $template = $template.Replace($anchor, '(0,z.jsxs)(z.Fragment,{children:[(0,z.jsx)(EntraCheckStatistics,{rows:e.CheckStatistics||[]}),' + $anchor + ']})')
    $sentinel = [regex]::Match($template, 'EndOfJson:(?:"EndOfJson"|`EndOfJson`)\}')
    if (-not $sentinel.Success) { throw 'Report template has no result placeholder.' }
    $assignments = [regex]::Matches($template.Substring(0, $sentinel.Index), '(?:var|const|let)\s+\w+\s*=')
    if (-not $assignments.Count) { throw 'Report template has no result assignment.' }
    $last = $assignments[$assignments.Count - 1]
    $payload = ConvertTo-Json -InputObject (Get-ReportResults $Report) -Depth 100 -Compress -EscapeHandling EscapeHtml
    $payload = $payload.Replace([string][char]0x2028, '\u2028').Replace([string][char]0x2029, '\u2029')
    $output = $template.Substring(0, $last.Index + $last.Length) + $payload + $template.Substring($sentinel.Index + $sentinel.Length)
    $brandCss = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'templates/brand.css'))
    $output = $output.Replace('</head>', '<style>' + $brandCss + '</style></head>')
    [IO.File]::WriteAllText($OutputPath, $output, [Text.UTF8Encoding]::new($false))
}

#= Expandable Actions summary using the same application details as HTML
function Export-ReportSummary {
    param($Report, [string]$ArtifactUrl, [string]$OutputPath)
    $now = [DateTimeOffset]::UtcNow
    $results = Get-ReportResults $Report $now
    $checkRows = [Collections.Generic.List[object]]::new()
    foreach ($check in $results.CheckStatistics) {
        $checkRows.Add(@($check.Check, $check.PASS, $check.FAIL, $check.WARN, $check.UNKNOWN, $check.SKIPPED, $check.NOT_APPLICABLE))
    }
    $summary = [Text.StringBuilder]::new("| Application / report entry | Severity | Status |`n|---|:---:|:---:|`n")
    $details = [Collections.Generic.List[string]]::new()
    $icons = @{ Passed = '✅'; Failed = '❌'; Investigate = '🔍'; Skipped = '⏭' }
    $results.Tests | ForEach-Object {
        $test = $_
        $title = Convert-ReportCell $test.Title; $badge = $icons[$test.Result] + ' ' + $test.Result
        [void]$summary.AppendLine('| ' + $test.Id + ': ' + $title + ' | ⚪ Info | ' + $badge + ' |')
        $content = $test.ResultDetail.TestResult; $content = $content.Substring($content.IndexOf("`n### ")).Replace("`n### ", "`n#### ")
        $details.Add('<details>' + "`n<summary><strong>" + $icons[$test.Result] + ' ' + $test.Id + ': ' + $title + "</strong></summary>`n`n" + $badge + "`n`n#### Overview`n`n**Category:** " + (Convert-ReportCell $test.Block) + "  `n**Tags:** " + (Convert-ReportCell ($test.Tag -join ', ')) + "`n`n" + $content + "`n`nFull raw configuration is available in the HTML report artifact.`n`n</details>`n")
    }
    $template = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'templates/summary.md'))
    $template = $template.Replace('%CheckStatistics%', (New-ReportSection 'Results by check' @('Check','PASS','FAIL','WARN','UNKNOWN','Excluded / disabled','Not applicable') $checkRows 'No configuration checks available.') + "`nEach application is counted once per check. Matching app registrations are included with their enterprise application. Report scope is excluded from these counts.`n")
    foreach ($key in @('TotalCount','PassedCount','FailedCount','InvestigateCount','SkippedCount','NotRunCount','TenantName')) {
        $template = $template.Replace('%' + $key + '%', (Convert-ReportCell $results[$key]))
    }
    $template = $template.Replace('%TestDate%', (Convert-ReportCell $results.ExecutedAt) + ' (UTC)').Replace('%TestSummary%', $summary.ToString().TrimEnd())
    $intro = '**Tenant ID:** ' + (Convert-ReportCell (Get-Val $Report 'tenantId')) + "`n`n**" + @(@((Get-Val $Report 'applications')) | Where-Object { $null -ne $_ }).Count + ' enterprise applications · ' + @(@((Get-Val $Report 'registrations')) | Where-Object { $null -ne $_ }).Count + " local registrations.** Report totals also include one report scope entry.`n`n[Download the interactive HTML report and JSON/CSV evidence](" + $ArtifactUrl + "). Extract the artifact and open report.html.`n`n"
    $template = $template.Replace('## Application summary', $intro + '## Application summary')
    $budget = 1MB - [Text.Encoding]::UTF8.GetByteCount($template) - 2048
    $included = [Text.StringBuilder]::new(); $count = 0
    foreach ($detail in $details) {
        $size = [Text.Encoding]::UTF8.GetByteCount($detail) + 1; if ($size -gt $budget) { break }
        [void]$included.AppendLine($detail); $budget -= $size; $count++
    }
    if ($count -lt $details.Count) { [void]$included.AppendLine("**GitHub summary size limit:** Expanded details are shown for $count of $($details.Count) entries. The application summary above lists every entry. The HTML/JSON artifact contains all application and tenant details.") }
    $template = $template.Replace('%TestDetails%', $included.ToString())
    if ([Text.Encoding]::UTF8.GetByteCount($template) -ge 1MB) { throw 'Summary exceeds the GitHub 1 MiB per-step limit.' }
    [IO.File]::WriteAllText($OutputPath, $template, [Text.UTF8Encoding]::new($false))
}

#= Flat CSV exports for evidence that administrators need to filter
function Export-DetailCsv {
    param($Report, [string]$OutputDirectory)
    foreach ($kind in @('owners','assignments','credentials')) {
        Export-EvidenceKindCsv $Report $OutputDirectory $kind
    }
}

#= Export one evidence collection without formula interpretation
function Export-EvidenceKindCsv {
    param($Report, [string]$OutputDirectory, [string]$Kind)
    if ($Kind -eq 'owners') { Export-OwnerContactsCsv $Report $OutputDirectory; return }
    $rows = @((Get-Val $Report 'applications') | ForEach-Object {
        $app = $_
        @(Get-Val $app $Kind) | Where-Object { $null -ne $_ } | ForEach-Object {
            $item = $_
            $row = [ordered]@{ Application = Convert-CsvText (Get-Str $app 'displayName'); AppId = Get-Str $app 'appId'; ServicePrincipalId = Get-Str $app 'servicePrincipalId' }
            foreach ($key in $item.Keys) {
                $row[$key] = Convert-CsvText ([string](Get-Val $item $key))
            }
            [pscustomobject]$row
        }
    })
    $columns = @($rows | ForEach-Object { $_.PSObject.Properties.Name } | Select-Object -Unique)
    if ($rows.Count) { $rows | Select-Object -Property $columns | Export-Csv -LiteralPath (Join-Path $OutputDirectory ($Kind + '.csv')) -NoTypeInformation -Encoding utf8 }
    else { Set-Content -LiteralPath (Join-Path $OutputDirectory ($Kind + '.csv')) -Value '"Application","AppId","ServicePrincipalId"' }
}

#= Export contact evidence for enterprise application and registration owners
function Export-OwnerContactsCsv {
    param($Report, [string]$OutputDirectory)
    $sources = @(@((Get-Val $Report 'applications')) | ForEach-Object { @{ app = $_; source = 'Enterprise application'; owners = Get-Val $_ 'owners' } })
    $sources += @(@((Get-Val $Report 'registrations')) | ForEach-Object { @{ app = $_; source = 'App registration'; owners = Get-Val (Get-Val $_ 'owners') 'items' } })
    $rows = @($sources | ForEach-Object {
        $source = $_
        @($source.owners) | Where-Object { $null -ne $_ } | ForEach-Object {
            $owner = $_
            $row = [ordered]@{ Application = Get-Str $source.app 'displayName'; AppId = Get-Str $source.app 'appId'; Source = $source.source; OwnerId = Get-Str $owner 'id'; OwnerAccount = Get-Str $owner 'userPrincipalName'; UserEmail = Get-Str $owner 'userEmail'; EmployeeId = Get-Str $owner 'employeeId'; ContactMatchStatus = Get-Str $owner 'contactMatchStatus'; ContactUserId = Get-Str $owner 'contactUserId'; ContactUserPrincipalName = Get-Str $owner 'contactUserPrincipalName' }
            foreach ($key in @($row.Keys)) {
                $row[$key] = Convert-CsvText (Get-Str $row $key)
            }
            [pscustomobject]$row
        }
    })
    $path = Join-Path $OutputDirectory 'owners.csv'
    if ($rows.Count) { $rows | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding utf8 }
    else { Set-Content -LiteralPath $path -Value '"Application","AppId","Source","OwnerId","OwnerAccount","UserEmail","EmployeeId","ContactMatchStatus","ContactUserId","ContactUserPrincipalName"' }
}
