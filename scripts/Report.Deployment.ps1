Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#= Validate report settings and the reader IDs supplied locally or by GitHub secrets
function Read-ReportDeployment {
    param(
        [string]$Path,
        [string]$TenantId = $env:AZURE_TENANT_ID,
        [string]$ClientId = $env:AZURE_CLIENT_ID
    )
    $config = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable
    $config['tenantId'] = $TenantId
    $config['clientId'] = $ClientId
    foreach ($field in @('tenantId', 'clientId')) {
        $parsed = [guid]::Empty
        if (-not [guid]::TryParse((Get-Str $config $field), [ref]$parsed) -or $parsed -eq [guid]::Empty) { throw "Supply valid TenantId and ClientId parameters, or AZURE_TENANT_ID and AZURE_CLIENT_ID environment values ($field is missing or invalid)." }
    }
    if ([string]::IsNullOrWhiteSpace((Get-Str $config 'tenantDisplayName'))) { throw 'Fill tenantDisplayName with the production tenant name.' }
    return $config
}

#= Match the reader identity before making any production inventory request
function Assert-ReportDeploymentContext {
    param($Context, [System.Collections.IDictionary]$Config)
    if ((Get-Str $Context 'TenantId') -ne (Get-Str $Config 'tenantId') -or (Get-Str $Context 'Environment') -ne 'Global') { throw 'Graph tenant/cloud does not match production configuration. No Graph requests made.' }
    if ((Get-Str $Context 'ClientId') -ne (Get-Str $Config 'clientId')) { throw 'Graph client does not match the configured production reader. No Graph requests made.' }
}
