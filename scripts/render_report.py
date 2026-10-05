"""Create a self-contained Entra application inventory and lifecycle HTML report."""

import argparse
import json
import math
from datetime import datetime, timezone
from pathlib import Path


def items(value):
    if value is None:
        return []
    return [value] if isinstance(value, dict) else value


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


def render(report, now=None):
    from render_maester_report import render as native_render
    return native_render(report, now)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    report = json.loads(args.report.read_text(encoding="utf-8-sig"))
    args.output.write_text(render(report), encoding="utf-8")
