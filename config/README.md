# Report configuration and rule rationale

[production.json](production.json) defines which configuration checks the report evaluates. The report reads Entra configuration; it does not enforce settings or change applications. The risks below explain the rationale for each check, not a measured risk rating for an application.

Enterprise application means the local **service principal (SPN)**. App registration means the **application object**. SPN Notes and owners are evaluated separately, even when they share the same Application (client) ID.

## Rules

| Setting | Default | Purpose and result | Risk addressed and limits |
|---|---|---|---|
| `ownerUpnPrefix` | `"azadmu"` | Identifies user owners whose UPN starts with this prefix, ignoring case. Used by both owner checks and to exclude admin accounts from regular-user contact matching. | Supports the company's separation between administrative and regular accounts. A name prefix alone does not prove that an account has an admin role, uses MFA, is enabled or belongs to the correct person. |
| `minimumEnterpriseAdminOwners` | `1` | `EnterpriseAdminOwner`: require this many matching user owners on the enterprise application. Insufficient owners produce FAIL; unreadable owner evidence produces UNKNOWN unless enough matching owners are already known. | Reduces ownerless enterprise applications and unclear responsibility for local SSO, provisioning and assignment configuration. One owner satisfies this policy but leaves dependency on one person. More owners also means more people able to manage the application. |
| `minimumRegistrationAdminOwners` | `1` | `RegistrationAdminOwner`: independently require this many matching user owners on the app registration. Insufficient owners produce FAIL; insufficient readable evidence produces UNKNOWN. | Reduces orphaned registrations and unclear responsibility for credentials and application configuration. The check counts owners; it does not verify their suitability, employment status or actual credential-management practices. |
| `requireNotes` | `true` | `Notes`: require nonempty **Notes** on the enterprise application / SPN (Graph `notes`). Edit in Entra → Enterprise applications → select app → Properties → Notes → Save. Empty or whitespace-only Notes produce WARN; `false` produces SKIPPED. | Helps identify the application's purpose during reviews and incident response, reducing operational uncertainty. Any nonempty text passes; correctness, order numbers and standard wording are not checked. |
| `requireAssignment` | `true` | `Assignments`: require assignment restriction enabled and at least one assignment (group, user or service principal). Restriction disabled or no assignments produces FAIL; unavailable restriction evidence produces UNKNOWN. Setting this rule to `false` produces SKIPPED. | Helps restrict application access to assigned principals. It does not validate whether assignments are appropriate, restrict the scope of already granted API permissions or prove the application cannot be accessed through another authentication method. |
| `requireRedirectUris` | `true` | `RedirectUriSecurity`: validate the scheme of configured redirect URLs. Invalid URLs produce FAIL; no URLs produce NOT_APPLICABLE and do not prevent Passed. `false` produces SKIPPED. The setting enables validation, not mandatory URL presence. | Flags insecure HTTP callbacks and malformed or unsupported URLs. HTTPS alone does not prove domain ownership, endpoint safety or correct token handling. Custom native callback schemes registered under publicClient are accepted except for unsafe browser/file schemes. Other unsupported schemes fail. |
| `allowLocalhostHttp` | `true` | Within `RedirectUriSecurity`, allow HTTP only for `localhost`, `127.0.0.1` and `[::1]`. Set to `false` to require HTTPS for every checked URL. | Provides a loopback exception for local clients or testing. It does not permit arbitrary HTTP hosts and does not verify which process receives the callback. It has no effect when the redirect check is disabled. |
| `maxSecretLifetimeDays` | `90` | `CredentialDates`: maximum secret lifetime, calculated from start to end date and rounded up to whole days. Exceeding the limit produces WARN for secrets. | Limits the potential period of misuse of a leaked secret while it remains valid. Does not detect leakage, confirm rotation or inspect secret storage. Shortening this setting changes the report result, not the credential. |
| `maxCertificateLifetimeDays` | `365` | `CredentialDates`: maximum certificate lifetime, calculated from start to end date and rounded up to whole days. Exceeding the limit produces FAIL. | Encourages periodic replacement and limits the validity period of credentials backed by a compromised private key. Does not inspect private-key protection, certificate trust or runtime use. |
| `credentialWarningDays` | `30` | `CredentialDates`: WARN when a nonexpired, otherwise valid credential has this many or fewer whole days left. Future start dates also produce WARN. Expired credentials and invalid date ranges produce WARN for secrets and FAIL for certificates; unparseable dates produce UNKNOWN. | Gives time to replace credentials before authentication failures or outages. The report does not rotate credentials, send notifications or determine whether an expired key is still used. |

Owner management and assignment requirements are established Entra controls; the configured minimum of one owner and the `azadmu` convention are this project's policy choices. Microsoft recommends at least two owners where possible. See [enterprise application ownership](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/overview-assign-app-owners) and [application access management](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/what-is-access-management).

Credential lifetime and redirect validation address only the metadata collected by this report. Broader application security considerations are described in [Microsoft's application-property security guidance](https://learn.microsoft.com/en-us/entra/identity-platform/security-best-practices-for-app-registration).

## Scope and interpretation

- Assignment checks apply to enterprise applications. For SAML, redirect checks use SPN reply URLs; otherwise they use linked registration redirect URLs. Standalone registrations currently have credential-date, federation and owner checks, without a redirect check.
- Credential checks include collected secrets and certificates from both objects, using the same lifetime limits. No credential metadata produces NOT_APPLICABLE. A failing certificate makes `CredentialDates` FAIL even if others pass. Client secret date issues produce WARN.
- A registration outside the tenant cannot be checked. Registration checks are NOT_APPLICABLE when no local registration exists, or UNKNOWN when local evidence was expected but is missing.
- Numeric settings accept integers from 1 to 10000. Boolean settings require JSON `true` or `false`. The UPN prefix must be nonempty, without spaces, `@` or wildcards. Invalid rule configuration stops the run.
- Overall FAIL takes precedence over UNKNOWN, then WARN, then PASS. WARN and UNKNOWN appear as Investigate. SKIPPED and NOT_APPLICABLE are not passes. Passing applicable checks is not a certification of application security.

Enable the SPN Notes check with `"requireNotes": true` under `rules`. Set it to `false` to show SKIPPED.

The legacy `minimumAdminOwners` setting provides a default for both owner counts; separate owner settings take precedence.

## Federated credentials

`FederatedCredentials` checks the linked app registration's `federatedIdentityCredentials`. At least one configured credential with available evidence produces PASS (green). An empty collection or no local registration produces NOT_APPLICABLE, because federation is optional. Unavailable evidence produces UNKNOWN. No additional Graph requests or permissions are needed; the existing federation inventory is reused.

Federation can avoid stored client secrets and the associated leakage and rotation burden. See [Microsoft's workload identity federation guidance](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation). This check confirms that a trust is configured; it does not validate issuer/subject restrictions, external platform security, successful token exchange or actual use. Certificates and secrets that remain are still evaluated by `CredentialDates`; federation does not override their FAIL or WARN results. Without certificates or secrets, `CredentialDates` remains NOT_APPLICABLE while federation can be PASS.

Disable this check globally with `"disabledChecks": ["FederatedCredentials"]`, or use an app-specific exclusion with that check ID and a reason. No extra rule setting is required.

## Other configuration fields

| Field | Purpose and risk implications |
|---|---|
| `tenantDisplayName` | Display label only. It does not select the tenant; Actions supplies the tenant ID. |
| `disabledChecks` | Disables listed check IDs globally. Results remain visible as SKIPPED. Disabling a check removes that condition from the pass decision; it does not fix the underlying configuration. |
| `exclusions` | Approved exceptions for an Application (client) ID, with specific `checks` and a mandatory `reason`. Use `["*"]` for every check on that application. Results remain SKIPPED with the reason; inventory remains visible. Exceptions have no automatic expiry. |

Valid check IDs are `EnterpriseAdminOwner`, `RegistrationAdminOwner`, `Notes`, `Assignments`, `RedirectUriSecurity`, `CredentialDates`, `FederatedCredentials`, `ClientSecrets`, `ImplicitFlow` and `OwnersMatch`. Use the separate IDs to disable checks independently for SPN and registration.

Owner contact matching via `employeeId` is informational and does not affect pass/fail. Missing or ambiguous contact matches never select an email address. The report does not collect sign-in or audit logs, evaluate Conditional Access, verify MFA or send email.


App-only runners and daemons may legitimately have no redirect URLs. Applications with no collected redirect URLs receive NOT_APPLICABLE when validation is enabled, without needing an exception or an unused URL. This does not determine the authentication flow or verify that an interactive application has every callback it needs. Existing URLs are still checked.

## Rebuilt checks

- `ClientSecrets`: any recorded client secret produces WARN. Secret date problems also remain WARN in CredentialDates; certificate failures remain FAIL. Presence of federation does not suppress secret warnings.
- `requireMatchingOwners` (default true) enables the informational `OwnersMatch` comparison of complete, unique owner object ID sets. Different sets or two empty sets produce WARN; matching nonempty sets PASS; unavailable/incomplete owner evidence UNKNOWN; missing local registration NOT_APPLICABLE. These results remain in details, statistics and filters but never affect approval or severity. Set to false to mark it SKIPPED. Each object's admin-owner minimum is a separate requirement; ordinary accounts do not count toward that minimum. Different administrators may own each object. The comparison helps identify differing responsibility without treating identical owner lists as a security requirement.
- `checkImplicitFlow` (default true) enables `ImplicitFlow`: either access-token or ID-token implicit issuance enabled produces WARN. Both explicitly false PASS; incomplete settings UNKNOWN. No local registration is NOT_APPLICABLE. This does not prove PKCE is used at runtime.
- Microsoft-owned applications are now included and labeled; filter their entries in the dashboard. Existing rules still apply unless disabled/excluded in configuration.

## Report wording and correction steps

`production.json` controls the requirements. The JSON files in [remediation](remediation) control how those results are explained to application owners. Edit the wording files independently of the rules; no PowerShell or JavaScript change is needed.

| File | Explains |
|---|---|
| [Assignments.json](remediation/Assignments.json) | Restricting access through assignments and adding approved users, groups or services. |
| [EnterpriseAdminOwner.json](remediation/EnterpriseAdminOwner.json) | Adding the required administrator owners to the enterprise application / SPN. |
| [RegistrationAdminOwner.json](remediation/RegistrationAdminOwner.json) | Adding the required administrator owners to the app registration. |
| [CredentialDates.json](remediation/CredentialDates.json) | Resolving certificate failures, expiry warnings and unreadable dates. |
| [RedirectUriSecurity.json](remediation/RedirectUriSecurity.json) | Correcting configured redirect addresses; an unused URL is not required. |
| [Notes.json](remediation/Notes.json) | Filling in enterprise application Notes. |
| [ClientSecrets.json](remediation/ClientSecrets.json) | Reviewing stored secrets; secret presence remains a warning. |
| [ImplicitFlow.json](remediation/ImplicitFlow.json) | Reviewing implicit token issuance without breaking an application that still depends on it. |
| [FederatedCredentials.json](remediation/FederatedCredentials.json) | Recovering missing federation evidence; lack of federation is not itself a failure. |
| [OwnersMatch.json](remediation/OwnersMatch.json) | Explaining differing owner lists as information only, without affecting approval. |

Each file has a `title` and the applicable `FAIL`, `WARN` or `UNKNOWN` sections. Each result section contains:

- `summary`: a short explanation of the issue in plain language.
- `actions`: an array of steps in the order the recipient should perform them. One string is one step.

For example, the FAIL section of `EnterpriseAdminOwner.json` can contain:

```json
"FAIL": {
  "summary": "Add a responsible administrator owner to this enterprise application.",
  "actions": [
    "Open Enterprise applications and locate this application using its Object ID.",
    "Open Owners and add an administrator account whose UPN starts with {{ownerUpnPrefix}}.",
    "Keep at least {{minimumEnterpriseAdminOwners}} qualifying owner(s), then run the report again."
  ]
}
```

This is a section to edit inside the existing file, not a replacement for the entire file. Keep the other required sections and the filename. Unknown fields, missing files/sections, empty summaries, invalid action arrays and unknown placeholders are rejected before collection. Use normal JSON syntax, without comments or trailing commas. Text is displayed as text rather than executed as code or raw HTML.

Use `{{ruleSetting}}` to insert a value from the report's active rules, such as `{{ownerUpnPrefix}}`, `{{minimumRegistrationAdminOwners}}`, `{{maxCertificateLifetimeDays}}` or `{{credentialWarningDays}}`. These values follow the saved report's policy when rebuilding HTML; editing guidance does not override that policy. For an UNKNOWN result, describe how the report administrator should restore missing evidence rather than telling the app owner to change an unverified setting.

The next collection uses the edited files. To rebuild HTML from existing data without another tenant scan:

```powershell
./scripts/Render-EntraAppsReport.ps1 -DataPath ./reports/latest/report.json
```

This updates HTML and creates `mail-findings.csv` beside the HTML using the current wording files; it does not overwrite the saved JSON. Newly collected JSON records the wording catalog in `remediationConfiguration` and expanded `title`, `summary` and `actions` on each finding. HTML, Markdown/print, Excel and the mail CSV share the expanded wording. `ActionSummary` and `CorrectiveActions` retain failure scope and owner-source attribution for the mail flow. No additional Graph permissions are needed, no changes are made to applications, and rule IDs/statuses remain stable. Review the generated text after a wording edit. Coordinate credential and authentication changes with the application team before removing an old credential or disabling a flow.
