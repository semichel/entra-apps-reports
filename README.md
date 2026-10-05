# Entra Apps Reports

Read-only production reports for Microsoft Entra applications.

## Set up

1. Fill [config/production.json](config/production.json) with your tenant ID, tenant name, reader app client ID and private GitHub repository.
2. Follow [the manual deployment guide](docs/production-deployment.md) to configure Graph permissions, the GitHub production environment and workload identity federation.
3. Validate the configuration with PowerShell 7:

```powershell
./scripts/Validate-ProductionConfig.ps1
```

4. Set `enabled` to `true`, commit the configuration to your trusted branch, and select **Actions → Entra application report → Run workflow**.

Production is disabled in the supplied configuration. Authentication is configured by you; no tenant or client identifiers are prefilled.

## Report

The Actions Summary contains totals, an application list and expandable details. Each run uploads a self-contained HTML report, JSON evidence and CSV files for findings, owners, assignments and credential dates.

The HTML report includes application owners, certificate/secret expiry, assignments, granted and requested API permissions, federation, sign-ins and policy observations. Large inventories retain all evidence in the artifact when GitHub's summary limit restricts expanded details.

The collector uses Graph GET requests. Credential values and private keys are not exported. Optional evidence failures appear as unavailable. Findings describe configuration observations; authentication and application-side validation remain manual.

## Contents

- `config/`: production settings.
- `scripts/`: collector, config validation and report generation.
- `scripts/templates/`: bundled report interface and summary template.
- `docs/`: manual deployment guide.
- `.github/workflows/report.yml`: one manually triggered production workflow.

PowerShell 7 and Python 3 are required. The workflow installs Microsoft Graph Authentication and authenticates using GitHub federation. Report retention defaults to seven days and is configurable. Generated output in `reports/` is ignored by Git.

Required third-party notices are in [THIRD-PARTY-NOTICES.txt](THIRD-PARTY-NOTICES.txt).
