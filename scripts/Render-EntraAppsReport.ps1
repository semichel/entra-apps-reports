#requires -Version 7.0
<#
.SYNOPSIS
Builds the HTML report from a saved JSON snapshot without contacting Entra.
.EXAMPLE
./scripts/Render-EntraAppsReport.ps1 -DataPath ./reports/latest/report.json
#>
[CmdletBinding()]
param(
    [string]$DataPath = (Join-Path $PSScriptRoot '../reports/latest/report.json'),
    [string]$OutputPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Report.Common.ps1')
. (Join-Path $PSScriptRoot 'Report.Render.ps1')
Assert-ReportPrerequisites
$report = Read-ReportDatabase $DataPath
$DataPath = (Resolve-Path -LiteralPath $DataPath).ProviderPath
if (-not $OutputPath) { $OutputPath = Join-Path ([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($DataPath))) 'report.html' }
$OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
if ([IO.Path]::GetFullPath($OutputPath) -eq [IO.Path]::GetFullPath($DataPath)) { throw 'HTML output must not overwrite the JSON data file.' }
Export-ReportHtml $report $OutputPath
Write-Host ('HTML report rendered from saved data: {0}' -f [IO.Path]::GetFullPath($OutputPath)) -ForegroundColor Green
