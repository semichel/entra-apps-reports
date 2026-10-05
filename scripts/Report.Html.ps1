Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

