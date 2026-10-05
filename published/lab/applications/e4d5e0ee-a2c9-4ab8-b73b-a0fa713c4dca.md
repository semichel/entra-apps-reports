# spn-tf-test

[← All applications](../README.md)

| Property | Value |
| --- | --- |
| Client ID | 6c72d97e-45f0-4767-841d-c2e3d50e0ae7 |
| Enterprise application ID | e4d5e0ee-a2c9-4ab8-b73b-a0fa713c4dca |
| Enabled | True |
| SSO hint | UNKNOWN |
| Publisher | Not available |
| Home tenant | 37dadda4-f2a4-47a8-8482-d40fe1a5aa48 |
| Assignment required | False |
| Policy observations | FAIL |


## Findings and required validation

| Check | Status | Evidence / next action |
| --- | --- | --- |
| AssignmentRequired | FAIL | Configured value: False |
| TwoHumanOwners | FAIL | Human owners: 0; total owners: 0. Automation owners are preserved. |
| RedirectUriSecurity | UNKNOWN | Non-HTTPS/non-localhost URIs: . Native-app custom schemes need separate review. |
| CredentialDates | FAIL | Policy: secrets &lt;=90 days; certificates &lt;=365 days; warning at &lt;=30 days remaining. Retired keys may still be listed. |
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
| Not available | AppRegistration | passwordCredentials | 06/30/2027 07:45:59 | 267.0 | 365.0 | FAIL |


## Callback URLs


```json
[]
```


## App registration and federation


```json
{
  "id": "4a322385-16ad-44ef-b4fe-0b39a1545fc7",
  "appId": "6c72d97e-45f0-4767-841d-c2e3d50e0ae7",
  "displayName": "spn-tf-test",
  "description": null,
  "signInAudience": "AzureADMyOrg",
  "publisherDomain": "Betancoraleman.onmicrosoft.com",
  "createdDateTime": "2026-06-30T07:43:35Z",
  "web": {
    "redirectUris": [],
    "homePageUrl": null,
    "implicitGrantSettings": {
      "enableIdTokenIssuance": false,
      "enableAccessTokenIssuance": false
    },
    "logoutUrl": null,
    "redirectUriSettings": []
  },
  "spa": {
    "redirectUris": []
  },
  "publicClient": {
    "redirectUris": []
  },
  "identifierUris": null,
  "optionalClaims": null,
  "groupMembershipClaims": null,
  "api": {
    "requestedAccessTokenVersion": null,
    "oauth2PermissionScopes": [],
    "preAuthorizedApplications": [],
    "acceptMappedClaims": null,
    "knownClientApplications": []
  },
  "appRoles": null,
  "requiredResourceAccess": null,
  "info": {
    "marketingUrl": null,
    "supportUrl": null,
    "termsOfServiceUrl": null,
    "privacyStatementUrl": null,
    "logoUrl": null
  },
  "tags": null,
  "owners": {
    "status": "AVAILABLE",
    "items": [],
    "reason": null
  },
  "federatedIdentityCredentials": {
    "status": "AVAILABLE",
    "items": [],
    "reason": null
  },
  "credentials": [
    {
      "source": "AppRegistration",
      "kind": "passwordCredentials",
      "keyId": "317cd20f-2dbb-4b6c-9998-f8ba2526ed22",
      "displayName": null,
      "usage": null,
      "startDateTime": "06/30/2026 07:45:59",
      "endDateTime": "06/30/2027 07:45:59",
      "daysRemaining": 267.0,
      "lifetimeDays": 365.0,
      "maximumDays": 90,
      "status": "FAIL"
    }
  ]
}
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
  "displayName": "spn-tf-test",
  "servicePrincipalId": "e4d5e0ee-a2c9-4ab8-b73b-a0fa713c4dca",
  "appId": "6c72d97e-45f0-4767-841d-c2e3d50e0ae7",
  "accountEnabled": true,
  "protocol": "UNKNOWN",
  "preferredSingleSignOnMode": null,
  "status": "FAIL",
  "registrationAvailable": true,
  "assignmentRequired": false,
  "owners": [],
  "assignments": [],
  "redirectUris": [],
  "identifierUris": [],
  "samlEntityIdentifiers": [
    "6c72d97e-45f0-4767-841d-c2e3d50e0ae7"
  ],
  "samlSettings": null,
  "loginUrl": null,
  "logoutUrl": null,
  "tokenEncryptionKeyId": null,
  "preferredTokenSigningKeyThumbprint": null,
  "optionalClaims": null,
  "implicitGrantSettings": {
    "enableIdTokenIssuance": false,
    "enableAccessTokenIssuance": false
  },
  "credentials": [
    {
      "source": "AppRegistration",
      "kind": "passwordCredentials",
      "keyId": "317cd20f-2dbb-4b6c-9998-f8ba2526ed22",
      "displayName": null,
      "usage": null,
      "startDateTime": "06/30/2026 07:45:59",
      "endDateTime": "06/30/2027 07:45:59",
      "daysRemaining": 267.0,
      "lifetimeDays": 365.0,
      "maximumDays": 90,
      "status": "FAIL"
    }
  ],
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
      "status": "FAIL",
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
  "appOwnerOrganizationId": "37dadda4-f2a4-47a8-8482-d40fe1a5aa48",
  "publisherName": null,
  "servicePrincipalType": "Application",
  "appRoles": null,
  "oauth2PermissionScopes": null,
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
  "registration": {
    "id": "4a322385-16ad-44ef-b4fe-0b39a1545fc7",
    "appId": "6c72d97e-45f0-4767-841d-c2e3d50e0ae7",
    "displayName": "spn-tf-test",
    "description": null,
    "signInAudience": "AzureADMyOrg",
    "publisherDomain": "Betancoraleman.onmicrosoft.com",
    "createdDateTime": "2026-06-30T07:43:35Z",
    "web": {
      "redirectUris": [],
      "homePageUrl": null,
      "implicitGrantSettings": {
        "enableIdTokenIssuance": false,
        "enableAccessTokenIssuance": false
      },
      "logoutUrl": null,
      "redirectUriSettings": []
    },
    "spa": {
      "redirectUris": []
    },
    "publicClient": {
      "redirectUris": []
    },
    "identifierUris": null,
    "optionalClaims": null,
    "groupMembershipClaims": null,
    "api": {
      "requestedAccessTokenVersion": null,
      "oauth2PermissionScopes": [],
      "preAuthorizedApplications": [],
      "acceptMappedClaims": null,
      "knownClientApplications": []
    },
    "appRoles": null,
    "requiredResourceAccess": null,
    "info": {
      "marketingUrl": null,
      "supportUrl": null,
      "termsOfServiceUrl": null,
      "privacyStatementUrl": null,
      "logoUrl": null
    },
    "tags": null,
    "owners": {
      "status": "AVAILABLE",
      "items": [],
      "reason": null
    },
    "federatedIdentityCredentials": {
      "status": "AVAILABLE",
      "items": [],
      "reason": null
    },
    "credentials": [
      {
        "source": "AppRegistration",
        "kind": "passwordCredentials",
        "keyId": "317cd20f-2dbb-4b6c-9998-f8ba2526ed22",
        "displayName": null,
        "usage": null,
        "startDateTime": "06/30/2026 07:45:59",
        "endDateTime": "06/30/2027 07:45:59",
        "daysRemaining": 267.0,
        "lifetimeDays": 365.0,
        "maximumDays": 90,
        "status": "FAIL"
      }
    ]
  },
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
