# Production deployment — manual steps

This follows your existing app-registration report setup: start one GitHub Actions job manually, sign in with OIDC, read Microsoft Graph, then publish an Actions Summary and a downloadable report artifact. The workflow is `.github/workflows/report.yml`.

To run directly on an on-premises Windows server without GitHub, use [the manual PowerShell guide](onprem-manual-run.md).

## 1. Put the report in your company repository

Use your existing `saabgroup/entra-app_registration_report` repository on `saabgroup.ghe.com`, or another approved private/internal company repository. Copy `scripts/`, `config/`, `docs/`, `README.md`, `.gitignore` and `THIRD-PARTY-NOTICES.txt`, plus `.github/workflows/report.yml`.

When replacing the old report, remove its `.github/workflows/main.yml` so there is only one report workflow. Do not copy `.git/`, the reference ZIP, or previously generated reports. Commit the source files to `main` using your normal company process. Do not run production reports in the personal development repository.

## Test on test-report before replacing main

The supplied workflow allows only `main` and `test-report`. The run name shows the selected branch. Both branches use the same repository secrets and read the same tenant; a test branch does not select a different tenant.

Do these steps manually in company GitHub and Entra:

1. Create `test-report` from the company repository's `main` branch.
2. Copy the new report's `scripts/`, `config/` and supporting source files into `test-report`. For this existing repository, put the contents of our `.github/workflows/report.yml` into its already registered `.github/workflows/main.yml` **on test-report only**. Keep the existing workflow filename and do not also add `report.yml`. This lets you use the existing manual workflow entry without changing the report on `main`.
3. Check the reader app's read permissions and existing `AZURE_TENANT_ID` / `AZURE_CLIENT_ID` secrets as described below. Set the report's tenant display name.
4. In Entra, open the reader app → **Certificates & secrets → Federated credentials → Add credential → Other issuer**. Name it `github-test-report`. Copy the issuer and audience from the working main-branch credential. For a branch-based subject, preserve the complete repository/owner portion, including any immutable IDs, and replace only the ending `refs/heads/main` with `refs/heads/test-report`. Keep the original credential. If your existing subject is customized, have the administrator confirm the exact test-branch subject instead.
5. Commit the files to `test-report`. Open the existing workflow under **Actions** (its menu name can still be **Run App Registration Script**, from the version on main). Select **Run workflow → test-report**. The run uses the workflow and collector from that branch and generates its own Summary and artifact.
6. After reviewing the report, merge through your normal company process. Keep one workflow filename; when using `main.yml`, continue using that file instead of adding `report.yml`. You can then remove the test-branch federated credential when testing is finished.

If using a new workflow filename instead of the existing one, GitHub requires that workflow with `workflow_dispatch` to exist on the default branch before it can be manually dispatched. See [GitHub's manual workflow instructions](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow).

## 2. Reuse or create the Entra reader app

In the production tenant, check the Tenant ID in **Entra ID → Overview**. Open the reader app used by your current report and note its **Application (client) ID**. Reuse it if your administrator approves the following read permissions.

If you need a new reader, select **App registrations → New registration**, name it `Entra Apps Reports`, select **Accounts in this organizational directory only**, and leave the redirect URI empty.

Under **API permissions → Add a permission → Microsoft Graph → Application permissions**, verify these permissions and have an authorized administrator grant consent:

| Permission | Report evidence |
|---|---|
| `Application.Read.All` | App registrations, enterprise apps, configuration and federated credentials |
| `Directory.Read.All` | Owners, assignments and consent evidence |
| `Policy.Read.All` | Conditional Access and claims-mapping policies |
| `AuditLog.Read.All` | Sign-in and directory audit evidence |

The collector uses Graph GET requests. It includes all applications and extended evidence. Some evidence can be unavailable because of permissions, licensing or log retention. No Azure subscription or Graph write permission is needed. See the [Microsoft Graph permission reference](https://learn.microsoft.com/en-us/graph/permissions-reference).

## 3. Set the same two GitHub repository secrets

Open **Settings → Secrets and variables → Actions → Repository secrets** in the company repository:

| Secret | Value |
|---|---|
| `AZURE_TENANT_ID` | Production Directory/Tenant ID |
| `AZURE_CLIENT_ID` | Reader app's Application/client ID, not its Object ID |

Keep the existing values if you reuse the same tenant and app. These identifiers select the reader; OIDC federation authenticates it. No client-secret value, certificate or `production` GitHub environment is required.

## 4. Check the federated credential

Open the reader app's **Certificates & secrets → Federated credentials**. If the existing workflow already authenticates from this same repository and `main` branch, reuse its matching credential. Our workflow uses the same two secrets and no GitHub environment.

If you use a new app or repository, add a credential for the actual issuer and subject used by that repository. On `saabgroup.ghe.com`, the default issuer is `https://token.actions.saabgroup.ghe.com`; enterprise customization can change it. The audience for this workflow is `api://AzureADTokenExchange`.

The usual name-based branch subject for the existing repository is:

```text
repo:saabgroup/entra-app_registration_report:ref:refs/heads/main
```

Use the **actual** subject from your existing verified credential or GitHub OIDC settings. Newer repositories can include immutable owner/repository IDs, and customized subjects can differ. For a custom issuer or subject, select **Other issuer** in Entra and enter the verified values. Do not use an `environment:production` subject for this workflow. Protect `main` using your normal company change-review process.

See [GitHub's OIDC reference](https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/security/oidc) and [Microsoft's federated credential instructions](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust).

## 5. Set the report label

Edit `config/production.json`:

```json
{
  "tenantDisplayName": "Saab Production"
}
```

This is only the name displayed in the report. The tenant and client IDs come from the two GitHub secrets. There are no application filters or evidence switches; every run collects the complete report. Artifact retention follows the repository's **Settings → Actions → General → Artifact and log retention** setting.

## 6. Run the report

Open **Actions → Entra application report → Run workflow**, select `main`, and click **Run workflow**.

The single job uses `runs-on: ubuntu-latest`, just like your existing workflow. GitHub starts one temporary hosted Ubuntu runner for each run; you do not need to install another runner. Your organization must allow that runner and the workflow actions.

The job validates the IDs and repository visibility, installs Az and Microsoft Graph Authentication, uses `azure/login@v2` with OIDC, gets a Graph token through `Get-AzAccessToken`, and calls `scripts/Export-EntraAppsReport.ps1`. The collector verifies the signed-in tenant and client before reading inventory. It then uploads the report and publishes the Summary. Nothing writes to Entra.

## 7. Open the report

Open the completed run's **Summary** for totals, the application list and expandable application details. Under **Artifacts**, download `entra-apps-report-<run number>`, extract it, and open `report.html` for the complete interactive report. The same artifact contains JSON evidence and CSV exports, including owners, assignments, permissions and certificate/secret dates.

GitHub renders the Summary directly on the run page; the HTML is opened after downloading. Large summaries can move some expanded details to the artifact because of GitHub's 1 MiB Summary limit. Complete evidence stays in the artifact. Generated reports are not committed to the repository.

## If a step fails

- **Missing/invalid ID:** check the two repository secrets.
- **Branch validation:** select `main` or `test-report`, and ensure Entra has the matching federated credential.
- **Repository visibility:** use a private or internal company repository.
- **OIDC/login failure:** compare the actual issuer, subject and audience with the Entra credential, and check Actions policies.
- **Tenant/client mismatch:** check that both secrets select the intended production reader.
- **Graph 403 or unavailable evidence:** check consent, the permission named by the failing API and relevant licensing.
- **No hosted runner available:** ask your GitHub administrator for the approved runner label and update the existing job's `runs-on`; do not add a second workflow.

This guide targets the `saabgroup.ghe.com` setup shown by your existing project. A separate on-premises GitHub Enterprise Server requires its own runner and server-supported action versions; `actions/upload-artifact@v4` is not supported there. See [the upload-artifact compatibility notice](https://github.com/actions/upload-artifact#v4---whats-new). Another Git product requires that product's pipeline format.

The workflow runs only when manually started. These source files do not create Entra resources, grant consent or configure company GitHub settings automatically.
