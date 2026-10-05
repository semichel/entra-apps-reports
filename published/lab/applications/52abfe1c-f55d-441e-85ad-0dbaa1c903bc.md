# Azure API for DICOM

[← All applications](../README.md)

Collected UTC: 2026-10-05T12:01:04.2888438+02:00

| Property | Value |
| --- | --- |
| Client ID | 75e725bf-66ce-4cea-9b9a-5c4caae57f33 |
| Enterprise application ID | 52abfe1c-f55d-441e-85ad-0dbaa1c903bc |
| Enabled | True |
| SSO hint | UNKNOWN |
| Publisher | Not available |
| Home tenant | f8cdef31-a31e-4b4a-93e4-5f571e91255a |
| Assignment required | False |
| Policy observations | FAIL |


## Findings and required validation

| Check | Status | Evidence / next action |
| --- | --- | --- |
| AssignmentRequired | FAIL | Configured value: False |
| TwoHumanOwners | FAIL | Human owners: 0; total owners: 0. Automation owners are preserved. |
| RedirectUriSecurity | UNKNOWN | Non-HTTPS/non-localhost URIs: . Native-app custom schemes need separate review. |
| CredentialDates | MANUAL | Policy: secrets &lt;=90 days; certificates &lt;=365 days; warning at &lt;=30 days remaining. Retired keys may still be listed. |
| GroupAssignmentsPreferred | WARN | Groups: 0; direct users: 0. Nested membership is not evaluated. |
| ProtocolConfirmation | MANUAL | Graph SSO hint: . A missing hint does not prove absence of OIDC. |
| AuthenticationAndClaims | MANUAL | Test assigned/unassigned users, emitted claims, assertion validation, token lifetime, redirects, and logout in the actual application. |
| SamlVerificationAndEncryption | MANUAL | Verify request-signature enforcement, active signing certificate, claim mappings, metadata and encryption requirement against the delivery form. UNKNOWN protocol still requires protocol review. |
| OperationsAndDocumentation | MANUAL | Review sign-in/audit logs, Conditional Access, TLS configuration, approval, business/support contacts and delivery form. |


## Owners

| Name | Object type | Object ID |
| --- | --- | --- |


## Assigned users and groups

| Name | Type | Principal ID | Role ID |
| --- | --- | --- | --- |


## Credential dates

| Name | Source | Kind | Expires UTC | Days remaining | Lifetime days | Status |
| --- | --- | --- | --- | --- | --- | --- |


## Callback URLs


```json
[]
```


## App registration and federation


```json
null
```


## Granted application permissions


```json
{
  "status": "AVAILABLE",
  "items": [],
  "reason": null
}
```


## Granted delegated permissions


```json
{
  "status": "AVAILABLE",
  "items": []
}
```


## Recent sign-ins


```json
{
  "status": "AVAILABLE",
  "items": []
}
```


## Optional claims


```json
null
```


## Exposed application roles

| Permission / role | Display name | Role ID |
| --- | --- | --- |


## Exposed delegated scopes

| Scope | Admin consent display name | Scope ID |
| --- | --- | --- |
| Dicom.ReadWrite | Read and write DICOM | e69ab058-b8ae-4c0f-b687-5d97888ddccb |


## Complete collected application configuration

[View the complete application evidence on GitHub](52abfe1c-f55d-441e-85ad-0dbaa1c903bc.json).
