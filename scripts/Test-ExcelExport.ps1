#requires -Version 7.0
<#
.SYNOPSIS
Checks application notes, failed-check rows and clipboard formatting offline with synthetic data.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Report.Common.ps1')
. (Join-Path $PSScriptRoot 'Report.Render.ps1')

$owner = @{ id = 'owner-1'; displayName = 'Owner'; userPrincipalName = 'azadmu.owner@example.test'; userEmail = 'owner@example.test'; contactMatchStatus = 'MATCHED' }
$registration = @{ id = 'registration-1'; owners = @{ status = 'AVAILABLE'; items = @($owner, @{ id = 'owner-2'; userPrincipalName = 'azadmu.missing@example.test'; contactMatchStatus = 'AMBIGUOUS' }) } }
$app = @{ displayName = '=Example'; notes = "First line`nSecond`tline – äö"; status = 'FAIL'; appId = 'client-1'; servicePrincipalId = 'spn-1'; owners = @($owner); ownerEvidenceStatus = 'AVAILABLE'; registration = $registration }
$checks = @(
    @{ Check = 'Notes'; AppliesTo = 'Enterprise application / SPN'; Evidence = "Missing notes`nwith a tab`tand text" }
    @{ Check = 'RegistrationAdminOwner'; AppliesTo = 'App registration'; Evidence = 'Registration finding' }
    @{ Check = 'CredentialDates'; AppliesTo = 'Both / combined'; Evidence = 'Expired certificate' }
)
$rows = @(Get-ReportExcelRows $app $checks)
if ($rows.Count -ne 6) { throw 'Expected one row per check and owner in the affected scopes.' }
if (@($rows | Where-Object { $_.Check -eq 'Notes' }).Count -ne 1) { throw 'SPN finding used registration owners.' }
if (@($rows | Where-Object { $_.Check -eq 'RegistrationAdminOwner' }).Count -ne 2) { throw 'Registration owners were lost.' }
if (@($rows | Where-Object { $_.Check -eq 'CredentialDates' }).Count -ne 3) { throw 'Combined finding lost an owner source.' }
if ($rows[0].OwnerAccount -ne $owner.userPrincipalName -or $rows[0].UserEmail -ne $owner.userEmail) { throw 'Owner account and regular user email must remain separate.' }
if ($null -ne $rows[2].UserEmail -or $rows[2].ContactMatchStatus -ne 'AMBIGUOUS') { throw 'Ambiguous contacts must not gain a guessed email.' }
if ($rows[0].AppId -ne 'client-1' -or $rows[0].ServicePrincipalId -ne 'spn-1' -or $rows[0].RegistrationId -ne 'registration-1') { throw 'Object IDs must remain separate.' }
if (@(Get-ReportExcelRows $app @()).Count) { throw 'No failures must produce no export rows.' }
$allRows = @(Get-ReportExcelRows $app -IncludeAll)
if ($allRows.Count -ne 3 -or $allRows[0].Notes -cne $app.notes -or $rows[0].Notes -cne $app.notes) { throw 'Complete notes and all owner sources must be exported.' }
if (@($allRows | Where-Object { $null -ne $_.Check }).Count) { throw 'Application rows must not invent failed checks.' }
$passedApp = @{ displayName = 'Passed app'; notes = 'Notes for an app without failures'; status = 'PASS'; appId = 'passed-client'; servicePrincipalId = 'passed-spn'; owners = @($owner) }
$passedRows = @(Get-ReportExcelRows $passedApp -IncludeAll)
if ($passedRows.Count -ne 1 -or $passedRows[0].Notes -ne $passedApp.notes -or $passedRows[0].Status -ne 'PASS') { throw 'Apps without failures must retain notes and owner contacts.' }
$app.findings = @(
    @{ rule = 'Notes'; status = 'FAIL'; evidence = 'Missing notes' }
    @{ rule = 'ImplicitFlow'; status = 'WARN'; evidence = 'Warning only' }
    @{ rule = 'Assignments'; status = 'SKIPPED'; evidence = 'Disabled' }
    @{ rule = 'RegistrationAdminOwner'; status = 'PASS'; evidence = 'Owner found' }
)
$details = Get-ReportAppDetails $app ([DateTimeOffset]::UtcNow) @{} @{} $null -Split
$integrated = @(Get-ReportExcelRows $app (Get-Val $details 'failedChecks'))
if ($integrated.Count -ne 1 -or $integrated[0].Check -ne 'Notes') { throw 'Only exact FAIL findings must reach the export, including a single failure.' }
$app.protocol = 'SAML'
$app.findings = @(@{ rule = 'RedirectUriSecurity'; status = 'FAIL'; evidence = 'Insecure reply URL' })
$details = Get-ReportAppDetails $app ([DateTimeOffset]::UtcNow) @{} @{} $null -Split
if ((@(Get-ReportExcelRows $app (Get-Val $details 'failedChecks')))[0].OwnerSource -ne 'Enterprise application / SPN') { throw 'SAML redirect findings belong to the SPN.' }

$app.owners = @()
$emptyOwner = @(Get-ReportExcelRows $app @($checks[0]))
if ($emptyOwner.Count -ne 1 -or $emptyOwner[0].ContactMatchStatus -ne 'NO_OWNER' -or $null -ne $emptyOwner[0].UserEmail) { throw 'Ownerless findings must remain visible without a recipient.' }
$app.Remove('ownerEvidenceStatus')
if ((@(Get-ReportExcelRows $app @($checks[0])))[0].ContactMatchStatus -ne 'NO_OWNER') { throw 'Core SPN owner collection defaults to available, matching the rule evaluator.' }
$app.ownerEvidenceStatus = 'UNAVAILABLE'
if ((@(Get-ReportExcelRows $app @($checks[0])))[0].ContactMatchStatus -ne 'UNAVAILABLE') { throw 'Unavailable owner evidence must remain explicit.' }
$app.Remove('servicePrincipalId')
$app.Remove('notes')
$registration.description = 'Registration description is not enterprise Notes'
$standalone = @(Get-ReportExcelRows $app @($checks[1]))
if ($standalone.Count -ne 2 -or $null -ne $standalone[0].ServicePrincipalId) { throw 'Standalone registrations must retain their owner rows.' }
$standaloneAll = @(Get-ReportExcelRows $app -IncludeAll)
if ($standaloneAll.Count -ne 2 -or $null -ne $standaloneAll[0].Notes) { throw 'Standalone registrations must not use descriptions as enterprise Notes.' }

$fixturePath = Join-Path ([IO.Path]::GetTempPath()) ('entra-excel-check-' + [guid]::NewGuid() + '.json')
try {
    ConvertTo-Json -InputObject @{ failures = $rows; applications = $allRows; passed = $passedRows } -Depth 10 | Set-Content -LiteralPath $fixturePath -Encoding utf8
    node (Join-Path $PSScriptRoot 'tests/excel-export.test.cjs') $fixturePath
    if ($LASTEXITCODE -ne 0) { throw 'Excel JavaScript checks failed.' }
} finally {
    Remove-Item -LiteralPath $fixturePath -ErrorAction SilentlyContinue
}
Write-Host 'Excel export checks passed (offline).' -ForegroundColor Green
