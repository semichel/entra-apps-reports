# Entra Apps Reports

Read-only inventory and configuration checks for Entra app registrations and enterprise applications. Reports include owners, SPN Notes, certificate and secret dates, assignments, requested API permissions, granted application permissions and federation. Microsoft-owned enterprise applications are included and categorized separately. Sign-in and audit logs are not collected.

## Run and view

Run **Actions → Entra application report → Run workflow** on `main`. The full interactive HTML report is published to **GitHub Pages**. Open it from the workflow's deployment link or **Settings → Pages → Visit site**. Actions contains links instead of an expanded report summary. JSON data and an offline HTML copy remain available in the run's artifact. Each successful deployment replaces the website with the latest report.

Set **Settings → Pages → Build and deployment → Source → GitHub Actions**. Allow `main` to deploy to the `github-pages` environment and approve deployments if your organization requires it. A public repository may publish a public report website; everyone can read the HTML and its embedded evidence. Use only data intended for public access in that repository.

For a private/internal company repository, configure **private Pages access**. Private repository visibility alone does not guarantee private website access; the workflow rejects public Pages for private/internal repositories. If private Pages is unavailable on your plan/host, the workflow keeps the report artifact but does not publish the site. See [GitHub Pages access control](https://docs.github.com/en/enterprise-cloud@latest/pages/getting-started-with-github-pages/changing-the-visibility-of-your-github-pages-site).

Report collection and Pages deployment use separate jobs. Keep the existing Entra federation subject for the collection job; the `github-pages` environment does not need an Entra credential. GitHub must allow the Pages upload/deploy actions on the chosen host and runner.

Filter tags identify the check and result, for example `EnterpriseAdminOwner: FAIL`. Tag options follow the selected status, category, severity and search. Failed shows FAIL tags; Passed shows PASS tags; Investigate shows WARN/UNKNOWN tags.

Every **Results by check** cell is clickable across its full area. Select a count to show only applications with that check result, or select the check name to show all its results. All six statuses are supported, including zero-count cells. A check's PASS can belong to an application whose overall result is Failed. Selecting a cell clears previous list filters and preserves sort order; **Clear check filter** restores the complete list.

The workflow uses federated authentication. Set `AZURE_TENANT_ID` and `AZURE_CLIENT_ID` as repository Actions secrets or variables under **Settings → Secrets and variables → Actions**. Secrets take priority. Client ID means the report application's **Application (client) ID**, not its Object ID. Organization secrets must allow this repository; environment secrets require the job to target that environment. Keep production data in a private or internal company repository.

The report application uses Microsoft Graph **Application permissions** `Application.Read.All` and `User.Read.All`, with tenant admin consent. `User.Read.All` is needed for employee-ID contact matching; basic user access does not include `employeeId`. Add `RoleManagement.Read.Directory` to include direct active Entra directory roles assigned to service principals. Without it, role evidence is marked unavailable and the rest of collection continues. Directory-wide access and policy access are not required. Delegated consent grants, Conditional Access policies and claims-mapping policies are not collected. Requested delegated permissions are shown with consent marked as not collected. See Microsoft's [role-assignment API permissions](https://learn.microsoft.com/en-us/graph/api/rbacapplication-list-roleassignments?view=graph-rest-1.0).

**Graph overview** in the left menu shows Graph access by application, with permission, grant-evidence, severity and search filters. Granted app-only permissions and requested permissions are distinguished. Direct active Entra directory roles show their assignment scope. Group-inherited roles, PIM eligibility and Azure RBAC are outside this inventory. Existing application details and export views remain available.

**Graph access distribution** shows application counts for granted write/action access, other grants, unresolved grants, requested/unverified access and missing grant evidence. Applications with no observed Graph permissions are counted separately below the chart. Categories are mutually exclusive, with granted write/action access taking precedence. The chart shows tenant totals; the application-list filters below it do not change those totals.

**By severity** ranks observed access and recorded configuration findings. It does not change any Pass/Fail result. The highest matching rule wins:

| Severity | Basic exposure rule |
|---|---|
| Critical | Granted `RoleManagement.ReadWrite.Directory` or `AppRoleAssignment.ReadWrite.All`, or an active Global Administrator / Privileged Role Administrator assignment. |
| High | Other granted Graph write/action permissions, any other active directory role assignment (conservative ranking, including reader roles), or a failed certificate-date / redirect-security check. |
| Medium | Requested Graph write/action permissions without a verified grant, unresolved permission names, other failed or UNKNOWN checks, or warnings from `ClientSecrets`, `CredentialDates`, `ImplicitFlow` or `OwnersMatch`. UNKNOWN indicates incomplete evidence, not a confirmed vulnerability. |
| Low | Granted Graph permissions without a write/action name match, or other warnings such as empty Notes. |
| Info | No ranked access or configuration findings observed. Missing evidence remains visible; this does not establish that access is harmless. |

Write/action detection uses operation names such as `ReadWrite`, `Write`, `Create`, `Delete`, `Send`, `Manage` and `PrivilegedOperations`. This is a basic indicator, not an exhaustive effective-access assessment. Apps on Investigate and Skipped are included in severity statistics; the report-scope entry is excluded. The Home severity chart covers every application; the Graph page severity chart covers applications with observed Graph permissions or directory roles. Disabled, excluded and not-applicable configuration findings do not raise severity. Existing access grants and role assignments still contribute to severity even when configuration checks are excluded. No logs are required.

Click anywhere in the **High** row, including the label, bar or empty track area, to show all High applications regardless of Passed/Failed/Investigate/Skipped status. Other severities are excluded from the list rather than moved lower down. Previous list filters are cleared; the existing sort order is unchanged. Each full row is a keyboard-accessible button showing the total across all statuses. Chart toggles hide colored segments only; they do not narrow the severity selection. Clicking the same row again keeps the filter. **Clear severity filter** restores the default list. This works on both Home and Graph overview, within each page's application scope.

The Markdown tab retains the complete source and Copy Markdown export. Its rendered Preview is limited to the first 64K characters, with a visible notice for larger reports, so opening it does not parse the entire inventory and manifests into browser elements.

Application details begin with **Failed checks** when FAIL findings exist, listing every failed check, its object scope and evidence. WARN, UNKNOWN and excluded checks are not included in that list. Below it, **Enterprise application / SPN** and **App registration** appear side by side on desktop. Owners, credentials and permissions appear under their source object: granted permissions on the SPN, requested permissions and federation on the registration. Cross-object and combined credential checks appear below both panels. The background stays neutral; only FAIL rows in check and credential-status tables receive red highlighting. Narrow screens and print views stack the panels. Advanced evidence and the existing Markdown/Excel exports remain available, including the failures-first order.

Each object panel shows its own **Object ID** and the shared **Application (client) ID / appId** directly under its heading. The registration Object ID is not the SPN Object ID. IDs can be selected and copied without scrolling a table; missing registration IDs are shown as not collected.

Owners show **Owner account** and **User email** in the HTML website and the JSON data. The report matches `employeeId` to exactly one regular user account whose UPN does not start with the configured `ownerUpnPrefix`, then uses that account's `mail`. A regular owner can match itself. Missing employee IDs, missing mail, missing matches and ambiguous matches are shown explicitly, with no email selected. Contact matching does not affect the configuration checks and does not send email. The user catalog is read once with only ID, name, UPN, employee ID and mail; only owner and matched-contact evidence is saved.

## Configuration

[config/production.json](config/production.json) defines the report rules. `tenantDisplayName` changes the display label; the workflow's tenant ID selects the tenant.

| Setting | Default requirement / check |
|---|---|
| `ownerUpnPrefix` | Admin owner UPN prefix, default **azadmu**. Also identifies admin accounts excluded from regular-user contact matching. |
| `minimumEnterpriseAdminOwners` | Minimum admin owners on the enterprise application / SPN, default **1**: `EnterpriseAdminOwner`. |
| `minimumRegistrationAdminOwners` | Minimum admin owners on the app registration, default **1**: `RegistrationAdminOwner`. |
| `requireNotes` | Require nonempty **Notes** on the enterprise application / SPN: `Notes`. Edit under Enterprise applications → select app → Properties → Notes → Save. Default `true`; empty or whitespace-only values produce WARN. |
| `requireAssignment` | Assignment required must be enabled and at least one group, user or service principal must be assigned; otherwise FAIL: `Assignments`. No preference for groups over direct assignments. |
| `requireRedirectUris`, `allowLocalhostHttp` | Validate configured redirect URLs for HTTPS, with localhost HTTP allowed by default. Invalid URLs produce FAIL; no URLs produce NOT_APPLICABLE and do not prevent Passed: `RedirectUriSecurity`. `requireRedirectUris` enables validation; it does not require a URL to exist. |
| `maxSecretLifetimeDays`, `maxCertificateLifetimeDays` | Maximum lifetime **90** days for secrets and **365** days for certificates. Expired credentials, invalid date ranges or excessive lifetime produce FAIL: `CredentialDates`. |
| `credentialWarningDays` | WARN at **30** or fewer whole days remaining. Future start dates also produce WARN. |

Set a `require...` setting to `false` to disable that requirement. Numeric settings accept integers from 1 to 10000. Missing credential metadata and external app registrations are not applicable; missing evidence needed for evaluation produces UNKNOWN. API permissions are informational. Federation configuration is evaluated separately by `FederatedCredentials`.


**Passed** means all active, applicable checks passed. FAIL produces **Failed**; WARN or UNKNOWN produces **Investigate**. The report does not perform application sign-in tests or require manual validation.

`FederatedCredentials` shows PASS when a federated identity credential is configured on the app registration. No federation is NOT_APPLICABLE; unreadable evidence is UNKNOWN. Certificates and secrets remain checked independently, including when federation is configured. This checks configuration presence, not whether federation is used or its trust is correctly restricted. Disable it through `disabledChecks` or an app-specific exclusion if needed.

## Exclusions

`disabledChecks` disables named checks for all applications, for example `["Assignments"]`. Use `exclusions` for individual applications, identified by **Application (client) ID**:

```json
"exclusions": [
  {
    "appId": "11111111-2222-3333-4444-555555555555",
    "checks": ["Notes"],
    "reason": "Approved exception under request 12345"
  }
]
```

Use `"checks": ["*"]` to exclude every check for that application. Excluded checks remain visible as SKIPPED with the reason; applications remain in the inventory. Rules and exclusions are saved with each report and shown in the tenant entry. No exclusions are enabled by default.

Developer handover and script responsibilities: [scripts/README.md](scripts/README.md).

## Local additions under review

The existing report layout, charts, expandable details and manual UI exports remain in place. Collection stores only report.json and report.html. CSV files are not generated automatically; original manual export helpers remain available. Rebuild HTML from saved data with `./scripts/Render-EntraAppsReport.ps1` without connecting to Graph.

Added checks: `ClientSecrets` warns for secret presence (secret date issues also warn); `ImplicitFlow` reviews token issuance with `checkImplicitFlow`; `OwnersMatch` compares the complete registration/SPN owner sets with `requireMatchingOwners`. Certificates retain their date-policy failures. Permission tags extend the existing tag filter with Requested/Granted names and Graph write/action review markers. App role names and authentication platform settings extend the existing details; the sanitized Graph application manifest is inside Advanced configuration and evidence. Graph overview adds a page alongside the original dashboard.
