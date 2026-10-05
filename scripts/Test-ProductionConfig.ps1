<#
.SYNOPSIS
Validates production deployment configuration and prints manual federation settings.
.DESCRIPTION
Offline validation only. Does not authenticate or change Entra or GitHub.
.EXAMPLE
./scripts/Test-ProductionConfig.ps1 -ConfigPath ./config/production.json
#>
[CmdletBinding()]
param([string]$ConfigPath = (Join-Path $PSScriptRoot '../config/production.json'))
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Report.Common.ps1')
. (Join-Path $PSScriptRoot 'Report.Deployment.ps1')
$config = Read-ReportDeployment $ConfigPath -AllowDisabled
Write-Host 'Production configuration is valid. No service was contacted.' -ForegroundColor Green
Write-Host ('Tenant: {0} ({1})' -f (Get-Str $config 'tenantDisplayName'), (Get-Str $config 'tenantId')) -ForegroundColor Cyan
Write-Host ('Client ID: {0}' -f (Get-Str $config 'clientId')) -ForegroundColor Cyan
Write-Host 'Federated issuer: https://token.actions.githubusercontent.com' -ForegroundColor Cyan
Write-Host ('Federated subject: repo:{0}:environment:production' -f (Get-Str $config 'githubRepository')) -ForegroundColor Cyan
Write-Host 'Federated audience: api://AzureADTokenExchange' -ForegroundColor Cyan
Write-Host ('Trusted branch: {0}; artifact retention: {1} days' -f (Get-Str $config 'githubBranch'), (Get-Val $config 'artifactRetentionDays')) -ForegroundColor Cyan
if (-not (Get-Val $config 'enabled')) { Write-Host 'Deployment remains disabled until manual setup is completed and enabled is set to true.' -ForegroundColor Yellow }
