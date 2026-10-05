Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#= Validate the explicit production identity and report scope before authentication
function Read-ReportDeployment {
    param([string]$Path, [switch]$AllowDisabled)
    $config = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable
    if ((Get-Str $config 'schemaVersion') -ne '1.0') { throw 'Deployment schemaVersion must be 1.0.' }
    if ((Get-Str $config 'environment') -ne 'production') { throw 'Deployment environment must be production.' }
    if ((Get-Val $config 'enabled') -isnot [bool]) { throw 'Deployment enabled must be a JSON boolean.' }
    if (-not $AllowDisabled -and -not (Get-Val $config 'enabled')) { throw 'Production deployment is disabled. Complete the manual setup before setting enabled to true.' }
    foreach ($field in @('tenantId', 'clientId')) {
        $parsed = [guid]::Empty
        if (-not [guid]::TryParse((Get-Str $config $field), [ref]$parsed) -or $parsed -eq [guid]::Empty) { throw "Fill $field with the production GUID." }
    }
    if ([string]::IsNullOrWhiteSpace((Get-Str $config 'tenantDisplayName'))) { throw 'Fill tenantDisplayName with the production tenant name.' }
    if ((Get-Str $config 'githubRepository') -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') { throw 'Fill githubRepository with owner/repository.' }
    if ((Get-Str $config 'githubBranch') -notmatch '^[A-Za-z0-9][A-Za-z0-9_./-]*$') { throw 'Fill githubBranch with the trusted deployment branch.' }
    if ((Get-Val $config 'includeExtendedEvidence') -isnot [bool]) { throw 'includeExtendedEvidence must be a JSON boolean.' }
    $retention = Get-Val $config 'artifactRetentionDays'
    if ($retention -isnot [long] -and $retention -isnot [int]) { throw 'artifactRetentionDays must be an integer.' }
    if ($retention -lt 1 -or $retention -gt 90) { throw 'artifactRetentionDays must be between 1 and 90.' }
    if (-not $config.Contains('applicationIds') -or $config['applicationIds'] -isnot [array]) { throw 'applicationIds must be a JSON array of application/client GUIDs, or [].' }
    foreach ($applicationId in $config['applicationIds']) {
        $parsed = [guid]::Empty
        if (-not [guid]::TryParse($applicationId, [ref]$parsed) -or $parsed -eq [guid]::Empty) { throw 'applicationIds contains an invalid application/client GUID.' }
    }
    return $config
}

#= Match the reader identity before making any production inventory request
function Assert-ReportDeploymentContext {
    param($Context, [System.Collections.IDictionary]$Config)
    if ((Get-Str $Context 'TenantId') -ne (Get-Str $Config 'tenantId') -or (Get-Str $Context 'Environment') -ne 'Global') { throw 'Graph tenant/cloud does not match production configuration. No Graph requests made.' }
    if ((Get-Str $Context 'ClientId') -ne (Get-Str $Config 'clientId')) { throw 'Graph client does not match the configured production reader. No Graph requests made.' }
}
