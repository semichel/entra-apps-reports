Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#= Require at least one human administrator owner using the company UPN convention
function New-AdminOwnerFinding {
    param([string]$Rule, [string]$Label, $Owners, [string]$Availability = 'AVAILABLE')
    $items = @($Owners | Where-Object { $null -ne $_ })
    $admins = @($items | Where-Object { (Get-Str $_ '@odata.type') -eq '#microsoft.graph.user' -and (Get-Str $_ 'userPrincipalName') -like 'azadmu*' })
    $unknown = @($items | Where-Object { ((Get-Str $_ '@odata.type') -eq '#microsoft.graph.user' -or -not (Get-Str $_ '@odata.type')) -and [string]::IsNullOrWhiteSpace((Get-Str $_ 'userPrincipalName')) })
    $status = if ($Availability -ne 'AVAILABLE') { 'UNKNOWN' } elseif ($admins.Count -ge 1) { 'PASS' } elseif ($unknown.Count) { 'UNKNOWN' } else { 'FAIL' }
    $evidence = "$Label requires at least one user owner whose UPN starts with azadmu. Matching admin owners: $($admins.Count); total owners: $($items.Count)."
    if ($status -eq 'UNKNOWN') { $evidence += ' Owner evidence or UPN is unavailable; collect again with directory read access to verify.' }
    return New-Finding $Rule $status $evidence
}
#= Description policy currently requires content without prescribing a standard text
function New-DescriptionFinding {
    param([string]$Rule, [string]$Label, $Object)
    $status = if ([string]::IsNullOrWhiteSpace((Get-Str $Object 'description'))) { 'WARN' } else { 'PASS' }
    $evidence = if ($status -eq 'WARN') { "⚠ $Label description is empty. Fill in the description; standard wording and order-number requirements will be defined later." } else { "$Label description is populated. No standard wording requirement is applied yet." }
    return New-Finding $Rule $status $evidence
}
#= Replace obsolete checks and evaluate each object separately
function Update-AppGovernance {
    param([System.Collections.IDictionary]$App)
    $rules = @('TwoHumanOwners','EnterpriseAdminOwner','RegistrationAdminOwner','EnterpriseDescription','RegistrationDescription')
    $findings = [Collections.Generic.List[object]]::new()
    @((Get-Val $App 'findings')) | Where-Object { $null -ne $_ -and (Get-Str $_ 'rule') -notin $rules } | ForEach-Object { $findings.Add($_) }
    if (Get-Str $App 'servicePrincipalId') {
        $availability = Get-Str $App 'ownerEvidenceStatus'; if (-not $availability) { $availability = 'AVAILABLE' }
        $findings.Add((New-AdminOwnerFinding 'EnterpriseAdminOwner' 'Enterprise application / SPN' (Get-Val $App 'owners') $availability))
        $findings.Add((New-DescriptionFinding 'EnterpriseDescription' 'Enterprise application / SPN' $App))
    }
    $registration = Get-Val $App 'registration'
    if ($null -ne $registration) {
        $owners = Get-Val $registration 'owners'; $availability = Get-Str $owners 'status'
        $findings.Add((New-AdminOwnerFinding 'RegistrationAdminOwner' 'App registration' (Get-Val $owners 'items') $availability))
        $findings.Add((New-DescriptionFinding 'RegistrationDescription' 'App registration' $registration))
    }
    else {
        $status = if (Get-Val $App 'registrationAvailable') { 'UNKNOWN' } else { 'NOT_APPLICABLE' }
        $findings.Add((New-Finding 'RegistrationAdminOwner' $status 'No local app registration evidence. An external home-tenant registration cannot be checked from this tenant.'))
        $findings.Add((New-Finding 'RegistrationDescription' $status 'No local app registration evidence. An external home-tenant description cannot be checked from this tenant.'))
    }
    $App['findings'] = $findings.ToArray()
    $statuses = @($findings | ForEach-Object { Get-Str $_ 'status' })
    $App['status'] = if ($statuses -contains 'FAIL') { 'FAIL' } elseif ($statuses -contains 'UNKNOWN') { 'UNKNOWN' } elseif ($statuses -contains 'WARN') { 'WARN' } elseif ($statuses -contains 'MANUAL') { 'MANUAL' } else { 'PASS' }
}
#= Apply the same checks to saved evidence, enterprise apps and standalone registrations
function Update-ReportGovernance {
    param([System.Collections.IDictionary]$Report)
    @((Get-Val $Report 'applications')) | Where-Object { $null -ne $_ } | ForEach-Object { Update-AppGovernance $_ }
    @((Get-Val $Report 'registrations')) | Where-Object { $null -ne $_ } | ForEach-Object {
        $app = @{ registration = $_; findings = @() }; Update-AppGovernance $app
        $_['findings'] = $app.findings; $_['status'] = $app.status
    }
}
