"""Create a self-contained Entra application inventory and lifecycle HTML report."""

import argparse
import html
import json
import math
from datetime import datetime, timezone
from pathlib import Path
from collections import Counter


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
    return f'<section class="subsection"><h3>{esc(title)}</h3>{content}</section>'


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
        ]))
    raw = '<section class="raw"><h3>Raw configuration evidence</h3><pre>' + esc(json.dumps(app, indent=2, ensure_ascii=False)) + '</pre></section>'
    expired = sum(state == "Expired" for state in states)
    alert = f'<span class="pill">{expired} expired credential(s)</span>' if expired else ''
    return f'<dialog class="app" id="app-{index}" aria-labelledby="title-{index}" {attributes}><div class="dialog-toolbar"><button type="button" data-previous>← Previous</button><span class="dialog-position"></span><button type="button" data-next>Next →</button><button type="button" class="close-dialog" aria-label="Close application details">✕</button></div><div class="dialog-body"><h2 id="title-{index}">{esc(name)}</h2><p class="muted">Application report details</p><div class="badges"><span class="pill">{esc(app.get("protocol"))}</span><span class="pill">{esc(app.get("status"))} policy observations</span>{alert}</div>{sections}{raw}</div></dialog>'


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
    css = Path(__file__).with_name('report.css').read_text(encoding='utf-8')
    javascript = Path(__file__).with_name('report.js').read_text(encoding='utf-8')
    observation_counts = Counter(finding.get('status') for app in apps for finding in items(app.get('findings')))
    colors = {'PASS': '#10b981', 'FAIL': '#f43f5e', 'WARN': '#f97316', 'UNKNOWN': '#3b82f6', 'MANUAL': '#94a3b8', 'NOT_APPLICABLE': '#cbd5e1'}
    labels = {'PASS': 'Passed', 'FAIL': 'Failed', 'WARN': 'Warning', 'UNKNOWN': 'Unknown', 'MANUAL': 'Manual review', 'NOT_APPLICABLE': 'Not applicable'}
    total_observations = sum(observation_counts.values())
    stops, legend, cursor = [], [], 0
    for status, count in observation_counts.items():
        percent = count / max(1, total_observations) * 100
        color = colors.get(status, '#94a3b8')
        stops.append(f'{color} {cursor:.3f}% {cursor + percent:.3f}%')
        cursor += percent
        legend.append(f'<div><i class="dot" style="background:{color}"></i>{esc(labels.get(status, status))} {count}</div>')
    donut = '<div class="donut-layout"><div class="donut" style="background:conic-gradient(' + (','.join(stops) or '#cbd5e1 0% 100%') + ')"><span>' + str(total_observations) + '</span></div><div class="legend">' + ''.join(legend) + '</div></div>'
    def bars(values):
        maximum = max((count for _, count, _ in values), default=1) or 1
        return '<div class="bars">' + ''.join(f'<div><div class="bar-label"><span>{esc(label)}</span><span>{count}</span></div><div class="bar-track"><span style="background:{color};width:{count / maximum * 100:.2f}%"></span></div></div>' for label, count, color in values) + '</div>'
    app_failures = sum(app.get('status') == 'FAIL' for app in apps)
    cards = [('Total applications', len(apps), '#3b82f6', len(apps)), ('Failed observations', app_failures, '#f43f5e', len(apps)), ('Expired credentials', expired, '#f97316', len(credentials)), ('Granted permissions', len(grants), '#10b981', len(grants))]
    output = [f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Entra apps report</title><style>{css}</style></head><body>',
        '<aside class="sidebar"><div class="brand"><span class="brand-icon">◈</span><div><strong>Entra apps report</strong><small>MichelAB</small></div></div><nav><a class="active" href="#overview">⌂ &nbsp; Home</a><a href="#applications">▦ &nbsp; Applications</a><a href="#coverage">◉ &nbsp; Tenant evidence</a><a href="report.json" download>▤ &nbsp; JSON evidence</a><a href="findings.csv" download>▦ &nbsp; Excel / CSV</a><button id="print-report" type="button">▧ &nbsp; Print</button></nav><footer>MichelAB lab tenant<br>Read-only application inventory</footer></aside>',
        '<div class="workspace"><div class="topbar"><button id="sidebar-toggle" type="button" aria-label="Toggle sidebar">◫</button><span>Home / Application overview</span><button id="theme-toggle" type="button" class="theme" aria-label="Switch to dark mode">☼</button></div><main id="overview"><h1>Application Overview</h1>',
        f'<p class="meta">MichelAB · {esc(utc_date(report.get("generatedAtUtc")))} · {esc(mode_label)}</p>',
        '<div class="cards">' + ''.join(f'<div class="card"><div class="label">{esc(label)}<span style="color:{color}">●</span></div><strong>{count}</strong><div class="meter"><span style="background:{color};width:{count / max(1, denominator) * 100:.2f}%"></span></div></div>' for label, count, color, denominator in cards) + '</div>',
        '<div class="charts"><section class="chart"><h3>Policy observations</h3>' + donut + '</section><section class="chart"><h3>Certificate &amp; secret validity</h3>' + bars([('Expired', expired, '#f43f5e'), ('Expires ≤90 days', soon, '#f97316'), ('Valid beyond 90 days', sum(expiry(value, now)[0] == 'Valid beyond 90 days' for _, value in credentials), '#10b981'), ('Unknown / not yet valid', sum(expiry(value, now)[0] in {'Unknown expiry', 'Not yet valid'} for _, value in credentials), '#94a3b8')]) + '</section><section class="chart"><h3>Application coverage</h3>' + bars([('Local registrations', len(registrations), '#3b82f6'), ('Enterprise owner gaps (<2)', missing_owners, '#f97316'), ('With recorded API grants', sum(bool(permission_rows(app, by_id)) for app in apps), '#10b981')]) + '</section></div>',
        f'<p class="notice">Tenant: {esc(report.get("tenantId"))}. Expiry calculations as of UTC {esc(utc_date(now.isoformat()))}. Failed observations are configuration findings, not a complete compliance verdict. Platform/resource apps need an applicability review. Snapshot data reflects the recorded collection time.</p>',
        '<section id="applications" class="results"><h2>Applications</h2><div class="controls"><input id="search" placeholder="Search by application, client ID or owner…" aria-label="Search applications"><select id="status-filter" aria-label="Filter by observation status"><option value="all">All observation statuses</option>' + ''.join(f'<option value="{esc(value)}">{esc(value)}</option>' for value in sorted({app.get('status') or 'UNKNOWN' for app in apps})) + '</select><select id="filter" aria-label="Filter applications"><option value="all">All applications</option><option value="local">Local registrations</option><option value="expired">Expired credentials</option><option value="expiring">Expires within 90 days</option><option value="owner-gap">Enterprise owner gaps</option></select></div><p id="shown" class="muted"></p><div class="table-wrap"><table><thead><tr><th>Application</th><th>SSO hint</th><th>Owners</th><th>Credential expiry</th><th>API grants</th><th>Observations</th></tr></thead><tbody id="application-rows">']
    for index, app in enumerate(apps):
        states = [expiry(value, now)[0] for value in items(app.get('credentials'))]
        search = ' '.join(str(value or '') for value in [app.get('displayName'), app.get('appId'), app.get('protocol'), owner_names(app)]).lower()
        attributes = f'data-target="app-{index}" data-search="{esc(search)}" data-status="{esc(app.get("status") or "UNKNOWN")}" data-local="{str(bool(app.get("registration"))).lower()}" data-expired="{str("Expired" in states).lower()}" data-expiring="{str(any(value.startswith("Expires within") for value in states)).lower()}" data-owner-gap="{str(len(items(app.get("owners"))) < 2).lower()}"'
        next_end = min((date(value.get('endDateTime')) for value in items(app.get('credentials')) if date(value.get('endDateTime'))), default=None)
        credential_label = 'Expired' if 'Expired' in states else 'Expiring' if any(value.startswith('Expires within') for value in states) else 'Recorded' if states else 'No local credentials'
        cells = [f'<button class="app-link" type="button">{esc(app.get("displayName"))}</button><small class="subtext">{esc(app.get("appId"))}</small>', esc(app.get('protocol')), esc(owner_names(app)), f'<span class="pill {credential_label}">{credential_label}</span><small class="subtext">{esc(utc_date(next_end.isoformat()) if next_end else "")}</small>', str(len(permission_rows(app, by_id))), f'<span class="pill {esc(app.get("status"))}">{esc(app.get("status"))}</span>']
        output.append(f'<tr {attributes}>' + ''.join(f'<td>{value}</td>' for value in cells) + '</tr>')
    output.append('</tbody></table></div></section>')
    output.extend(app_html(app, index, now, by_id, by_app_id) for index, app in enumerate(apps))
    tenant = report.get('tenantEvidence') or {}
    coverage = [(key, value.get('status'), len(items(value.get('items'))), value.get('reason')) for key, value in tenant.items() if isinstance(value, dict)]
    coverage_html = table(['Evidence', 'Availability', 'Records', 'Reason'], coverage, 'Extended tenant evidence was not collected.')
    policies = (tenant.get('conditionalAccessPolicies') or {}).get('items')
    coverage_html += subsection('Conditional Access policies', table(['Policy', 'State', 'Policy ID'], [(value.get('displayName'), value.get('state'), value.get('id')) for value in items(policies)]))
    coverage_html += '<section class="raw"><h3>Complete tenant policy, consent and log evidence</h3><pre>' + esc(json.dumps(tenant, indent=2, ensure_ascii=False)) + '</pre></section>'
    output.append(panel('Evidence coverage and tenant policies', '<p>UNAVAILABLE means a query could not be completed. Logs cover the collected window only.</p>' + coverage_html, 'coverage'))
    standalone_links = []
    for value in registrations:
        if value.get('appId') in matched_ids:
            continue
        index = len(apps) + len(standalone_links)
        standalone = {'displayName': value.get('displayName'), 'appId': value.get('appId'), 'registration': value, 'credentials': value.get('credentials'), 'status': 'Registration only', 'findings': []}
        standalone_links.append(f'<p><button class="app-link" data-open-app="app-{index}" type="button">{esc(value.get("displayName"))}</button></p>')
        output.append(app_html(standalone, index, now, by_id, by_app_id))
    if standalone_links:
        output.append(panel('Registrations without an enterprise application', ''.join(standalone_links)))
    output.append(f'</main></div><script>{javascript}</script></body></html>')
    return ''.join(output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    report = json.loads(args.report.read_text(encoding="utf-8-sig"))
    args.output.write_text(render(report), encoding="utf-8")
