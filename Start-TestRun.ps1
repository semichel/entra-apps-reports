#requires -Version 7.0
<#
.SYNOPSIS
Starts a local report test using your own Microsoft Entra account.
.EXAMPLE
./Start-TestRun.ps1
.EXAMPLE
./Start-TestRun.ps1 -TenantId 'YOUR-TENANT-ID' -UseDeviceCode
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][guid]$TenantId,
    [switch]$UseDeviceCode,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'reports/latest')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'scripts/Invoke-EntraAppsReport.ps1') @PSBoundParameters
