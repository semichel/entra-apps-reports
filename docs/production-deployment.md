# Production deployment — manual steps

Start with `config/production.json`. The workflow cannot authenticate until the tenant and client IDs are filled in and valid. The single **Entra application report** workflow uses the GitHub environment named **production**. These files prepare the deployment; they do not create tenant resources, grant permissions or run production queries.

## 1. Choose the repository and confirm the tenant

Use the private GitHub repository approved to hold your production application inventory, owners and sign-in evidence. Copy this project there if a company repository is required. The reader's federation will trust that exact repository. Check the production tenant's **Overview → Tenant ID** in the Entra admin center.

## 2. Create the production reader app manually

In the production tenant, open **App registrations → New registration**.

- Name: `Entra Apps Reports - Production Reader`.
- Supported account types: **Accounts in this organizational directory only**.
- Redirect URI: leave empty.

After registering, copy **Application (client) ID**, not Object ID. You need an administrator authorized to consent to Microsoft Graph application permissions for the next step. No Azure subscription, client secret or certificate is required for this runner.

## 3. Add the read permissions and grant consent

Open **API permissions → Add a permission → Microsoft Graph → Application permissions**.

| Permission | Used for |
|---|---|
| `Application.Read.All` | Required: application/service principal inventory, configuration and federated credentials |
| `Directory.Read.All` | Extended consent/assignment coverage and owner directory information |
| `Policy.Read.All` | Conditional Access and claims-mapping policy evidence |
| `AuditLog.Read.All` | Sign-in and directory audit evidence |

For the holistic report, have your authorized administrator review these four application read permissions, then select **Grant admin consent** in the production tenant. Optional evidence can also appear as `UNAVAILABLE` when permissions or licensing prevent a query. The application receives no Graph write permission. See the [Microsoft Graph permission definitions](https://learn.microsoft.com/en-us/graph/permissions-reference).

## 4. Fill in the deployment configuration

Edit `config/production.json`:

| Field | Enter |
|---|---|
| `tenantId` | Production Directory/Tenant ID |
| `tenantDisplayName` | Name to show in the report, e.g. `Saab Production` |
| `clientId` | Application/client ID from step 2 |
| `githubRepository` | Approved GitHub `owner/repository` |

Identifiers are safe to commit to the private deployment repository; put no tokens, passwords or secret values in the file.

Validate locally in PowerShell 7. This command contacts no service:

```powershell
Set-Location C:\jobb\entra-apps-reports
pwsh -NoProfile -File .\scripts\Validate-ProductionConfig.ps1
```

It prints the exact issuer, subject, audience and trusted branch for your configuration. Blank or invalid IDs fail with the field name to fill.

## 5. Set up the GitHub environment manually

In your selected repository, open **Settings → Environments → New environment** and name it **production**, exactly.

Set **Deployment branches and tags** to `main`. Configure required reviewers if supported by your organization's GitHub plan. Protect that branch with your normal change review rules, since changes to the workflow or deployment config control the reader identity. Production tenant/client IDs come from the config; no `PROD_*` secrets or variables are needed.

## 6. Add the federated credential manually

Back in the production reader app, open **Certificates & secrets → Federated credentials → Add credential**. Select **GitHub Actions deploying Azure resources** and enter:

- GitHub organization/owner and repository: match `githubRepository`.
- Entity type: **Environment**.
- Environment: **production**.
- Name: `github-production-report`.
- Issuer: `https://token.actions.githubusercontent.com`.
- Subject: `repo:YOUR-OWNER/YOUR-REPOSITORY:environment:production`.
- Audience: `api://AzureADTokenExchange`.

Use the exact subject printed by the validation command. This is the environment subject even when the trusted branch is `main`. Microsoft's [federated credential setup](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust) describes the trust relationship, and [GitHub's Azure OIDC guide](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-azure) describes the workflow exchange.

## 7. Run your first production report

Validate the file, then commit the config and deployment code to `main` in your approved repository. The workflow verifies the repository, branch, tenant and client before reading production.

Open **Actions → Entra application report → Run workflow**. Select `main`, then click **Run workflow**. Approve the environment deployment if a reviewer is configured.

The job runs on one GitHub-hosted Ubuntu runner. It signs in through federation, verifies the Graph context and reads the configured tenant. Rule failures are report observations; they do not fail the runner. Authentication or required inventory failures do fail it. Reports identify the production tenant and collection time.

Open the completed run's **Summary** for the application report. Download `entra-apps-report-<run number>`, extract it and open `report.html` for complete evidence. Large tenants keep the complete application list in the Summary; GitHub's 1 MiB summary limit can move some expanded details to the full artifact. Generated production reports are not committed to Git.


## If a step fails

- **Missing GUID:** fill the tenant and client IDs in the config.
- **Repository or branch mismatch:** compare the actual GitHub repository with the config and select `main`.
- **Federation mismatch:** compare issuer, audience and the `environment:production` subject exactly.
- **Client or tenant mismatch:** compare the app's client ID and Directory ID with the config; the report stops before inventory requests.
- **Graph 403:** check application permissions and production admin consent. A subscriptionless login does not require an Azure role assignment.
- **UNAVAILABLE evidence:** check the named API's permission/licensing requirements. It is not proof that no records exist.

The workflow runs only when manually started. To revoke the runner's access, your administrator can remove the federated credential or disable the reader app. No automatic schedule is enabled.

Reports always include all enterprise applications, all local app registrations and extended evidence. Artifact retention is managed in GitHub **Settings → Actions → General → Artifact and log retention**.
