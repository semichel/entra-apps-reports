# Entra Apps Reports

Read-only production reports for Microsoft Entra applications.

## Set up

1. Copy the project into your approved private/internal company GitHub repository, replacing the old report workflow.
2. Follow [the manual deployment guide](docs/production-deployment.md) to reuse or configure the reader app, Graph read permissions and branch-based OIDC federation.
3. Set repository secrets `AZURE_TENANT_ID` and `AZURE_CLIENT_ID`, just like the existing app-registration report.
4. Set the tenant display name in [config/production.json](config/production.json), commit to `main`, and select **Actions → Entra application report → Run workflow**.

One job runs on a GitHub-hosted Ubuntu runner. It uses `azure/login@v2`, Az and a Graph access token, following the existing work setup. No GitHub environment or client-secret value is required. Blank or invalid reader IDs prevent authentication; the collector verifies the signed-in tenant and client before requesting inventory.

To try the new report before replacing production code, use the `test-report` branch. The workflow allows `main` and `test-report`; Entra needs a separate matching test-branch federated credential. The guide explains how to reuse the existing company workflow filename so `main` can keep its current report during testing.

## Report

For direct execution on an on-premises Windows server with your own Global Reader account, follow [the manual PowerShell guide](docs/onprem-manual-run.md). Run `scripts/Invoke-EntraAppsReport.ps1 -TenantId YOUR-TENANT-ID` to sign in interactively and write the HTML/JSON/CSV report locally.

The Actions Summary contains totals, an application list and expandable details. Each run uploads a self-contained HTML report, JSON evidence and CSV files for findings, owners, assignments and credential dates.

The HTML report includes application owners, certificate/secret expiry, assignments, granted and requested API permissions, federation, sign-ins and policy observations. Large inventories retain all evidence in the artifact when GitHub's summary limit restricts expanded details.

The collector uses Graph GET requests. Credential values and private keys are not exported. Optional evidence failures appear as unavailable. Findings describe configuration observations; authentication and application-side validation remain manual.

## Contents

- `config/`: production settings.
- `scripts/`: collector, config validation and report generation.
- `scripts/templates/`: bundled report interface and summary template.
- `docs/`: manual deployment guide.
- `.github/workflows/report.yml`: one manually triggered production workflow.

PowerShell 7 and Python 3 are required. The workflow installs Microsoft Graph Authentication and authenticates using GitHub federation. Artifact retention follows the GitHub repository setting. Generated output in `reports/` is ignored by Git.

Required third-party notices are in [THIRD-PARTY-NOTICES.txt](THIRD-PARTY-NOTICES.txt).
