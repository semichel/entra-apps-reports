# Report configuration and rule rationale

[production.json](production.json) defines which configuration checks the report evaluates. The report reads Entra configuration; it does not enforce settings or change applications. The risks below explain the rationale for each check, not a measured risk rating for an application.

Enterprise application means the local **service principal (SPN)**. App registration means the **application object**. SPN Notes, registration descriptions and owners are evaluated separately, even when they share the same Application (client) ID.

## Rules

| Setting | Default | Purpose and result | Risk addressed and limits |
|---|---|---|---|
| `ownerUpnPrefix` | `"azadmu"` | Identifies user owners whose UPN starts with this prefix, ignoring case. Used by both owner checks and to exclude admin accounts from regular-user contact matching. | Supports the company's separation between administrative and regular accounts. A name prefix alone does not prove that an account has an admin role, uses MFA, is enabled or belongs to the correct person. |
| `minimumEnterpriseAdminOwners` | `1` | `EnterpriseAdminOwner`: require this many matching user owners on the enterprise application. Insufficient owners produce FAIL; unreadable owner evidence produces UNKNOWN unless enough matching owners are already known. | Reduces ownerless enterprise applications and unclear responsibility for local SSO, provisioning and assignment configuration. One owner satisfies this policy but leaves dependency on one person. More owners also means more people able to manage the application. |
| `minimumRegistrationAdminOwners` | `1` | `RegistrationAdminOwner`: independently require this many matching user owners on the app registration. Insufficient owners produce FAIL; insufficient readable evidence produces UNKNOWN. | Reduces orphaned registrations and unclear responsibility for credentials and application configuration. The check counts owners; it does not verify their suitability, employment status or actual credential-management practices. |
| `requireEnterpriseDescription` | `true` | `EnterpriseDescription`: require nonempty **Notes** on the enterprise application / SPN (Graph `notes`). Edit in Entra → Enterprise applications → select app → Properties → Notes → Save. Empty or whitespace-only Notes produce WARN; `false` produces SKIPPED. | Helps identify the application's purpose during reviews and incident response, reducing operational uncertainty. Any nonempty text passes; correctness, order numbers and standard wording are not checked. |
| `requireRegistrationDescription` | `true` | `RegistrationDescription`: the same description requirement, independently on the app registration. `false` produces SKIPPED. | Helps document the registration's purpose and reduces the chance of retaining unidentified registrations. A populated description is documentation evidence, not a technical security control. |
| `requireAssignment` | `true` | `AssignmentRequired`: require the enterprise application's assignment-required property to be enabled. `false` in Entra produces FAIL; unavailable evidence produces UNKNOWN. Setting this rule to `false` produces SKIPPED. | Helps restrict application access to assigned principals. It does not validate whether assignments are appropriate, restrict the scope of already granted API permissions or prove the application cannot be accessed through another authentication method. |
| `requireGroupAssignment` | `true` | `GroupAssignmentsPreferred`: require at least one group assignment to the enterprise application. No group produces WARN; setting the rule to `false` produces SKIPPED. Direct user assignments are permitted. | Encourages group-managed access and reduces fragmented individual assignments. One group is enough to pass; group membership, nested membership, approval and access reviews are not evaluated. This is separate from requiring assignment. |
| `requireRedirectUris` | `true` | `RedirectUriSecurity`: require at least one redirect URL and validate its scheme. Invalid or missing URLs produce FAIL. `false` produces SKIPPED. | Flags insecure HTTP callbacks and malformed or unsupported URLs. HTTPS alone does not prove domain ownership, endpoint safety or correct token handling. Custom native-app schemes fail this rule even when legitimate for that application. |
| `allowLocalhostHttp` | `true` | Within `RedirectUriSecurity`, allow HTTP only for `localhost`, `127.0.0.1` and `[::1]`. Set to `false` to require HTTPS for every checked URL. | Provides a loopback exception for local clients or testing. It does not permit arbitrary HTTP hosts and does not verify which process receives the callback. It has no effect when the redirect check is disabled. |
| `maxSecretLifetimeDays` | `90` | `CredentialDates`: maximum secret lifetime, calculated from start to end date and rounded up to whole days. Exceeding the limit produces FAIL. | Limits the potential period of misuse of a leaked secret while it remains valid. Does not detect leakage, confirm rotation or inspect secret storage. Shortening this setting changes the report result, not the credential. |
| `maxCertificateLifetimeDays` | `365` | `CredentialDates`: maximum certificate lifetime, calculated from start to end date and rounded up to whole days. Exceeding the limit produces FAIL. | Encourages periodic replacement and limits the validity period of credentials backed by a compromised private key. Does not inspect private-key protection, certificate trust or runtime use. |
| `credentialWarningDays` | `30` | `CredentialDates`: WARN when a nonexpired, otherwise valid credential has this many or fewer whole days left. Future start dates also produce WARN. Expired credentials and invalid date ranges produce FAIL; unparseable dates produce UNKNOWN. | Gives time to replace credentials before authentication failures or outages. The report does not rotate credentials, send notifications or determine whether an expired key is still used. |

Owner management and assignment requirements are established Entra controls; the configured minimum of one owner and the `azadmu` convention are this project's policy choices. Microsoft recommends at least two owners where possible. See [enterprise application ownership](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/overview-assign-app-owners) and [application access management](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/what-is-access-management).

Credential lifetime and redirect validation address only the metadata collected by this report. Broader application security considerations are described in [Microsoft's application-property security guidance](https://learn.microsoft.com/en-us/entra/identity-platform/security-best-practices-for-app-registration).

## Scope and interpretation

- Assignment checks apply to enterprise applications. For SAML, redirect checks use SPN reply URLs; otherwise they use linked registration redirect URLs. Standalone registrations currently have credential, owner and description checks, without a redirect check.
- Credential checks include collected secrets and certificates from both objects, using the same lifetime limits. No credential metadata produces NOT_APPLICABLE. One failing credential makes `CredentialDates` FAIL, even if other credentials pass.
- A registration outside the tenant cannot be checked. Registration checks are NOT_APPLICABLE when no local registration exists, or UNKNOWN when local evidence was expected but is missing. An explicitly disabled description check remains SKIPPED.
- Numeric settings accept integers from 1 to 10000. Boolean settings require JSON `true` or `false`. The UPN prefix must be nonempty, without spaces, `@` or wildcards. Invalid rule configuration stops the run.
- Overall FAIL takes precedence over UNKNOWN, then WARN, then PASS. WARN and UNKNOWN appear as Investigate. SKIPPED and NOT_APPLICABLE are not passes. Passing applicable checks is not a certification of application security.

To require SPN Notes without requiring a registration description, change these entries inside `rules`:

```json
"requireEnterpriseDescription": true,
"requireRegistrationDescription": false
```

The legacy settings `requireDescriptions` and `minimumAdminOwners` remain supported as defaults for both objects. The corresponding separate settings take precedence when present. New configurations should use the separate settings shown in `production.json`.

## Other configuration fields

| Field | Purpose and risk implications |
|---|---|
| `tenantDisplayName` | Display label only. It does not select the tenant; Actions supplies the tenant ID. |
| `disabledChecks` | Disables listed check IDs globally. Results remain visible as SKIPPED. Disabling a check removes that condition from the pass decision; it does not fix the underlying configuration. |
| `exclusions` | Approved exceptions for an Application (client) ID, with specific `checks` and a mandatory `reason`. Use `["*"]` for every check on that application. Results remain SKIPPED with the reason; inventory remains visible. Exceptions have no automatic expiry. |

Valid check IDs are `EnterpriseAdminOwner`, `RegistrationAdminOwner`, `EnterpriseDescription`, `RegistrationDescription`, `AssignmentRequired`, `GroupAssignmentsPreferred`, `RedirectUriSecurity` and `CredentialDates`. Use the separate IDs to disable checks independently for SPN and registration.

Owner contact matching via `employeeId` is informational and does not affect pass/fail. Missing or ambiguous contact matches never select an email address. The report does not collect sign-in or audit logs, evaluate Conditional Access, verify MFA or send email.

The setting `requireEnterpriseDescription` and check ID `EnterpriseDescription` retain their names for existing configs, filters and exclusions, but now evaluate SPN `notes` exclusively. SPN `description` does not satisfy this check. App registration checks still evaluate `description`. Existing saved reports without `notes` need a fresh collection.

App-only runners and daemons may legitimately have no redirect URLs. When `requireRedirectUris` is enabled they receive FAIL, not UNKNOWN. Use an app-specific `RedirectUriSecurity` exclusion with a documented reason for these applications; do not add an unused URL merely to pass the report.
