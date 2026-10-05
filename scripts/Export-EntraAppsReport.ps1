<#
.SYNOPSIS
Exports read-only enterprise application configuration findings from the lab or configured production tenant.
.DESCRIPTION
Uses Microsoft Graph GET requests only. Demo mode uses local synthetic data.
Production requires an enabled deployment config and the matching reader Graph context.
.EXAMPLE
./scripts/Export-EntraAppsReport.ps1 -Demo
.EXAMPLE
./scripts/Export-EntraAppsReport.ps1 -TenantId '<lab-guid>' -UseDeviceCode
#>
[CmdletBinding()]
param(
    [string]$TenantId = '37dadda4-f2a4-47a8-8482-d40fe1a5aa48',
    [string[]]$ApplicationIds = @(),
    [switch]$Demo,
    [switch]$UseDeviceCode,
    [switch]$UseExistingContext,
    [switch]$UseAzureCli,
    [switch]$IncludeExtendedEvidence,
    [string]$SnapshotPath,
    [string]$ConfigPath,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '../reports/latest')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Report.Common.ps1')
$script:LogPath = if ($env:IACPORTAL_LOG) { $env:IACPORTAL_LOG } else { Join-Path ([IO.Path]::GetTempPath()) ('entra-apps-report-{0}.log' -f [guid]::NewGuid()) }
$deployment = $null
if ($ConfigPath) {
    if ($Demo -or $SnapshotPath -or $UseAzureCli -or $UseDeviceCode -or -not $UseExistingContext) { throw 'Production config requires -UseExistingContext with the dedicated reader; demo, snapshot and interactive auth options cannot be combined.' }
    . (Join-Path $PSScriptRoot 'Report.Deployment.ps1')
    $deployment = Read-ReportDeployment $ConfigPath
    if ($PSBoundParameters.ContainsKey('TenantId') -and $TenantId -ne (Get-Str $deployment 'tenantId')) { throw 'TenantId conflicts with production configuration.' }
    if ($PSBoundParameters.ContainsKey('ApplicationIds') -or $PSBoundParameters.ContainsKey('IncludeExtendedEvidence')) { throw 'Set report scope in production.json when using ConfigPath.' }
    $TenantId = Get-Str $deployment 'tenantId'
    $ApplicationIds = $deployment['applicationIds']
    $IncludeExtendedEvidence = [bool](Get-Val $deployment 'includeExtendedEvidence')
}
if ($SnapshotPath) {
    if ($Demo -or $UseAzureCli -or $UseExistingContext -or $UseDeviceCode) { throw 'Snapshot rendering cannot be combined with demo or authentication options.' }
    $snapshot = Get-Content -LiteralPath $SnapshotPath -Raw | ConvertFrom-Json -AsHashtable
    if ((Get-Str $snapshot 'mode') -ne 'LIVE' -or (Get-Str $snapshot 'tenantId') -ne '37dadda4-f2a4-47a8-8482-d40fe1a5aa48') { throw 'Expected a previously collected LIVE MichelAB report.' }
    $snapshot['mode'] = 'SNAPSHOT'
    $snapshot['renderedAtUtc'] = [DateTimeOffset]::UtcNow.ToString('o')
    Export-AppReport $snapshot $OutputDirectory
    Write-ReportLog 'Rendered an existing real lab snapshot; no fresh tenant query was made.' Green
    return
}
$applications = [System.Collections.Generic.List[object]]::new()
if ($Demo) {
    Write-ReportLog 'Creating a synthetic demo report (no tenant connection).'
    $fixture = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../tests/fixture.json') -Raw | ConvertFrom-Json -AsHashtable
    foreach ($entry in @(Get-Val $fixture 'entries')) {
        $applications.Add((New-AppReport (Get-Val $entry 'principal') (Get-Val $entry 'registration') @(Get-Val $entry 'owners') @(Get-Val $entry 'assignments')))
    }
    $TenantId = 'DEMO-NO-TENANT'
}
else {
    $parsedTenant = [guid]::Empty
    if (-not [guid]::TryParse($TenantId, [ref]$parsedTenant) -or $parsedTenant -eq [guid]::Empty) { throw 'Provide a valid tenant GUID.' }
    if ($null -eq $deployment -and $parsedTenant -ne [guid]'37dadda4-f2a4-47a8-8482-d40fe1a5aa48') { throw 'A non-lab tenant requires an explicit enabled production deployment config.' }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if ($UseAzureCli) {
        $cliTenant = az account show --query tenantId -o tsv
        if ($LASTEXITCODE -ne 0 -or $cliTenant -ne $TenantId) { throw 'Azure CLI tenant must match MichelAB.' }
        $graphToken = az account get-access-token --resource https://graph.microsoft.com --query accessToken -o tsv
        if ($LASTEXITCODE -ne 0 -or -not $graphToken) { throw 'Azure CLI could not acquire a Graph token.' }
        Connect-MgGraph -AccessToken (ConvertTo-SecureString $graphToken -AsPlainText -Force) -NoWelcome
    }
    elseif (-not $UseExistingContext) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        if ($UseDeviceCode) { Connect-MgGraph -TenantId $TenantId -Scopes 'Application.Read.All' -UseDeviceCode -ContextScope Process -NoWelcome }
        else {
            try { Connect-MgGraph -TenantId $TenantId -Scopes 'Application.Read.All' -ContextScope Process -NoWelcome }
            catch {
                Write-ReportLog 'Interactive login failed; retrying with device code.' Yellow
                Connect-MgGraph -TenantId $TenantId -Scopes 'Application.Read.All' -UseDeviceCode -ContextScope Process -NoWelcome
            }
        }
    }
    $context = Get-MgContext
    if ($null -eq $context -or $context.TenantId -ne $TenantId -or $context.Environment -ne 'Global') { throw 'Graph context does not match the configured tenant / Global cloud. No report generated.' }
    if ($null -ne $deployment) { Assert-ReportDeploymentContext $context $deployment }
    Write-ReportLog ("Reading application configuration from tenant {0}." -f $context.TenantId)
    $registrations = @(Invoke-MgGetAll 'https://graph.microsoft.com/v1.0/applications?$select=id,appId,displayName,web,spa,publicClient,identifierUris,optionalClaims,passwordCredentials,keyCredentials')
    $registrationByApp = @{}
    foreach ($registration in $registrations) {
        $registrationByApp[(Get-Str $registration 'appId')] = $registration
    }
    $principals = @(Invoke-MgGetAll 'https://graph.microsoft.com/v1.0/servicePrincipals?$filter=servicePrincipalType%20eq%20%27Application%27&$select=id,appId,displayName,accountEnabled,appRoleAssignmentRequired,preferredSingleSignOnMode,replyUrls,servicePrincipalNames,samlSingleSignOnSettings,loginUrl,logoutUrl,tokenEncryptionKeyId,preferredTokenSigningKeyThumbprint,passwordCredentials,keyCredentials')
    if ($ApplicationIds.Count) {
        $principals = @($principals | Where-Object { (Get-Str $_ 'appId') -in $ApplicationIds })
        $foundIds = @($principals | ForEach-Object { Get-Str $_ 'appId' })
        if (@($ApplicationIds | Where-Object { $_ -notin $foundIds }).Count) { throw 'One or more requested application client IDs have no enterprise application in this tenant.' }
    }
    foreach ($principal in $principals) {
        $applications.Add((Get-LiveAppReport $principal $registrationByApp))
    }
}
$report = [ordered]@{
    schemaVersion = '1.0'; tenantId = $TenantId; generatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
    mode = $(if ($Demo) { 'DEMO' } else { 'LIVE' }); applications = $applications.ToArray()
}
$report['tenantDisplayName'] = if ($null -ne $deployment) { Get-Str $deployment 'tenantDisplayName' } elseif ($Demo) { 'Demo' } else { 'MichelAB' }
$report['deploymentEnvironment'] = if ($null -ne $deployment) { 'production' } elseif ($Demo) { 'demo' } else { 'lab' }
if ($IncludeExtendedEvidence -and -not $Demo) {
    . (Join-Path $PSScriptRoot 'Report.Evidence.ps1')
    Add-ExtendedEvidence $report
}
Export-AppReport $report $OutputDirectory
Write-ReportLog ("Report written to {0}; log: {1}" -f [IO.Path]::GetFullPath($OutputDirectory), $script:LogPath) Green
