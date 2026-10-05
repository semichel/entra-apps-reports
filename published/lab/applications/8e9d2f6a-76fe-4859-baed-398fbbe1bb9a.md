# WindowsDefenderATP

[← All applications](../README.md)

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


## Complete collected application configuration


```json
{
  "displayName": "WindowsDefenderATP",
  "servicePrincipalId": "8e9d2f6a-76fe-4859-baed-398fbbe1bb9a",
  "appId": "fc780465-2017-40d4-a0c5-307022471b92",
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
    "fc780465-2017-40d4-a0c5-307022471b92",
    "https://userrequestsgraphapiep-prd.trafficmanager.net",
    "https://api.securitycenter.windows.com/",
    "https://securitycenter.onmicrosoft.com/windowsatpservice",
    "https://managementapi.securitycenter.windows.com/",
    "https://publicapi-prd.trafficmanager.net/",
    "https://api.securitycenter.windows.us/",
    "https://securityoperations.microsoft.com",
    "https://api-gov.securitycenter.microsoft.us",
    "https://api.securitycenter.microsoft.com",
    "https://api-us.securitycenter.microsoft.com",
    "https://api-eu.securitycenter.microsoft.com",
    "https://api-uk.securitycenter.microsoft.com",
    "https://securitycenter.microsoft.com/mtp",
    "https://api-gcc.securitycenter.microsoft.us/",
    "https://api.securitycenter.microsoft.com/",
    "https://api-gcc.securitycenter.microsoft.us",
    "https://securitycenter.microsoft.com/mtp/",
    "https://api-uk.securitycenter.microsoft.com/",
    "https://api-eu.securitycenter.microsoft.com/",
    "https://api-us.securitycenter.microsoft.com/",
    "https://api-gov.securitycenter.microsoft.us/",
    "https://securityoperations.microsoft.com/",
    "https://api.securitycenter.windows.us",
    "https://publicapi-prd.trafficmanager.net",
    "https://managementapi.securitycenter.windows.com",
    "https://securitycenter.onmicrosoft.com/windowsatpservice/",
    "https://api.securitycenter.windows.com",
    "https://userrequestsgraphapiep-prd.trafficmanager.net/"
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
      "value": "SecurityBaselinesAssessment.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read all security baselines assessment information",
      "isEnabled": true,
      "origin": "Application",
      "id": "e870c0c1-c1a2-41ca-948e-a33912d2d3f0",
      "displayName": "Read all security baselines assessment information"
    },
    {
      "value": "SecurityConfiguration.ReadWrite.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read and write all security configurations",
      "isEnabled": true,
      "origin": "Application",
      "id": "e5e05709-32a3-4c85-89c8-67596eb94f24",
      "displayName": "Read and write all security configurations"
    },
    {
      "value": "SecurityConfiguration.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read all security configurations",
      "isEnabled": true,
      "origin": "Application",
      "id": "227f2ea0-c2c2-4428-b7af-9ff40f1a720e",
      "displayName": "Read all security configurations"
    },
    {
      "value": "Library.Manage",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to manage live response library files",
      "isEnabled": true,
      "origin": "Application",
      "id": "41d209c7-2511-4fc9-b899-8008a3976f09",
      "displayName": "Manage live response library files"
    },
    {
      "value": "RemediationTasks.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read all remediation tasks",
      "isEnabled": true,
      "origin": "Application",
      "id": "6a33eedf-ba73-4e5a-821b-f057ef63853a",
      "displayName": "Read all remediation tasks"
    },
    {
      "value": "Score.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read any Threat and Vulnerability Management  score",
      "isEnabled": true,
      "origin": "Application",
      "id": "02b005dd-f804-43b4-8fc7-078460413f74",
      "displayName": "Read Threat and Vulnerability Management score"
    },
    {
      "value": "Vulnerability.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read any Threat and Vulnerability Management vulnerability information",
      "isEnabled": true,
      "origin": "Application",
      "id": "41269fc5-d04d-4bfd-bce7-43a51cea049a",
      "displayName": "Read Threat and Vulnerability Management vulnerability information"
    },
    {
      "value": "Software.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read any Threat and Vulnerability Management software information",
      "isEnabled": true,
      "origin": "Application",
      "id": "37f71c98-d198-41ae-964d-2c49aab74926",
      "displayName": "Read Threat and Vulnerability Management software information"
    },
    {
      "value": "SecurityRecommendation.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read any Threat and Vulnerability Management security recommendation",
      "isEnabled": true,
      "origin": "Application",
      "id": "6443965c-7dd2-4cfd-b38f-bb7772bee163",
      "displayName": "Read Threat and Vulnerability Management security recommendations"
    },
    {
      "value": "Ti.ReadWrite.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to manage all IOCs of the tenant",
      "isEnabled": true,
      "origin": "Application",
      "id": "fc511a58-3adf-4d71-af24-00f13e35e479",
      "displayName": "Read and write all IOCs"
    },
    {
      "value": "Machine.CollectForensics",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to collect forensics from a machine",
      "isEnabled": true,
      "origin": "Application",
      "id": "15405ab2-2103-4a3c-ad80-e829841cedcc",
      "displayName": "Collect forensics"
    },
    {
      "value": "Alert.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read any alert",
      "isEnabled": true,
      "origin": "Application",
      "id": "71fe6b80-7034-4028-9ed8-0f316df9c3ff",
      "displayName": "Read all alerts"
    },
    {
      "value": "User.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read all user profiles",
      "isEnabled": true,
      "origin": "Application",
      "id": "a833834a-4cf1-4732-8acf-bbcfa13fb610",
      "displayName": "Read user profiles"
    },
    {
      "value": "Ip.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read all IP address profiles",
      "isEnabled": true,
      "origin": "Application",
      "id": "47bf842d-354b-49ef-b741-3a6dd815bc13",
      "displayName": "Read IP address profiles"
    },
    {
      "value": "Url.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read all URL profiles",
      "isEnabled": true,
      "origin": "Application",
      "id": "721af526-ffa8-42d7-9b84-1a56244dd99d",
      "displayName": "Read URL profiles"
    },
    {
      "value": "File.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read all file profiles",
      "isEnabled": true,
      "origin": "Application",
      "id": "8788f1a9-beca-4e26-ba58-10513f3b896f",
      "displayName": "Read file profiles"
    },
    {
      "value": "Machine.Offboard",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to offboard a machine from the service",
      "isEnabled": true,
      "origin": "Application",
      "id": "594435bf-36dd-4548-83bd-1bdafe157d7a",
      "displayName": "Offboard machine"
    },
    {
      "value": "Machine.StopAndQuarantine",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to stop a file running on a machine and to quarantine that file",
      "isEnabled": true,
      "origin": "Application",
      "id": "96e72b5e-7e68-4171-aad1-3937599e4751",
      "displayName": "Stop and quarantine file"
    },
    {
      "value": "Machine.RestrictExecution",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to restrict code execution on a machine according to policy",
      "isEnabled": true,
      "origin": "Application",
      "id": "96b6b35d-074d-4e2d-b167-8d68d9269648",
      "displayName": "Restrict code execution"
    },
    {
      "value": "Machine.Scan",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to scan a machine",
      "isEnabled": true,
      "origin": "Application",
      "id": "a86d9824-b2b6-45f8-b042-16bc4922ed4e",
      "displayName": "Scan machine"
    },
    {
      "value": "Machine.Isolate",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to isolate a machine",
      "isEnabled": true,
      "origin": "Application",
      "id": "7e4e1300-e1b9-4102-88ba-f0cb6e6d5974",
      "displayName": "Isolate machine"
    },
    {
      "value": "Machine.ReadWrite.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to create machine records and to read or update any machine record",
      "isEnabled": true,
      "origin": "Application",
      "id": "aa027352-232b-4ed4-b963-a705fc4d6d2c",
      "displayName": "Read and write all machine information"
    },
    {
      "value": "Machine.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read all machine profiles, including the commands that were sent to each machine",
      "isEnabled": true,
      "origin": "Application",
      "id": "ea8291d3-4b9a-44b5-bc3a-6cea3026dc79",
      "displayName": "Read all machine profiles"
    },
    {
      "value": "AdvancedQuery.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to run advanced queries",
      "isEnabled": true,
      "origin": "Application",
      "id": "93489bf5-0fbc-4f2d-b901-33f2fe08ff05",
      "displayName": "Run advanced queries"
    },
    {
      "value": "Event.Write",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to create events in the machine timeline",
      "isEnabled": true,
      "origin": "Application",
      "id": "84ddd701-5fac-4c30-b0ad-aa73a67bea1a",
      "displayName": "Write timeline events"
    },
    {
      "value": "Ti.ReadWrite",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to create IOCs and to read or update IOCs it created",
      "isEnabled": true,
      "origin": "Application",
      "id": "a8bc2240-f96a-46a1-bad5-6a960b7327a1",
      "displayName": "Read and write IOCs belonging to the app"
    },
    {
      "value": "Alert.ReadWrite.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to create or update any alert",
      "isEnabled": true,
      "origin": "Application",
      "id": "0f7000ec-157b-497f-b70e-ef0b0584f140",
      "displayName": "Read and write all alerts"
    },
    {
      "value": "secop",
      "allowedMemberTypes": [
        "User"
      ],
      "description": "Users assign to this role will be able to access the Windows Defender ATP portal, view all the data and be able to perform actions such as change alerts status, apply suppression rules etc.",
      "isEnabled": true,
      "origin": "Application",
      "id": "2261fd4a-5f23-4b74-9e4d-f4ac92dc86a2",
      "displayName": "Security Operations - Read & Write"
    },
    {
      "value": "readonly",
      "allowedMemberTypes": [
        "User"
      ],
      "description": "Users assign to this role will be able to access the Windows Defender ATP portal, view all the data but will not be able to perform any action",
      "isEnabled": true,
      "origin": "Application",
      "id": "f820e656-f1d1-4cb8-a566-31d18eeecb40",
      "displayName": "Security Operations - Read Only"
    },
    {
      "value": "IntegrationConfiguration.ReadWrite",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read and modify integration settings between itself and the service",
      "isEnabled": true,
      "origin": "Application",
      "id": "7c6f6912-60e9-4fcd-bb2a-c25bc35e8c59",
      "displayName": "Read and Write Integration settings"
    },
    {
      "value": "Ti.Read.All",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to read all IOCs",
      "isEnabled": true,
      "origin": "Application",
      "id": "528ca142-c849-4a5b-935e-10b8b9c38a84",
      "displayName": "Read all IOCs"
    },
    {
      "value": "Machine.LiveResponse",
      "allowedMemberTypes": [
        "Application"
      ],
      "description": "Allows the app to run a live response on a specific machine",
      "isEnabled": true,
      "origin": "Application",
      "id": "1629b959-c0af-42a1-92f0-f6162060bdf1",
      "displayName": "Run live response on a specific machine"
    }
  ],
  "oauth2PermissionScopes": [
    {
      "id": "d42e2aa1-a664-43a9-b7c6-2766d44a6687",
      "userConsentDisplayName": "Read security baselines assessment information",
      "adminConsentDescription": "Allows the app to read security baselines assessment information",
      "value": "SecurityBaselinesAssessment.Read",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read security baselines assessment information",
      "userConsentDescription": "Allows the app to read security baselines assessment information"
    },
    {
      "id": "bfc81a3a-4f6d-4bfe-b945-d7fe6747d2a0",
      "userConsentDisplayName": "Read and write security configurations",
      "adminConsentDescription": "Allows the app to read and write security configurations that the signed in user can manage",
      "value": "SecurityConfiguration.ReadWrite",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read and write security configurations",
      "userConsentDescription": "Read and write seAllows the app to read and write security configurations that the signed in user can managecurity configurations"
    },
    {
      "id": "4ac83e46-552f-4948-91c2-f7eaff971018",
      "userConsentDisplayName": "Read security configurations",
      "adminConsentDescription": "Allows the app to read security configurations that the signed in user can access",
      "value": "SecurityConfiguration.Read",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read security configurations",
      "userConsentDescription": "Allows the app to read security configurations that the signed in user can access"
    },
    {
      "id": "5998a3da-2c9b-4bf3-99bd-44c9fe337ad2",
      "userConsentDisplayName": "Manage live response library files",
      "adminConsentDescription": "Allows the app to manage live response library files on behalf of the signed-in user",
      "value": "Library.Manage",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Manage live response library files",
      "userConsentDescription": "Allows the app to manage live response library files on behalf of the signed-in user"
    },
    {
      "id": "19956c04-168f-4f44-b471-48c8f50dc0c8",
      "userConsentDisplayName": "Read remediation tasks",
      "adminConsentDescription": "Allows the app to read remediation tasks that the signed in user can",
      "value": "RemediationTasks.Read",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read remediation tasks",
      "userConsentDescription": "Allows the app to read remediation tasks that the signed in user can"
    },
    {
      "id": "df4ed126-3a4c-460a-b0fc-67aea84fc332",
      "userConsentDisplayName": "Read Threat and Vulnerability Management score",
      "adminConsentDescription": "Allows the app to read Threat and Vulnerability Management score on behalf of the signed-in user",
      "value": "Score.Read",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read Threat and Vulnerability Management score",
      "userConsentDescription": "Allows the app to read Threat and Vulnerability Management score on behalf of the signed-in user"
    },
    {
      "id": "63a677ce-818c-4409-9d12-5c6d2e2a6bfe",
      "userConsentDisplayName": "Read Threat and Vulnerability Management vulnerability information",
      "adminConsentDescription": "Allows the app to read Threat and Vulnerability Management vulnerability information on behalf of the signed-in user",
      "value": "Vulnerability.Read",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read Threat and Vulnerability Management vulnerability information",
      "userConsentDescription": "Allows the app to read Threat and Vulnerability Management vulnerability information on behalf of the signed-in user"
    },
    {
      "id": "5f216ada-3f51-4a22-ace5-06b198328476",
      "userConsentDisplayName": "Read Threat and Vulnerability Management software information",
      "adminConsentDescription": "Allows the app to read Threat and Vulnerability Management software information on behalf of the signed-in user",
      "value": "Software.Read",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read Threat and Vulnerability Management software information",
      "userConsentDescription": "Allows the app to read Threat and Vulnerability Management software information on behalf of the signed-in user"
    },
    {
      "id": "1ab96238-1253-4059-a32f-4087f20ed65d",
      "userConsentDisplayName": "Read Threat and Vulnerability Management security recommendations",
      "adminConsentDescription": "Allows the app to read Threat and Vulnerability Management security recommendations on behalf of the signed-in user",
      "value": "SecurityRecommendation.Read",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read Threat and Vulnerability Management security recommendations",
      "userConsentDescription": "Allows the app to read Threat and Vulnerability Management security recommendations on behalf of the signed-in user"
    },
    {
      "id": "650ff1f9-dd5f-48ee-8c58-7beef332c818",
      "userConsentDisplayName": "Read and write IOCs",
      "adminConsentDescription": "Allows the app to create IOCs and to read or update IOCs it created, on behalf of the signed-in user",
      "value": "Ti.ReadWrite",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read and write IOCs",
      "userConsentDescription": "Allows the app to create IOCs and to read or update IOCs it created, on behalf of the signed-in user"
    },
    {
      "id": "1fb6e712-1bd9-4184-b1c0-5e71e759196b",
      "userConsentDisplayName": "Run advanced queries",
      "adminConsentDescription": "Allows the app to run advanced queries, that the signed-in user can execute.",
      "value": "AdvancedQuery.Read",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Run advanced queries",
      "userConsentDescription": "Allows the app to run advanced queries, that the signed-in user can execute."
    },
    {
      "id": "fbd3d33a-b1f5-4573-906c-51b39682fbcf",
      "userConsentDisplayName": "Read machine information",
      "adminConsentDescription": "Allows the app to read machine profiles (including the commands that were sent to each machine), that the signed in user can access",
      "value": "Machine.Read",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read machine information",
      "userConsentDescription": "Allows the app to read machine profiles (including the commands that were sent to each machine), that the signed in user can access"
    },
    {
      "id": "f6846c57-9e3c-4a65-81aa-2f5e09ff4f0b",
      "userConsentDisplayName": "Read and write  machine information",
      "adminConsentDescription": "Allows the app to create machine records and to read or update any machine record that the signed-in user can create, read or update.",
      "value": "Machine.ReadWrite",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read and write  machine information",
      "userConsentDescription": "Allows the app to create machine records and to read or update any machine record that the signed-in user can create, read or update."
    },
    {
      "id": "479231ef-3b86-4933-ae6b-1fa84bba9e31",
      "userConsentDisplayName": "Isolate machine",
      "adminConsentDescription": "Allows the app to isolate a machine on behalf of the signed-in user",
      "value": "Machine.Isolate",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Isolate machine",
      "userConsentDescription": "Allows the app to isolate a machine on behalf of the signed-in user"
    },
    {
      "id": "5eb7b9dc-cbce-4c7e-9d73-5be248260ae6",
      "userConsentDisplayName": "Collect forensics",
      "adminConsentDescription": "Allows the app to collect forensics data from a machine on behalf of the signed-in user",
      "value": "Machine.CollectForensics",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Collect forensics",
      "userConsentDescription": "Allows the app to collect forensics data from a machine on behalf of the signed-in user"
    },
    {
      "id": "b4618115-647e-42a5-bd0d-0ea9878fb376",
      "userConsentDisplayName": "Scan machine",
      "adminConsentDescription": "Allows the app to scan a machine on behalf of the signed-in user",
      "value": "Machine.Scan",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Scan machine",
      "userConsentDescription": "Allows the app to scan a machine on behalf of the signed-in user"
    },
    {
      "id": "abddfa88-80bb-4aef-81ff-18cbf29363a9",
      "userConsentDisplayName": "Restrict code execution",
      "adminConsentDescription": "Allows the app to restrict code execution on a machine according to policy on behalf of the signed-in user",
      "value": "Machine.RestrictExecution",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Restrict code execution",
      "userConsentDescription": "Allows the app to restrict code execution on a machine according to policy on behalf of the signed-in user"
    },
    {
      "id": "69e036b7-3f10-4d4c-a85e-82295629eca8",
      "userConsentDisplayName": "Stop and quarantine file",
      "adminConsentDescription": "Allows the app to restrict code execution on a machine according to policy on behalf of the signed-in user",
      "value": "Machine.StopAndQuarantine",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Stop and quarantine file",
      "userConsentDescription": "Allows the app to restrict code execution on a machine according to policy on behalf of the signed-in user"
    },
    {
      "id": "29d1c73a-07f6-495f-b62b-1554a954d0a3",
      "userConsentDisplayName": "Offboard machine",
      "adminConsentDescription": "Allows the app to offboard a machine from the service on behalf of the signed-in user",
      "value": "Machine.Offboard",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Offboard machine",
      "userConsentDescription": "Allows the app to offboard a machine from the service on behalf of the signed-in user"
    },
    {
      "id": "8fce64a0-67c8-4e39-8f47-cac9ff7e13bb",
      "userConsentDisplayName": "Read file profiles",
      "adminConsentDescription": "Allows the app to read all file profiles on",
      "value": "File.Read.All",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read file profiles",
      "userConsentDescription": "Allows the app to read all file profiles on"
    },
    {
      "id": "42b4777c-6196-49ad-9cfc-207e73f2eb61",
      "userConsentDisplayName": "Read URL profiles",
      "adminConsentDescription": "Allows the app to read all URL profiles on behalf of the signed-in user",
      "value": "Url.Read.All",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read URL profiles",
      "userConsentDescription": "Allows the app to read all URL profiles on behalf of the signed-in user"
    },
    {
      "id": "b65a97e8-c8e8-4908-b19a-f654615de1a9",
      "userConsentDisplayName": "Read IP address profiles",
      "adminConsentDescription": "Allows the app to read all IP address profiles on behalf of the signed-in user",
      "value": "Ip.Read.All",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read IP address profiles",
      "userConsentDescription": "Allows the app to read all IP address profiles on behalf of the signed-in user"
    },
    {
      "id": "ffd6563e-842b-4cfc-b349-06006e0473a3",
      "userConsentDisplayName": "Read user profiles",
      "adminConsentDescription": "Allows the app to read all user profiles on behalf of the signed-in user",
      "value": "User.Read.All",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read user profiles",
      "userConsentDescription": "Allows the app to read all user profiles on behalf of the signed-in user"
    },
    {
      "id": "cbc3b413-21e6-416d-95a4-af87687efbd0",
      "userConsentDisplayName": "Read and write alerts",
      "adminConsentDescription": "Allows the app to create or update any alert that the signed in user can create or update",
      "value": "Alert.ReadWrite",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read and write alerts",
      "userConsentDescription": "Allows the app to create or update any alert that the signed in user can create or update"
    },
    {
      "id": "b2069dc0-9fe9-4e6d-9aca-ccf3dd503819",
      "userConsentDisplayName": "Read alerts",
      "adminConsentDescription": "Allows the app to read any alert that the signed in user can access",
      "value": "Alert.Read",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read alerts",
      "userConsentDescription": "Allows the app to read any alert that the signed in user can access"
    },
    {
      "id": "7c6f6912-60e9-4fcd-bb2a-c25bc35e8c59",
      "userConsentDisplayName": "Read and Write Integration settings",
      "adminConsentDescription": "Allows the app to read and modify integration settings between itself and the service",
      "value": "IntegrationConfiguration.ReadWrite",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Read and Write Integration settings",
      "userConsentDescription": "Allows the app to read and modify integration settings between itself and the service"
    },
    {
      "id": "25fb0c21-5877-492a-8d0c-e7893a9585cc",
      "userConsentDisplayName": "Run live response on a specific machine",
      "adminConsentDescription": "Allows the app to run live response on a specific machine according to policy on behalf of the signed-in user",
      "value": "Machine.LiveResponse",
      "type": "Admin",
      "isEnabled": true,
      "adminConsentDisplayName": "Run live response on a specific machine",
      "userConsentDescription": "Allows the app to run live response on a specific machine according to policy on behalf of the signed-in user"
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
