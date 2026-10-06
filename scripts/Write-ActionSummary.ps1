#requires -Version 7.0
<#
.SYNOPSIS
Writes the expandable GitHub Actions summary from collected inventory.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ReportPath,
    [Parameter(Mandatory)][string]$ArtifactUrl,
    [Parameter(Mandatory)][string]$OutputPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Report.Common.ps1')
. (Join-Path $PSScriptRoot 'Report.Render.ps1')
$report = Get-Content -LiteralPath $ReportPath -Raw | ConvertFrom-Json -AsHashtable -Depth 100
Export-ReportSummary $report $ArtifactUrl $OutputPath
