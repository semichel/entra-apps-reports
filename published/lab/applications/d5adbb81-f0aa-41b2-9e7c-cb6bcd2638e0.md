# Azure Healthcare APIs

[← All applications](../README.md)

Collected UTC: 2026-10-05T12:01:04.2888438+02:00

| Property | Value |
| --- | --- |
| Client ID | 4f6778d8-5aef-43dc-a1ff-b073724b9495 |
| Enterprise application ID | d5adbb81-f0aa-41b2-9e7c-cb6bcd2638e0 |
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
| offline_access | offline_access | 7f08bce5-b21b-4518-b783-c69c9c0cd658 |
| system.all.all | system.all.all | bea2566c-7172-42d0-a06a-0e2e2b58f084 |
| system.all.read | system.all.read | a44c4c64-cdb5-48fc-adbd-070df4852b2c |


## Exposed delegated scopes

| Scope | Admin consent display name | Scope ID |
| --- | --- | --- |
| offline_access | offline_access | 7f08bce5-b21b-4518-b783-c69c9c0cd658 |
| openid | openid | 0ea38e69-761b-46c7-ac06-9cd17d518949 |
| user.Immunization.read | user.Immunization.read | 97d73b5a-b052-4953-a6da-3e3f159a2f85 |
| patient.Location.read | patient.Location.read | 6fbb6a2c-cd2f-486c-a421-b188f2184df8 |
| user.Provenance.read | user.Provenance.read | 8d821765-6bbb-4f52-8b7f-0dfe9ce5cb1e |
| user.Procedure.read | user.Procedure.read | 81d46baa-aaff-454b-9a35-b6fdaa0eb2d9 |
| user.Practitioner.read | user.Practitioner.read | 079186df-3044-4484-a785-d9750101f8f3 |
| user.Patient.read | user.Patient.read | 56998e01-1f00-4832-a130-c358e252acf2 |
| user.Organization.read | user.Organization.read | e75606ef-f141-4339-a248-f4c9b07886b2 |
| user.Observation.read | user.Observation.read | 556e34b1-56e8-4c27-b6be-679d856c0efa |
| user.MedicationRequest.read | user.MedicationRequest.read | c1519c05-9e3c-4656-844a-c83845bbaa9a |
| user.Location.read | user.Location.read | cf8b4a64-fb79-401f-94a4-28d9d7cd6a8d |
| user.Goal.read | user.Goal.read | 81d580ea-26f6-4822-9d91-31fb29019023 |
| user.Encounter.read | user.Encounter.read | 0e5be5d5-7b95-4583-aa3c-2de990f139c9 |
| user.DiagnosticReport.read | user.DiagnosticReport.read | 588567a0-59db-4598-8bd7-0cbea9ff1811 |
| user.DocumentReference.read | user.DocumentReference.read | 23b15307-5f89-4954-b86c-00e2c4279a8f |
| user.Device.read | user.Device.read | a246e7b9-d55c-43a2-9b5a-b3341bc1a57d |
| user.Condition.read | user.Condition.read | dd554abf-e473-4190-8382-9b096fe49efa |
| user.CareTeam.read | user.CareTeam.read | 3cb5f829-1e8d-4224-9e87-678b02c8f9b1 |
| user.PractitionerRole.read | user.PractitionerRole.read | ae77fe95-13db-47f8-968c-5eee9d973273 |
| patient.PractitionerRole.read | patient.PractitionerRole.read | 1d6a9f65-62f4-42b0-93d7-fc3437112f46 |
| patient.Provenance.read | patient.Provenance.read | d56c68f3-ec5f-4e12-82cc-afa8921337f0 |
| patient.Procedure.read | patient.Procedure.read | be1c7593-9057-4947-a456-424dde696627 |
| patient.Practitioner.read | patient.Practitioner.read | ad27d725-86ff-4bc9-86fb-afdb2f007089 |
| patient.Patient.read | patient.Patient.read | d23f0b68-a2f5-4647-987b-b58fdd86b49d |
| patient.Organization.read | patient.Organization.read | 81882045-ad54-4a5f-926c-a2a09d7dd2b5 |
| patient.Observation.read | patient.Observation.read | 890da85b-b5ad-4981-8966-4b80fd75a5b8 |
| patient.MedicationRequest.read | patient.MedicationRequest.read | 16352d13-6c69-4eee-adbb-f7420b3f252b |
| patient.Immunization.read | patient.Immunization.read | f6c2728b-b49d-4d10-bb69-7798f1603807 |
| patient.Goal.read | patient.Goal.read | e6e32ed0-c9a2-4f1b-adb5-e3d59e47bb54 |
| patient.Encounter.read | patient.Encounter.read | 9e7cdd6e-af8a-4e6d-9170-4274b35864bc |
| patient.DocumentReference.read | patient.DocumentReference.read | e2a5290a-59c6-4847-af7f-c5b16c692f24 |
| patient.DiagnosticReport.read | patient.DiagnosticReport.read | ef9475b2-f7da-4a86-b385-9fffe030c310 |
| patient.Device.read | patient.Device.read | f7b318b5-9bf5-46d0-8701-845c568925d9 |
| patient.Condition.read | patient.Condition.read | 60fd617d-0d96-4c44-9cf3-ee91c0c45161 |
| patient.CareTeam.read | patient.CareTeam.read | 4860ad86-f40e-4e2b-8661-ba03ee154b19 |
| patient.CarePlan.read | patient.CarePlan.read | 4fcc09b8-fd6b-430f-9b2b-7bbd2c2b7e8f |
| user.CarePlan.read | user.CarePlan.read | c2c62692-9cd2-4612-9f15-cf5641284e41 |
| user.AllergyIntolerance.read | user.AllergyIntolerance.read | 263687ba-ab05-41b1-98ad-f057c7365c91 |
| patient.AllergyIntolerance.read | patient.AllergyIntolerance.read | fa23e5cb-b06f-4d07-bcf8-f5ce114dd847 |
| user.Medication.read | user.Medication.read | e5a7cdb9-3edb-4b0a-a43d-40a377726680 |
| patient.Medication.read | patient.Medication.read | 058fa58e-ac09-4308-970e-2f2da3bf49b4 |
| fhirUser | fhirUser | a86144c7-3e19-4b56-9675-15803eb1e617 |
| online_access | online_access | 8f4fe9ac-b7f2-43ca-a0ef-070f4a8ae5dc |
| launch.patient | launch.patient | f6c8eb20-e799-4de7-a7ce-74ca0c7270e1 |
| launch | launch | fa5f9b76-5f20-4466-8b3d-6718de9744e2 |
| user.all.read | user.all.read | 5a03b38d-4081-4265-9558-aab5f2a18b8b |
| patient.all.read | patient.all.read | c71e9482-f052-461b-80e1-7cfeba7b2b12 |
| user_impersonation | Access Azure Healthcare APIs | db75143a-8f20-4238-9450-8b73ef4992f4 |


## Complete collected application configuration

[View the complete application evidence on GitHub](d5adbb81-f0aa-41b2-9e7c-cb6bcd2638e0.json).
