Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#= Merge defaults and reject invalid policy settings before collection
function Get-ReportRuleConfiguration {
    param($Config)
    $defaults = [ordered]@{ ownerUpnPrefix = 'azadmu'; minimumAdminOwners = 1; requireDescriptions = $true; requireAssignment = $true; requireGroupAssignment = $true; requireRedirectUris = $true; allowLocalhostHttp = $true; maxSecretLifetimeDays = 90; maxCertificateLifetimeDays = 365; credentialWarningDays = 30 }
    $rules = Get-Val $Config 'rules'
    if ($null -eq $rules) { $rules = @{} }
    if ($null -ne $rules -and $rules -isnot [Collections.IDictionary]) { throw 'rules must be a JSON object.' }
    foreach ($key in @($rules.Keys)) {
        if ($key -notin @($defaults.Keys)) { throw "Unknown rule setting: $key." }; $defaults[$key] = Get-Val $rules $key
    }
    foreach ($key in @('requireDescriptions','requireAssignment','requireGroupAssignment','requireRedirectUris','allowLocalhostHttp')) {
        if ($defaults[$key] -isnot [bool]) { throw "$key must be true or false." }
    }
    foreach ($key in @('minimumAdminOwners','maxSecretLifetimeDays','maxCertificateLifetimeDays','credentialWarningDays')) {
        if ($defaults[$key] -isnot [int] -and $defaults[$key] -isnot [long]) { throw "$key must be an integer." }; if ($defaults[$key] -lt 1 -or $defaults[$key] -gt 10000) { throw "$key must be between 1 and 10000." }
    }
    if ($defaults.ownerUpnPrefix -isnot [string] -or [string]::IsNullOrWhiteSpace($defaults.ownerUpnPrefix) -or $defaults.ownerUpnPrefix -match '[\s*?\[\]@]') { throw 'ownerUpnPrefix must be a nonempty literal UPN prefix without spaces, @ or wildcards.' }
    $names = @('AssignmentRequired','RedirectUriSecurity','CredentialDates','GroupAssignmentsPreferred','EnterpriseAdminOwner','RegistrationAdminOwner','EnterpriseDescription','RegistrationDescription')
    $disabled = @((Get-Val $Config 'disabledChecks') | Where-Object { $null -ne $_ })
    foreach ($name in $disabled) {
        if ($name -notin $names) { throw "Unknown disabled check: $name." }
    }
    $exclusions = @((Get-Val $Config 'exclusions') | Where-Object { $null -ne $_ })
    foreach ($exclusion in $exclusions) {
        $id = [guid]::Empty; if (-not [guid]::TryParse((Get-Str $exclusion 'appId'), [ref]$id) -or $id -eq [guid]::Empty) { throw 'Each exclusion must have a valid application/client appId.' }
        if ([string]::IsNullOrWhiteSpace((Get-Str $exclusion 'reason'))) { throw 'Each exclusion must have a reason.' }
        $checks = @((Get-Val $exclusion 'checks') | Where-Object { $null -ne $_ })
        if (-not $checks.Count) { throw 'Each exclusion must have checks (use ["*"] for all checks).' }
        foreach ($check in $checks) {
            if ($check -ne '*' -and $check -notin $names) { throw "Unknown excluded check: $check." }
        }
    }
    return @{ rules = $defaults; disabledChecks = $disabled; exclusions = $exclusions }
}

#= Keep exclusions visible and never count excluded checks as passes
function Set-ReportFindingExclusions {
    param($App, $Findings, $Configuration)
    $appId = Get-Str $App 'appId'
    $exclusions = @($Configuration.exclusions | Where-Object { (Get-Str $_ 'appId') -eq $appId })
    $Findings | ForEach-Object {
        $finding = $_; $rule = Get-Str $finding 'rule'
        if ($Configuration.disabledChecks -contains $rule) { $finding['status'] = 'SKIPPED'; $finding['evidence'] = 'Check disabled in configuration.' }
        $matching = @($exclusions | Where-Object { @((Get-Val $_ 'checks')) -contains '*' -or @((Get-Val $_ 'checks')) -contains $rule })
        if ($matching.Count) { $finding['status'] = 'SKIPPED'; $finding['evidence'] = 'Excluded by app ID: ' + (($matching | ForEach-Object { Get-Str $_ 'reason' }) -join '; ') }
    }
}

#= Build automatic checks from collected configuration rather than cached results
function Get-ConfiguredCoreFindings {
    param($App, $Rules)
    $credentials = @((Get-Val $App 'credentials') | Where-Object { $null -ne $_ })
    $credentials | ForEach-Object { Update-ReportCredentialPolicy $_ $Rules }
    $statuses = @($credentials | ForEach-Object { Get-Str $_ 'status' })
    $status = if ($statuses -contains 'FAIL') { 'FAIL' } elseif ($statuses -contains 'UNKNOWN') { 'UNKNOWN' } elseif ($statuses -contains 'WARN') { 'WARN' } elseif ($credentials.Count) { 'PASS' } else { 'NOT_APPLICABLE' }
    $evidence = if ($credentials.Count) { 'Maximum lifetime: secrets {0} days; certificates {1} days. Warning at {2} days remaining. Expired or invalid date ranges fail.' -f $Rules.maxSecretLifetimeDays, $Rules.maxCertificateLifetimeDays, $Rules.credentialWarningDays } else { 'No certificate or client-secret metadata exists in the collected application objects.' }
    New-Finding 'CredentialDates' $status $evidence
    if (-not (Get-Str $App 'servicePrincipalId')) { return }
    $assignment = Get-Val $App 'assignmentRequired'
    $status = if (-not $Rules.requireAssignment) { 'SKIPPED' } elseif ($null -eq $assignment) { 'UNKNOWN' } elseif ($assignment -eq $true) { 'PASS' } else { 'FAIL' }
    New-Finding 'AssignmentRequired' $status ('Assignment required: {0}; rule enforced: {1}.' -f $assignment, $Rules.requireAssignment)
    $urls = @((Get-Val $App 'redirectUris') | Where-Object { $null -ne $_ })
    $invalid = @($urls | Where-Object { $uri = $null; -not [uri]::TryCreate([string]$_, [UriKind]::Absolute, [ref]$uri) -or ($uri.Scheme -ne 'https' -and -not ($Rules.allowLocalhostHttp -and $uri.Scheme -eq 'http' -and $uri.Host -in @('localhost','127.0.0.1','[::1]'))) })
    $status = if (-not $Rules.requireRedirectUris) { 'SKIPPED' } elseif ($invalid.Count) { 'FAIL' } elseif (-not $urls.Count) { 'UNKNOWN' } else { 'PASS' }
    New-Finding 'RedirectUriSecurity' $status ('Redirect URLs: {0}; invalid URLs: {1}; localhost HTTP allowed: {2}; rule enforced: {3}.' -f $urls.Count, ($invalid -join ', '), $Rules.allowLocalhostHttp, $Rules.requireRedirectUris)
    $assignments = @((Get-Val $App 'assignments') | Where-Object { $null -ne $_ })
    $groups = @($assignments | Where-Object { (Get-Str $_ 'principalType') -eq 'Group' })
    $users = @($assignments | Where-Object { (Get-Str $_ 'principalType') -eq 'User' })
    $status = if (-not $Rules.requireGroupAssignment) { 'SKIPPED' } elseif ($groups.Count) { 'PASS' } else { 'WARN' }
    New-Finding 'GroupAssignmentsPreferred' $status ('Groups: {0}; direct users: {1}; rule enforced: {2}.' -f $groups.Count, $users.Count, $Rules.requireGroupAssignment)
}

#= Re-evaluate stored credential metadata against configured date limits
function Update-ReportCredentialPolicy {
    param([System.Collections.IDictionary]$Credential, $Rules)
    $kind = Get-Str $Credential 'kind'
    $limit = if ($kind -eq 'passwordCredentials') { Get-Val $Rules 'maxSecretLifetimeDays' } else { Get-Val $Rules 'maxCertificateLifetimeDays' }
    $start = [DateTimeOffset]::MinValue; $end = [DateTimeOffset]::MinValue
    $valid = [DateTimeOffset]::TryParse((Get-Str $Credential 'startDateTime'), [ref]$start) -and [DateTimeOffset]::TryParse((Get-Str $Credential 'endDateTime'), [ref]$end)
    $Credential['maximumDays'] = $limit; $Credential['daysRemaining'] = $null; $Credential['lifetimeDays'] = $null; $Credential['status'] = 'UNKNOWN'
    if ($valid) {
        $now = [DateTimeOffset]::UtcNow; $days = [Math]::Floor(($end - $now).TotalDays); $lifetime = [Math]::Ceiling(($end - $start).TotalDays)
        $Credential['daysRemaining'] = $days; $Credential['lifetimeDays'] = $lifetime
        $Credential['status'] = if ($end -le $now -or $end -le $start -or $lifetime -gt $limit) { 'FAIL' } elseif ($start -gt $now) { 'WARN' } elseif ($days -le (Get-Val $Rules 'credentialWarningDays')) { 'WARN' } else { 'PASS' }
    }
}
