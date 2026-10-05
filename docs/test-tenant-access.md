# MichelAB test tenant access

Tenant ID: `37dadda4-f2a4-47a8-8482-d40fe1a5aa48`  
Domain: `Betancoraleman.onmicrosoft.com`

Confirmed by the user and independently matched to `C:\jobb\entra-access-iac\config\environments\lab.json`. These are identifiers, not credentials.

## Interactive access

1. Open PowerShell 7 and install `Microsoft.Graph.Authentication`.
2. Run `./scripts/Export-EntraAppsReport.ps1 -UseDeviceCode`.
3. Open the URL printed by Microsoft Graph and enter the device code. Use an authorized **MichelAB** account.
4. If required, have an authorized lab administrator approve the delegated `Application.Read.All` permission. Directory Readers is a documented supported role for the owner/assignment reads used here. Existing directory consent and user privileges determine whether the query succeeds.
5. The script checks the Graph tenant and public-cloud environment before any Graph GET requests.

Without `-UseDeviceCode`, the script attempts interactive login first, then falls back to device code. Interactive sessions use a process-scoped context. Use `-UseExistingContext` only after connecting Graph in the same PowerShell process.

## Verified local Azure CLI access

On 5 October 2026, the existing Azure CLI session was verified against the lab tenant and successfully collected the full live report. Reuse it with:

```powershell
./scripts/Export-EntraAppsReport.ps1 -UseAzureCli -IncludeExtendedEvidence -OutputDirectory ./reports/lab-latest
```

This reads through the existing authorized local identity. It does not export that identity's credential or configure GitHub authentication. Log/policy access was available in this session, despite the separately recorded premium-license limitation; availability must be checked on each run.

## Existing local reader

The existing local file `C:\jobb\entra-access-iac-dev-support\export-reader-spn.local.json` identifies reader client ID `59c2e30b-643d-4aa1-949e-f5eb074de800` and a certificate in `Cert:\CurrentUser\My`. Its certificate expired **1 October 2026**. Do not copy the private key or local settings into this repository. A local certificate is not automatically available on a GitHub-hosted runner.

After a lab administrator supplies a valid reader certificate, a local noninteractive connection can be made as follows. This is an optional example; the reporting project does not renew credentials or change consent.

```powershell
$reader = Get-Content 'C:\jobb\entra-access-iac-dev-support\export-reader-spn.local.json' -Raw | ConvertFrom-Json -AsHashtable
if ($reader['tenantId'] -ne '37dadda4-f2a4-47a8-8482-d40fe1a5aa48') { throw 'Lab tenant mismatch' }
Connect-MgGraph -TenantId $reader['tenantId'] -ClientId $reader['clientId'] -CertificateThumbprint $reader['certificateThumbprint'] -ContextScope Process -NoWelcome
./scripts/Export-EntraAppsReport.ps1 -UseExistingContext
```

Microsoft Graph `Application.Read.All` suffices for the inventory endpoints. Owner display names can be null when the caller lacks permission to read their object type; owner IDs and object types still provide useful evidence. No broader directory read permission is requested just to populate names.

## Existing SSO test application

`C:\jobb\scim-oidc-lab` documents **SCIM-OIDC Lab - Helpdesk Lite**:

- Client ID: `f298ff2a-11df-43a4-99ef-4a0047abcddd`.
- Enterprise application object ID: `8a14d633-d739-4cc6-8f26-8d67237f833a`.
- Local callback: `http://localhost:8390/auth/callback`.
- Roles: Helpdesk.Admin, Helpdesk.Agent and Helpdesk.ReadOnly.

This application is an appropriate first live reporting target. The report does not start it, assign users or simulate actual sign-in.

## Lab limitation

The inherited workspace instructions state that Entra ID Premium P2 is suspended. Keep this project focused on ordinary application inventory. PIM, Conditional Access writes, entitlement management and premium log availability must not be assumed to work.

References: [List application owners](https://learn.microsoft.com/en-us/graph/api/serviceprincipal-list-owners?view=graph-rest-1.0), [List assignments](https://learn.microsoft.com/en-us/graph/api/serviceprincipal-list-approleassignedto?view=graph-rest-1.0).
