"""Render a live Entra report as GitHub-readable Markdown and evidence files."""

import argparse
import json
import shutil
from collections import Counter
from pathlib import Path


def cell(value):
    if value is None:
        return "Not available"
    return (str(value).replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace("|", "&#124;")
            .replace("[", "&#91;").replace("]", "&#93;")
            .replace("`", "&#96;").replace("\r", " ").replace("\n", " "))


def table(headers, rows):
    lines = ["| " + " | ".join(headers) + " |",
             "| " + " | ".join("---" for _ in headers) + " |"]
    lines.extend("| " + " | ".join(cell(v) for v in row) + " |" for row in rows)
    return "\n".join(lines) + "\n"


def evidence(value):
    # A long fence prevents embedded Markdown in directory strings escaping the block.
    text = json.dumps(value, indent=2, ensure_ascii=False)
    length = max(3, max((len(part) for part in text.split("\n")
                         if part and set(part) == {"`"}), default=0) + 1)
    # Directory strings can contain backticks inside JSON string values.
    while "`" * length in text:
        length += 1
    fence = "`" * length
    return f"\n{fence}json\n{text}\n{fence}\n"


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def publish(source, destination):
    report = json.loads((source / "report.json").read_text(encoding="utf-8-sig"))
    if report.get("mode") != "LIVE":
        raise ValueError("Only LIVE reports may replace the published lab report")
    if report.get("tenantId") != "37dadda4-f2a4-47a8-8482-d40fe1a5aa48":
        raise ValueError("Expected the confirmed MichelAB tenant")
    apps = sorted(report["applications"], key=lambda app: (app.get("displayName") or "").casefold())
    registrations = sorted(report.get("registrations", []), key=lambda app: (app.get("displayName") or "").casefold())
    destination.mkdir(parents=True, exist_ok=True)
    index = ["# MichelAB — live Entra application report\n",
             f"Tenant: `{report['tenantId']}`  \nCollected UTC: {cell(report['generatedAtUtc'])}  \nExtended evidence UTC: {cell(report.get('evidenceCollectedAtUtc'))}\n",
             f"**{len(apps)} enterprise application service principals · {len(registrations)} local app registrations**\n",
             "This is real tenant data. Click an application below to read its findings and evidence directly on GitHub.\n",
             "Catalog entries include Microsoft/platform/resource applications. Confirm that an application is in scope for the supplied SSO policy before remediation. Manual sign-in, token/assertion validation, TLS and business approval checks remain required.\n",
             "[Tenant policies, consent and recent logs](tenant-evidence.md) · [Requirement checklist](requirements.md) · [Complete JSON evidence](report.json)\n",
             "## Applications\n",
             "| Application | Protocol hint | Policy observations | Owners | Assignments |\n|---|---|---|---|---|\n"]
    for app in apps:
        object_id = app["servicePrincipalId"]
        if not object_id or any(ch not in "0123456789abcdefABCDEF-" for ch in object_id):
            raise ValueError("Invalid enterprise application object ID")
        index.append(f"| [{cell(app.get('displayName'))}](applications/{object_id}.md) | {cell(app.get('protocol'))} | {cell(app.get('status'))} | {len(app.get('owners', []))} | {len(app.get('assignments', []))} |\n")
        page = [f"# {cell(app.get('displayName'))}\n", "[← All applications](../README.md)\n",
                f"Collected UTC: {cell(report['generatedAtUtc'])}\n",
                table(["Property", "Value"], [("Client ID", app.get("appId")), ("Enterprise application ID", object_id),
                      ("Enabled", app.get("accountEnabled")), ("SSO hint", app.get("protocol")),
                      ("Publisher", app.get("publisherName")), ("Home tenant", app.get("appOwnerOrganizationId")),
                      ("Assignment required", app.get("assignmentRequired")), ("Policy observations", app.get("status"))]),
                "\n## Findings and required validation\n",
                table(["Check", "Status", "Evidence / next action"],
                      [(f["rule"], f["status"], f["evidence"]) for f in app["findings"]]),
                "\n## Owners\n", table(["Name", "Object type", "Object ID"],
                    [(v.get("displayName"), v.get("@odata.type"), v.get("id")) for v in app.get("owners", [])]),
                "\n## Assigned users and groups\n", table(["Name", "Type", "Principal ID", "Role ID"],
                    [(v.get("principalDisplayName"), v.get("principalType"), v.get("principalId"), v.get("appRoleId")) for v in app.get("assignments", [])]),
                "\n## Credential dates\n", table(["Name", "Source", "Kind", "Expires UTC", "Days remaining", "Lifetime days", "Status"],
                    [(v.get("displayName"), v.get("source"), v.get("kind"), v.get("endDateTime"), v.get("daysRemaining"), v.get("lifetimeDays"), v.get("status")) for v in app.get("credentials", [])])]
        for key, title in [("redirectUris", "Callback URLs"), ("registration", "App registration and federation"),
                           ("applicationPermissionGrants", "Granted application permissions"),
                           ("delegatedConsentGrants", "Granted delegated permissions"),
                           ("recentSignIns", "Recent sign-ins"), ("optionalClaims", "Optional claims")]:
            page.extend([f"\n## {title}\n", evidence(app.get(key))])
        page.extend(["\n## Exposed application roles\n", table(["Permission / role", "Display name", "Role ID"],
                    [(v.get("value"), v.get("displayName"), v.get("id")) for v in app.get("appRoles") or []]),
                    "\n## Exposed delegated scopes\n", table(["Scope", "Admin consent display name", "Scope ID"],
                    [(v.get("value"), v.get("adminConsentDisplayName"), v.get("id")) for v in app.get("oauth2PermissionScopes") or []]),
                    f"\n## Complete collected application configuration\n\n[View the complete application evidence on GitHub]({object_id}.json).\n"])
        write(destination / "applications" / f"{object_id}.json", json.dumps(app, indent=2, ensure_ascii=False) + "\n")
        write(destination / "applications" / f"{object_id}.md", "\n".join(page))
    index.extend(["\n## Local app registrations\n", "| Registration | Client ID |\n|---|---|\n"])
    for registration in registrations:
        object_id = registration["id"]
        if not object_id or any(ch not in "0123456789abcdefABCDEF-" for ch in object_id):
            raise ValueError("Invalid registration object ID")
        index.append(f"| [{cell(registration.get('displayName'))}](registrations/{object_id}.md) | {cell(registration.get('appId'))} |\n")
        write(destination / "registrations" / f"{object_id}.md",
              f"# {cell(registration.get('displayName'))}\n\n[← Report index](../README.md)\n\n" + evidence(registration))
    counts = Counter((finding["rule"], finding["status"]) for app in apps for finding in app["findings"])
    index.extend(["\n## Policy observation totals\n", table(["Check", "Status", "Count"],
                  [(rule, status, count) for (rule, status), count in sorted(counts.items())]),
                  "\n## CSV evidence\n\n[Findings](findings.csv) · [Owners](owners.csv) · [Assignments](assignments.csv) · [Credential dates](credentials.csv)\n"])
    write(destination / "README.md", "\n".join(index))
    tenant = report.get("tenantEvidence", {})
    tenant_page = ["# Tenant evidence\n", "[← Application report](README.md)\n",
                   f"Log lookback: {cell(tenant.get('lookbackDays'))} days, starting {cell(tenant.get('sinceUtc'))}.\n",
                   "UNAVAILABLE means a query failed or access/licensing was insufficient; it does not indicate a passing control. Conditional Access applicability and effective enforcement require review.\n"]
    for key, title in [("conditionalAccessPolicies", "Conditional Access policies"), ("claimsMappingPolicies", "Claims mapping policies"),
                       ("delegatedConsentGrants", "Delegated consent grants"), ("signIns", "Recent sign-ins"), ("directoryAudits", "Recent audit events")]:
        tenant_page.extend([f"\n## {title}\n", evidence(tenant.get(key))])
    write(destination / "tenant-evidence.md", "\n".join(tenant_page))
    for name in ["report.json", "findings.csv", "owners.csv", "assignments.csv", "credentials.csv"]:
        if (source / name).exists():
            shutil.copyfile(source / name, destination / name)
    requirements = Path(__file__).resolve().parent.parent / "docs" / "report-requirements.md"
    shutil.copyfile(requirements, destination / "requirements.md")
    for folder, expected_ids in [("applications", {app["servicePrincipalId"] for app in apps}),
                                 ("registrations", {app["id"] for app in registrations})]:
        for path in (destination / folder).iterdir():
            if (path.suffix in {".md", ".json"} and path.stem not in expected_ids
                    and all(ch in "0123456789abcdefABCDEF-" for ch in path.stem)):
                path.unlink()
    print(f"Published {len(apps)} applications and {len(registrations)} registrations to {destination}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--destination", type=Path, default=Path("published/lab"))
    args = parser.parse_args()
    publish(args.source, args.destination)
