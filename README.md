# Entra Apps Reports

Read-only inventory and configuration checks for Entra app registrations and enterprise applications. Reports include owners, descriptions, certificate and secret dates, assignments, requested API permissions, granted application permissions and federation. Microsoft-owned enterprise applications are excluded. Sign-in and audit logs are not collected.

## Run and view

Run **Actions → Entra application report → Run workflow** on `main`. The Actions summary includes application results and statistics per check. Download the run's artifact for the self-contained HTML report and JSON/CSV evidence.

Filter tags identify the check and result, for example `EnterpriseAdminOwner: FAIL`. Tag options follow the selected status, category, severity and search. Failed shows FAIL tags; Passed shows PASS tags; Investigate shows WARN/UNKNOWN tags.

The workflow uses federated authentication. Set `AZURE_TENANT_ID` and `AZURE_CLIENT_ID` as repository Actions secrets or variables under **Settings → Secrets and variables → Actions**. Secrets take priority. Client ID means the report application's **Application (client) ID**, not its Object ID. Organization secrets must allow this repository; environment secrets require the job to target that environment. The repository must be private or internal.

The report application uses Microsoft Graph **Application permissions** `Application.Read.All` and `User.Read.All`, with tenant admin consent. `User.Read.All` is needed for employee-ID contact matching; basic user access does not include `employeeId`. Directory-wide access and policy access are not required. Delegated consent grants, Conditional Access policies and claims-mapping policies are not collected. Requested delegated permissions are shown with consent marked as not collected.

Owners show **Owner account** and **User email** in HTML, the Actions summary and `owners.csv`. The report matches `employeeId` to exactly one regular user account whose UPN does not start with the configured `ownerUpnPrefix`, then uses that account's `mail`. A regular owner can match itself. Missing employee IDs, missing mail, missing matches and ambiguous matches are shown explicitly, with no email selected. Contact matching does not affect the eight configuration checks and does not send email. The user catalog is read once with only ID, name, UPN, employee ID and mail; only owner and matched-contact evidence is saved.

## Configuration

[config/production.json](config/production.json) defines the report rules. `tenantDisplayName` changes the display label; the workflow's tenant ID selects the tenant.

| Setting | Default requirement / check |
|---|---|
| `ownerUpnPrefix`, `minimumAdminOwners` | At least **1** user owner with UPN prefix **azadmu**, checked separately on the enterprise application and app registration: `EnterpriseAdminOwner`, `RegistrationAdminOwner`. |
| `requireDescriptions` | Nonempty descriptions on both objects. Empty or whitespace-only values produce WARN: `EnterpriseDescription`, `RegistrationDescription`. No standard wording is enforced. |
| `requireAssignment` | User assignment required must be enabled; otherwise FAIL: `AssignmentRequired`. |
| `requireGroupAssignment` | At least one assigned group; otherwise WARN. Direct user assignments may also exist: `GroupAssignmentsPreferred`. |
| `requireRedirectUris`, `allowLocalhostHttp` | Redirect URLs must exist and use HTTPS, with localhost HTTP allowed by default. Invalid URLs produce FAIL; missing URLs produce UNKNOWN: `RedirectUriSecurity`. |
| `maxSecretLifetimeDays`, `maxCertificateLifetimeDays` | Maximum lifetime **90** days for secrets and **365** days for certificates. Expired credentials, invalid date ranges or excessive lifetime produce FAIL: `CredentialDates`. |
| `credentialWarningDays` | WARN at **30** or fewer whole days remaining. Future start dates also produce WARN. |

Set a `require...` setting to `false` to disable that requirement. Numeric settings accept integers from 1 to 10000. Missing credential metadata and external app registrations are not applicable; missing evidence needed for evaluation produces UNKNOWN. API permissions and federation are informational.

**Passed** means all active, applicable checks passed. FAIL produces **Failed**; WARN or UNKNOWN produces **Investigate**. The report does not perform application sign-in tests or require manual validation.

## Exclusions

`disabledChecks` disables named checks for all applications, for example `["GroupAssignmentsPreferred"]`. Use `exclusions` for individual applications, identified by **Application (client) ID**:

```json
"exclusions": [
  {
    "appId": "11111111-2222-3333-4444-555555555555",
    "checks": ["EnterpriseDescription", "RegistrationDescription"],
    "reason": "Approved exception under request 12345"
  }
]
```

Use `"checks": ["*"]` to exclude every check for that application. Excluded checks remain visible as SKIPPED with the reason; applications remain in the inventory. Rules and exclusions are saved with each report and shown in the tenant entry. No exclusions are enabled by default.

Developer handover and script responsibilities: [scripts/README.md](scripts/README.md).
