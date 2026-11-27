#Requires -Version 7.0
<#
.SYNOPSIS
Checks structured notification export, ownership scopes and collection provenance without Graph.
#>
[CmdletBinding()]
param([string]$OutputDirectory = (Join-Path ([IO.Path]::GetTempPath()) ('report-mail-json-' + [guid]::NewGuid())))
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Report.Common.ps1')
. (Join-Path $PSScriptRoot 'Report.Render.ps1')
$script:LogPath = Join-Path $OutputDirectory 'test.log'
$checks = 0

#= Fail on a broken producer contract before it can reach the mailer
function Assert-MailJson {
    param([bool]$Condition, [string]$Label)
    if (-not $Condition) { throw "Notification JSON export check failed: $Label" }
    $script:checks++
}

$owner = @{ id = '44444444-4444-4444-8444-444444444444'; '@odata.type' = '#microsoft.graph.user'; displayName = 'Example admin'; userPrincipalName = 'azadmu.owner@example.test'; userEmail = 'owner@example.test'; contactMatchStatus = 'MATCHED' }
$unresolved = @{ id = '55555555-5555-4555-8555-555555555555'; '@odata.type' = '#microsoft.graph.user'; userPrincipalName = 'regular@example.test'; contactMatchStatus = 'MISSING_EMPLOYEE_ID' }
$registration = @{ id = '33333333-3333-4333-8333-333333333333'; appId = '22222222-2222-4222-8222-222222222222'; displayName = 'JSON export example'; owners = @{ status = 'AVAILABLE'; items = @($unresolved) }; credentials = @(); federatedIdentityCredentials = @{ status = 'AVAILABLE'; items = @() } }
$app = @{
    appId = $registration.appId; displayName = 'JSON export <example>'; servicePrincipalId = '66666666-6666-4666-8666-666666666666'
    owners = @($owner); ownerEvidenceStatus = 'AVAILABLE'; registration = $registration; registrationAvailable = $true
    notes = ''; tags = @('production','business-critical'); protocol = 'OIDC'; assignmentRequired = $false; assignments = @(); redirectUris = @()
    credentials = @(@{ source = 'AppRegistration'; kind = 'keyCredentials'; keyId = '77777777-7777-4777-8777-777777777777'; startDateTime = [DateTimeOffset]::UtcNow.AddDays(-100).ToString('o'); endDateTime = [DateTimeOffset]::UtcNow.AddDays(700).ToString('o') })
    findings = @()
}
$standalone = @{ id = '88888888-8888-4888-8888-888888888888'; appId = '99999999-9999-4999-8999-999999999999'; displayName = 'Standalone registration'; owners = @{ status = 'AVAILABLE'; items = @($owner) }; credentials = @(); federatedIdentityCredentials = @{ status = 'AVAILABLE'; items = @() } }
$report = @{ schemaVersion = '3.0'; tenantId = '11111111-1111-4111-8111-111111111111'; tenantDisplayName = 'Example data'; generatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o'); mode = 'FIXTURE'; applications = @($app); registrations = @($registration,$standalone); ruleConfiguration = @{}; notificationSource = @{ repository = 'example/report'; branch = 'main'; runId = '123'; runUrl = 'https://github.com/example/report/actions/runs/123' } }
[void](New-Item -ItemType Directory -Path $OutputDirectory -Force)
Set-Content -LiteralPath (Join-Path $OutputDirectory 'mail-findings.csv') -Value 'Obsolete automatic export'
Export-AppReport $report $OutputDirectory
$path = Join-Path $OutputDirectory 'mail-findings.json'
$data = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -AsHashtable -Depth 100
Assert-MailJson ($data.kind -eq 'entra-apps-notifications' -and $data.schemaVersion -eq '1.0') 'Versioned notification contract'
Assert-MailJson ($data.objects -is [array] -and $data.objects.Count -eq 2) 'Linked registration is combined; standalone registration retained'
$object = @($data.objects | Where-Object { $_.appId -eq $app.appId })[0]
Assert-MailJson ($object.tags -contains 'production' -and $object.tags -contains 'business-critical') 'Native tags preserved'
Assert-MailJson ($object.owners.Count -eq 2 -and $object.owners[0].readyToSend -is [bool]) 'Owners retained with native booleans'
Assert-MailJson ($object.owners[0].recipientEmail -eq 'owner@example.test' -and $null -eq $object.owners[1].recipientEmail) 'No guessed address for unresolved contact'
Assert-MailJson (@($object.findings | Where-Object { $_.status -eq 'WARN' }).Count -gt 0 -and @($object.findings | Where-Object { $_.status -eq 'PASS' }).Count -gt 0) 'WARN and PASS evidence remains available'
$assignment = @($object.findings | Where-Object { $_.checkId -eq 'Assignments' })[0]
Assert-MailJson ($assignment.status -eq 'FAIL' -and $assignment.appliesTo -eq 'Enterprise application / SPN' -and $assignment.actions -is [array] -and $assignment.actions.Count -gt 0) 'Failed check includes correction steps and correct scope'
Assert-MailJson ($object.credentials[0].endDateTime -eq $app.credentials[0].endDateTime) 'Certificate expiry retained'
Assert-MailJson ($object.Contains('permissions') -and $object.Contains('directoryRoles') -and $object.Contains('federatedCredentials')) 'Extended evidence remains available to consumers'
Assert-MailJson ($data.source.runId -eq '123' -and (Convert-ReportDate $data.report.generatedAtUtc) -eq (Convert-ReportDate $report.generatedAtUtc)) 'Source and collection time preserved'
Assert-MailJson (-not (Test-Path -LiteralPath (Join-Path $OutputDirectory 'mail-findings.csv'))) 'Automatic CSV removed after successful JSON export'
$empty = @{ reportView = @{ Tests = @() }; applications = @(); registrations = @(); tenantId = $report.tenantId; generatedAtUtc = $report.generatedAtUtc; notificationSource = $report.notificationSource }
$emptyPath = Join-Path $OutputDirectory 'empty.json'
$count = Export-ReportMailJson $empty $emptyPath
$emptyData = Get-Content -LiteralPath $emptyPath -Raw | ConvertFrom-Json -AsHashtable
Assert-MailJson ($count -eq 0 -and $emptyData.objects -is [array] -and $emptyData.objects.Count -eq 0) 'Empty report retains envelope and empty array'
$null = Export-ReportMailJson $report (Join-Path $OutputDirectory 'rebuilt.json')
$rebuilt = Get-Content -LiteralPath (Join-Path $OutputDirectory 'rebuilt.json') -Raw | ConvertFrom-Json -AsHashtable
Assert-MailJson ($rebuilt.source.runId -eq '123' -and (Convert-ReportDate $rebuilt.report.generatedAtUtc) -eq (Convert-ReportDate $report.generatedAtUtc)) 'Rebuild does not refresh provenance or collection timestamp'
Write-Host "$checks notification JSON export checks passed offline. Output: $path" -ForegroundColor Green
