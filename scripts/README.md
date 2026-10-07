# Developer reference

This directory contains the production report pipeline. GitHub Actions is the supported execution path. Local lab launchers are maintained outside this repository. Read the [repository overview](../README.md) for rule settings and the [workflow](../.github/workflows/report.yml) for authentication and orchestration.

## Script responsibilities

| Script | Responsibility | Main entry points |
|---|---|---|
| [Validate-ProductionConfig.ps1](Validate-ProductionConfig.ps1) | Offline validation of reader IDs, tenant label, rules and exclusions. Does not authenticate or call Graph. | Script parameters: `ConfigPath`, `TenantId`, `ClientId`. |
| [Export-EntraAppsReport.ps1](Export-EntraAppsReport.ps1) | Collects inventory using an existing Graph context, enriches it, evaluates rules and writes artifacts. | Script parameters: `ConfigPath`, `OutputDirectory`, `TenantId`, `ClientId`. |
| [Write-ActionSummary.ps1](Write-ActionSummary.ps1) | Reads saved JSON and writes the expandable Actions summary, including the artifact link. Does not call Graph. | Required parameters: `ReportPath`, `ArtifactUrl`, `OutputPath`. |
| [Report.Common.ps1](Report.Common.ps1) | Dictionary helpers, Graph requests and pagination, logging, base inventory construction, configuration/context validation and artifact orchestration. Loads the rule library. | `Get-Val`, `Get-Str`, `Invoke-MgGetAll`, `Get-LiveAppReport`, `Read-ReportDeployment`, `Assert-ReportDeploymentContext`, `Export-AppReport`. |
| [Report.Evidence.ps1](Report.Evidence.ps1) | Enriches registrations and applications with owners, federation and permissions evidence. Builds indexes to avoid repeated scans. | `Add-ExtendedEvidence`, `Get-OptionalEvidence`, `Get-RegistrationEvidence`, `Add-AppEvidence`. |
| [Report.Rules.ps1](Report.Rules.ps1) | The single source of configuration-check decisions, credential date rules, owner/description rules and exclusions. Re-evaluates saved data. | `Get-ReportRuleConfiguration`, `Update-ReportCredentialPolicy`, `Update-AppGovernance`, `Update-ReportGovernance`. |
| [Report.Render.ps1](Report.Render.ps1) | Shared report entries, per-check statistics, application details, HTML, Actions Markdown and detailed CSV exports. | `Get-ReportResults`, `Export-ReportHtml`, `Export-ReportSummary`, `Export-DetailCsv`. |

`Report.*.ps1` files are function libraries loaded by dot-sourcing. Running a library directly does not generate a report. Collection constructs metadata with unevaluated statuses; `Report.Rules.ps1` evaluates it after enrichment. Do not reintroduce rule decisions into the collector.

The reader requires only Microsoft Graph application permissions `Application.Read.All` and `User.ReadBasic.All`, with admin consent. `User.ReadBasic.All` exposes the name and UPN fields used by owner checks. Do not request directory-wide, full-user-profile, policy, log or write permissions for this pipeline.

## Execution flow

1. The workflow resolves `AZURE_TENANT_ID` and `AZURE_CLIENT_ID` from secrets, with variables as fallback. It validates their GUID format, the configuration, `main` and private/internal repository visibility.
2. The runner installs Az and Microsoft.Graph.Authentication. `azure/login` authenticates through federation; the workflow obtains a Microsoft Graph token and connects Graph with that token.
3. `Export-EntraAppsReport.ps1` validates the connected tenant, client and Global cloud against the supplied IDs before any inventory requests.
4. App registrations are collected once. Enterprise applications of type `Application` are collected and Microsoft-owned objects excluded using the owning tenant IDs, not display names. Owners and assignments are then collected for retained enterprise applications.
5. `Add-ExtendedEvidence` reuses the registrations, collects federation and registration owners, resolves permission names from a service-principal catalog without querying delegated consent or tenant policies.
6. `Export-AppReport` evaluates rules and writes JSON, findings CSV, HTML and detailed CSV files. Rendering also re-evaluates the data through the shared rules.
7. The workflow uploads `reports/latest/` as an artifact. `Write-ActionSummary.ps1` reads its JSON and writes to `GITHUB_STEP_SUMMARY` using the uploaded artifact URL. Graph is disconnected in a `finally` block during collection.

The current workflow is manually dispatched and has a 30-minute timeout. A successful workflow means collection and publication succeeded; FAIL findings do not themselves cause a nonzero script exit. There is no separate notification or remediation step.

## Data and result contracts

The final JSON schema version is `2.0`. Its main fields are:

| Field | Contents |
|---|---|
| `tenantId`, `tenantDisplayName`, `generatedAtUtc`, `mode` | Identity, report label, collection timestamp and inventory mode. |
| `ruleConfiguration` | Validated rule settings, disabled checks and exclusions saved with that run. |
| `inventoryScope` | Microsoft-app exclusion flag and counts. |
| `applications` | Retained enterprise applications with their linked registration, owners, assignments, credentials, permissions, findings and overall status. |
| `registrations` | All collected app registrations, including those without a retained enterprise application. |


Evidence wrappers use `{ status, items, reason }`, where availability is `AVAILABLE` or `UNAVAILABLE`. Unavailable evidence must not be presented as a successful empty query. Credential records contain metadata, never secret values or certificate bytes.

A finding uses `{ rule, status, evidence }`. Keep rule IDs stable: config exclusions, statistics and filter tags depend on them. The eight current rule IDs are `AssignmentRequired`, `RedirectUriSecurity`, `CredentialDates`, `GroupAssignmentsPreferred`, `EnterpriseAdminOwner`, `EnterpriseDescription`, `RegistrationAdminOwner` and `RegistrationDescription`.

| Finding status | Meaning / application result |
|---|---|
| `FAIL` | A requirement failed; application is **Failed**. |
| `UNKNOWN` | Required evidence cannot be evaluated; application is **Investigate** unless a FAIL exists. |
| `WARN` | Attention is needed; application is **Investigate** unless FAIL or UNKNOWN exists. |
| `PASS` | Check passed; application is **Passed** when no FAIL, UNKNOWN or WARN exists. |
| `SKIPPED` | Disabled or excluded, with an explanation. Does not count as PASS. |
| `NOT_APPLICABLE` | The check cannot apply to the collected object, such as a registration in an external home tenant. Does not count as PASS. |

An application with only skipped/not-applicable checks is Skipped when any check is SKIPPED; otherwise its overall status is UNKNOWN. Standalone registrations have credential, registration-owner and registration-description checks; enterprise-specific checks require a service-principal ID.

`Get-ReportResults` combines enterprise applications with unmatched registrations, so linked registrations are not separate report entries. It adds one **Report rules and scope** entry marked Investigate. Consequently, overall dashboard counts include that entry. Per-check statistics exclude it and count each application once per check.

Disabled checks and app exclusions are applied after evaluation and remain visible as SKIPPED. Exclusions match the Application (client) ID. The owner rule recognizes user owners by the configured UPN prefix; it does not verify directory roles or MFA. API permissions and federation are informational. Delegated consent grants and tenant policies are not collected. No sign-in logs, audit logs or application authentication tests are performed.

## Outputs and templates

| Output | Coverage |
|---|---|
| `report.json` | Full collected report and saved configuration. |
| `report.html` | Self-contained interactive report, including unmatched registrations and report scope. |
| `findings.csv` | Findings for retained enterprise applications, including their registration checks. Standalone registration findings are not exported here. |
| `owners.csv`, `assignments.csv`, `credentials.csv` | Detailed evidence for retained enterprise applications; these also exclude standalone registrations. |
| Actions summary | Application index, per-check statistics and expandable details. It is written to the path supplied by the workflow, not included as a separate artifact file by default. |

The summary has a 1 MiB budget. Expanded details are truncated when necessary, with a notice and a link to the full artifact. The application index and statistics remain included if the summary fits; an oversized summary raises an error.

| Template/asset | Purpose |
|---|---|
| [templates/report.html](templates/report.html) | Bundled interactive UI and placeholder result payload. Its embedded third-party license notice must be retained. |
| [templates/check-statistics.js](templates/check-statistics.js) | Per-check dashboard table injected into the UI. |
| [templates/report-filters.js](templates/report-filters.js) | Tag options derived from status, category, severity and search. Incompatible selected tags are cleared by the injected UI effect. |
| [templates/summary.md](templates/summary.md) | Actions Markdown placeholders. |
| [templates/brand.css](templates/brand.css), [templates/saab-logo.png](templates/saab-logo.png) | Brand palette and transparent emblem embedded in the generated HTML. |

HTML generation patches specific anchors in the bundled JavaScript and replaces the payload ending in `EndOfJson`. Several anchors require exactly one match and fail explicitly if the template changes. A template upgrade therefore requires reviewing `Export-ReportHtml`, generated JavaScript syntax and actual UI behavior. The component JavaScript uses the bundle's existing React runtime; there is no separate frontend build or Python dependency.

Inventory text is escaped for Markdown/HTML, the embedded JSON uses HTML escaping, and CSV text is protected against spreadsheet formula interpretation. Preserve these safeguards when adding fields.

## Maintaining the code

For a new check, add its stable ID to config validation, implement its evaluation in `Report.Rules.ps1`, include it in the checks rebuilt by `Update-AppGovernance`, and document its settings in the root README. Statistics and tags are derived from findings automatically. Collect any new evidence in `Report.Evidence.ps1` or the initial inventory query; add its presentation in `Get-ReportAppDetails` if needed.

Use `Get-Val`/`Get-Str` for Graph dictionaries. Missing helper values return null. Follow `@odata.nextLink` explicitly with `Invoke-MgGetAll`. Expanded owners are accepted only below the 20-owner expansion limit with no next link; otherwise the collector uses a separate owners query. Preserve that completeness check.

`Invoke-ReportGet` accepts only HTTPS Graph URLs and retries HTTP 429, 503 and 504 for up to five attempts, with waits capped at 30 seconds. Optional evidence failures retain an availability reason; core inventory failures stop the run. Reuse the registration and service-principal catalogs instead of downloading them per app.

Keep StrictMode and terminating errors. Use four-space indentation and `#=` function sections. Validate PowerShell syntax after each changed function. Progress goes to the console and to `IACPORTAL_LOG` when set, otherwise a temporary log file. Generated reports and credentials must remain outside version control.

## Developer verification

Use a saved, access-controlled report to verify rendering without Graph or authentication. Run from the repository root in PowerShell 7:

```powershell
. ./scripts/Report.Common.ps1
. ./scripts/Report.Render.ps1
$report = Get-Content 'PATH-TO-SAVED/report.json' -Raw |
    ConvertFrom-Json -AsHashtable -Depth 100
$script:LogPath = Join-Path ([IO.Path]::GetTempPath()) 'entra-render-check.log'
$output = Join-Path ([IO.Path]::GetTempPath()) ('entra-render-' + [guid]::NewGuid())
Export-AppReport $report $output
Export-ReportSummary $report 'https://github.com/OWNER/REPO/actions' (Join-Path $output 'summary.md')
```

Saved configuration is used unless `report.ruleConfiguration` is replaced before evaluation. Credential expiry is evaluated at render time; rendering the same snapshot later can legitimately change its status. Review generated HTML, tags, statistics and Markdown. Compare app results and CSV output when refactoring.

For rule changes, verify valid, expired, near-expiry and malformed credential dates; custom thresholds; missing/non-admin owners; empty descriptions; disabled checks; whole-app and per-check exclusions; external registrations; and standalone registrations. After UI/template changes, also check generated JavaScript syntax and filter transitions, including clearing stale tag selections.

Use the separate lab tooling for live collection checks before production use. Verify the connected tenant and client, inspect availability failures and keep real tenant reports untracked. Do not restore local launchers, lab IDs, test archives or credentials to this production repository.
