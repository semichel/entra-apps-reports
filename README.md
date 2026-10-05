# Entra Apps Reports

Read-only enterprise application configuration reports based on the supplied SSO guide.

**Test tenant:** MichelAB / `Betancoraleman.onmicrosoft.com`  
**Tenant ID:** `37dadda4-f2a4-47a8-8482-d40fe1a5aa48`

The script rejects other tenants before authentication and verifies the signed-in Graph context before reading data. It does not change applications, owners, assignments, permissions or tenant policies.

## Start locally

Use PowerShell 7. No Graph module or login is required for the synthetic demo:

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

See [test tenant access](docs/test-tenant-access.md) for roles, consent, existing local access details and the licensing limitation.

## Report output

Each successful run writes:

| File | Content |
|---|---|
| `report.html` | Application findings readable in a browser |
| `report.json` | Owners, assignments, SSO configuration observations and credential metadata |
| `findings.csv` | One row per application/check for filtering in Excel |

By default these are in `reports/latest/`. Use `-OutputDirectory` to select another folder. Reports are ignored by Git. Logs use `$env:IACPORTAL_LOG` when set, otherwise a unique temporary log.

Findings use `PASS`, `FAIL`, `WARN`, `UNKNOWN`, `MANUAL`, or `NOT_APPLICABLE`. A rule-level PASS confirms only that particular observation; the overall application remains subject to manual review. Findings do not make the reporting job fail. Authentication, API, missing requested application and export failures do.

Scope: enterprise applications with `servicePrincipalType=Application`, including third-party and Microsoft applications. Associated locally registered applications are matched by client ID. Managed identities and registrations without an enterprise application are outside this initial report. Use `-ApplicationIds` to limit findings to selected client IDs; registration inventory is still read tenant-wide.

## GitHub runner and artifacts

[Runner setup](docs/github-runner.md) explains the `lab` GitHub environment and secretless OIDC authentication.

Run **Actions → Entra application report → Run workflow** and select `demo` or `lab`. The default is `demo`, which works without tenant credentials. Download the artifact from the completed run and open `report.html`.

The workflow uses a GitHub-hosted Ubuntu runner and uploads HTML, JSON and CSV together with 14-day retention. No scheduled tenant runs are enabled. Validation runs on pushes and pull requests without tenant access.

Live runner access requires an app registration with Microsoft Graph **Application.Read.All** application permission, administrator consent, and a GitHub federated identity credential. No Azure subscription is required. Those tenant resources are not created by the reporting script.

## Requirements and limits

See [report requirements](docs/report-requirements.md) for the mapping from the supplied article to automated and manual checks. The source article is preserved in [docs/source-sso-guide.txt](docs/source-sso-guide.txt).

The article contains guidance that needs protocol-specific interpretation. Optional claims, implicit token settings and the presence of certificates alone cannot prove successful or secure authentication. Sign-in logs, Conditional Access, app-side TLS, emitted tokens and delivery-form comparisons need separate evidence. Entra Premium P2 is suspended in this lab; the report does not attempt PIM, Conditional Access writes or entitlement management.

## Verified locally

Offline tests cover dictionary helpers, pagination, tenant and URL guards, secret omission, credential expiry/lifetime rules, HTML escaping and the complete demo export. Live access was attempted using an existing reader certificate, but it expired on **1 October 2026**. No live report is claimed until a valid authorized authentication method is configured.
