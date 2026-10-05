<#
.SYNOPSIS
Runs offline report, pagination, tenant guard and credential policy checks.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../scripts/Report.Common.ps1')

#= Test assertion
function Assert-Report {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

#= Mock Graph transport for pagination
function Invoke-MgGraphRequest {
    param($Method, $Uri, $OutputType)
    Assert-Report ($Method -eq 'GET') 'Report transport must only use GET.'
    $script:RequestedUrls.Add($Uri)
    if ($Uri -eq 'https://graph.microsoft.com/v1.0/mock') {
        return @{ value = @(@{ id = 'first' }); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/mock?page=2' }
    }
    return @{ value = @(@{ id = 'second' }) }
}

Assert-Report ($null -eq (Get-Val $null 'absent')) 'Null helper failed.'
Assert-Report ($null -eq (Get-Val @{present = 1} 'absent')) 'Missing hashtable property failed.'
Assert-Report ($null -eq (Get-Str ([pscustomobject]@{present = 1}) 'absent')) 'Missing object property failed.'
Assert-Report ((Get-Str ([ordered]@{name = 'lab'}) 'name') -eq 'lab') 'Ordered dictionary failed.'
Assert-Report ((Convert-CsvText '=SUM(1,2)') -eq "'=SUM(1,2)") 'Spreadsheet formulas must be neutralized.'
$script:RequestedUrls = [System.Collections.Generic.List[string]]::new()
$pages = @(Invoke-MgGetAll 'https://graph.microsoft.com/v1.0/mock')
Assert-Report ($pages.Count -eq 2 -and $script:RequestedUrls.Count -eq 2) 'Pagination lost results.'
$blocked = $false
try { Invoke-ReportGet 'https://example.com/mock' | Out-Null } catch { $blocked = $true }
Assert-Report $blocked 'Unexpected nextLink host must be blocked.'
$fixture = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixture.json') -Raw | ConvertFrom-Json -AsHashtable
$first = $fixture['entries'][0]
$app = New-AppReport $first['principal'] $first['registration'] $first['owners'] $first['assignments']
Assert-Report ($app['status'] -eq 'FAIL') 'Insecure demo app must fail.'
Assert-Report (@($app['findings'] | Where-Object { $_['rule'] -eq 'RedirectUriSecurity' -and $_['status'] -eq 'FAIL' }).Count -eq 1) 'HTTP production callback must fail.'
$second = $fixture['entries'][1]
$app = New-AppReport $second['principal'] $second['registration'] $second['owners'] $second['assignments']
Assert-Report ($app['status'] -eq 'MANUAL') 'Configuration observations cannot certify complete compliance.'
Assert-Report ($app['owners'].Count -eq 3) 'Automation owner disappeared.'
$unknown = New-AppReport @{ id='unknown'; appId='unknown'; displayName='unknown' } $null @() @()
Assert-Report (@($unknown['findings'] | Where-Object { $_['rule'] -eq 'AssignmentRequired' -and $_['status'] -eq 'UNKNOWN' }).Count -eq 1) 'Missing assignment setting must be UNKNOWN.'
$now = [DateTimeOffset]::UtcNow
$secret = @{keyId='test'; startDateTime=$now.AddDays(-10).ToString('o'); endDateTime=$now.AddDays(80).ToString('o'); secretText='MUST-NOT-EXPORT'}
$credential = Convert-Credential $secret 'passwordCredentials' 'AppRegistration'
Assert-Report ($credential['status'] -eq 'PASS') 'A 90-day secret with 80 days remaining should pass.'
Assert-Report (-not $credential.Contains('secretText')) 'Secret value leaked.'
$secret['startDateTime'] = $now.AddDays(-100).ToString('o')
$credential = Convert-Credential $secret 'passwordCredentials' 'AppRegistration'
Assert-Report ($credential['status'] -eq 'FAIL') 'Secret lifetime above 90 days must fail.'
$secret['endDateTime'] = $now.AddDays(-1).ToString('o')
$credential = Convert-Credential $secret 'passwordCredentials' 'AppRegistration'
Assert-Report ($credential['status'] -eq 'FAIL') 'Expired secret must fail.'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Get-ChildItem -LiteralPath $repo -Recurse -Filter '*.ps1' | ForEach-Object {
    $parseTokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$parseTokens, [ref]$parseErrors)
    Assert-Report ($parseErrors.Count -eq 0) ("Syntax error in {0}" -f $_.Name)
}
$wrongTenantBlocked = $false
try { & (Join-Path $repo 'scripts/Export-EntraAppsReport.ps1') -TenantId '99999999-9999-9999-9999-999999999999' } catch { $wrongTenantBlocked = $true }
Assert-Report $wrongTenantBlocked 'Foreign tenant must be rejected before authentication.'
$output = Join-Path $repo 'reports/test'
& (Join-Path $repo 'scripts/Export-EntraAppsReport.ps1') -Demo -OutputDirectory $output
$report = Get-Content -LiteralPath (Join-Path $output 'report.json') -Raw | ConvertFrom-Json -AsHashtable
Assert-Report ($report['mode'] -eq 'DEMO' -and $report['applications'].Count -eq 2) 'Demo end-to-end report failed.'
$html = Get-Content -LiteralPath (Join-Path $output 'report.html') -Raw
Assert-Report ($html.Contains('&lt;test&gt;') -and -not $html.Contains('application <test>')) 'HTML app name must be escaped.'
Assert-Report ((Import-Csv -LiteralPath (Join-Path $output 'findings.csv')).Count -gt 0) 'CSV missing findings.'
Write-Host 'All offline report checks passed.' -ForegroundColor Green

