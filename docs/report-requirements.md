# Report requirements from the supplied SSO guide

The original article is in `source-sso-guide.txt`. Its organizational rules are the starting point; observations do not replace the configuration delivery form or application testing.

| Requirement | Initial report behavior |
|---|---|
| User assignment required | PASS/FAIL from enterprise application's `appRoleAssignmentRequired`; missing data is UNKNOWN |
| At least two owners | Counts human owners; service principal automation owners remain in evidence. Interprets continuity as two human owners; confirm this interpretation with IAM |
| Prefer group assignment | Lists direct assignments with principal type, principal ID and role ID; warns when no groups are assigned |
| HTTPS redirects | Checks collected callback URLs; permits HTTP localhost/127.0.0.1/IPv6 loopback. Native-app schemes require contextual review |
| Secret maximum lifetime 90 days | Checks start/end dates and expiry; exports metadata only |
| Certificate maximum lifetime 365 days | Checks start/end dates and expiry; warns at 30 days or less; listed retired keys can produce findings needing review |
| Prefer federation, then certificate | Extended evidence lists local federated identity credentials. Preference and relying-party compatibility still need review; upstream credentials may not be visible |
| SAML basic settings | Exports service principal identifiers, reply URLs, login/logout URLs and SAML settings for comparison with delivery form |
| SAML certificate verification | Exports key dates and preferred signing thumbprint; manual confirmation of active key, request signature verification and relying-party behavior |
| SAML encryption when required | Exports tokenEncryptionKeyId; requirement and active encryption remain manual checks |
| OIDC settings | Exports available redirect URIs, optional claims and implicit grant settings; verifies neither emitted tokens nor protocol correctness |
| Claims: sub/upn/oid/email | Manual token/assertion review; default claims are not necessarily listed as optional claims |
| Logout, token lifetimes, assertion validation | Manual tests in the application |
| TLS policy and trusted server certificate | Manual app-side/network verification; Graph configuration cannot establish TLS support |
| Assigned and unassigned user testing | Manual; presence of assignments does not prove enforcement by the application |
| Conditional Access, sign-in/audit monitoring | Extended evidence reads policies and seven days of logs where authorized. Applicability, monitoring process and successful validation remain manual |
| Business owner, support contact, approval and runbook | Manual document review |

**No application receives an overall compliance PASS.** Even configurations with passing automated rules still require protocol, app-side and operational checks. Missing SSO hints do not prove absence of OIDC; many registrations use OAuth/OIDC without populating that service principal field.

## Article points needing clarification

- Modern OIDC applications using authorization code flow do not automatically need implicit grants enabled. The report exposes those flags for review rather than requiring them.
- `sub`, `oid`, `upn` and `email` have protocol/token-specific behavior. Treat the delivery form and actual emitted token as evidence rather than requiring every name in an optional-claims list.
- Fixed one-hour token lifetimes and refresh token durations are not universal defaults or a conclusion that Graph application metadata can validate.
- SAML verification of incoming signed authentication requests and app verification of Entra's signed assertions are distinct controls.
- Tenant-side token encryption metadata and certificate presence do not prove that the application validates or decrypts assertions correctly.

Microsoft Graph sources: [Service principal resource](https://learn.microsoft.com/en-us/graph/api/resources/serviceprincipal?view=graph-rest-1.0), [Application resource](https://learn.microsoft.com/en-us/graph/api/resources/application?view=graph-rest-1.0), [List applications](https://learn.microsoft.com/en-us/graph/api/application-list?view=graph-rest-1.0).
