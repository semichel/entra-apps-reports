<#
.SYNOPSIS
Runs the complete report locally using your own Microsoft Entra account.
.DESCRIPTION
Uses delegated interactive authentication with read-only Graph scopes.
Requires PowerShell 7 and Microsoft.Graph.Authentication.
.EXAMPLE
./scripts/Invoke-EntraAppsReport.ps1 -TenantId 'YOUR-PRODUCTION-TENANT-ID'
.EXAMPLE
./scripts/Invoke-EntraAppsReport.ps1 -TenantId 'YOUR-PRODUCTION-TENANT-ID' -UseDeviceCode
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][guid]$TenantId,
    [switch]$UseDeviceCode,
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../config/production.json'),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '../reports/latest')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Report.Common.ps1')
if ($TenantId -eq [guid]::Empty) { throw 'Supply the intended tenant ID.' }
Write-Host ('[{0:HH:mm:ss}] Checking report files and Microsoft Graph module.' -f [DateTimeOffset]::Now) -ForegroundColor Cyan
Assert-ReportPrerequisites
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$connection = @{
    TenantId = $TenantId.ToString()
    Scopes = @('Application.Read.All', 'Directory.Read.All', 'Policy.Read.All', 'AuditLog.Read.All')
    ContextScope = 'Process'
    NoWelcome = $true
}
if ($UseDeviceCode) { $connection['UseDeviceCode'] = $true }
Write-Host 'Sign in with your own account in the intended tenant.' -ForegroundColor Cyan
Connect-MgGraph @connection
try {
    $context = Get-MgContext
    Write-Host ('[{0:HH:mm:ss}] Signed in as {1}. Starting report collection.' -f [DateTimeOffset]::Now, (Get-Str $context 'Account')) -ForegroundColor Green
    if ((Get-Str $context 'AuthType') -ne 'Delegated') { throw 'Manual execution requires delegated user authentication.' }
    & (Join-Path $PSScriptRoot 'Export-EntraAppsReport.ps1') -ConfigPath $ConfigPath -OutputDirectory $OutputDirectory -TenantId $TenantId.ToString() -ClientId (Get-Str $context 'ClientId')
} finally {
    Write-Progress -Id 1 -Activity 'Report collection' -Completed
    Write-Progress -Id 2 -Activity 'Microsoft Graph request' -Completed
    Disconnect-MgGraph | Out-Null
}
