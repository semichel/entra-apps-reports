Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#= Merge defaults and reject invalid policy settings before collection
function Get-ReportRuleConfiguration {
    param($Config)
    $defaults = [ordered]@{ ownerUpnPrefix = 'azadmu'; minimumAdminOwners = 1; requireNotes = $true; requireAssignment = $true; requireGroupAssignment = $true; requireRedirectUris = $true; allowLocalhostHttp = $true; maxSecretLifetimeDays = 90; maxCertificateLifetimeDays = 365; credentialWarningDays = 30 }
    $rules = Get-Val $Config 'rules'
    if ($null -eq $rules) { $rules = @{} }
    if ($null -ne $rules -and $rules -isnot [Collections.IDictionary]) { throw 'rules must be a JSON object.' }
    $normalizedRules = @{}; foreach ($key in $rules.Keys) { $normalizedRules[$key] = Get-Val $rules $key }
    if (-not $normalizedRules.ContainsKey('requireNotes')) {
        if ($normalizedRules.ContainsKey('requireEnterpriseDescription')) { $normalizedRules['requireNotes'] = $normalizedRules['requireEnterpriseDescription'] }
        elseif ($normalizedRules.ContainsKey('requireDescriptions')) { $normalizedRules['requireNotes'] = $normalizedRules['requireDescriptions'] }
    }
    foreach ($key in @('requireEnterpriseDescription','requireRegistrationDescription','requireDescriptions')) { $normalizedRules.Remove($key) }
    $rules = $normalizedRules
    $defaults['minimumEnterpriseAdminOwners'] = 1; $defaults['minimumRegistrationAdminOwners'] = 1
    foreach ($key in @($rules.Keys)) {
        if ($key -notin @($defaults.Keys)) { throw "Unknown rule setting: $key." }; $defaults[$key] = Get-Val $rules $key
    }
    foreach ($key in @('requireNotes','requireAssignment','requireGroupAssignment','requireRedirectUris','allowLocalhostHttp')) {
        if ($defaults[$key] -isnot [bool]) { throw "$key must be true or false." }
    }
    foreach ($key in @('minimumAdminOwners','minimumEnterpriseAdminOwners','minimumRegistrationAdminOwners','maxSecretLifetimeDays','maxCertificateLifetimeDays','credentialWarningDays')) {
        if ($defaults[$key] -isnot [int] -and $defaults[$key] -isnot [long]) { throw "$key must be an integer." }; if ($defaults[$key] -lt 1 -or $defaults[$key] -gt 10000) { throw "$key must be between 1 and 10000." }
    }
    if (-not $rules.Contains('minimumEnterpriseAdminOwners')) { $defaults['minimumEnterpriseAdminOwners'] = $defaults['minimumAdminOwners'] }
    if (-not $rules.Contains('minimumRegistrationAdminOwners')) { $defaults['minimumRegistrationAdminOwners'] = $defaults['minimumAdminOwners'] }
    if ($defaults.ownerUpnPrefix -isnot [string] -or [string]::IsNullOrWhiteSpace($defaults.ownerUpnPrefix) -or $defaults.ownerUpnPrefix -match '[\s*?\[\]@]') { throw 'ownerUpnPrefix must be a nonempty literal UPN prefix without spaces, @ or wildcards.' }
    $names = @('AssignmentRequired','RedirectUriSecurity','CredentialDates','FederatedCredentials','GroupAssignmentsPreferred','EnterpriseAdminOwner','RegistrationAdminOwner','Notes')
    $disabled = @((Get-Val $Config 'disabledChecks') | Where-Object { $null -ne $_ -and $_ -ne 'RegistrationDescription' } | ForEach-Object { if ($_ -eq 'EnterpriseDescription') { 'Notes' } else { $_ } })
    foreach ($name in $disabled) {
        if ($name -notin $names) { throw "Unknown disabled check: $name." }
    }
    $exclusions = @((Get-Val $Config 'exclusions') | Where-Object { $null -ne $_ } | ForEach-Object {
        $entry = $_; $oldChecks = @((Get-Val $entry 'checks') | Where-Object { $null -ne $_ })
        $checks = @($oldChecks | Where-Object { $_ -ne 'RegistrationDescription' } | ForEach-Object { if ($_ -eq 'EnterpriseDescription') { 'Notes' } else { $_ } })
        if ($oldChecks.Count -and -not $checks.Count) { return }
        @{ appId = Get-Str $entry 'appId'; reason = Get-Str $entry 'reason'; checks = $checks }
    })
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
    $registration = Get-Val $App 'registration'
    $federation = Get-Val $registration 'federatedIdentityCredentials'
    $trusts = @((Get-Val $federation 'items') | Where-Object { $null -ne $_ })
    $status = if ($null -eq $registration -and -not (Get-Val $App 'registrationAvailable')) { 'NOT_APPLICABLE' } elseif ((Get-Str $federation 'status') -ne 'AVAILABLE') { 'UNKNOWN' } elseif ($trusts.Count) { 'PASS' } else { 'NOT_APPLICABLE' }
    $evidence = if ($status -eq 'PASS') { '{0} federated identity credential(s) configured. Workload identity federation supports authentication without stored client secrets. This confirms configuration presence, not runtime use or trust correctness. Existing certificates and secrets are checked separately by CredentialDates.' -f $trusts.Count } elseif ($status -eq 'UNKNOWN') { 'Federated credential evidence is unavailable; configuration presence cannot be verified.' } else { 'No federated identity credentials are configured in the available local registration evidence, or no local registration exists. Federation is optional.' }
    New-Finding 'FederatedCredentials' $status $evidence
    if (-not (Get-Str $App 'servicePrincipalId')) { return }
    $assignment = Get-Val $App 'assignmentRequired'
    $status = if (-not $Rules.requireAssignment) { 'SKIPPED' } elseif ($null -eq $assignment) { 'UNKNOWN' } elseif ($assignment -eq $true) { 'PASS' } else { 'FAIL' }
    New-Finding 'AssignmentRequired' $status ('Assignment required: {0}; rule enforced: {1}.' -f $assignment, $Rules.requireAssignment)
    $urls = @((Get-Val $App 'redirectUris') | Where-Object { $null -ne $_ })
    $invalid = @($urls | Where-Object { $uri = $null; -not [uri]::TryCreate([string]$_, [UriKind]::Absolute, [ref]$uri) -or ($uri.Scheme -ne 'https' -and -not ($Rules.allowLocalhostHttp -and $uri.Scheme -eq 'http' -and $uri.Host -in @('localhost','127.0.0.1','[::1]'))) })
    $status = if (-not $Rules.requireRedirectUris) { 'SKIPPED' } elseif (-not $urls.Count) { 'NOT_APPLICABLE' } elseif ($invalid.Count) { 'FAIL' } else { 'PASS' }
    $evidence = 'Redirect URLs: {0}; invalid URLs: {1}; localhost HTTP allowed: {2}; rule enforced: {3}.' -f $urls.Count, ($invalid -join ', '), $Rules.allowLocalhostHttp, $Rules.requireRedirectUris
    if ($Rules.requireRedirectUris -and -not $urls.Count) { $evidence += ' No redirect URLs are configured in the collected evidence; redirect security is not applicable. This does not prevent the application from passing.' }
    New-Finding 'RedirectUriSecurity' $status $evidence
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

#= Require at least one human administrator owner using the company UPN convention
function New-AdminOwnerFinding {
    param([string]$Rule, [string]$Label, $Owners, [string]$Availability = 'AVAILABLE', [string]$Prefix = 'azadmu', [int]$Minimum = 1)
    $items = @($Owners | Where-Object { $null -ne $_ })
    $admins = @($items | Where-Object { (Get-Str $_ '@odata.type') -eq '#microsoft.graph.user' -and ([string](Get-Str $_ 'userPrincipalName')).StartsWith($Prefix, [StringComparison]::OrdinalIgnoreCase) })
    $unknown = @($items | Where-Object { ((Get-Str $_ '@odata.type') -eq '#microsoft.graph.user' -or -not (Get-Str $_ '@odata.type')) -and [string]::IsNullOrWhiteSpace((Get-Str $_ 'userPrincipalName')) })
    $status = if ($Availability -ne 'AVAILABLE') { 'UNKNOWN' } elseif ($admins.Count -ge $Minimum) { 'PASS' } elseif ($unknown.Count) { 'UNKNOWN' } else { 'FAIL' }
    $evidence = "$Label requires at least $Minimum user owner(s) whose UPN starts with $Prefix. Matching admin owners: $($admins.Count); total owners: $($items.Count)."
    if ($status -eq 'UNKNOWN') { $evidence += ' Owner evidence or UPN is unavailable; collect again with directory read access to verify.' }
    return New-Finding $Rule $status $evidence
}

#= Require portal-editable SPN Notes without prescribing standard wording
function New-NotesFinding {
    param($Object, [bool]$Required = $true)
    $status = if (-not $Required) { 'SKIPPED' } elseif ([string]::IsNullOrWhiteSpace((Get-Str $Object 'notes'))) { 'WARN' } else { 'PASS' }
    $evidence = if ($status -eq 'WARN') { 'Enterprise application / SPN Notes are empty. Fill in Properties > Notes in the Entra portal.' } else { 'Enterprise application / SPN Notes are populated. No standard wording requirement is applied.' }
    if (-not $Required) { $evidence = 'Notes check disabled in configuration.' }
    return New-Finding 'Notes' $status $evidence
}

#= Replace obsolete checks and evaluate each object separately
function Update-AppGovernance {
    param([System.Collections.IDictionary]$App, $Configuration = (Get-ReportRuleConfiguration @{}))
    $rules = @('AssignmentRequired','RedirectUriSecurity','CredentialDates','FederatedCredentials','GroupAssignmentsPreferred','TwoHumanOwners','ProtocolConfirmation','AuthenticationAndClaims','SamlVerificationAndEncryption','OperationsAndDocumentation','EnterpriseAdminOwner','RegistrationAdminOwner','Notes','EnterpriseDescription','RegistrationDescription')
    $findings = [Collections.Generic.List[object]]::new()
    @((Get-Val $App 'findings')) | Where-Object { $null -ne $_ -and (Get-Str $_ 'rule') -notin $rules } | ForEach-Object { $findings.Add($_) }
    $policy = $Configuration.rules
    @(Get-ConfiguredCoreFindings $App $policy) | ForEach-Object { $findings.Add($_) }
    if (Get-Str $App 'servicePrincipalId') {
        $availability = Get-Str $App 'ownerEvidenceStatus'; if (-not $availability) { $availability = 'AVAILABLE' }
        $findings.Add((New-AdminOwnerFinding 'EnterpriseAdminOwner' 'Enterprise application / SPN' (Get-Val $App 'owners') $availability $policy.ownerUpnPrefix $policy.minimumEnterpriseAdminOwners))
        $findings.Add((New-NotesFinding $App $policy.requireNotes))
    }
    $registration = Get-Val $App 'registration'
    if ($null -ne $registration) {
        $owners = Get-Val $registration 'owners'; $availability = Get-Str $owners 'status'
        $findings.Add((New-AdminOwnerFinding 'RegistrationAdminOwner' 'App registration' (Get-Val $owners 'items') $availability $policy.ownerUpnPrefix $policy.minimumRegistrationAdminOwners))
    }
    else {
        $status = if (Get-Val $App 'registrationAvailable') { 'UNKNOWN' } else { 'NOT_APPLICABLE' }
        $findings.Add((New-Finding 'RegistrationAdminOwner' $status 'No local app registration evidence. An external home-tenant registration cannot be checked from this tenant.'))
    }
    Set-ReportFindingExclusions $App $findings $Configuration
    $App['findings'] = $findings.ToArray()
    $statuses = @($findings | ForEach-Object { Get-Str $_ 'status' })
    if ($App.Contains('manualValidationRequired')) { $App.Remove('manualValidationRequired') }
    if ($App.Contains('delegatedConsentGrants')) { $App.Remove('delegatedConsentGrants') }
    $App['status'] = if ($statuses -contains 'FAIL') { 'FAIL' } elseif ($statuses -contains 'UNKNOWN') { 'UNKNOWN' } elseif ($statuses -contains 'WARN') { 'WARN' } elseif ($statuses -contains 'PASS') { 'PASS' } elseif ($statuses -contains 'SKIPPED') { 'SKIPPED' } else { 'UNKNOWN' }
}

#= Apply the same checks to saved evidence, enterprise apps and standalone registrations
function Update-ReportGovernance {
    param([System.Collections.IDictionary]$Report)
    $configuration = Get-ReportRuleConfiguration (Get-Val $Report 'ruleConfiguration')
    $Report['ruleConfiguration'] = $configuration
    if ($Report.Contains('tenantEvidence')) { $Report.Remove('tenantEvidence') }
    @((Get-Val $Report 'applications')) | Where-Object { $null -ne $_ } | ForEach-Object { Update-AppGovernance $_ $configuration }
    @((Get-Val $Report 'registrations')) | Where-Object { $null -ne $_ } | ForEach-Object {
        $app = @{ appId = Get-Val $_ 'appId'; registration = $_; credentials = Get-Val $_ 'credentials'; findings = @() }; Update-AppGovernance $app $configuration
        $_['findings'] = $app.findings; $_['status'] = $app.status
    }
}
