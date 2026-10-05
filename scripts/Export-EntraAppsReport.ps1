<#
.SYNOPSIS
Exports read-only production Entra application configuration and evidence.
.DESCRIPTION
Requires a valid production configuration and an existing matching reader Graph context.
The GitHub workflow establishes that context using workload identity federation.
.EXAMPLE
./scripts/Export-EntraAppsReport.ps1 -ConfigPath ./config/production.json
#>
[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../config/production.json'),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '../reports/latest')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Report.Common.ps1')
. (Join-Path $PSScriptRoot 'Report.Deployment.ps1')
$script:LogPath = if ($env:IACPORTAL_LOG) { $env:IACPORTAL_LOG } else { Join-Path ([IO.Path]::GetTempPath()) ('entra-apps-report-{0}.log' -f [guid]::NewGuid()) }
$deployment = Read-ReportDeployment $ConfigPath
$TenantId = Get-Str $deployment 'tenantId'
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$context = Get-MgContext
Assert-ReportDeploymentContext $context $deployment
Write-ReportLog ("Reading application configuration from tenant {0}." -f $TenantId)
$applications = [System.Collections.Generic.List[object]]::new()
$registrations = @(Invoke-MgGetAll 'https://graph.microsoft.com/v1.0/applications?$select=id,appId,displayName,web,spa,publicClient,identifierUris,optionalClaims,passwordCredentials,keyCredentials')
$registrationByApp = @{}
foreach ($registration in $registrations) {
    $registrationByApp[(Get-Str $registration 'appId')] = $registration
}
$principals = @(Invoke-MgGetAll 'https://graph.microsoft.com/v1.0/servicePrincipals?$filter=servicePrincipalType%20eq%20%27Application%27&$select=id,appId,displayName,accountEnabled,appRoleAssignmentRequired,preferredSingleSignOnMode,replyUrls,servicePrincipalNames,samlSingleSignOnSettings,loginUrl,logoutUrl,tokenEncryptionKeyId,preferredTokenSigningKeyThumbprint,passwordCredentials,keyCredentials')
foreach ($principal in $principals) {
    $applications.Add((Get-LiveAppReport $principal $registrationByApp))
}
$report = [ordered]@{
    schemaVersion = '1.0'; tenantId = $TenantId; generatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
    tenantDisplayName = Get-Str $deployment 'tenantDisplayName'
    deploymentEnvironment = 'production'; mode = 'LIVE'; applications = $applications.ToArray()
}
. (Join-Path $PSScriptRoot 'Report.Evidence.ps1')
Add-ExtendedEvidence $report
Export-AppReport $report $OutputDirectory
Write-ReportLog ("Report written to {0}; log: {1}" -f [IO.Path]::GetFullPath($OutputDirectory), $script:LogPath) Green
