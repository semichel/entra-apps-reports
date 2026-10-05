Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#= Validate the explicit production identity and report scope before authentication
function Read-ReportDeployment {
    param([string]$Path)
    $config = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable
    foreach ($field in @('tenantId', 'clientId')) {
        $parsed = [guid]::Empty
        if (-not [guid]::TryParse((Get-Str $config $field), [ref]$parsed) -or $parsed -eq [guid]::Empty) { throw "Fill $field with the production GUID." }
    }
    if ([string]::IsNullOrWhiteSpace((Get-Str $config 'tenantDisplayName'))) { throw 'Fill tenantDisplayName with the production tenant name.' }
    if ((Get-Str $config 'githubRepository') -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') { throw 'Fill githubRepository with owner/repository.' }
    return $config
}

#= Match the reader identity before making any production inventory request
function Assert-ReportDeploymentContext {
    param($Context, [System.Collections.IDictionary]$Config)
    if ((Get-Str $Context 'TenantId') -ne (Get-Str $Config 'tenantId') -or (Get-Str $Context 'Environment') -ne 'Global') { throw 'Graph tenant/cloud does not match production configuration. No Graph requests made.' }
    if ((Get-Str $Context 'ClientId') -ne (Get-Str $Config 'clientId')) { throw 'Graph client does not match the configured production reader. No Graph requests made.' }
}
