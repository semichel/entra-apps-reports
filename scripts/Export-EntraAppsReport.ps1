<#
.SYNOPSIS
Exports read-only enterprise application configuration findings from a lab tenant.
.DESCRIPTION
Uses Microsoft Graph GET requests only. Demo mode uses local synthetic data.
Live mode requires an explicit lab tenant ID and validates Graph context.
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
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '../reports/latest')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Report.Common.ps1')
$script:LogPath = if ($env:IACPORTAL_LOG) { $env:IACPORTAL_LOG } else { Join-Path ([IO.Path]::GetTempPath()) ('entra-apps-report-{0}.log' -f [guid]::NewGuid()) }
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
    if (-not [guid]::TryParse($TenantId, [ref]$parsedTenant) -or $parsedTenant -eq [guid]::Empty) { throw 'Provide the confirmed MichelAB lab tenant GUID using -TenantId.' }
    if ($parsedTenant -ne [guid]'37dadda4-f2a4-47a8-8482-d40fe1a5aa48') { throw 'This project is restricted to the confirmed MichelAB lab tenant.' }
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
    if ($null -eq $context -or $context.TenantId -ne $TenantId -or $context.Environment -ne 'Global') { throw 'Graph context does not match the requested lab tenant / Global cloud. No report generated.' }
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
if ($IncludeExtendedEvidence -and -not $Demo) {
    . (Join-Path $PSScriptRoot 'Report.Evidence.ps1')
    Add-ExtendedEvidence $report
}
Export-AppReport $report $OutputDirectory
Write-ReportLog ("Report written to {0}; log: {1}" -f [IO.Path]::GetFullPath($OutputDirectory), $script:LogPath) Green
