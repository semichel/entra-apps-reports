#requires -Version 7.0
<#
.SYNOPSIS
Verifies batched collection and sequential-result parity using synthetic Graph responses offline.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Report.Common.ps1')
. (Join-Path $PSScriptRoot 'Report.Batch.ps1')
. (Join-Path $PSScriptRoot 'Report.Evidence.ps1')
$script:LogPath = Join-Path ([IO.Path]::GetTempPath()) 'entra-batch-test.log'
$script:Routes = @{}; $script:Mode = ''; $script:Batches = [Collections.Generic.List[object]]::new()
$script:GetCalls = 0; $script:Sleeps = [Collections.Generic.List[int]]::new()

#= Synthetic Graph transport checks that every batch member is a GET
function Invoke-MgGraphRequest {
    param($Method, $Uri, $Body, $OutputType, $ContentType)
    if ($script:Mode -eq 'Transport') { throw 'Synthetic transport failure.' }
    if ($Method -eq 'GET') {
        $script:GetCalls++
        $route = $script:Routes[([uri]$Uri).PathAndQuery.Substring('/v1.0'.Length)]
        if ($route.status -ne 200) { throw 'Synthetic optional Graph error.' }
        return $route.body
    }
    if ($Uri -ne 'https://graph.microsoft.com/v1.0/$batch' -or $Method -ne 'POST') { throw 'Unexpected transport operation.' }
    $requests = @((ConvertFrom-Json $Body -AsHashtable).requests)
    if ($requests.Count -gt 20 -or $requests.Count -eq 0) { throw 'Invalid batch size.' }
    $script:Batches.Add($requests)
    $responses = @($requests | ForEach-Object {
        if ($_.method -ne 'GET') { throw 'Batch contains a write operation.' }
        $route = $script:Routes[$_.url]
        if ($route -is [scriptblock]) { $route = & $route $_ }
        @{ id = $_.id; status = $route.status; body = Get-Val $route 'body'; headers = Get-Val $route 'headers' }
    })
    [array]::Reverse($responses)
    if ($script:Mode -eq 'Missing') { return @{ responses = @() } }
    if ($script:Mode -eq 'Duplicate') { $responses[0].id = $responses[1].id }
    return @{ responses = $responses }
}

#= Record retry delays without waiting in offline tests
function Start-Sleep {
    param([int]$Seconds)
    $script:Sleeps.Add($Seconds)
}

#= Ignore dictionary ordering when comparing complete collected evidence
function ConvertTo-TestCanonical {
    param($Value)
    if ($Value -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in @($Value.Keys | Sort-Object)) {
            $result[$key] = ConvertTo-TestCanonical (Get-Val $Value $key)
        }
        return $result
    }
    if ($Value -is [System.Collections.IList]) { return ,@($Value | ForEach-Object { ConvertTo-TestCanonical $_ }) }
    return $Value
}

$mustThrow = {
    param([scriptblock]$Action, [string]$Pattern)
    $thrown = $false
    try { & $Action | Out-Null } catch { $thrown = $true; if ($_ -notmatch $Pattern) { throw } }
    if (-not $thrown) { throw ('Expected failure: ' + $Pattern) }
}

$requests = [ordered]@{}
foreach ($number in 1..41) {
    $requests['https://graph.microsoft.com/v1.0/items/' + $number] = $true
    $script:Routes['/items/' + $number] = @{ status = 200; body = @{ value = @(@{ id = [string]$number }) } }
}
$script:Routes['/items/1'] = @{ status = 200; body = @{ value = @(); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/items/1?page=2' } }
$script:Routes['/items/1?page=2'] = @{ status = 200; body = @{ value = @(@{ id = 'second-page' }); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/items/1?page=3' } }
$script:Routes['/items/1?page=3'] = @{ status = 200; body = @{ value = @(@{ id = 'third-page' }) } }
$expected = @{}
foreach ($uri in $requests.Keys) {
    $expected[$uri] = @{ status = 'AVAILABLE'; items = @(Invoke-MgGetAll $uri); reason = $null }
}
$actual = Invoke-ReportBatchGetAll $requests
$expectedJson = ConvertTo-Json (ConvertTo-TestCanonical $expected) -Depth 30 -Compress
if ((ConvertTo-Json (ConvertTo-TestCanonical $actual) -Depth 30 -Compress) -ne $expectedJson) { throw 'Batch results differ from sequential results.' }
if ($script:Batches.Count -ne 4 -or $script:GetCalls -ne 43) { throw 'Expected four batches instead of 43 individual GETs, including empty-page pagination.' }
$before = $script:GetCalls
[void](Invoke-MgGetAll 'https://graph.microsoft.com/v1.0/items/1' $actual)
if ($script:GetCalls -ne $before) { throw 'Prefetched evidence was downloaded again.' }

$script:RetryCount = 0; $script:Batches.Clear(); $script:Sleeps.Clear()
$script:Routes['/retry'] = {
    $script:RetryCount++
    if ($script:RetryCount -lt 3) { return @{ status = 429; headers = @{ 'Retry-After' = '3' } } }
    return @{ status = 200; body = @{ value = @(@{ id = 'retried' }) } }
}
$retry = Invoke-ReportBatchGetAll ([ordered]@{ 'https://graph.microsoft.com/v1.0/retry' = $true; 'https://graph.microsoft.com/v1.0/items/2' = $true })
if ($script:Batches.Count -ne 3 -or $script:Batches[1].Count -ne 1 -or $script:Batches[2].Count -ne 1) { throw 'Only transient failures should be retried.' }
if ($script:Sleeps[0] -lt 3 -or (Get-Str (Get-Val $retry 'https://graph.microsoft.com/v1.0/retry') 'status') -ne 'AVAILABLE') { throw 'Retry-After or retry completion failed.' }
$script:Routes['/retry'] = @{ status = 503; headers = @{ 'Retry-After' = '0' } }
$script:Batches.Clear()
$exhausted = Invoke-ReportBatchGetAll @{ 'https://graph.microsoft.com/v1.0/retry' = $false }
if ($script:Batches.Count -ne 5 -or (Get-Str (Get-Val $exhausted 'https://graph.microsoft.com/v1.0/retry') 'status') -ne 'UNAVAILABLE') { throw 'Transient retries must be bounded.' }

$script:Routes['/partial'] = @{ status = 200; body = @{ value = @(@{ id = 'incomplete' }); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/denied' } }
$script:Routes['/denied'] = @{ status = 403 }
$unavailable = Invoke-ReportBatchGetAll @{ 'https://graph.microsoft.com/v1.0/partial' = $false }
$optional = Get-OptionalEvidence 'https://graph.microsoft.com/v1.0/partial' $unavailable
if ((Get-Str $optional 'status') -ne 'UNAVAILABLE' -or @((Get-Val $optional 'items')).Count) { throw 'A failed later page must discard partial optional evidence.' }
& $mustThrow { Invoke-ReportBatchGetAll @{ 'https://graph.microsoft.com/v1.0/denied' = $true } } 'HTTP 403'
& $mustThrow { Invoke-MgGetAll 'https://graph.microsoft.com/v1.0/partial' $unavailable } 'HTTP 403'

$script:Mode = 'Missing'
& $mustThrow { Invoke-ReportBatchGetAll @{ 'https://graph.microsoft.com/v1.0/items/2' = $true } } 'Incomplete Graph batch'
$script:Mode = 'Duplicate'
& $mustThrow { Invoke-ReportBatchGetAll ([ordered]@{ 'https://graph.microsoft.com/v1.0/items/2' = $true; 'https://graph.microsoft.com/v1.0/items/3' = $true }) } 'duplicate Graph batch'
$script:Mode = ''
$script:Routes['/cycle'] = @{ status = 200; body = @{ value = @(); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/cycle' } }
& $mustThrow { Invoke-ReportBatchGetAll @{ 'https://graph.microsoft.com/v1.0/cycle' = $false } } 'Repeated Graph batch nextLink'
$script:Routes['/bad-link'] = @{ status = 200; body = @{ value = @(); '@odata.nextLink' = 'https://example.invalid/v1.0/items' } }
& $mustThrow { Invoke-ReportBatchGetAll @{ 'https://graph.microsoft.com/v1.0/bad-link' = $true } } 'Batch relationship URL'
& $mustThrow { Invoke-ReportBatchGetAll @{ 'http://graph.microsoft.com/v1.0/items' = $true } } 'Batch relationship URL'
$script:Routes['/bad-body'] = @{ status = 200; body = @{} }
& $mustThrow { Invoke-ReportBatchGetAll @{ 'https://graph.microsoft.com/v1.0/bad-body' = $false } } 'no value collection'
$script:Mode = 'Transport'
$transport = Invoke-ReportBatchGetAll @{ 'https://graph.microsoft.com/v1.0/items/2' = $false }
if ((Get-Str (Get-Val $transport 'https://graph.microsoft.com/v1.0/items/2') 'status') -ne 'UNAVAILABLE') { throw 'Optional transport errors must remain unavailable.' }
& $mustThrow { Invoke-ReportBatchGetAll @{ 'https://graph.microsoft.com/v1.0/items/2' = $true } } 'transport failure'
$script:Mode = ''
Write-Host 'Batch transport and pagination checks passed (offline).' -ForegroundColor Green

$catalog = @(
    @{ id = 'sp-1'; appId = 'app-1'; displayName = 'Example'; servicePrincipalType = 'Application'; appRoleAssignmentRequired = $true; preferredSingleSignOnMode = 'saml'; replyUrls = @('https://example.test/callback'); owners = @(1..20 | ForEach-Object { @{ id = ('owner-' + $_) } }); keyCredentials = @(@{ keyId = 'cert-1'; startDateTime = '2020-01-01T00:00:00Z'; endDateTime = '2020-04-01T00:00:00Z'; key = 'CERTIFICATE_BYTES_MUST_NOT_APPEAR' }); notes = 'Notes'; appRoles = @() }
    @{ id = 'sp-2'; appId = 'app-2'; displayName = 'Other'; servicePrincipalType = 'Application'; owners = @(); appRoles = @() }
    @{ id = 'graph-resource'; appId = '00000003-0000-0000-c000-000000000000'; servicePrincipalType = 'ManagedIdentity'; appRoles = @(@{ id = 'read-role'; value = 'User.Read.All'; displayName = 'Read users' }) }
)
$registrations = @(@{ id = 'reg-1'; appId = 'app-1'; displayName = 'Registration'; owners = @(@{ id = 'truncated-owner' }); 'owners@odata.nextLink' = 'https://graph.microsoft.com/v1.0/applications/reg-1/owners?page=2'; passwordCredentials = @(@{ keyId = 'secret-1'; secretText = 'SECRET_MUST_NOT_APPEAR'; startDateTime = '2020-01-01T00:00:00Z'; endDateTime = '2020-04-01T00:00:00Z' }) })
$owner = @{ id = 'owner-1'; '@odata.type' = '#microsoft.graph.user'; userPrincipalName = 'azadmu.owner@example.test' }
$ownerSelect = '?$select=id,displayName,userPrincipalName'
$assignmentSelect = '?$select=id,principalId,principalDisplayName,principalType,appRoleId,resourceId'
$grantSelect = '?$select=id,appRoleId,resourceId,resourceDisplayName,principalId'
$script:Routes = @{
    ('/servicePrincipals/sp-1/owners' + $ownerSelect) = @{ status = 200; body = @{ value = @($owner) } }
    ('/servicePrincipals/sp-1/appRoleAssignedTo' + $assignmentSelect) = @{ status = 200; body = @{ value = @(@{ id = 'assignment-1'; principalId = 'user-1'; principalType = 'User' }); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/servicePrincipals/sp-1/appRoleAssignedTo?page=2' } }
    '/servicePrincipals/sp-1/appRoleAssignedTo?page=2' = @{ status = 200; body = @{ value = @(@{ id = 'assignment-2'; principalId = 'group-1'; principalType = 'Group' }) } }
    ('/servicePrincipals/sp-1/appRoleAssignments' + $grantSelect) = @{ status = 200; body = @{ value = @(@{ id = 'grant-1'; resourceId = 'graph-resource'; appRoleId = 'read-role' }) } }
    ('/servicePrincipals/sp-2/appRoleAssignedTo' + $assignmentSelect) = @{ status = 200; body = @{ value = @() } }
    ('/servicePrincipals/sp-2/appRoleAssignments' + $grantSelect) = @{ status = 200; body = @{ value = @() } }
    ('/applications/reg-1/owners' + $ownerSelect) = @{ status = 200; body = @{ value = @($owner) } }
    '/applications/reg-1/federatedIdentityCredentials' = @{ status = 200; body = @{ value = @(@{ id = 'federation-1'; issuer = 'https://issuer.example.test'; subject = 'repo:example/test' }) } }
    '/roleManagement/directory/roleAssignments?$expand=roleDefinition' = @{ status = 200; body = @{ value = @(@{ id = 'role-assignment'; principalId = 'sp-1'; roleDefinitionId = 'reader'; roleDefinition = @{ displayName = 'Reader'; templateId = 'reader' } }) } }
    '/users?$top=999&$select=id,displayName,userPrincipalName,employeeId,mail' = @{ status = 200; body = @{ value = @(@{ id = 'owner-1'; userPrincipalName = 'azadmu.owner@example.test'; employeeId = '123' }, @{ id = 'regular-user'; userPrincipalName = 'owner@example.test'; employeeId = '123'; mail = 'owner@example.test' }) } }
}
$catalogJson = ConvertTo-Json -InputObject $catalog -Depth 20
$registrationsJson = ConvertTo-Json -InputObject $registrations -Depth 20
$snapshots = @{}; $counts = @{}
foreach ($mode in @('sequential', 'batched')) {
    $catalog = @(ConvertFrom-Json $catalogJson -AsHashtable)
    $registrations = @(ConvertFrom-Json $registrationsJson -AsHashtable)
    $principals = @($catalog | Where-Object { (Get-Str $_ 'servicePrincipalType') -eq 'Application' })
    $byApp = @{}; $script:GetCalls = 0; $script:Batches.Clear()
    foreach ($registration in $registrations) {
        $byApp[(Get-Str $registration 'appId')] = $registration
    }
    $cache = if ($mode -eq 'batched') { Get-ReportRelationshipEvidence $principals $registrations } else { $null }
    $report = [ordered]@{ applications = @($principals | ForEach-Object { Get-LiveAppReport $_ $byApp $cache }); ruleConfiguration = Get-ReportRuleConfiguration $null }
    Add-ExtendedEvidence $report -Registrations $registrations -Principals $catalog -EvidenceCache $cache
    Update-ReportGovernance $report
    $report.Remove('evidenceCollectedAtUtc')
    $snapshots[$mode] = ConvertTo-Json (ConvertTo-TestCanonical $report) -Depth 60 -Compress
    $counts[$mode] = $script:GetCalls + $script:Batches.Count
    $app = @((Get-Val $report 'applications'))[0]
    if ((Get-Str @((Get-Val $app 'owners'))[0] 'userEmail') -ne 'owner@example.test') { throw 'Owner contact matching changed.' }
    if (@((Get-Val $app 'assignments')).Count -ne 2) { throw 'Assignment pagination was lost.' }
    if ((Get-Str @((Get-Val (Get-Val $app 'applicationPermissionGrants') 'items'))[0] 'permission') -ne 'User.Read.All') { throw 'Resource permission-name resolution was lost.' }
    if ($snapshots[$mode] -match 'MUST_NOT_APPEAR') { throw 'Credential content leaked into the report.' }
}
if ($snapshots['sequential'] -ne $snapshots['batched']) { throw 'Collected evidence or governance results changed after batching.' }
if ($counts['batched'] -ne 4 -or $counts['sequential'] -ne 10) { throw 'Unexpected collection request counts.' }
Write-Host ('Full evidence and governance parity passed: {0} sequential requests versus {1} batch/catalog requests.' -f $counts['sequential'], $counts['batched']) -ForegroundColor Green
