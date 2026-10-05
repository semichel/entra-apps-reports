# Azure Healthcare APIs

[← All applications](../README.md)

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


## Complete collected application configuration


```json
{
  "displayName": "Azure Healthcare APIs",
  "servicePrincipalId": "d5adbb81-f0aa-41b2-9e7c-cb6bcd2638e0",
  "appId": "4f6778d8-5aef-43dc-a1ff-b073724b9495",
  "accountEnabled": true,
  "protocol": "UNKNOWN",
  "preferredSingleSignOnMode": null,
  "status": "FAIL",
  "registrationAvailable": false,
  "assignmentRequired": false,
  "owners": [],
  "assignments": [],
  "redirectUris": [],
  "identifierUris": [
    null
  ],
  "samlEntityIdentifiers": [
    "4f6778d8-5aef-43dc-a1ff-b073724b9495",
    "https://azurehealthcareapis.com",
    "https://fhir.azurehealthcareapis.com"
  ],
  "samlSettings": null,
  "loginUrl": null,
  "logoutUrl": null,
  "tokenEncryptionKeyId": null,
  "preferredTokenSigningKeyThumbprint": null,
  "optionalClaims": null,
  "implicitGrantSettings": null,
  "credentials": [],
  "findings": [
    {
      "rule": "AssignmentRequired",
      "status": "FAIL",
      "evidence": "Configured value: False"
    },
    {
      "rule": "TwoHumanOwners",
      "status": "FAIL",
      "evidence": "Human owners: 0; total owners: 0. Automation owners are preserved."
    },
    {
      "rule": "RedirectUriSecurity",
      "status": "UNKNOWN",
      "evidence": "Non-HTTPS/non-localhost URIs: . Native-app custom schemes need separate review."
    },
    {
      "rule": "CredentialDates",
      "status": "MANUAL",
      "evidence": "Policy: secrets <=90 days; certificates <=365 days; warning at <=30 days remaining. Retired keys may still be listed."
    },
    {
      "rule": "GroupAssignmentsPreferred",
      "status": "WARN",
      "evidence": "Groups: 0; direct users: 0. Nested membership is not evaluated."
    },
    {
      "rule": "ProtocolConfirmation",
      "status": "MANUAL",
      "evidence": "Graph SSO hint: . A missing hint does not prove absence of OIDC."
    },
    {
      "rule": "AuthenticationAndClaims",
      "status": "MANUAL",
      "evidence": "Test assigned/unassigned users, emitted claims, assertion validation, token lifetime, redirects, and logout in the actual application."
    },
    {
      "rule": "SamlVerificationAndEncryption",
      "status": "MANUAL",
      "evidence": "Verify request-signature enforcement, active signing certificate, claim mappings, metadata and encryption requirement against the delivery form. UNKNOWN protocol still requires protocol review."
    },
    {
      "rule": "OperationsAndDocumentation",
      "status": "MANUAL",
      "evidence": "Review sign-in/audit logs, Conditional Access, TLS configuration, approval, business/support contacts and delivery form."
    }
  ],
  "appOwnerOrganizationId": "f8cdef31-a31e-4b4a-93e4-5f571e91255a",
  "publisherName": null,
  "servicePrincipalType": "Application",
  "appRoles": [
    {
      "value": "offline_access",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Grants permission for refresh tokens to be used to obtain a new access token even after the user is no longer online.",
      "isEnabled": false,
      "origin": "Application",
      "id": "7f08bce5-b21b-4518-b783-c69c9c0cd658",
      "displayName": "offline_access"
    },
    {
      "value": "system.all.all",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Read and write all resources in the system.",
      "isEnabled": true,
      "origin": "Application",
      "id": "bea2566c-7172-42d0-a06a-0e2e2b58f084",
      "displayName": "system.all.all"
    },
    {
      "value": "system.all.read",
      "allowedMemberTypes": [
        "Application",
        "User"
      ],
      "description": "Allows a user to read all resources in the system.",
      "isEnabled": true,
      "origin": "Application",
      "id": "a44c4c64-cdb5-48fc-adbd-070df4852b2c",
      "displayName": "system.all.read"
    }
  ],
  "oauth2PermissionScopes": [
    {
      "id": "7f08bce5-b21b-4518-b783-c69c9c0cd658",
      "userConsentDisplayName": "offline_access",
      "adminConsentDescription": "Grants permission for refresh tokens to be used to obtain a new access token even after the user is no longer online.",
      "value": "offline_access",
      "type": "Admin",
      "isEnabled": false,
      "adminConsentDisplayName": "offline_access",
      "userConsentDescription": "Grants permission for refresh tokens to be used to obtain a new access token even after the user is no longer online."
    },
    {
      "id": "0ea38e69-761b-46c7-ac06-9cd17d518949",
      "userConsentDisplayName": "openid",
      "adminConsentDescription": "Grants permission to retrieve information about the current logged-in user.",
      "value": "openid",
      "type": "User",
      "isEnabled": false,
      "adminConsentDisplayName": "openid",
      "userConsentDescription": "Grants permission to retrieve information about the current logged-in user."
    },
    {
      "id": "97d73b5a-b052-4953-a6da-3e3f159a2f85",
      "userConsentDisplayName": "user.Immunization.read",
      "adminConsentDescription": "Allows user to read Immunization resources in their compartment.",
      "value": "user.Immunization.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.Immunization.read",
      "userConsentDescription": "Allows user to read Immunization resources in their compartment."
    },
    {
      "id": "6fbb6a2c-cd2f-486c-a421-b188f2184df8",
      "userConsentDisplayName": "patient.Location.read",
      "adminConsentDescription": "Allows a user to read Location resources in a patient's compartment.",
      "value": "patient.Location.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.Location.read",
      "userConsentDescription": "Allows a user to read Location resources in a patient's compartment."
    },
    {
      "id": "8d821765-6bbb-4f52-8b7f-0dfe9ce5cb1e",
      "userConsentDisplayName": "user.Provenance.read",
      "adminConsentDescription": "Allows user to read Provenance resources in their own compartment.",
      "value": "user.Provenance.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.Provenance.read",
      "userConsentDescription": "Allows user to read Provenance resources in their own compartment."
    },
    {
      "id": "81d46baa-aaff-454b-9a35-b6fdaa0eb2d9",
      "userConsentDisplayName": "user.Procedure.read",
      "adminConsentDescription": "Allows user to read Procedure resources in their own compartment.",
      "value": "user.Procedure.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.Procedure.read",
      "userConsentDescription": "Allows user to read Procedure resources in their own compartment."
    },
    {
      "id": "079186df-3044-4484-a785-d9750101f8f3",
      "userConsentDisplayName": "user.Practitioner.read",
      "adminConsentDescription": "Allows user to read Practitioner resources in their own compartment.",
      "value": "user.Practitioner.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.Practitioner.read",
      "userConsentDescription": "Allows user to read Practitioner resources in their own compartment."
    },
    {
      "id": "56998e01-1f00-4832-a130-c358e252acf2",
      "userConsentDisplayName": "user.Patient.read",
      "adminConsentDescription": "Allows user to read Patient resources in their own compartment.",
      "value": "user.Patient.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.Patient.read",
      "userConsentDescription": "Allows user to read Patient resources in their own compartment."
    },
    {
      "id": "e75606ef-f141-4339-a248-f4c9b07886b2",
      "userConsentDisplayName": "user.Organization.read",
      "adminConsentDescription": "Allows user to read Organization resources in their own compartment.",
      "value": "user.Organization.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.Organization.read",
      "userConsentDescription": "Allows user to read Organization resources in their own compartment."
    },
    {
      "id": "556e34b1-56e8-4c27-b6be-679d856c0efa",
      "userConsentDisplayName": "user.Observation.read",
      "adminConsentDescription": "Allows user to read Observation resources in their own compartment.",
      "value": "user.Observation.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.Observation.read",
      "userConsentDescription": "Allows user to read Observation resources in their own compartment."
    },
    {
      "id": "c1519c05-9e3c-4656-844a-c83845bbaa9a",
      "userConsentDisplayName": "user.MedicationRequest.read",
      "adminConsentDescription": "Allows user to read MedicationRequest resources in their own compartment.",
      "value": "user.MedicationRequest.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.MedicationRequest.read",
      "userConsentDescription": "Allows user to read MedicationRequest resources in their own compartment."
    },
    {
      "id": "cf8b4a64-fb79-401f-94a4-28d9d7cd6a8d",
      "userConsentDisplayName": "user.Location.read",
      "adminConsentDescription": "Allows user to read Location resources in their own compartment.",
      "value": "user.Location.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.Location.read",
      "userConsentDescription": "Allows user to read Location resources in their own compartment."
    },
    {
      "id": "81d580ea-26f6-4822-9d91-31fb29019023",
      "userConsentDisplayName": "user.Goal.read",
      "adminConsentDescription": "Allows user to read Goal resources in their own compartment.",
      "value": "user.Goal.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.Goal.read",
      "userConsentDescription": "Allows user to read Goal resources in their own compartment."
    },
    {
      "id": "0e5be5d5-7b95-4583-aa3c-2de990f139c9",
      "userConsentDisplayName": "user.Encounter.read",
      "adminConsentDescription": "Allows user to read Encounter resources in their own compartment.",
      "value": "user.Encounter.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.Encounter.read",
      "userConsentDescription": "Allows user to read Encounter resources in their own compartment."
    },
    {
      "id": "588567a0-59db-4598-8bd7-0cbea9ff1811",
      "userConsentDisplayName": "user.DiagnosticReport.read",
      "adminConsentDescription": "Allows user to read DiagnosticReport resources in their own compartment.",
      "value": "user.DiagnosticReport.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.DiagnosticReport.read",
      "userConsentDescription": "Allows user to read DiagnosticReport resources in their own compartment."
    },
    {
      "id": "23b15307-5f89-4954-b86c-00e2c4279a8f",
      "userConsentDisplayName": "user.DocumentReference.read",
      "adminConsentDescription": "Allows user to read DocumentReference resources in their own compartment.",
      "value": "user.DocumentReference.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.DocumentReference.read",
      "userConsentDescription": "Allows user to read DocumentReference resources in their own compartment."
    },
    {
      "id": "a246e7b9-d55c-43a2-9b5a-b3341bc1a57d",
      "userConsentDisplayName": "user.Device.read",
      "adminConsentDescription": "Allows user to read Device resources in their own compartment.",
      "value": "user.Device.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.Device.read",
      "userConsentDescription": "Allows user to read Device resources in their own compartment."
    },
    {
      "id": "dd554abf-e473-4190-8382-9b096fe49efa",
      "userConsentDisplayName": "user.Condition.read",
      "adminConsentDescription": "Allows user to read Condition resources in their own compartment.",
      "value": "user.Condition.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.Condition.read",
      "userConsentDescription": "Allows user to read Condition resources in their own compartment."
    },
    {
      "id": "3cb5f829-1e8d-4224-9e87-678b02c8f9b1",
      "userConsentDisplayName": "user.CareTeam.read",
      "adminConsentDescription": "Allows user to read CareTeam resources in their own compartment.",
      "value": "user.CareTeam.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.CareTeam.read",
      "userConsentDescription": "Allows user to read CareTeam resources in their own compartment."
    },
    {
      "id": "ae77fe95-13db-47f8-968c-5eee9d973273",
      "userConsentDisplayName": "user.PractitionerRole.read",
      "adminConsentDescription": "Allows user to read PractitionerRole resources in their own compartment.",
      "value": "user.PractitionerRole.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.PractitionerRole.read",
      "userConsentDescription": "Allows user to read PractitionerRole resources in their own compartment."
    },
    {
      "id": "1d6a9f65-62f4-42b0-93d7-fc3437112f46",
      "userConsentDisplayName": "patient.PractitionerRole.read",
      "adminConsentDescription": "Allows user to read PractitionerRole resources in a patient's compartment.",
      "value": "patient.PractitionerRole.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.PractitionerRole.read",
      "userConsentDescription": "Allows user to read PractitionerRole resources in a patient's compartment."
    },
    {
      "id": "d56c68f3-ec5f-4e12-82cc-afa8921337f0",
      "userConsentDisplayName": "patient.Provenance.read",
      "adminConsentDescription": "Allows user to read Provenance resources in a patient's compartment.",
      "value": "patient.Provenance.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.Provenance.read",
      "userConsentDescription": "Allows user to read Provenance resources in a patient's compartment."
    },
    {
      "id": "be1c7593-9057-4947-a456-424dde696627",
      "userConsentDisplayName": "patient.Procedure.read",
      "adminConsentDescription": "Allows user to read Procedure resources in a patient's compartment.",
      "value": "patient.Procedure.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.Procedure.read",
      "userConsentDescription": "Allows user to read Procedure resources in a patient's compartment."
    },
    {
      "id": "ad27d725-86ff-4bc9-86fb-afdb2f007089",
      "userConsentDisplayName": "patient.Practitioner.read",
      "adminConsentDescription": "Allows user to read Practitioner resources in a patient's compartment.",
      "value": "patient.Practitioner.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.Practitioner.read",
      "userConsentDescription": "Allows user to read Practitioner resources in a patient's compartment."
    },
    {
      "id": "d23f0b68-a2f5-4647-987b-b58fdd86b49d",
      "userConsentDisplayName": "patient.Patient.read",
      "adminConsentDescription": "Allows user to read Patient resources in a patient's compartment.",
      "value": "patient.Patient.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.Patient.read",
      "userConsentDescription": "Allows user to read Patient resources in a patient's compartment."
    },
    {
      "id": "81882045-ad54-4a5f-926c-a2a09d7dd2b5",
      "userConsentDisplayName": "patient.Organization.read",
      "adminConsentDescription": "Allows user to read Organization resources in a patient's compartment.",
      "value": "patient.Organization.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.Organization.read",
      "userConsentDescription": "Allows user to read Organization resources in a patient's compartment."
    },
    {
      "id": "890da85b-b5ad-4981-8966-4b80fd75a5b8",
      "userConsentDisplayName": "patient.Observation.read",
      "adminConsentDescription": "Allows user to read Observation resources in a patient's compartment.",
      "value": "patient.Observation.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.Observation.read",
      "userConsentDescription": "Allows user to read Observation resources in a patient's compartment."
    },
    {
      "id": "16352d13-6c69-4eee-adbb-f7420b3f252b",
      "userConsentDisplayName": "patient.MedicationRequest.read",
      "adminConsentDescription": "Allows user to read MedicationRequest resources in a patient's compartment.",
      "value": "patient.MedicationRequest.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.MedicationRequest.read",
      "userConsentDescription": "Allows user to read MedicationRequest resources in a patient's compartment."
    },
    {
      "id": "f6c2728b-b49d-4d10-bb69-7798f1603807",
      "userConsentDisplayName": "patient.Immunization.read",
      "adminConsentDescription": "Allows user to read Immunization resources in a patient's compartment.",
      "value": "patient.Immunization.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.Immunization.read",
      "userConsentDescription": "Allows user to read Immunization resources in a patient's compartment."
    },
    {
      "id": "e6e32ed0-c9a2-4f1b-adb5-e3d59e47bb54",
      "userConsentDisplayName": "patient.Goal.read",
      "adminConsentDescription": "Allows user to read Goal resources in a patient's compartment.",
      "value": "patient.Goal.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.Goal.read",
      "userConsentDescription": "Allows user to read Goal resources in a patient's compartment."
    },
    {
      "id": "9e7cdd6e-af8a-4e6d-9170-4274b35864bc",
      "userConsentDisplayName": "patient.Encounter.read",
      "adminConsentDescription": "Allows user to read Encounter resources in a patient's compartment.",
      "value": "patient.Encounter.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.Encounter.read",
      "userConsentDescription": "Allows user to read Encounter resources in a patient's compartment."
    },
    {
      "id": "e2a5290a-59c6-4847-af7f-c5b16c692f24",
      "userConsentDisplayName": "patient.DocumentReference.read",
      "adminConsentDescription": "Allows user to read DocumentReference resources in a patient's compartment.",
      "value": "patient.DocumentReference.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.DocumentReference.read",
      "userConsentDescription": "Allows user to read DocumentReference resources in a patient's compartment."
    },
    {
      "id": "ef9475b2-f7da-4a86-b385-9fffe030c310",
      "userConsentDisplayName": "patient.DiagnosticReport.read",
      "adminConsentDescription": "Allows user to read DiagnosticReport resources in a patient's compartment.",
      "value": "patient.DiagnosticReport.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.DiagnosticReport.read",
      "userConsentDescription": "Allows user to read DiagnosticReport resources in a patient's compartment."
    },
    {
      "id": "f7b318b5-9bf5-46d0-8701-845c568925d9",
      "userConsentDisplayName": "patient.Device.read",
      "adminConsentDescription": "Allows user to read Device resources in a patient's compartment.",
      "value": "patient.Device.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.Device.read",
      "userConsentDescription": "Allows user to read Device resources in a patient's compartment."
    },
    {
      "id": "60fd617d-0d96-4c44-9cf3-ee91c0c45161",
      "userConsentDisplayName": "patient.Condition.read",
      "adminConsentDescription": "Allows user to read Condition resources in a patient's compartment.",
      "value": "patient.Condition.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.Condition.read",
      "userConsentDescription": "Allows user to read Condition resources in a patient's compartment."
    },
    {
      "id": "4860ad86-f40e-4e2b-8661-ba03ee154b19",
      "userConsentDisplayName": "patient.CareTeam.read",
      "adminConsentDescription": "Allows user to read CareTeam resources in a patient's compartment.",
      "value": "patient.CareTeam.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.CareTeam.read",
      "userConsentDescription": "Allows user to read CareTeam resources in a patient's compartment."
    },
    {
      "id": "4fcc09b8-fd6b-430f-9b2b-7bbd2c2b7e8f",
      "userConsentDisplayName": "patient.CarePlan.read",
      "adminConsentDescription": "Allows user to read CarePlan resources in a patient's compartment.",
      "value": "patient.CarePlan.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.CarePlan.read",
      "userConsentDescription": "Allows user to read CarePlan resources in a patient's compartment."
    },
    {
      "id": "c2c62692-9cd2-4612-9f15-cf5641284e41",
      "userConsentDisplayName": "user.CarePlan.read",
      "adminConsentDescription": "Allows user to read CarePlan resources in their own compartment.",
      "value": "user.CarePlan.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.CarePlan.read",
      "userConsentDescription": "Allows user to read CarePlan resources in their own compartment."
    },
    {
      "id": "263687ba-ab05-41b1-98ad-f057c7365c91",
      "userConsentDisplayName": "user.AllergyIntolerance.read",
      "adminConsentDescription": "Allows user to read AllergyIntolerance resources in their own compartment.",
      "value": "user.AllergyIntolerance.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.AllergyIntolerance.read",
      "userConsentDescription": "Allows user to read AllergyIntolerance resources in their own compartment."
    },
    {
      "id": "fa23e5cb-b06f-4d07-bcf8-f5ce114dd847",
      "userConsentDisplayName": "patient.AllergyIntolerance.read",
      "adminConsentDescription": "Allows user to read AllergyIntolerance resources in a patient's compartment.",
      "value": "patient.AllergyIntolerance.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.AllergyIntolerance.read",
      "userConsentDescription": "Allows user to read AllergyIntolerance resources in a patient's compartment."
    },
    {
      "id": "e5a7cdb9-3edb-4b0a-a43d-40a377726680",
      "userConsentDisplayName": "user.Medication.read",
      "adminConsentDescription": "Allows user to read Medication resources in their own compartment.",
      "value": "user.Medication.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.Medication.read",
      "userConsentDescription": "Allows user to read Medication resources in their own compartment."
    },
    {
      "id": "058fa58e-ac09-4308-970e-2f2da3bf49b4",
      "userConsentDisplayName": "patient.Medication.read",
      "adminConsentDescription": "Allows user to read Medication resources in a patient's compartment.",
      "value": "patient.Medication.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.Medication.read",
      "userConsentDescription": "samples readAllows user to read Medication resources in a patient's compartment."
    },
    {
      "id": "a86144c7-3e19-4b56-9675-15803eb1e617",
      "userConsentDisplayName": "fhirUser",
      "adminConsentDescription": "Grants permission to read information about the current logged-in user.",
      "value": "fhirUser",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "fhirUser",
      "userConsentDescription": "Grants permission to read information about the current logged-in user."
    },
    {
      "id": "8f4fe9ac-b7f2-43ca-a0ef-070f4a8ae5dc",
      "userConsentDisplayName": "online_access",
      "adminConsentDescription": "Grants permission for a refresh token to be used to obtain a new access token as long as the user is still online.",
      "value": "online_access",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "online_access",
      "userConsentDescription": "Grants permission for a refresh token to be used to obtain a new access token as long as the user is still online."
    },
    {
      "id": "f6c8eb20-e799-4de7-a7ce-74ca0c7270e1",
      "userConsentDisplayName": "launch.patient",
      "adminConsentDescription": "Asks for a patient to be selected at launch time.",
      "value": "launch.patient",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "launch.patient",
      "userConsentDescription": "Asks for a patient to be selected at launch time."
    },
    {
      "id": "fa5f9b76-5f20-4466-8b3d-6718de9744e2",
      "userConsentDisplayName": "launch",
      "adminConsentDescription": "Grants permission to obtain launch context.",
      "value": "launch",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "launch",
      "userConsentDescription": "Grants permission to obtain launch context."
    },
    {
      "id": "5a03b38d-4081-4265-9558-aab5f2a18b8b",
      "userConsentDisplayName": "user.all.read",
      "adminConsentDescription": "Allows a user to read all resources in their compartment.",
      "value": "user.all.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "user.all.read",
      "userConsentDescription": "Allows a user to read all resources in their compartment."
    },
    {
      "id": "c71e9482-f052-461b-80e1-7cfeba7b2b12",
      "userConsentDisplayName": "patient.all.read",
      "adminConsentDescription": "Allows user to read all resources in a patient's compartment.",
      "value": "patient.all.read",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "patient.all.read",
      "userConsentDescription": "Allows user to read all resources in a patient's compartment."
    },
    {
      "id": "db75143a-8f20-4238-9450-8b73ef4992f4",
      "userConsentDisplayName": "Access Azure Healthcare APIs",
      "adminConsentDescription": "Allow the application to access Azure Healthcare APIs on behalf of the signed-in user.",
      "value": "user_impersonation",
      "type": "User",
      "isEnabled": true,
      "adminConsentDisplayName": "Access Azure Healthcare APIs",
      "userConsentDescription": "Allow the application to access Azure Healthcare APIs on your behalf."
    }
  ],
  "description": null,
  "homepage": null,
  "tags": null,
  "info": {
    "marketingUrl": null,
    "supportUrl": null,
    "termsOfServiceUrl": null,
    "privacyStatementUrl": null,
    "logoUrl": null
  },
  "registration": null,
  "applicationPermissionGrants": {
    "status": "AVAILABLE",
    "items": [],
    "reason": null
  },
  "delegatedConsentGrants": {
    "status": "AVAILABLE",
    "items": []
  },
  "recentSignIns": {
    "status": "AVAILABLE",
    "items": []
  },
  "scopeNote": "Catalog observation; apply the supplied SSO requirements only after confirming this is an in-scope production SSO application. Platform/resource apps may legitimately differ."
}
```
