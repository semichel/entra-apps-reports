# Entra Apps Reports

Read-only enterprise application configuration reports based on the supplied SSO guide.

Private repository: [semichel/entra-apps-reports](https://github.com/semichel/entra-apps-reports).

**[View the live Entra application report directly on GitHub](published/lab/README.md)** — browse the application index, click an application, and read its findings, owners, assignments, credentials and full configuration evidence. This is live tenant data; Actions demo artifacts contain synthetic data.

**Per-run report:** open [Entra application report in Actions](https://github.com/semichel/entra-apps-reports/actions/workflows/report.yml). Each successful run shows expandable application findings directly on its Summary page and provides an interactive HTML artifact, following the Maester reporting pattern.

The [downloadable report bundle](https://github.com/semichel/entra-apps-reports/releases/tag/lab-report-2026-10-05) is also available.

**Test tenant:** MichelAB / `Betancoraleman.onmicrosoft.com`  
**Tenant ID:** `37dadda4-f2a4-47a8-8482-d40fe1a5aa48`

The script rejects other tenants before authentication and verifies the signed-in Graph context before reading data. It does not change applications, owners, assignments, permissions or tenant policies.

## Start locally

Use PowerShell 7 and Python 3. No Graph module or login is required for the synthetic demo:

```powershell
Set-Location C:\jobb\entra-apps-reports
pwsh -NoProfile -File .\tests\Test-Report.ps1
pwsh -NoProfile -File .\scripts\Export-EntraAppsReport.ps1 -Demo
Invoke-Item .\reports\latest\report.html
```

For live reads, install the authentication module and sign in to MichelAB:

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Repository PSGallery
.\scripts\Export-EntraAppsReport.ps1 -UseDeviceCode
```

For the existing Helpdesk Lite test application only:

```powershell
.\scripts\Export-EntraAppsReport.ps1 -UseDeviceCode -ApplicationIds 'f298ff2a-11df-43a4-99ef-4a0047abcddd'
```

The existing local Azure CLI lab login also works. To produce the complete report, including extended evidence:

```powershell
.\scripts\Export-EntraAppsReport.ps1 -UseAzureCli -IncludeExtendedEvidence -OutputDirectory .\reports\lab-latest
```

Azure CLI must already be authenticated to MichelAB. Credentials stay in the local credential store; no existing administrator credential is copied to GitHub.

See [test tenant access](docs/test-tenant-access.md) for roles, consent, existing local access details and the licensing limitation.

## Report output

Each successful run writes:

| File | Content |
|---|---|
| `report.html` | Application findings readable in a browser |
| `report.json` | Owners, assignments, SSO configuration observations and credential metadata |
| `findings.csv` | One row per application/check for filtering in Excel |
| `owners.csv` | Enterprise application owner evidence |
| `assignments.csv` | Assigned users/groups and role identifiers |
| `credentials.csv` | Certificate and secret dates, lifetime and expiry findings; no credential values |

The HTML report provides an expiry calendar with expired / 30 / 60 / 90-day states, named enterprise/registration owners, assigned principals, granted application and delegated API permissions, requested-versus-granted permission comparisons, federation and recent sign-ins. Search by application or owner, or filter to expiring credentials and ownership gaps. Raw configuration is available in secondary expandable sections.

By default these are in `reports/latest/`. Use `-OutputDirectory` to select another folder. Runtime output is ignored by Git; the readable live report and evidence are committed under `published/lab/`. Logs use `$env:IACPORTAL_LOG` when set, otherwise a unique temporary log.

Findings use `PASS`, `FAIL`, `WARN`, `UNKNOWN`, `MANUAL`, or `NOT_APPLICABLE`. A rule-level PASS confirms only that particular observation; the overall application remains subject to manual review. Findings do not make the reporting job fail. Authentication, API, missing requested application and export failures do.

Scope: enterprise applications with `servicePrincipalType=Application`, including third-party and Microsoft applications. Associated locally registered applications are matched by client ID. With `-IncludeExtendedEvidence`, all local app registrations are included, even those without an enterprise application. Managed identities are outside the assessed enterprise application catalog. Use `-ApplicationIds` to limit enterprise application findings; extended registration and tenant evidence remain tenant-wide.

Extended evidence includes registration owners, federated identity credentials, requested API permissions, granted application/delegated permissions, app roles, seven days of sign-in/audit records, Conditional Access policies and claims-mapping policy inventory. Optional query failures appear as UNAVAILABLE with a reason; they do not become empty passing results. For a minimally privileged hosted identity, `Application.Read.All` reads application inventory and federation. Additional consent/log/policy coverage may need `Directory.Read.All`, `AuditLog.Read.All` and `Policy.Read.All` and applicable licensing. The reporting script does not grant permissions.

## GitHub runner and artifacts

[Runner setup](docs/github-runner.md) explains the `lab` GitHub environment and secretless OIDC authentication.

Run **Actions → Entra application report → Run workflow**. Select `snapshot` to render the previously collected real inventory without credentials, `lab` for a fresh tenant read after identity setup, or `demo` for synthetic data. The default is `snapshot`. Every summary clearly identifies its mode and source collection time. Expand applications directly on the Actions Summary page; for the full searchable HTML report, download the artifact and open `report.html`.

There is one workflow: **Entra application report**. It runs its checks, generates the report and publishes the summary/artifact on a GitHub-hosted Ubuntu runner. HTML, JSON and CSV artifacts have 14-day retention. It does not commit generated reports. The existing `published/lab/` inventory is a dated reference snapshot. No scheduled tenant runs are enabled.

Live runner access requires an app registration with Microsoft Graph **Application.Read.All** application permission, administrator consent, and a GitHub federated identity credential. No Azure subscription is required. Those tenant resources are not created by the reporting script.

## Requirements and limits

See [report requirements](docs/report-requirements.md) for the mapping from the supplied article to automated and manual checks. The source article is preserved in [docs/source-sso-guide.txt](docs/source-sso-guide.txt).

The article contains guidance that needs protocol-specific interpretation. Optional claims, implicit token settings and the presence of certificates alone cannot prove successful or secure authentication. Sign-in logs, Conditional Access, app-side TLS, emitted tokens and delivery-form comparisons need separate evidence. Entra Premium P2 is suspended in this lab; the report does not attempt PIM, Conditional Access writes or entitlement management.

## Validation

Offline tests cover dictionary helpers, pagination, tenant and URL guards, secret omission, credential expiry/lifetime rules, permission-name resolution, audit property-value omission, HTML escaping and the complete demo export. The old certificate reader expired on **1 October 2026**, but a valid existing Azure CLI session enabled a real read-only lab report on **5 October 2026**.

The live report contains **334 application service principals, 21 local registrations, 7 Conditional Access policies, 4 recent sign-ins, 15 recent audit records and 4 delegated consent grants**. Logs cover the preceding seven days. The report is available locally at `reports/lab-latest/report.html`; a dated private GitHub release archives the complete bundle. The report covers catalog entries, and SSO policy applicability still needs review for Microsoft/platform/resource applications.

GitHub validation and the [first demo runner execution](https://github.com/semichel/entra-apps-reports/actions/runs/37292550523) both succeeded on **5 October 2026**. The demo run published an artifact containing HTML, JSON and CSV. The `lab` GitHub environment and `LAB_TENANT_ID` variable are configured, with deployment limited to `main`. `LAB_CLIENT_ID`, Graph consent and federation remain to be configured for live runs.
