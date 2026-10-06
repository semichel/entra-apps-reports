# Run manually on-premises with your own account

Run the report in PowerShell 7 and sign in with your own account as Global Reader. This uses delegated Microsoft Graph authentication. No certificate, thumbprint, GitHub runner or GitHub federation is required. You do not need to create a separate reader app when using the default Microsoft Graph PowerShell sign-in application, if your organization permits it.

## Prerequisites

- PowerShell 7 and Python 3, with `python` available in the session.
- Access from the machine to Microsoft Entra sign-in and Microsoft Graph over HTTPS.
- Your Global Reader role must be active in the target tenant. If eligible through PIM, activate it before signing in.
- The sign-in application needs approved delegated read scopes: `Application.Read.All`, `Directory.Read.All`, `Policy.Read.All` and `AuditLog.Read.All`. Global Reader does not itself grant application consent. If sign-in asks for administrator approval, an authorized administrator must approve these scopes under your organization's policy. Existing application permissions on the GitHub reader app do not supply this delegated consent.

See [Microsoft's Graph PowerShell authentication guide](https://learn.microsoft.com/en-us/powershell/microsoftgraph/authentication-commands). Log/policy evidence can also depend on licensing, retention and the specific API's delegated access rules; unavailable evidence is identified in the report.

## One-time setup

Copy the project to the machine, for example `C:\jobb\entra-apps-reports`, and install the authentication module in PowerShell 7 (or use approved offline module distribution):

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Repository PSGallery -Force
```

Set `tenantDisplayName` in `config/production.json` to the label you want in the report. This field is a display label; the `-TenantId` parameter selects the actual tenant.

## Start a report

```powershell
Set-Location C:\jobb\entra-apps-reports
.\Start-TestRun.ps1
```

Enter the intended tenant ID when prompted, then sign in with your own account and complete MFA as required. You can also supply `-TenantId 'YOUR-PRODUCTION-TENANT-ID'` directly. The script requests only read scopes, checks delegated authentication, and calls the existing collector with the sign-in application's client ID. The collector verifies the tenant, cloud and client before reading inventory. The session is disconnected when collection finishes or fails.

For a remote/headless machine, or if the normal sign-in broker fails, use device-code authentication if permitted by your organization's Conditional Access policies:

```powershell
.\Start-TestRun.ps1 -TenantId 'YOUR-PRODUCTION-TENANT-ID' -UseDeviceCode
```

Follow the URL and code displayed by Microsoft Graph PowerShell using a browser on your workstation. No password is entered into the script or config file.

## Open the result

The full report is `C:\jobb\entra-apps-reports\reports\latest\report.html`. JSON evidence and CSV exports are in the same folder. On a machine with a browser:

```powershell
Invoke-Item .\reports\latest\report.html
```

On a server without a desktop, copy the output folder to your workstation and open the self-contained HTML file there. A local run writes local report files; it does not create a GitHub Actions artifact or Summary.

Each successful run replaces the files in `reports\latest`. To retain separate runs:

```powershell
.\Start-TestRun.ps1 -TenantId 'YOUR-PRODUCTION-TENANT-ID' -OutputDirectory C:\Reports\Entra\run-001
```

## Troubleshooting

- **Administrator approval required:** delegated Graph consent is missing; Global Reader cannot grant that consent.
- **Interactive/broker sign-in fails:** retry with `-UseDeviceCode` if your organization permits that method.
- **Tenant mismatch:** use the intended production Tenant ID and select the account in that tenant.
- **Graph 403/unavailable evidence:** check delegated consent, active role and relevant licensing/API requirements.
- **Python/module unavailable:** install or distribute prerequisites using your company's approved method.

No production authentication or consent is performed automatically while preparing these source files. The GitHub workflow continues to use its own reader app and repository secrets.
