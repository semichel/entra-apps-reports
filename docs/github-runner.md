# GitHub runner setup

Use a private repository because the article and live application inventory contain internal administration information. Generated reports are workflow artifacts; they are not committed into the source branch.

Current repository: [semichel/entra-apps-reports](https://github.com/semichel/entra-apps-reports), private. The `lab` environment, its tenant-ID variable and the `main` deployment restriction are already configured. Demo execution and artifact upload have passed. Complete the application identity, consent, federated credential and client-ID variable steps below to enable live reporting.

## Prepare lab authentication

An authorized **MichelAB** administrator performs the following one-time setup:

1. Open Entra admin center and verify tenant ID `37dadda4-f2a4-47a8-8482-d40fe1a5aa48`.
2. Register a dedicated single-tenant application named `Entra Apps Reports - Lab Reader`. Copy its application/client ID.
3. Add Microsoft Graph **Application.Read.All**, choosing **Application permissions** rather than Delegated. Grant admin consent in the lab. This requires an administrator permitted to grant Microsoft Graph application permissions.
4. Under Certificates & secrets → Federated credentials, add a GitHub Actions credential for the repository hosting this project and environment `lab`:
   - Issuer: `https://token.actions.githubusercontent.com`.
   - Subject: `repo:semichel/entra-apps-reports:environment:lab` when hosted at that repository. Substitute the actual owner/repository if different.
   - Audience: `api://AzureADTokenExchange`.
5. In GitHub Settings → Environments, create `lab`. Restrict deployment branches to the trusted default branch. Configure reviewer protection if available for your GitHub plan.
6. Add these **environment variables** to `lab`:

| Variable | Value |
|---|---|
| `LAB_TENANT_ID` | `37dadda4-f2a4-47a8-8482-d40fe1a5aa48` |
| `LAB_CLIENT_ID` | Dedicated report reader application/client ID |

No client secret, private key or Azure subscription ID is needed. The workflow explicitly permits subscriptionless login, obtains a token for Microsoft Graph, masks the token, and connects Graph in the runner process. Tenant checks also occur inside the reporting script.

The existing local certificate reader has no verified GitHub federation setup, so its client ID must not simply be assumed to work on the runner.

## Run

1. Open Actions → **Entra application report** → Run workflow.
2. Select `demo` for an offline synthetic report, or `lab` after completing the authentication setup.
3. Wait for the job to complete.
4. Download `entra-apps-report-<mode>-<run number>` under Artifacts.
5. Extract it and open `report.html`. Use `report.json` for application evidence and `findings.csv` for filtering.

A failing live API request stops the job without uploading a successful-looking incomplete report. Rule findings marked FAIL are report data and do not prevent artifact publication. Reports persist for 14 days and are visible to users with access to the repository/artifacts.

## Troubleshooting

- **Missing variables:** set variables on the GitHub environment named `lab`.
- **No matching federated identity:** compare issuer, subject, environment and audience exactly. This workflow uses an environment subject, not a branch subject.
- **Graph 403:** confirm application permission and admin consent in MichelAB.
- **Tenant/context mismatch:** inspect the configured tenant/client identifiers; the script intentionally accepts only the confirmed lab tenant.
- **Graph throttling:** bounded retries handle 429/503/504. Large tenants selecting credential metadata can encounter Graph rate limits; rerun later if retries exhaust.
- **Missing app registration:** third-party registrations live in their home tenants; their credential/redirect details cannot be completely inspected through the local service principal.

References: [Microsoft workload identity federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation), [GitHub OIDC with Azure](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-azure), [Azure Login action, including subscriptionless login](https://github.com/Azure/login).
