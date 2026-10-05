Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#= Escape nested report evidence for readable HTML
function Convert-EvidenceHtml {
    param($Value)
    if ($null -eq $Value) { return '<p>No local evidence available.</p>' }
    $json = ConvertTo-Json -InputObject $Value -Depth 40
    return '<pre>' + [System.Net.WebUtility]::HtmlEncode($json) + '</pre>'
}

#= Complete HTML report with index and application evidence
function New-FullReportHtml {
    param($Report)
    $html = [Text.StringBuilder]::new()
    [void]$html.Append('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>MichelAB Entra application report</title><style>body{font:15px system-ui;color:#18314b;background:#f5f7fb;margin:0}main{max-width:1300px;margin:auto;padding:32px}header,.app,.panel{background:white;padding:24px;border:1px solid #d7e0eb;border-radius:12px;margin-bottom:20px}h1{margin-top:0}table{border-collapse:collapse;width:100%;margin:16px 0}td,th{padding:9px;border:1px solid #d7e0eb;text-align:left;vertical-align:top}th{background:#edf3f9}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:13px ui-monospace;background:#f1f5fa;padding:16px;max-height:650px;overflow:auto}input{padding:12px;width:calc(100% - 28px);font:inherit}summary{cursor:pointer;font-weight:600;padding:12px 0}a{color:#175ea3}.FAIL{color:#ad2831}.PASS{color:#166b47}.WARN,.MANUAL,.UNKNOWN{color:#8b610d}.muted{color:#567}@media print{input{display:none}details{display:block}}</style></head><body><main><header><h1>Entra application configuration report</h1>')
    $apps = @((Get-Val $Report 'applications') | Sort-Object { Get-Str $_ 'displayName' })
    [void]$html.Append(('<p><strong>Tenant:</strong> MichelAB — {0}<br><strong>Collected UTC:</strong> {1}<br><strong>Mode:</strong> {2} | <strong>Application service principals:</strong> {3} | <strong>Local registrations:</strong> {4}</p>' -f [System.Net.WebUtility]::HtmlEncode((Get-Str $Report 'tenantId')), [System.Net.WebUtility]::HtmlEncode((Get-Str $Report 'generatedAtUtc')), (Get-Str $Report 'mode'), $apps.Count, @(Get-Val $Report 'registrations').Where({$null -ne $_}).Count))
    [void]$html.Append('<p>Catalog coverage includes platform and resource applications. A failed policy observation does not establish that every catalog entry is a production SSO application. Confirm applicability before remediation. Manual sign-in, application-side verification, TLS, approvals and business documentation remain required.</p><p>Use the application index below. Expand an application to inspect findings, owners, assigned principals, credential dates and configuration evidence. Credential values and private keys are excluded.</p></header><section class="panel"><h2>Application index</h2><input id="search" placeholder="Filter by application name, client ID or protocol" aria-label="Filter applications"><table><thead><tr><th>Application</th><th>Protocol hint</th><th>Policy observations</th><th>Owners</th><th>Assignments</th></tr></thead><tbody id="index">')
    $index = 0
    foreach ($app in $apps) {
        [void]$html.Append(('<tr><td><a href="#app-{0}">{1}</a><br><small>{2}</small></td><td>{3}</td><td>{4}</td><td>{5}</td><td>{6}</td></tr>' -f $index++, [System.Net.WebUtility]::HtmlEncode((Get-Str $app 'displayName')), [System.Net.WebUtility]::HtmlEncode((Get-Str $app 'appId')), (Get-Str $app 'protocol'), (Get-Str $app 'status'), @(Get-Val $app 'owners').Count, @(Get-Val $app 'assignments').Count))
    }
    [void]$html.Append('</tbody></table></section><section class="panel"><h2>Tenant evidence and coverage gaps</h2><p>Recent logs cover the configured lookback window, not all historical activity. UNAVAILABLE means the query could not be completed; it never means the tenant passed a control. Conditional Access policies are tenant evidence and need per-app applicability review.</p>')
    [void]$html.Append((Convert-EvidenceHtml (Get-Val $Report 'tenantEvidence')))
    [void]$html.Append('</section>')
    $index = 0
    foreach ($app in $apps) {
        [void]$html.Append((New-AppEvidenceHtml $app $index))
        $index++
    }
    [void]$html.Append('<section class="panel"><h2>All local app registrations</h2><p>Includes registrations without a local enterprise application. Their registration evidence is included here; enterprise application policy findings apply only where a service principal exists.</p>')
    [void]$html.Append((Convert-EvidenceHtml (Get-Val $Report 'registrations')))
    [void]$html.Append('</section></main><script>document.getElementById("search").addEventListener("input",function(){const q=this.value.toLowerCase();document.querySelectorAll("#index tr").forEach(function(row){row.hidden=!row.textContent.toLowerCase().includes(q);});});</script></body></html>')
    return $html.ToString()
}

#= Application detail with full collected evidence and explicit manual checks
function New-AppEvidenceHtml {
    param($App, [int]$Index)
    $html = [Text.StringBuilder]::new()
    [void]$html.Append(('<details class="app" id="app-{0}"><summary>{1} — {2}</summary><p>Client ID: {3}<br>Enterprise application ID: {4}<br>Enabled: {5}</p><table><tr><th>Check</th><th>Status</th><th>Evidence / next action</th></tr>' -f $Index, [System.Net.WebUtility]::HtmlEncode((Get-Str $App 'displayName')), (Get-Str $App 'status'), [System.Net.WebUtility]::HtmlEncode((Get-Str $App 'appId')), [System.Net.WebUtility]::HtmlEncode((Get-Str $App 'servicePrincipalId')), (Get-Val $App 'accountEnabled')))
    foreach ($finding in @(Get-Val $App 'findings')) {
        [void]$html.Append(('<tr><td>{0}</td><td class="{1}">{1}</td><td>{2}</td></tr>' -f (Get-Str $finding 'rule'), (Get-Str $finding 'status'), [System.Net.WebUtility]::HtmlEncode((Get-Str $finding 'evidence'))))
    }
    [void]$html.Append('</table>')
    foreach ($section in @('owners','assignments','credentials','redirectUris','registration','applicationPermissionGrants','delegatedConsentGrants','recentSignIns')) {
        [void]$html.Append(('<h3>{0}</h3>{1}' -f $section, (Convert-EvidenceHtml (Get-Val $App $section))))
    }
    [void]$html.Append('<details><summary>Complete collected application configuration</summary>')
    [void]$html.Append((Convert-EvidenceHtml $App))
    [void]$html.Append('</details></details>')
    return $html.ToString()
}

#= Flat CSV exports for evidence that administrators need to filter
function Export-DetailCsv {
    param($Report, [string]$OutputDirectory)
    foreach ($kind in @('owners','assignments','credentials')) {
        Export-EvidenceKindCsv $Report $OutputDirectory $kind
    }
}

#= Export one evidence collection without formula interpretation
function Export-EvidenceKindCsv {
    param($Report, [string]$OutputDirectory, [string]$Kind)
    $rows = @((Get-Val $Report 'applications') | ForEach-Object {
        $app = $_
        @(Get-Val $app $Kind) | Where-Object { $null -ne $_ } | ForEach-Object {
            $item = $_
            $row = [ordered]@{ Application = Convert-CsvText (Get-Str $app 'displayName'); AppId = Get-Str $app 'appId'; ServicePrincipalId = Get-Str $app 'servicePrincipalId' }
            foreach ($key in $item.Keys) {
                $row[$key] = Convert-CsvText ([string](Get-Val $item $key))
            }
            [pscustomobject]$row
        }
    })
    $columns = @($rows | ForEach-Object { $_.PSObject.Properties.Name } | Select-Object -Unique)
    if ($rows.Count) { $rows | Select-Object -Property $columns | Export-Csv -LiteralPath (Join-Path $OutputDirectory ($Kind + '.csv')) -NoTypeInformation -Encoding utf8 }
    else { Set-Content -LiteralPath (Join-Path $OutputDirectory ($Kind + '.csv')) -Value '"Application","AppId","ServicePrincipalId"' }
}

