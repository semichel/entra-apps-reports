# Tenant evidence

[← Application report](README.md)

Log lookback: 7 days, starting 2026-09-28T10:04:15Z.

UNAVAILABLE means a query failed or access/licensing was insufficient; it does not indicate a passing control. Conditional Access applicability and effective enforcement require review.


## Conditional Access policies


```json
{
  "status": "AVAILABLE",
  "items": [
    {
      "modifiedDateTime": null,
      "sessionControls": null,
      "displayName": "Require MFA for all users (except automation)",
      "state": "enabled",
      "templateId": null,
      "grantControls": {
        "termsOfUse": [],
        "authenticationStrength": null,
        "builtInControls": [
          "mfa"
        ],
        "customAuthenticationFactors": [],
        "authenticationStrength@odata.context": "https://graph.microsoft.com/v1.0/$metadata#identity/conditionalAccess/policies('d6708b9a-9b3f-4c23-887f-a8fc0044e44c')/grantControls/authenticationStrength/$entity",
        "operator": "OR"
      },
      "deletedDateTime": null,
      "conditions": {
        "applications": {
          "excludeApplications": [],
          "includeAuthenticationContextClassReferences": [],
          "applicationFilter": null,
          "includeUserActions": [],
          "includeApplications": [
            "All"
          ]
        },
        "users": {
          "excludeRoles": [],
          "includeGuestsOrExternalUsers": null,
          "includeRoles": [],
          "includeGroups": [],
          "excludeGroups": [],
          "excludeUsers": [
            "81b6daea-b56b-4e0c-914b-12daad13c27d",
            "d8bf0dd2-fbbe-467b-aee3-212d23992291"
          ],
          "excludeGuestsOrExternalUsers": null,
          "includeUsers": [
            "All"
          ]
        },
        "clientAppTypes": [
          "all"
        ],
        "authenticationFlows": null,
        "clientApplications": null,
        "locations": null,
        "userRiskLevels": [],
        "devices": null,
        "platforms": null,
        "signInRiskLevels": [],
        "insiderRiskLevels": null,
        "servicePrincipalRiskLevels": []
      },
      "createdDateTime": "2026-07-22T10:43:18.4179592Z",
      "id": "d6708b9a-9b3f-4c23-887f-a8fc0044e44c"
    },
    {
      "modifiedDateTime": null,
      "conditions": {
        "applications": {
          "excludeApplications": [],
          "includeAuthenticationContextClassReferences": [],
          "applicationFilter": null,
          "includeUserActions": [],
          "includeApplications": [
            "All"
          ]
        },
        "users": {
          "excludeRoles": [],
          "includeGuestsOrExternalUsers": null,
          "includeRoles": [],
          "includeGroups": [],
          "excludeGroups": [
            "c7c03ec0-b150-4d59-ad3d-072321aaa392",
            "084d70f4-a8a3-4ed0-88c4-38c4f7793cef",
            "4864730b-b2f2-40e7-a2dc-64d2c38a2701"
          ],
          "excludeUsers": [],
          "excludeGuestsOrExternalUsers": null,
          "includeUsers": [
            "All"
          ]
        },
        "clientAppTypes": [
          "all"
        ],
        "authenticationFlows": null,
        "clientApplications": null,
        "locations": null,
        "userRiskLevels": [],
        "devices": {
          "deviceFilter": {
            "mode": "exclude",
            "rule": "(device.trustType -eq \"ServerAD\" -or device.trustType -eq \"AzureAD\")"
          }
        },
        "platforms": null,
        "signInRiskLevels": [],
        "insiderRiskLevels": null,
        "servicePrincipalRiskLevels": []
      },
      "displayName": "CA0010 : Scope(global) DeviceFilter(exclude_Trusted_Devices Action(EnforceSessionLimits)  ",
      "state": "enabledForReportingButNotEnforced",
      "templateId": null,
      "sessionControls": {
        "secureSignInSession": null,
        "applicationEnforcedRestrictions": null,
        "cloudAppSecurity": null,
        "signInFrequency": {
          "isEnabled": true,
          "frequencyInterval": "timeBased",
          "type": "hours",
          "value": 12,
          "authenticationType": "primaryAndSecondaryAuthentication"
        },
        "persistentBrowser": {
          "mode": "never",
          "isEnabled": true
        },
        "disableResilienceDefaults": null
      },
      "grantControls": null,
      "deletedDateTime": null,
      "createdDateTime": "2026-08-06T10:17:34.2636857Z",
      "id": "c6c52a28-8c45-47a9-b171-b03028f14978"
    },
    {
      "modifiedDateTime": null,
      "sessionControls": null,
      "displayName": "CA0000 : Scope(global) Action(block) legacyAuth ",
      "state": "enabledForReportingButNotEnforced",
      "templateId": null,
      "grantControls": {
        "termsOfUse": [],
        "authenticationStrength": null,
        "builtInControls": [
          "block"
        ],
        "customAuthenticationFactors": [],
        "authenticationStrength@odata.context": "https://graph.microsoft.com/v1.0/$metadata#identity/conditionalAccess/policies('b81dc1da-7b54-4874-8974-a9f8b80e22b3')/grantControls/authenticationStrength/$entity",
        "operator": "OR"
      },
      "deletedDateTime": null,
      "conditions": {
        "applications": {
          "excludeApplications": [],
          "includeAuthenticationContextClassReferences": [],
          "applicationFilter": null,
          "includeUserActions": [],
          "includeApplications": [
            "All"
          ]
        },
        "users": {
          "excludeRoles": [],
          "includeGuestsOrExternalUsers": null,
          "includeRoles": [],
          "includeGroups": [],
          "excludeGroups": [
            "c7c03ec0-b150-4d59-ad3d-072321aaa392",
            "084d70f4-a8a3-4ed0-88c4-38c4f7793cef",
            "af8d4004-88eb-431f-871d-dccec93b4c05"
          ],
          "excludeUsers": [],
          "excludeGuestsOrExternalUsers": null,
          "includeUsers": [
            "All"
          ]
        },
        "clientAppTypes": [
          "exchangeActiveSync",
          "other"
        ],
        "authenticationFlows": null,
        "clientApplications": null,
        "locations": null,
        "userRiskLevels": [],
        "devices": null,
        "platforms": null,
        "signInRiskLevels": [],
        "insiderRiskLevels": null,
        "servicePrincipalRiskLevels": []
      },
      "createdDateTime": "2026-08-06T10:17:34.3293074Z",
      "id": "b81dc1da-7b54-4874-8974-a9f8b80e22b3"
    },
    {
      "modifiedDateTime": null,
      "conditions": {
        "applications": {
          "excludeApplications": [],
          "includeAuthenticationContextClassReferences": [],
          "applicationFilter": null,
          "includeUserActions": [],
          "includeApplications": [
            "All"
          ]
        },
        "users": {
          "excludeRoles": [],
          "includeGuestsOrExternalUsers": null,
          "includeRoles": [],
          "includeGroups": [],
          "excludeGroups": [
            "c7c03ec0-b150-4d59-ad3d-072321aaa392",
            "084d70f4-a8a3-4ed0-88c4-38c4f7793cef",
            "855d9752-ed92-40bb-b451-bcd0d8aef132"
          ],
          "excludeUsers": [],
          "excludeGuestsOrExternalUsers": null,
          "includeUsers": [
            "All"
          ]
        },
        "clientAppTypes": [
          "all"
        ],
        "authenticationFlows": null,
        "clientApplications": null,
        "locations": null,
        "userRiskLevels": [],
        "devices": null,
        "platforms": null,
        "signInRiskLevels": [],
        "insiderRiskLevels": null,
        "servicePrincipalRiskLevels": []
      },
      "displayName": "CA0002 : Scope(global) Action(EnforceSessionLimits) baseline ",
      "state": "enabledForReportingButNotEnforced",
      "templateId": null,
      "sessionControls": {
        "secureSignInSession": null,
        "applicationEnforcedRestrictions": null,
        "cloudAppSecurity": null,
        "signInFrequency": {
          "isEnabled": true,
          "frequencyInterval": "timeBased",
          "type": "days",
          "value": 14,
          "authenticationType": "primaryAndSecondaryAuthentication"
        },
        "persistentBrowser": null,
        "disableResilienceDefaults": null
      },
      "grantControls": null,
      "deletedDateTime": null,
      "createdDateTime": "2026-08-06T10:17:34.5830786Z",
      "id": "60a7d4b5-83ae-4094-8946-c6ee695def48"
    },
    {
      "modifiedDateTime": null,
      "conditions": {
        "applications": {
          "excludeApplications": [],
          "includeAuthenticationContextClassReferences": [],
          "applicationFilter": null,
          "includeUserActions": [],
          "includeApplications": [
            "All"
          ]
        },
        "users": {
          "excludeRoles": [],
          "includeGuestsOrExternalUsers": null,
          "includeRoles": [
            "62e90394-69f5-4237-9190-012177145e10",
            "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9",
            "e8611ab8-c189-46e8-94e1-60213ab1f814",
            "194ae4cb-b126-40b2-bd5b-6091b380977d",
            "fe930be7-5e62-47db-91af-98c3a49a38b1"
          ],
          "includeGroups": [],
          "excludeGroups": [
            "c7c03ec0-b150-4d59-ad3d-072321aaa392",
            "084d70f4-a8a3-4ed0-88c4-38c4f7793cef",
            "5fcfa29c-ccd5-4aba-bcef-02e750610db7"
          ],
          "excludeUsers": [],
          "excludeGuestsOrExternalUsers": null,
          "includeUsers": []
        },
        "clientAppTypes": [
          "all"
        ],
        "authenticationFlows": null,
        "clientApplications": null,
        "locations": null,
        "userRiskLevels": [],
        "devices": null,
        "platforms": null,
        "signInRiskLevels": [],
        "insiderRiskLevels": null,
        "servicePrincipalRiskLevels": []
      },
      "displayName": "CA0201 : Scope(admin) Action(EnforceSessionLimits) admin session limits ",
      "state": "enabledForReportingButNotEnforced",
      "templateId": null,
      "sessionControls": {
        "secureSignInSession": null,
        "applicationEnforcedRestrictions": null,
        "cloudAppSecurity": null,
        "signInFrequency": {
          "isEnabled": true,
          "frequencyInterval": "timeBased",
          "type": "hours",
          "value": 8,
          "authenticationType": "primaryAndSecondaryAuthentication"
        },
        "persistentBrowser": {
          "mode": "never",
          "isEnabled": true
        },
        "disableResilienceDefaults": null
      },
      "grantControls": null,
      "deletedDateTime": null,
      "createdDateTime": "2026-08-06T10:17:34.6651693Z",
      "id": "3a6ce5f4-eb4f-4c7f-bd67-77ae2ac26c3a"
    },
    {
      "modifiedDateTime": null,
      "sessionControls": null,
      "displayName": "CA0200 : Scope(admin) require(MFAPolicy: Lab phishing-resistant MFA) admin strong auth ",
      "state": "enabledForReportingButNotEnforced",
      "templateId": null,
      "grantControls": {
        "termsOfUse": [],
        "authenticationStrength": {
          "modifiedDateTime": "2026-08-06T10:17:07.7025223Z",
          "combinationConfigurations@odata.context": "https://graph.microsoft.com/v1.0/$metadata#identity/conditionalAccess/policies('874a64b7-cfa6-416b-9836-1f308247499c')/grantControls/authenticationStrength/combinationConfigurations",
          "allowedCombinations": [
            "windowsHelloForBusiness",
            "fido2",
            "x509CertificateMultiFactor"
          ],
          "displayName": "Lab phishing-resistant MFA",
          "combinationConfigurations": [],
          "policyType": "custom",
          "description": "FIDO2 security keys, Windows Hello for Business or certificate-based auth",
          "requirementsSatisfied": "mfa",
          "createdDateTime": "2026-08-06T10:17:07.7025223Z",
          "id": "68005ace-725e-43a5-b706-d97f931f5876"
        },
        "builtInControls": [],
        "customAuthenticationFactors": [],
        "authenticationStrength@odata.context": "https://graph.microsoft.com/v1.0/$metadata#identity/conditionalAccess/policies('874a64b7-cfa6-416b-9836-1f308247499c')/grantControls/authenticationStrength/$entity",
        "operator": "OR"
      },
      "deletedDateTime": null,
      "conditions": {
        "applications": {
          "excludeApplications": [],
          "includeAuthenticationContextClassReferences": [],
          "applicationFilter": null,
          "includeUserActions": [],
          "includeApplications": [
            "All"
          ]
        },
        "users": {
          "excludeRoles": [],
          "includeGuestsOrExternalUsers": null,
          "includeRoles": [
            "62e90394-69f5-4237-9190-012177145e10",
            "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9",
            "e8611ab8-c189-46e8-94e1-60213ab1f814",
            "194ae4cb-b126-40b2-bd5b-6091b380977d",
            "fe930be7-5e62-47db-91af-98c3a49a38b1"
          ],
          "includeGroups": [],
          "excludeGroups": [
            "c7c03ec0-b150-4d59-ad3d-072321aaa392",
            "084d70f4-a8a3-4ed0-88c4-38c4f7793cef",
            "1d8f17c2-a9e4-4fff-b5cc-36fa84d7c604"
          ],
          "excludeUsers": [],
          "excludeGuestsOrExternalUsers": null,
          "includeUsers": []
        },
        "clientAppTypes": [
          "all"
        ],
        "authenticationFlows": null,
        "clientApplications": null,
        "locations": null,
        "userRiskLevels": [],
        "devices": null,
        "platforms": null,
        "signInRiskLevels": [],
        "insiderRiskLevels": null,
        "servicePrincipalRiskLevels": []
      },
      "createdDateTime": "2026-08-06T10:17:35.1351049Z",
      "id": "874a64b7-cfa6-416b-9836-1f308247499c"
    },
    {
      "modifiedDateTime": null,
      "sessionControls": null,
      "displayName": "CA0001 : Scope(global) require(mfa)  ",
      "state": "enabledForReportingButNotEnforced",
      "templateId": null,
      "grantControls": {
        "termsOfUse": [],
        "authenticationStrength": null,
        "builtInControls": [
          "mfa"
        ],
        "customAuthenticationFactors": [],
        "authenticationStrength@odata.context": "https://graph.microsoft.com/v1.0/$metadata#identity/conditionalAccess/policies('62a2e574-fc02-467b-90e1-3af85e1e0f41')/grantControls/authenticationStrength/$entity",
        "operator": "OR"
      },
      "deletedDateTime": null,
      "conditions": {
        "applications": {
          "excludeApplications": [],
          "includeAuthenticationContextClassReferences": [],
          "applicationFilter": null,
          "includeUserActions": [],
          "includeApplications": [
            "All"
          ]
        },
        "users": {
          "excludeRoles": [],
          "includeGuestsOrExternalUsers": null,
          "includeRoles": [],
          "includeGroups": [],
          "excludeGroups": [
            "c7c03ec0-b150-4d59-ad3d-072321aaa392",
            "084d70f4-a8a3-4ed0-88c4-38c4f7793cef",
            "96a2c65b-6144-4d49-a0c4-323a0d4a3852"
          ],
          "excludeUsers": [],
          "excludeGuestsOrExternalUsers": null,
          "includeUsers": [
            "All"
          ]
        },
        "clientAppTypes": [
          "all"
        ],
        "authenticationFlows": null,
        "clientApplications": null,
        "locations": null,
        "userRiskLevels": [],
        "devices": null,
        "platforms": null,
        "signInRiskLevels": [],
        "insiderRiskLevels": null,
        "servicePrincipalRiskLevels": []
      },
      "createdDateTime": "2026-08-06T10:17:57.7388182Z",
      "id": "62a2e574-fc02-467b-90e1-3af85e1e0f41"
    }
  ],
  "reason": null
}
```


## Claims mapping policies


```json
{
  "status": "AVAILABLE",
  "items": [],
  "reason": null
}
```


## Delegated consent grants


```json
{
  "status": "AVAILABLE",
  "items": [
    {
      "consentType": "AllPrincipals",
      "clientId": "c8362cb9-5c07-4056-9473-8f1a9a309a9e",
      "resourceId": "9aff273f-aa0c-4ad9-a1f4-2c86ff11a875",
      "id": "uSw2yAdcVkCUc48amjCanj8n_5oMqtlKofQshv8RqHU",
      "principalId": null,
      "scope": " openid offline_access EntitlementManagement.Read.All RoleManagement.Read.Directory Group.Read.All Directory.Read.All RoleEligibilitySchedule.Read.Directory PrivilegedAccess.Read.AzureADGroup profile RoleManagement.ReadWrite.Directory EntitlementManagement.ReadWrite.All User.Read PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup PrivilegedAccess.Read.AzureResources Group.ReadWrite.All AdministrativeUnit.Read.All PrivilegedEligibilitySchedule.Remove.AzureADGroup AccessReview.ReadWrite.All User.Read.All AdministrativeUnit.ReadWrite.All RoleManagementPolicy.ReadWrite.AzureADGroup RoleEligibilitySchedule.ReadWrite.Directory User.ReadWrite.All PrivilegedAccess.ReadWrite.AzureADGroup Organization.Read.All"
    },
    {
      "consentType": "Principal",
      "clientId": "c8362cb9-5c07-4056-9473-8f1a9a309a9e",
      "resourceId": "9aff273f-aa0c-4ad9-a1f4-2c86ff11a875",
      "id": "uSw2yAdcVkCUc48amjCanj8n_5oMqtlKofQshv8RqHXSDb_Yvvt7Rq7jIS0jmSKR",
      "principalId": "d8bf0dd2-fbbe-467b-aee3-212d23992291",
      "scope": " Directory.Read.All RoleManagement.Read.All RoleManagement.Read.Directory openid AdministrativeUnit.Read.All offline_access profile Application.ReadWrite.All EntitlementManagement.ReadWrite.All AccessReview.ReadWrite.All Group.ReadWrite.All RoleManagementPolicy.ReadWrite.AzureADGroup RoleManagement.ReadWrite.Directory AdministrativeUnit.ReadWrite.All PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup PrivilegedEligibilitySchedule.Read.AzureADGroup"
    },
    {
      "consentType": "AllPrincipals",
      "clientId": "6b4b0d53-1a63-40ef-aac3-29d64758707a",
      "resourceId": "9aff273f-aa0c-4ad9-a1f4-2c86ff11a875",
      "id": "Uw1La2Ma70CqwynWR1hwej8n_5oMqtlKofQshv8RqHU",
      "principalId": null,
      "scope": "EntitlementManagement.ReadWrite.All RoleManagement.ReadWrite.Directory Group.ReadWrite.All AdministrativeUnit.ReadWrite.All AccessReview.ReadWrite.All User.Read.All PrivilegedAccess.Read.AzureADGroup PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup RoleManagementPolicy.ReadWrite.AzureADGroup"
    },
    {
      "consentType": "AllPrincipals",
      "clientId": "8a14d633-d739-4cc6-8f26-8d67237f833a",
      "resourceId": "9aff273f-aa0c-4ad9-a1f4-2c86ff11a875",
      "id": "M9YUijnXxkyPJo1nI3-DOj8n_5oMqtlKofQshv8RqHU",
      "principalId": null,
      "scope": " openid profile email"
    }
  ],
  "reason": null
}
```


## Recent sign-ins


```json
{
  "status": "AVAILABLE",
  "items": [
    {
      "id": "a1eae67f-ed32-4c0f-98ae-3bfcf3be3c01",
      "userId": "d8bf0dd2-fbbe-467b-aee3-212d23992291",
      "conditionalAccessStatus": "notApplied",
      "createdDateTime": "2026-10-05T09:45:08Z",
      "appDisplayName": "Azure Portal",
      "userPrincipalName": "michel@betancoraleman.onmicrosoft.com",
      "status": {
        "additionalDetails": null,
        "errorCode": 0,
        "failureReason": "Other."
      },
      "appId": "c44b4083-3bb0-49c1-b47d-974e53cbdf3c"
    },
    {
      "id": "a1eae67f-ed32-4c0f-98ae-3bfcc0be3c01",
      "userId": "d8bf0dd2-fbbe-467b-aee3-212d23992291",
      "conditionalAccessStatus": "notApplied",
      "createdDateTime": "2026-10-05T09:45:08Z",
      "appDisplayName": "Azure Portal",
      "userPrincipalName": "michel@betancoraleman.onmicrosoft.com",
      "status": {
        "additionalDetails": null,
        "errorCode": 50207,
        "failureReason": "This web native bridge interrupt will be shown to the user during login when the application is requesting login through the native broker and needs eSTS to ensure the broker is properly configured."
      },
      "appId": "c44b4083-3bb0-49c1-b47d-974e53cbdf3c"
    },
    {
      "id": "337610d2-c1cc-44f4-86af-dc7e313a5900",
      "userId": "d8bf0dd2-fbbe-467b-aee3-212d23992291",
      "conditionalAccessStatus": "notApplied",
      "createdDateTime": "2026-10-02T10:46:04Z",
      "appDisplayName": "Azure Portal",
      "userPrincipalName": "michel@betancoraleman.onmicrosoft.com",
      "status": {
        "additionalDetails": null,
        "errorCode": 0,
        "failureReason": "Other."
      },
      "appId": "c44b4083-3bb0-49c1-b47d-974e53cbdf3c"
    },
    {
      "id": "df0371fe-357c-466b-b772-8ba7e2365a00",
      "userId": "d8bf0dd2-fbbe-467b-aee3-212d23992291",
      "conditionalAccessStatus": "notApplied",
      "createdDateTime": "2026-10-02T10:46:03Z",
      "appDisplayName": "Azure Portal",
      "userPrincipalName": "michel@betancoraleman.onmicrosoft.com",
      "status": {
        "additionalDetails": null,
        "errorCode": 50207,
        "failureReason": "This web native bridge interrupt will be shown to the user during login when the application is requesting login through the native broker and needs eSTS to ensure the broker is properly configured."
      },
      "appId": "c44b4083-3bb0-49c1-b47d-974e53cbdf3c"
    }
  ],
  "reason": null
}
```


## Recent audit events


```json
{
  "status": "AVAILABLE",
  "items": [
    {
      "id": "Directory_539451ac-3677-4954-abc2-d1bd2028fe3e_G6WH6_118492872",
      "activityDateTime": "2026-10-03T08:57:23.2622332Z",
      "activityDisplayName": "Hard delete service principal",
      "category": "ApplicationManagement",
      "result": "failure",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Microsoft Online Services Garbage Collector",
          "servicePrincipalId": null,
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "8d66f074-d6dd-496d-84ef-aa775a0f6353",
          "type": "ServicePrincipal",
          "displayName": "ts-portal-apptest-untagged"
        }
      ]
    },
    {
      "id": "Directory_2d6a5dd2-1c8b-4066-bee8-15e30f7d3f02_G6WH6_118491786",
      "activityDateTime": "2026-10-03T08:57:17.9495865Z",
      "activityDisplayName": "Hard delete service principal",
      "category": "ApplicationManagement",
      "result": "failure",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Microsoft Online Services Garbage Collector",
          "servicePrincipalId": null,
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "8d66f074-d6dd-496d-84ef-aa775a0f6353",
          "type": "ServicePrincipal",
          "displayName": "ts-portal-apptest-untagged"
        }
      ]
    },
    {
      "id": "Directory_30426a33-8193-4015-a3a8-bf62bfc87205_G6WH6_118490717",
      "activityDateTime": "2026-10-03T08:57:12.5209347Z",
      "activityDisplayName": "Hard delete service principal",
      "category": "ApplicationManagement",
      "result": "success",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Microsoft Online Services Garbage Collector",
          "servicePrincipalId": null,
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "8d66f074-d6dd-496d-84ef-aa775a0f6353",
          "type": "ServicePrincipal",
          "displayName": "ts-portal-apptest-untagged"
        }
      ]
    },
    {
      "id": "Directory_97358a0c-2653-4f8f-87b6-4ee07b2ea535_G6WH6_118489656",
      "activityDateTime": "2026-10-03T08:57:07.1301602Z",
      "activityDisplayName": "Hard delete service principal",
      "category": "ApplicationManagement",
      "result": "failure",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Microsoft Online Services Garbage Collector",
          "servicePrincipalId": null,
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "766ef2cb-e48f-4fe8-a56e-b7e5cf145bf7",
          "type": "ServicePrincipal",
          "displayName": "ts-portal-apptest-untagged"
        }
      ]
    },
    {
      "id": "Directory_0fd72112-58c7-40c0-847e-c6e7827469bd_G6WH6_118488601",
      "activityDateTime": "2026-10-03T08:57:01.8487739Z",
      "activityDisplayName": "Hard delete service principal",
      "category": "ApplicationManagement",
      "result": "failure",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Microsoft Online Services Garbage Collector",
          "servicePrincipalId": null,
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "766ef2cb-e48f-4fe8-a56e-b7e5cf145bf7",
          "type": "ServicePrincipal",
          "displayName": "ts-portal-apptest-untagged"
        }
      ]
    },
    {
      "id": "Directory_5059479d-17d9-42ff-87a4-eaf280e2a1af_G6WH6_118487463",
      "activityDateTime": "2026-10-03T08:56:56.6454901Z",
      "activityDisplayName": "Hard delete service principal",
      "category": "ApplicationManagement",
      "result": "success",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Microsoft Online Services Garbage Collector",
          "servicePrincipalId": null,
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "766ef2cb-e48f-4fe8-a56e-b7e5cf145bf7",
          "type": "ServicePrincipal",
          "displayName": "ts-portal-apptest-untagged"
        }
      ]
    },
    {
      "id": "Directory_7def37e0-366f-4a33-8b7c-38650e21f3a0_G6WH6_118428655",
      "activityDateTime": "2026-10-03T08:53:57.3149806Z",
      "activityDisplayName": "Hard delete service principal",
      "category": "ApplicationManagement",
      "result": "failure",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Microsoft Online Services Garbage Collector",
          "servicePrincipalId": null,
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "f8886c20-96aa-4a89-b616-9b2c920aeaa8",
          "type": "ServicePrincipal",
          "displayName": "ts-portal-apptest-tag"
        }
      ]
    },
    {
      "id": "Directory_30db1503-4033-46b8-913b-870c5c71fb35_G6WH6_118423750",
      "activityDateTime": "2026-10-03T08:53:52.0327008Z",
      "activityDisplayName": "Hard delete service principal",
      "category": "ApplicationManagement",
      "result": "failure",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Microsoft Online Services Garbage Collector",
          "servicePrincipalId": null,
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "f8886c20-96aa-4a89-b616-9b2c920aeaa8",
          "type": "ServicePrincipal",
          "displayName": "ts-portal-apptest-tag"
        }
      ]
    },
    {
      "id": "Directory_00b395ac-6532-4f97-987a-3ad4eddad910_G6WH6_118422608",
      "activityDateTime": "2026-10-03T08:53:46.7646903Z",
      "activityDisplayName": "Hard delete service principal",
      "category": "ApplicationManagement",
      "result": "success",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Microsoft Online Services Garbage Collector",
          "servicePrincipalId": null,
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "f8886c20-96aa-4a89-b616-9b2c920aeaa8",
          "type": "ServicePrincipal",
          "displayName": "ts-portal-apptest-tag"
        }
      ]
    },
    {
      "id": "Directory_94732e89-4042-4e25-b127-f5514eb4f731_G6WH6_117689555",
      "activityDateTime": "2026-10-03T08:16:38.9278446Z",
      "activityDisplayName": "Hard delete service principal",
      "category": "ApplicationManagement",
      "result": "failure",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Microsoft Online Services Garbage Collector",
          "servicePrincipalId": null,
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "3ecec6c3-a69e-4f9b-bd71-c2135f7b0535",
          "type": "ServicePrincipal",
          "displayName": "ts-portal-apptest-1"
        }
      ]
    },
    {
      "id": "Directory_598c0f56-2b9a-48f0-a648-115bafca18cb_G6WH6_117688463",
      "activityDateTime": "2026-10-03T08:16:33.7035052Z",
      "activityDisplayName": "Hard delete service principal",
      "category": "ApplicationManagement",
      "result": "failure",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Microsoft Online Services Garbage Collector",
          "servicePrincipalId": null,
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "3ecec6c3-a69e-4f9b-bd71-c2135f7b0535",
          "type": "ServicePrincipal",
          "displayName": "ts-portal-apptest-1"
        }
      ]
    },
    {
      "id": "Directory_61d578b8-d057-4f2c-baa7-b1828f1188b0_G6WH6_117687371",
      "activityDateTime": "2026-10-03T08:16:28.3439606Z",
      "activityDisplayName": "Hard delete service principal",
      "category": "ApplicationManagement",
      "result": "failure",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Microsoft Online Services Garbage Collector",
          "servicePrincipalId": null,
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "3ecec6c3-a69e-4f9b-bd71-c2135f7b0535",
          "type": "ServicePrincipal",
          "displayName": "ts-portal-apptest-1"
        }
      ]
    },
    {
      "id": "Directory_ffa26b06-ad35-4d98-8a33-78ca497dee3c_G6WH6_117682257",
      "activityDateTime": "2026-10-03T08:16:23.1407103Z",
      "activityDisplayName": "Hard delete service principal",
      "category": "ApplicationManagement",
      "result": "success",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Microsoft Online Services Garbage Collector",
          "servicePrincipalId": null,
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "3ecec6c3-a69e-4f9b-bd71-c2135f7b0535",
          "type": "ServicePrincipal",
          "displayName": "ts-portal-apptest-1"
        }
      ]
    },
    {
      "id": "Directory_aee804b4-ce6a-4745-9395-f27dbf75654e_W3V6H_521039467",
      "activityDateTime": "2026-09-30T13:25:35.213454Z",
      "activityDisplayName": "Update device",
      "category": "Device",
      "result": "success",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Device Registration Service",
          "servicePrincipalId": "fa446166-8b29-4dd5-98ac-c89eb295788a",
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "6e3190ef-cf57-4b8e-a5af-45e18d562ee1",
          "type": "Device",
          "displayName": "Pluto"
        }
      ]
    },
    {
      "id": "Directory_b931a9eb-3fc2-4496-8b84-eafcd7f007f8_ABHPB_89417027",
      "activityDateTime": "2026-09-29T10:17:23.1487976Z",
      "activityDisplayName": "Add service principal",
      "category": "ApplicationManagement",
      "result": "success",
      "initiatedBy": {
        "app": {
          "appId": null,
          "displayName": "Azure Resource Manager",
          "servicePrincipalId": "d00bfe64-0573-4002-a2a4-0d8ee478de34",
          "servicePrincipalName": null
        },
        "user": null
      },
      "targetResources": [
        {
          "id": "3585e51d-2f37-4143-aac7-7ebed4a3f7eb",
          "type": "ServicePrincipal",
          "displayName": "API Management AI Gateway Data Plane"
        }
      ]
    }
  ],
  "reason": null
}
```
