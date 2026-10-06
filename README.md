# Entra Apps Reports

Read-only production reports for Microsoft Entra applications.

## Set up

1. Copy the project into your approved private/internal company GitHub repository, replacing the old report workflow.
2. Follow [the manual deployment guide](docs/production-deployment.md) to reuse or configure the reader app, Graph read permissions and branch-based OIDC federation.
3. Set repository secrets `AZURE_TENANT_ID` and `AZURE_CLIENT_ID`, just like the existing app-registration report.
4. Set the tenant display name in [config/production.json](config/production.json), commit to `main`, and select **Actions → Entra application report → Run workflow**.

One job runs on a GitHub-hosted Ubuntu runner. It uses `azure/login@v2`, Az and a Graph access token, following the existing work setup. No GitHub environment or client-secret value is required. Blank or invalid reader IDs prevent authentication; the collector verifies the signed-in tenant and client before requesting inventory.

The workflow runs only from `main` and only when manually started. Replace the existing report workflow so the company repository contains one report workflow. Keep the existing repository secrets and matching main-branch federation, and verify the full report's Graph read permissions before the first run.

## Report

For a local test with your own Global Reader account, run `./Start-TestRun.ps1` in PowerShell 7 from the project root. It asks for the tenant ID and starts interactive sign-in. The HTML/JSON/CSV report is written locally. Prerequisites and device-code sign-in are described in [the manual PowerShell guide](docs/onprem-manual-run.md).

If collection completed but HTML rendering failed, run `./Render-Report.ps1` to regenerate HTML and CSV from the saved JSON without another Graph collection.

The Actions Summary contains totals, an application list and expandable details. Each run uploads a self-contained HTML report, JSON evidence and CSV files for findings, owners, assignments and credential dates.

The HTML report includes application owners, certificate/secret expiry, assignments, granted and requested API permissions, federation and policy observations. Large inventories retain all evidence in the artifact when GitHub's summary limit restricts expanded details.

Kontroller, godkännandekrav, ändringsbara regler och undantag beskrivs i [regelöversikten](docs/report-rules.md). Ändra config/production.json för era krav. Undantagna kontroller visas som Skipped med motivering; apparna finns kvar i inventeringen.

The inventory includes your organization's and third-party enterprise apps and local registrations. First-party Microsoft enterprise apps are excluded using their owning tenant IDs, not their names. Microsoft API/resource metadata is still read in the background to resolve granted permissions such as Microsoft Graph roles. Apps with unknown owning tenants are retained rather than guessed away.

The collector uses Graph GET requests. Credential values and private keys are not exported. Optional evidence failures appear as unavailable. Findings describe automatically evaluated configuration observations.

`Passed` means the automatic configuration checks passed. Only automatic checks are included. When no credential metadata exists, the credential check is not applicable. Failed checks produce `Failed`, while warnings or unknown results produce `Investigate`. A configuration pass does not certify working sign-in or overall compliance.

Sign-in logs and directory audit logs are not collected. `AuditLog.Read.All` is not required. The report is a configuration snapshot with observations; it does not send alerts or monitor changes between runs.

## Contents

- `config/`: production settings.
- `scripts/`: collector, config validation and report generation.
- `scripts/templates/`: bundled report interface and summary template.
- `docs/`: manual deployment guide.
- `.github/workflows/report.yml`: one manually triggered production workflow.

PowerShell 7 is required. HTML and Actions summaries are generated directly in PowerShell; Python is not required. The workflow installs Microsoft Graph Authentication and authenticates using GitHub federation. Artifact retention follows the GitHub repository setting. Generated output in `reports/` is ignored by Git.

Attribution for the bundled report interface is embedded in the HTML template and generated report.
