<#
.SYNOPSIS
Validates report settings and production reader IDs without authenticating.
.DESCRIPTION
Offline validation only. Does not authenticate or change Entra or GitHub.
.EXAMPLE
./scripts/Validate-ProductionConfig.ps1 -ConfigPath ./config/production.json
#>
[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../config/production.json'),
    [string]$TenantId = $env:AZURE_TENANT_ID,
    [string]$ClientId = $env:AZURE_CLIENT_ID
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Report.Common.ps1')
. (Join-Path $PSScriptRoot 'Report.Deployment.ps1')
$config = Read-ReportDeployment $ConfigPath -TenantId $TenantId -ClientId $ClientId
Write-Host 'Production configuration is valid. No service was contacted.' -ForegroundColor Green
Write-Host ('Report tenant label: {0}' -f (Get-Str $config 'tenantDisplayName')) -ForegroundColor Cyan
Write-Host 'Reader IDs and report rules are valid. Federation must match this GitHub host, repository and main branch.' -ForegroundColor Cyan
Write-Host 'Allowed workflow branch: main. Organization/third-party apps and extended evidence are included; Microsoft-owned enterprise apps are excluded.' -ForegroundColor Cyan
