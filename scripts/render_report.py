"""Create a self-contained Entra application inventory and lifecycle HTML report."""

import argparse
import html
import json
import math
from datetime import datetime, timezone
from pathlib import Path


def items(value):
    if value is None:
        return []
    return [value] if isinstance(value, dict) else value


def esc(value):
    return html.escape("Not available" if value is None else str(value), quote=True)


def date(value):
    if not value:
        return None
    try:
        result = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return result.replace(tzinfo=timezone.utc) if result.tzinfo is None else result
    except (TypeError, ValueError):
        # Older exports cast Graph UTC timestamps to invariant MM/dd/yyyy strings.
        try:
            return datetime.strptime(value, "%m/%d/%Y %H:%M:%S").replace(tzinfo=timezone.utc)
        except (TypeError, ValueError):
            return None


def utc_date(value):
    parsed = date(value)
    return parsed.astimezone(timezone.utc).isoformat().replace("+00:00", "Z") if parsed else value


def expiry(credential, now):
    end = date(credential.get("endDateTime"))
    start = date(credential.get("startDateTime"))
    if end is None:
        return "Unknown expiry", None
    days = math.floor((end - now).total_seconds() / 86400)
    if end <= now:
        return "Expired", days
    if start and start > now:
        return "Not yet valid", days
    if days <= 30:
        return "Expires within 30 days", days
    if days <= 60:
        return "Expires within 60 days", days
    if days <= 90:
        return "Expires within 90 days", days
    return "Valid beyond 90 days", days


def table(headers, rows, empty="No records in this inventory."):
    rows = list(rows)
    if not rows:
        return f'<p class="empty">{esc(empty)}</p>'
    head = "".join(f"<th>{esc(header)}</th>" for header in headers)
    body = "".join("<tr>" + "".join(f"<td>{esc(value)}</td>" for value in row) + "</tr>" for row in rows)
    return f'<div class="table-wrap"><table><thead><tr>{head}</tr></thead><tbody>{body}</tbody></table></div>'


def panel(title, content, anchor=None):
    identity = f' id="{esc(anchor)}"' if anchor else ""
    return f'<details class="panel"{identity}><summary><strong>{esc(title)}</strong></summary>{content}</details>'


def subsection(title, content):
    return f'<details class="subsection"><summary>{esc(title)}</summary>{content}</details>'


def owner_rows(app):
    rows = [("Enterprise application", value.get("displayName"), value.get("@odata.type", "").replace("#microsoft.graph.", ""), value.get("id"))
            for value in items(app.get("owners"))]
    registration = app.get("registration") or {}
    rows.extend(("App registration", value.get("displayName"), value.get("@odata.type", "").replace("#microsoft.graph.", ""), value.get("id"))
                for value in items((registration.get("owners") or {}).get("items")))
    return rows


def owner_names(app):
    return "; ".join(dict.fromkeys(row[1] or row[3] for row in owner_rows(app))) or "No recorded owners"


def permission_rows(app, by_id):
    rows = []
    for grant in items((app.get("applicationPermissionGrants") or {}).get("items")):
        resource = by_id.get(grant.get("resourceId"), {})
        rows.append((grant.get("resourceDisplayName") or resource.get("displayName") or grant.get("resourceId"),
                     "Application", grant.get("permission") or grant.get("appRoleId"), "App-only grant", grant.get("appRoleId")))
    for grant in items((app.get("delegatedConsentGrants") or {}).get("items")):
        resource = by_id.get(grant.get("resourceId"), {})
        consent = "Tenant-wide admin consent" if grant.get("consentType") == "AllPrincipals" else "User-specific consent: " + str(grant.get("principalId"))
        for scope in (grant.get("scope") or "").split():
            rows.append((resource.get("displayName") or grant.get("resourceId"), "Delegated", scope, consent, grant.get("id")))
    return rows


def requested_rows(app, by_app_id):
    registration = app.get("registration") or {}
    granted_roles = {(entry.get("resourceId"), entry.get("appRoleId")) for entry in items((app.get("applicationPermissionGrants") or {}).get("items"))}
    delegated = items((app.get("delegatedConsentGrants") or {}).get("items"))
    rows = []
    for api in items(registration.get("requiredResourceAccess")):
        resource = by_app_id.get(api.get("resourceAppId"), {})
        for requested in items(api.get("resourceAccess")):
            kind = requested.get("type")
            definitions = items(resource.get("appRoles") if kind == "Role" else resource.get("oauth2PermissionScopes"))
            definition = next((entry for entry in definitions if entry.get("id") == requested.get("id")), {})
            name = definition.get("value") or requested.get("id")
            if kind == "Role":
                state = "Granted" if (resource.get("servicePrincipalId"), requested.get("id")) in granted_roles else "No matching grant observed"
            else:
                matches = [entry for entry in delegated if entry.get("resourceId") == resource.get("servicePrincipalId") and name in (entry.get("scope") or "").split()]
                state = "Tenant-wide grant observed" if any(entry.get("consentType") == "AllPrincipals" for entry in matches) else "User-specific grant observed" if matches else "No matching grant observed"
            evidence = app.get("applicationPermissionGrants") if kind == "Role" else app.get("delegatedConsentGrants")
            if not evidence or evidence.get("status") != "AVAILABLE":
                state = "Grant evidence unavailable"
            rows.append((resource.get("displayName") or api.get("resourceAppId"), "Application" if kind == "Role" else "Delegated", name, state, requested.get("id")))
    return rows


def credential_rows(app, now):
    return [(value.get("displayName") or value.get("keyId"), value.get("source"),
             "Certificate" if value.get("kind") == "keyCredentials" else "Client secret",
             utc_date(value.get("startDateTime")), utc_date(value.get("endDateTime")), expiry(value, now)[1], expiry(value, now)[0],
             value.get("lifetimeDays"), value.get("status"), value.get("keyId"))
            for value in items(app.get("credentials"))]


def app_html(app, index, now, by_id, by_app_id):
    name = app.get("displayName")
    local = bool(app.get("registration"))
    states = [expiry(value, now)[0] for value in items(app.get("credentials"))]
    search = " ".join(str(value or "") for value in [name, app.get("appId"), app.get("protocol"), owner_names(app)])
    attributes = f'data-search="{esc(search.lower())}" data-local="{str(local).lower()}" data-expired="{str("Expired" in states).lower()}" data-expiring="{str(any(value.startswith("Expires within") for value in states)).lower()}" data-owner-gap="{str(len(items(app.get("owners"))) < 2).lower()}"'
    overview = table(["Property", "Value"], [("Client ID", app.get("appId")), ("Enterprise application ID", app.get("servicePrincipalId")),
                     ("Enabled", app.get("accountEnabled")), ("SSO hint", app.get("protocol")), ("Publisher", app.get("publisherName")),
                     ("Home tenant", app.get("appOwnerOrganizationId")), ("User assignment required", app.get("assignmentRequired")),
                     ("Login URL", app.get("loginUrl")), ("Logout URL", app.get("logoutUrl")),
                     ("Preferred SAML signing thumbprint", app.get("preferredTokenSigningKeyThumbprint")),
                     ("Token encryption key ID", app.get("tokenEncryptionKeyId"))])
    owners = table(["Owner source", "Owner name", "Object type", "Object ID"], owner_rows(app), "No owners recorded in the available enterprise application / registration evidence.")
    registration = app.get("registration") or {}
    reg_owner_evidence = registration.get("owners") or {}
    if reg_owner_evidence.get("status") == "UNAVAILABLE":
        owners += '<p class="warning">App registration owner evidence is unavailable.</p>'
    creds = table(["Credential", "Source", "Type", "Valid from UTC", "Expires UTC", "Days left", "Expiry state", "Lifetime days", "Policy observation", "Key ID"], credential_rows(app, now), "No local credential metadata recorded. This does not prove federation is used; credentials may live in an external home tenant.")
    assignment_rows = [(value.get("principalDisplayName"), value.get("principalType"), value.get("principalId"), value.get("appRoleId")) for value in items(app.get("assignments"))]
    permissions = table(["Resource API", "Permission type", "Granted permission", "Consent / grant", "Grant or role ID"], permission_rows(app, by_id), "No granted API permissions in the available inventory.")
    for key, label in [("applicationPermissionGrants", "Application permission grants"), ("delegatedConsentGrants", "Delegated consent grants")]:
        evidence = app.get(key) or {}
        if evidence.get("status") != "AVAILABLE":
            permissions += f'<p class="warning">{esc(label)}: evidence unavailable.</p>'
    requests = table(["Resource API", "Requested type", "Requested permission", "Consent evidence", "Permission ID"], requested_rows(app, by_app_id), "No requested API permissions recorded in a locally available registration.")
    federation = registration.get("federatedIdentityCredentials") or {}
    federation_rows = [(value.get("name"), value.get("issuer"), value.get("subject"), "; ".join(items(value.get("audiences")))) for value in items(federation.get("items"))]
    findings = table(["Check", "Observation", "Evidence / required action"], [(value.get("rule"), value.get("status"), value.get("evidence")) for value in app.get("findings", [])])
    signins = app.get("recentSignIns") or {}
    signin_rows = [(value.get("createdDateTime"), value.get("userPrincipalName") or value.get("userId"), (value.get("status") or {}).get("errorCode"),
                    (value.get("status") or {}).get("failureReason"), value.get("conditionalAccessStatus")) for value in items(signins.get("items"))]
    blocks = [("Application profile", overview), ("Owners", owners), ("Certificates and client secrets", creds),
              ("Assigned users and groups", table(["Name", "Type", "Principal ID", "Role ID"], assignment_rows)),
              ("Granted API permissions", permissions), ("Requested API permissions and consent", requests),
              ("Redirect / callback URLs", table(["URL"], [(value,) for value in items(app.get("redirectUris"))])),
              ("Federated credentials", table(["Name", "Issuer", "Subject", "Audiences"], federation_rows,
                    "No federation records in the available local evidence." if federation.get("status") == "AVAILABLE" else "Federation evidence unavailable or registration belongs to another tenant.")),
              ("Recent sign-ins", table(["UTC time", "User", "Error code", "Failure reason", "Conditional Access"], signin_rows,
                    "No sign-ins in the collected window." if signins.get("status") == "AVAILABLE" else "Sign-in evidence unavailable.")),
              ("Policy findings and manual validation", findings)]
    sections = "".join(subsection(title, content) for title, content in blocks)
    if registration:
        sections += subsection('App registration configuration', table(['Property', 'Value'], [
            ('Registration ID', registration.get('id')), ('Sign-in audience', registration.get('signInAudience')),
            ('Publisher domain', registration.get('publisherDomain')), ('Created UTC', utc_date(registration.get('createdDateTime')))
        ]) + '<details class="raw"><summary>Complete registration settings</summary><pre>' + esc(json.dumps(registration, indent=2, ensure_ascii=False)) + '</pre></details>')
    raw = '<details class="raw"><summary>Raw configuration evidence</summary><pre>' + esc(json.dumps(app, indent=2, ensure_ascii=False)) + '</pre></details>'
    expired = sum(state == "Expired" for state in states)
    alert = f'<span class="pill">{expired} expired credential(s)</span>' if expired else ''
    return f'<details class="app" id="app-{index}" {attributes}><summary><strong>{esc(name)}</strong><span class="pill">{esc(app.get("protocol"))}</span><span class="pill">{esc(app.get("status"))} policy observations</span>{alert}</summary>{sections}{raw}</details>'


def render(report, now=None):
    now = now or datetime.now(timezone.utc)
    apps = sorted(report["applications"], key=lambda value: (value.get("displayName") or "").casefold())
    registrations = items(report.get("registrations"))
    by_id = {value.get("servicePrincipalId"): value for value in apps}
    by_app_id = {value.get("appId"): value for value in apps}
    credentials = [(app, value) for app in apps for value in items(app.get("credentials"))]
    matched_ids = {app.get("appId") for app in apps}
    for registration in registrations:
        if registration.get("appId") not in matched_ids:
            app = {"displayName": registration.get("displayName"), "appId": registration.get("appId"), "registration": registration}
            credentials.extend((app, value) for value in items(registration.get("credentials")))
    credentials.sort(key=lambda pair: date(pair[1].get("endDateTime")) or datetime.max.replace(tzinfo=timezone.utc))
    expired = sum(expiry(value, now)[0] == "Expired" for _, value in credentials)
    soon = sum(expiry(value, now)[0].startswith("Expires within") for _, value in credentials)
    grants = [(app, row) for app in apps for row in permission_rows(app, by_id)]
    missing_owners = sum(len(items(app.get("owners"))) < 2 for app in apps)
    mode = report.get("mode")
    mode_label = {"LIVE": "Fresh tenant collection", "SNAPSHOT": "Previously collected tenant snapshot", "DEMO": "Synthetic demo"}.get(mode, mode)
    cards = [("Applications", len(apps)), ("Local registrations", len(registrations)), ("Credentials expired", expired),
             ("Credentials expire ≤90 days", soon), ("Enterprise apps with <2 owners", missing_owners), ("Granted API permissions", len(grants))]
    css = '''body{margin:0;background:#f3f6fa;color:#18324d;font:15px system-ui}main{max-width:1500px;margin:auto;padding:28px}header,.panel,.app{background:white;border:1px solid #dce4ee;border-radius:12px;padding:22px;margin:18px 0}h1{margin:0 0 12px}h2{margin-top:0}h3{margin-top:28px}nav{display:flex;gap:18px;flex-wrap:wrap}a{color:#1764a4}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px}.card{background:#eaf1f8;border-radius:10px;padding:16px}.card strong{display:block;font-size:30px}.table-wrap{overflow:auto}table{border-collapse:collapse;width:100%;font-size:14px}th,td{padding:10px;border:1px solid #dce4ee;text-align:left;vertical-align:top;overflow-wrap:anywhere}th{background:#edf3f9;position:sticky;top:0}tbody tr:nth-child(even){background:#fafbfd}.empty{color:#617488}.warning{background:#fff3da;padding:12px;border-radius:8px}summary{cursor:pointer;padding:10px 0}.app>summary{display:flex;gap:12px;align-items:center;flex-wrap:wrap}.pill{padding:4px 9px;background:#edf3f9;border-radius:20px;font-size:12px}.controls{display:flex;gap:12px;margin:16px 0}input,select{font:inherit;padding:12px;border:1px solid #b8c9dc;border-radius:6px}input{flex:1}.index-scroll{max-height:540px;overflow:auto}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f3f6fa;padding:16px;font:12px ui-monospace;max-height:550px;overflow:auto}.raw{margin-top:20px}.muted{color:#617488}[hidden]{display:none!important}@media(max-width:700px){main{padding:12px}.controls{flex-direction:column}}@media print{.controls,nav{display:none}.table-wrap{overflow:visible}}'''
    css += '.subsection{border:1px solid #dce4ee;border-radius:8px;padding:8px 14px;margin:10px 0}.subsection>summary{font-weight:600}.app>summary::before{content:"▶"}.app[open]>summary::before{content:"▼"}.registration-app{margin:12px 0;padding:12px;border:1px solid #dce4ee;border-radius:8px}'
    output = [f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Entra application lifecycle and permissions report</title><style>{css}</style></head><body><main>',
              '<header id="overview"><h1>Entra application lifecycle and permissions</h1>',
              f'<p><strong>MichelAB</strong> · {esc(report.get("tenantId"))}<br><strong>{esc(mode_label)}</strong> · Inventory collected UTC: {esc(utc_date(report.get("generatedAtUtc")))}<br>Expiry calculations as of UTC: {esc(utc_date(now.isoformat()))}</p>',
              '<nav><a href="#applications">Applications</a><a href="#coverage">Tenant evidence</a></nav>',
              '<p class="muted">Catalog entries include platform/resource applications. Confirm SSO policy applicability before remediation. Snapshot data does not confirm that credentials or grants are still configured today.</p></header>',
              '<div class="cards">' + ''.join(f'<div class="card"><strong>{count}</strong>{esc(title)}</div>' for title, count in cards) + '</div>']
    controls = '<div class="controls"><input id="search" placeholder="Search application, client ID, owner or protocol" aria-label="Search applications"><select id="filter" aria-label="Filter applications"><option value="all">All applications</option><option value="local">Local registrations</option><option value="expired">Expired credentials</option><option value="expiring">Expires within 90 days</option><option value="owner-gap">Enterprise owner gaps</option></select></div><p id="shown" class="muted"></p>'
    output.append('<section id="applications"><h2>Applications</h2><p>Expand an application, then expand its owners, certificates, permissions or other details.</p>' + controls)
    output.extend(app_html(app, index, now, by_id, by_app_id) for index, app in enumerate(apps))
    output.append('</section>')
    tenant = report.get("tenantEvidence") or {}
    coverage = [(key, value.get("status"), len(items(value.get("items"))), value.get("reason")) for key, value in tenant.items() if isinstance(value, dict)]
    coverage_html = table(["Evidence", "Availability", "Records", "Reason"], coverage, "Extended tenant evidence was not collected in this report.")
    policies = (tenant.get("conditionalAccessPolicies") or {}).get("items")
    coverage_html += subsection('Conditional Access policies', table(["Policy", "State", "Policy ID"], [(value.get("displayName"), value.get("state"), value.get("id")) for value in items(policies)]))
    coverage_html += '<details class="raw"><summary>Complete tenant policy, consent and log evidence</summary><pre>' + esc(json.dumps(tenant, indent=2, ensure_ascii=False)) + '</pre></details>'
    output.append(panel("Evidence coverage and tenant policies", '<p>UNAVAILABLE means a query could not be completed, never a passing control. Recent logs cover the recorded lookback only. Conditional Access applicability and effective enforcement require separate review.</p>' + coverage_html, "coverage"))
    registration_blocks = []
    for value in registrations:
        registration_app = next((app for app in apps if app.get('appId') == value.get('appId')), None)
        if registration_app is not None:
            continue
        standalone = {'displayName': value.get('displayName'), 'appId': value.get('appId'), 'registration': value,
                      'credentials': value.get('credentials'), 'status': 'Registration only', 'findings': []}
        registration_blocks.append(app_html(standalone, len(apps) + len(registration_blocks), now, by_id, by_app_id).replace('class="app"', 'class="registration-app"'))
    if registration_blocks:
        output.append(panel('Registrations without an enterprise application', ''.join(registration_blocks)))
    javascript = '''function applyFilters(){const q=document.getElementById('search').value.toLowerCase();const f=document.getElementById('filter').value;let count=0;document.querySelectorAll('.app').forEach(el=>{const visible=el.dataset.search.includes(q)&&(f==='all'||el.getAttribute('data-'+f)==='true');el.hidden=!visible;if(visible)count++;});document.getElementById('shown').textContent=count+' applications shown';}document.getElementById('search').addEventListener('input',applyFilters);document.getElementById('filter').addEventListener('change',applyFilters);applyFilters();'''
    output.append(f'<script>{javascript}</script></main></body></html>')
    return "".join(output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    report = json.loads(args.report.read_text(encoding="utf-8-sig"))
    args.output.write_text(render(report), encoding="utf-8")
