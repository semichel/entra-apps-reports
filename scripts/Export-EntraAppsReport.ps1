<#
.SYNOPSIS
Exports read-only production Entra application configuration and evidence.
.DESCRIPTION
Runs from GitHub Actions with validated configuration and a matching reader Graph context.
The workflow authenticates using workload identity federation.
.EXAMPLE
./scripts/Export-EntraAppsReport.ps1 -ConfigPath ./config/production.json
#>
[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../config/production.json'),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '../reports/latest'),
    [string]$TenantId = $env:AZURE_TENANT_ID,
    [string]$ClientId = $env:AZURE_CLIENT_ID
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Report.Common.ps1')
Assert-ReportPrerequisites
$script:LogPath = if ($env:IACPORTAL_LOG) { $env:IACPORTAL_LOG } else { Join-Path ([IO.Path]::GetTempPath()) ('entra-apps-report-{0}.log' -f [guid]::NewGuid()) }
$deployment = Read-ReportDeployment $ConfigPath -TenantId $TenantId -ClientId $ClientId
$TenantId = Get-Str $deployment 'tenantId'
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$context = Get-MgContext
Assert-ReportDeploymentContext $context $deployment
$collectionTimer = [Diagnostics.Stopwatch]::StartNew()
Write-ReportLog ("Reading application configuration from tenant {0}." -f $TenantId)
Write-ReportLog ('Live progress is shown below. Log file: {0}' -f $script:LogPath)
$applications = [System.Collections.Generic.List[object]]::new()
Write-ReportLog 'Phase 1/4: loading app registrations.'
$registrations = @(Get-InventoryWithOwners 'https://graph.microsoft.com/v1.0/applications?$top=999')
Write-ReportLog ('Loaded {0} app registrations.' -f $registrations.Count) Green
$registrationByApp = @{}
foreach ($registration in $registrations) {
    $registrationByApp[(Get-Str $registration 'appId')] = $registration
}
Write-ReportLog 'Phase 2/4: loading enterprise apps, then owners, assignments and credential dates for each app.'
$principals = @(Get-InventoryWithOwners 'https://graph.microsoft.com/v1.0/servicePrincipals?$filter=servicePrincipalType%20eq%20%27Application%27&$select=id,appId,displayName,appOwnerOrganizationId,accountEnabled,appRoleAssignmentRequired,preferredSingleSignOnMode,replyUrls,servicePrincipalNames,samlSingleSignOnSettings,loginUrl,logoutUrl,tokenEncryptionKeyId,preferredTokenSigningKeyThumbprint,passwordCredentials,keyCredentials')
$loadedPrincipalCount = $principals.Count
Write-ReportLog ('Loaded {0} enterprise apps, including Microsoft-owned tenant applications.' -f $loadedPrincipalCount) Green
$index = 0
foreach ($principal in $principals) {
    $index++; Write-CollectionProgress 'Enterprise app inventory' $index $principals.Count (Get-Str $principal 'displayName')
    $applications.Add((Get-LiveAppReport $principal $registrationByApp))
}
Write-Progress -Id 1 -Activity 'Enterprise app inventory' -Completed
$report = [ordered]@{
    schemaVersion = '1.0'; tenantId = $TenantId; generatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
    tenantDisplayName = Get-Str $deployment 'tenantDisplayName'
    deploymentEnvironment = 'production'; mode = 'LIVE'; applications = $applications.ToArray()
    ruleConfiguration = Get-Val $deployment 'ruleConfiguration'
    inventoryScope = [ordered]@{ microsoftOwnedAppsExcluded = $false; excludedMicrosoftAppCount = 0; retainedApplicationCount = $principals.Count }
}
. (Join-Path $PSScriptRoot 'Report.Evidence.ps1')
Write-ReportLog 'Phase 3/4: collecting permissions, federation and owner contact matches.'
Add-ExtendedEvidence $report -Registrations $registrations
Write-ReportLog 'Phase 4/4: writing JSON data and rendering HTML.'
Export-AppReport $report $OutputDirectory
Write-ReportLog ("Report written to {0}; log: {1}" -f [IO.Path]::GetFullPath($OutputDirectory), $script:LogPath) Green
Write-ReportLog ('Total collection and rendering time: {0:hh\:mm\:ss}.' -f $collectionTimer.Elapsed) Green
