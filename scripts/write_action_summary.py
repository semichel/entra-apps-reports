"""Write a Maester-style, GitHub-native application report for an Actions run."""

import argparse
import json
from collections import Counter
from pathlib import Path
from datetime import datetime, timezone

from publish_report import cell, collection, table
from render_report import expiry, owner_rows, owner_names, permission_rows, utc_date


def render(report, artifact_url):
    apps = sorted(report["applications"], key=lambda item: (item.get("displayName") or "").casefold())
    now = datetime.now(timezone.utc)
    by_id = {app.get("servicePrincipalId"): app for app in apps}
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
    parts.extend(["## Certificate and secret expiry\n", f"Days remaining calculated as of UTC {now.isoformat()}. Inventory freshness is shown above.\n",
        table(["Application", "Owner(s)", "Type", "Credential", "Expires UTC", "Days left", "Expiry state"],
            [(app.get("displayName"), owner_names(app), "Certificate" if credential.get("kind") == "keyCredentials" else "Client secret",
              credential.get("displayName") or credential.get("keyId"), utc_date(credential.get("endDateTime")), expiry(credential, now)[1], expiry(credential, now)[0])
             for app in apps for credential in collection(app.get("credentials"))]),
        "## Recorded owners\n", table(["Application", "Owner source", "Owner name", "Object type", "Owner ID"],
            [(app.get("displayName"), *row) for app in apps for row in owner_rows(app)]),
        "## Granted API permissions\n", table(["Application", "Resource API", "Type", "Granted permission", "Consent / grant", "Grant or role ID"],
            [(app.get("displayName"), *row) for app in apps for row in permission_rows(app, by_id)])])
    counts = Counter((finding["rule"], finding["status"]) for app in apps for finding in app["findings"])
    parts.extend(["## Policy observation totals\n", table(["Check", "Status", "Count"],
                   [(rule, status, count) for (rule, status), count in sorted(counts.items())])])
    tenant = report.get("tenantEvidence") or {}
    if tenant:
        parts.extend(["## Evidence coverage\n", table(["Evidence", "Availability", "Records"],
            [(key, value.get("status"), len(collection(value.get("items")))) for key, value in tenant.items() if isinstance(value, dict)])])
    parts.append("## Application findings\n")
    for app in apps:
        block = [f"<details><summary><strong>{cell(app.get('displayName'))}</strong> — {cell(app.get('status'))}</summary>\n",
                 f"\nClient ID: `{cell(app.get('appId'))}`  \nEnterprise application ID: `{cell(app.get('servicePrincipalId'))}`  \nSSO hint: {cell(app.get('protocol'))} · Enabled: {cell(app.get('accountEnabled'))} · Assignment required: {cell(app.get('assignmentRequired'))}\n",
                 table(["Check", "Status", "Evidence / next action"],
                      [(item["rule"], item["status"], item["evidence"]) for item in app["findings"] if item["status"] in {"FAIL", "WARN", "UNKNOWN"}])]
        owners = owner_rows(app)
        if owners:
            block.extend(["\n**Owners**\n", table(["Source", "Name", "Type", "ID"], owners)])
        assignments = collection(app.get("assignments"))
        if assignments:
            block.extend(["\n**Assigned users/groups**\n", table(["Name", "Type", "Role ID"], [(item.get("principalDisplayName"), item.get("principalType"), item.get("appRoleId")) for item in assignments])])
        credentials = collection(app.get("credentials"))
        if credentials:
            block.extend(["\n**Credential expiry**\n", table(["Name", "Kind", "Expires UTC", "Days left", "Lifetime days", "Status"],
                        [(item.get("displayName"), item.get("kind"), utc_date(item.get("endDateTime")), expiry(item, now)[1], item.get("lifetimeDays"), expiry(item, now)[0]) for item in credentials])])
        redirects = collection(app.get("redirectUris"))
        if redirects:
            block.extend(["\n**Callback URLs**\n", table(["URL"], [(value,) for value in redirects])])
        grants = app.get("applicationPermissionGrants") or {}
        if collection(grants.get("items")):
            block.extend(["\n**Granted application permissions**\n", table(["Resource", "Permission", "Role ID"],
                        [(item.get("resourceDisplayName"), item.get("permission"), item.get("appRoleId")) for item in collection(grants.get("items"))])])
        block.append("\nFull configuration, optional claims, federation, raw evidence and manual checks are in the HTML artifact.\n\n</details>\n")
        parts.extend(block)
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
