#requires -Version 7.0
<#
.SYNOPSIS
Recreates HTML and CSV files from an existing report.json without connecting to Graph.
.EXAMPLE
./Render-Report.ps1
#>
[CmdletBinding()]
param(
    [string]$ReportPath = (Join-Path $PSScriptRoot 'reports/latest/report.json'),
    [string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/Report.Common.ps1')
Assert-ReportPrerequisites
$savedReportPath = (Resolve-Path -LiteralPath $ReportPath).Path
if (-not $OutputDirectory) { $OutputDirectory = Split-Path -Parent $savedReportPath }
$script:LogPath = if ($env:IACPORTAL_LOG) { $env:IACPORTAL_LOG } else { Join-Path ([IO.Path]::GetTempPath()) ('entra-report-render-{0}.log' -f [guid]::NewGuid()) }
$report = Get-Content -LiteralPath $savedReportPath -Raw | ConvertFrom-Json -AsHashtable -Depth 100
Export-AppReport $report $OutputDirectory
Write-ReportLog ('Report recreated: {0}. No Graph connection or collection.' -f (Join-Path ([IO.Path]::GetFullPath($OutputDirectory)) 'report.html')) Green
