"""Write a Maester-style, GitHub-native application report for an Actions run."""

import argparse
import json
from collections import Counter
from pathlib import Path
from datetime import datetime, timezone

from publish_report import cell, collection, table
from render_report import expiry, owner_rows, permission_rows, requested_rows, utc_date


def section(title, content):
    return f'<details><summary><strong>{cell(title)}</strong></summary>\n\n{content}\n\n</details>\n'


def records(headers, rows, empty='No records in the collected evidence.'):
    rows = list(rows)
    return table(headers, rows) if rows else empty


def render(report, artifact_url):
    apps = sorted(report["applications"], key=lambda item: (item.get("displayName") or "").casefold())
    now = datetime.now(timezone.utc)
    by_id = {app.get("servicePrincipalId"): app for app in apps}
    by_app_id = {app.get("appId"): app for app in apps}
    mode = report["mode"]
    label = {"LIVE": "Fresh tenant collection", "SNAPSHOT": "Previously collected real tenant snapshot", "DEMO": "Synthetic demo data"}.get(mode, mode)
    parts = ["# Entra application report\n", f"**{label}**\n",
             f"Tenant: `{cell(report['tenantId'])}`  \nData collected UTC: {cell(utc_date(report['generatedAtUtc']))}\n",
             f"**{len(apps)} enterprise application service principals · {len(collection(report.get('registrations')))} local app registrations**\n",
             f"## [Download the interactive HTML report]({artifact_url})\n\nThe artifact contains `report.html`, JSON and CSV evidence. Extract it and open `report.html` for the searchable full report.\n",
             "Read application findings directly below: expand an application to see owners, assignments, credential expiry and policy observations.\n",
             "Catalog entries include platform/resource applications; confirm SSO policy applicability before remediation. Manual sign-in, token/assertion validation, TLS, approvals and business documentation remain required.\n"]
    if mode == "SNAPSHOT":
        parts.append("**This run renders existing tenant data; it does not query Entra again. Choose `lab` for a fresh collection after configuring the runner identity.**\n")
    parts.append(f"Expiry calculations as of UTC {utc_date(now.isoformat())}. Expand an application, then expand the information you need.\n")
    counts = Counter((finding["rule"], finding["status"]) for app in apps for finding in app["findings"])
    parts.append(section('Policy observation totals', records(["Check", "Status", "Count"],
                   [(rule, status, count) for (rule, status), count in sorted(counts.items())])))
    tenant = report.get("tenantEvidence") or {}
    if tenant:
        parts.append(section('Tenant evidence coverage', records(["Evidence", "Availability", "Records"],
            [(key, value.get("status"), len(collection(value.get("items")))) for key, value in tenant.items() if isinstance(value, dict)])))
    parts.append("## Application findings\n")
    for app in apps:
        block = [section('Application profile', records(['Property', 'Value'], [
                 ('Client ID', app.get('appId')), ('Enterprise application ID', app.get('servicePrincipalId')),
                 ('SSO hint', app.get('protocol')), ('Enabled', app.get('accountEnabled')),
                 ('Assignment required', app.get('assignmentRequired'))])),
                 section('Policy findings and manual validation', records(["Check", "Status", "Evidence / next action"],
                      [(item["rule"], item["status"], item["evidence"]) for item in app["findings"]]))]
        owners = owner_rows(app)
        block.append(section('Owners', records(["Source", "Name", "Type", "ID"], owners, 'No owners recorded in the available evidence.')))
        assignments = collection(app.get("assignments"))
        block.append(section('Assigned users and groups', records(["Name", "Type", "Role ID"], [(item.get("principalDisplayName"), item.get("principalType"), item.get("appRoleId")) for item in assignments])))
        credentials = collection(app.get("credentials"))
        block.append(section('Certificates and client secrets', records(["Name", "Kind", "Valid from UTC", "Expires UTC", "Days left", "Lifetime days", "Expiry state"],
                        [(item.get("displayName") or item.get('keyId'), item.get("kind"), utc_date(item.get('startDateTime')), utc_date(item.get("endDateTime")), expiry(item, now)[1], item.get("lifetimeDays"), expiry(item, now)[0]) for item in credentials], 'No local credential metadata recorded; credentials may live in an external home tenant.')))
        redirects = collection(app.get("redirectUris"))
        block.append(section('Redirect / callback URLs', records(["URL"], [(value,) for value in redirects])))
        permission_content = records(['Resource API', 'Type', 'Granted permission', 'Consent / grant', 'Role or grant ID'], permission_rows(app, by_id))
        for key, label in [('applicationPermissionGrants', 'Application grants'), ('delegatedConsentGrants', 'Delegated consent')]:
            if (app.get(key) or {}).get('status') != 'AVAILABLE':
                permission_content += f'\n\n{label}: evidence unavailable.'
        block.append(section('Granted API permissions', permission_content))
        block.append(section('Requested API permissions and consent', records(['Resource API', 'Type', 'Requested permission', 'Consent evidence', 'Permission ID'], requested_rows(app, by_app_id))))
        registration = app.get('registration') or {}
        federation = registration.get('federatedIdentityCredentials') or {}
        block.append(section('Federated credentials', records(['Name', 'Issuer', 'Subject', 'Audiences'],
            [(item.get('name'), item.get('issuer'), item.get('subject'), '; '.join(collection(item.get('audiences')))) for item in collection(federation.get('items'))],
            'No federation records.' if federation.get('status') == 'AVAILABLE' else 'Federation evidence unavailable.')))
        signins = app.get('recentSignIns') or {}
        block.append(section('Recent sign-ins', records(['UTC time', 'User', 'Error code', 'Conditional Access'],
            [(utc_date(item.get('createdDateTime')), item.get('userPrincipalName') or item.get('userId'), (item.get('status') or {}).get('errorCode'), item.get('conditionalAccessStatus')) for item in collection(signins.get('items'))],
            'No sign-ins in the collected window.' if signins.get('status') == 'AVAILABLE' else 'Sign-in evidence unavailable.')))
        block.append('\nFull raw configuration is in the HTML artifact.\n')
        parts.append(section(f"{app.get('displayName')} — {app.get('status')}", '\n'.join(block)))
    text = "\n".join(parts)
    if len(text.encode("utf-8")) >= 1024 * 1024:
        raise ValueError("Summary exceeds GitHub's 1 MiB per-step limit; split it before publishing")
    return text


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--artifact-url", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    report = json.loads(args.report.read_text(encoding="utf-8-sig"))
    args.output.write_text(render(report, args.artifact_url), encoding="utf-8")
