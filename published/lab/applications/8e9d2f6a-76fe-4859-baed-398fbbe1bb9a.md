# WindowsDefenderATP

[← All applications](../README.md)

Collected UTC: 2026-10-05T12:01:04.2888438+02:00

| Property | Value |
| --- | --- |
| Client ID | fc780465-2017-40d4-a0c5-307022471b92 |
| Enterprise application ID | 8e9d2f6a-76fe-4859-baed-398fbbe1bb9a |
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
| SecurityBaselinesAssessment.Read.All | Read all security baselines assessment information | e870c0c1-c1a2-41ca-948e-a33912d2d3f0 |
| SecurityConfiguration.ReadWrite.All | Read and write all security configurations | e5e05709-32a3-4c85-89c8-67596eb94f24 |
| SecurityConfiguration.Read.All | Read all security configurations | 227f2ea0-c2c2-4428-b7af-9ff40f1a720e |
| Library.Manage | Manage live response library files | 41d209c7-2511-4fc9-b899-8008a3976f09 |
| RemediationTasks.Read.All | Read all remediation tasks | 6a33eedf-ba73-4e5a-821b-f057ef63853a |
| Score.Read.All | Read Threat and Vulnerability Management score | 02b005dd-f804-43b4-8fc7-078460413f74 |
| Vulnerability.Read.All | Read Threat and Vulnerability Management vulnerability information | 41269fc5-d04d-4bfd-bce7-43a51cea049a |
| Software.Read.All | Read Threat and Vulnerability Management software information | 37f71c98-d198-41ae-964d-2c49aab74926 |
| SecurityRecommendation.Read.All | Read Threat and Vulnerability Management security recommendations | 6443965c-7dd2-4cfd-b38f-bb7772bee163 |
| Ti.ReadWrite.All | Read and write all IOCs | fc511a58-3adf-4d71-af24-00f13e35e479 |
| Machine.CollectForensics | Collect forensics | 15405ab2-2103-4a3c-ad80-e829841cedcc |
| Alert.Read.All | Read all alerts | 71fe6b80-7034-4028-9ed8-0f316df9c3ff |
| User.Read.All | Read user profiles | a833834a-4cf1-4732-8acf-bbcfa13fb610 |
| Ip.Read.All | Read IP address profiles | 47bf842d-354b-49ef-b741-3a6dd815bc13 |
| Url.Read.All | Read URL profiles | 721af526-ffa8-42d7-9b84-1a56244dd99d |
| File.Read.All | Read file profiles | 8788f1a9-beca-4e26-ba58-10513f3b896f |
| Machine.Offboard | Offboard machine | 594435bf-36dd-4548-83bd-1bdafe157d7a |
| Machine.StopAndQuarantine | Stop and quarantine file | 96e72b5e-7e68-4171-aad1-3937599e4751 |
| Machine.RestrictExecution | Restrict code execution | 96b6b35d-074d-4e2d-b167-8d68d9269648 |
| Machine.Scan | Scan machine | a86d9824-b2b6-45f8-b042-16bc4922ed4e |
| Machine.Isolate | Isolate machine | 7e4e1300-e1b9-4102-88ba-f0cb6e6d5974 |
| Machine.ReadWrite.All | Read and write all machine information | aa027352-232b-4ed4-b963-a705fc4d6d2c |
| Machine.Read.All | Read all machine profiles | ea8291d3-4b9a-44b5-bc3a-6cea3026dc79 |
| AdvancedQuery.Read.All | Run advanced queries | 93489bf5-0fbc-4f2d-b901-33f2fe08ff05 |
| Event.Write | Write timeline events | 84ddd701-5fac-4c30-b0ad-aa73a67bea1a |
| Ti.ReadWrite | Read and write IOCs belonging to the app | a8bc2240-f96a-46a1-bad5-6a960b7327a1 |
| Alert.ReadWrite.All | Read and write all alerts | 0f7000ec-157b-497f-b70e-ef0b0584f140 |
| secop | Security Operations - Read &amp; Write | 2261fd4a-5f23-4b74-9e4d-f4ac92dc86a2 |
| readonly | Security Operations - Read Only | f820e656-f1d1-4cb8-a566-31d18eeecb40 |
| IntegrationConfiguration.ReadWrite | Read and Write Integration settings | 7c6f6912-60e9-4fcd-bb2a-c25bc35e8c59 |
| Ti.Read.All | Read all IOCs | 528ca142-c849-4a5b-935e-10b8b9c38a84 |
| Machine.LiveResponse | Run live response on a specific machine | 1629b959-c0af-42a1-92f0-f6162060bdf1 |


## Exposed delegated scopes

| Scope | Admin consent display name | Scope ID |
| --- | --- | --- |
| SecurityBaselinesAssessment.Read | Read security baselines assessment information | d42e2aa1-a664-43a9-b7c6-2766d44a6687 |
| SecurityConfiguration.ReadWrite | Read and write security configurations | bfc81a3a-4f6d-4bfe-b945-d7fe6747d2a0 |
| SecurityConfiguration.Read | Read security configurations | 4ac83e46-552f-4948-91c2-f7eaff971018 |
| Library.Manage | Manage live response library files | 5998a3da-2c9b-4bf3-99bd-44c9fe337ad2 |
| RemediationTasks.Read | Read remediation tasks | 19956c04-168f-4f44-b471-48c8f50dc0c8 |
| Score.Read | Read Threat and Vulnerability Management score | df4ed126-3a4c-460a-b0fc-67aea84fc332 |
| Vulnerability.Read | Read Threat and Vulnerability Management vulnerability information | 63a677ce-818c-4409-9d12-5c6d2e2a6bfe |
| Software.Read | Read Threat and Vulnerability Management software information | 5f216ada-3f51-4a22-ace5-06b198328476 |
| SecurityRecommendation.Read | Read Threat and Vulnerability Management security recommendations | 1ab96238-1253-4059-a32f-4087f20ed65d |
| Ti.ReadWrite | Read and write IOCs | 650ff1f9-dd5f-48ee-8c58-7beef332c818 |
| AdvancedQuery.Read | Run advanced queries | 1fb6e712-1bd9-4184-b1c0-5e71e759196b |
| Machine.Read | Read machine information | fbd3d33a-b1f5-4573-906c-51b39682fbcf |
| Machine.ReadWrite | Read and write  machine information | f6846c57-9e3c-4a65-81aa-2f5e09ff4f0b |
| Machine.Isolate | Isolate machine | 479231ef-3b86-4933-ae6b-1fa84bba9e31 |
| Machine.CollectForensics | Collect forensics | 5eb7b9dc-cbce-4c7e-9d73-5be248260ae6 |
| Machine.Scan | Scan machine | b4618115-647e-42a5-bd0d-0ea9878fb376 |
| Machine.RestrictExecution | Restrict code execution | abddfa88-80bb-4aef-81ff-18cbf29363a9 |
| Machine.StopAndQuarantine | Stop and quarantine file | 69e036b7-3f10-4d4c-a85e-82295629eca8 |
| Machine.Offboard | Offboard machine | 29d1c73a-07f6-495f-b62b-1554a954d0a3 |
| File.Read.All | Read file profiles | 8fce64a0-67c8-4e39-8f47-cac9ff7e13bb |
| Url.Read.All | Read URL profiles | 42b4777c-6196-49ad-9cfc-207e73f2eb61 |
| Ip.Read.All | Read IP address profiles | b65a97e8-c8e8-4908-b19a-f654615de1a9 |
| User.Read.All | Read user profiles | ffd6563e-842b-4cfc-b349-06006e0473a3 |
| Alert.ReadWrite | Read and write alerts | cbc3b413-21e6-416d-95a4-af87687efbd0 |
| Alert.Read | Read alerts | b2069dc0-9fe9-4e6d-9aca-ccf3dd503819 |
| IntegrationConfiguration.ReadWrite | Read and Write Integration settings | 7c6f6912-60e9-4fcd-bb2a-c25bc35e8c59 |
| Machine.LiveResponse | Run live response on a specific machine | 25fb0c21-5877-492a-8d0c-e7893a9585cc |


## Complete collected application configuration

[View the complete application evidence on GitHub](8e9d2f6a-76fe-4859-baed-398fbbe1bb9a.json).
