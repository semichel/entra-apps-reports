"""Lifecycle, permission-consent and escaped HTML checks for the actual report."""

import sys
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from render_report import expiry, permission_rows, requested_rows, render, utc_date
from render_maester_report import build_results


class ReportTests(unittest.TestCase):
    def setUp(self):
        self.now = datetime(2026, 10, 5, 12, tzinfo=timezone.utc)

    def test_expiry_states(self):
        for days, state in [(-1, "Expired"), (10, "Expires within 30 days"),
                            (45, "Expires within 60 days"), (80, "Expires within 90 days"),
                            (120, "Valid beyond 90 days")]:
            with self.subTest(days=days):
                credential = {"endDateTime": (self.now + timedelta(days=days)).isoformat()}
                self.assertEqual(expiry(credential, self.now), (state, days))
        self.assertEqual(expiry({}, self.now), ("Unknown expiry", None))

    def test_legacy_graph_utc_dates(self):
        credential = {"endDateTime": "10/01/2026 11:45:59"}
        self.assertEqual(expiry(credential, self.now)[0], "Expired")
        self.assertEqual(utc_date(credential["endDateTime"]), "2026-10-01T11:45:59Z")
        self.assertEqual(expiry({"endDateTime": "02/22/2027 09:09:10"}, self.now)[0], "Valid beyond 90 days")

    def test_requested_permission_is_not_presented_as_granted(self):
        resource = {"servicePrincipalId": "resource-sp", "displayName": "Microsoft Graph",
                    "appRoles": {"id": "role-id", "value": "Application.Read.All"}}
        app = {"registration": {"requiredResourceAccess": {"resourceAppId": "resource-app", "resourceAccess": {"id": "role-id", "type": "Role"}}},
               "applicationPermissionGrants": {"status": "AVAILABLE", "items": []}}
        rows = requested_rows(app, {"resource-app": resource})
        self.assertEqual(rows[0][3], "No matching grant observed")
        app["applicationPermissionGrants"]["items"] = [{"resourceId": "resource-sp", "appRoleId": "role-id"}]
        self.assertEqual(requested_rows(app, {"resource-app": resource})[0][3], "Granted")
        app["applicationPermissionGrants"]["status"] = "UNAVAILABLE"
        self.assertEqual(requested_rows(app, {"resource-app": resource})[0][3], "Grant evidence unavailable")

    def test_delegated_user_consent_keeps_its_scope(self):
        app = {"delegatedConsentGrants": {"items": [{"resourceId": "resource", "scope": "User.Read email", "consentType": "Principal", "principalId": "user"}]}}
        rows = permission_rows(app, {"resource": {"displayName": "Microsoft Graph"}})
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0][2], "User.Read")
        self.assertEqual(rows[0][3], "User-specific consent: user")

    def test_html_is_readable_and_escapes_directory_text(self):
        app = {"displayName": '<script>alert("owner")</script>', "appId": "app", "servicePrincipalId": "sp", "findings": [],
               "owners": [{"displayName": "Owner <test>", "id": "owner"}], "credentials": [{"kind": "keyCredentials", "displayName": "Signing certificate", "endDateTime": "2026-10-15T12:00:00Z"}],
               "applicationPermissionGrants": {"status": "AVAILABLE", "items": [{"resourceDisplayName": "Microsoft Graph", "permission": "Application.Read.All", "appRoleId": "role"}]}}
        page = render({"applications": [app], "mode": "SNAPSHOT"}, self.now)
        self.assertNotIn('<script>alert("owner")</script>', page)
        self.assertIn("Owner &lt;test&gt;", page)
        self.assertIn("Signing certificate", page)
        self.assertIn("2026-10-15T12:00:00Z", page)
        self.assertIn("Expires within 30 days", page)
        self.assertIn("Application.Read.All", page)
        self.assertIn("Granted API permissions", page)
        self.assertIn("Requested API permissions and consent", page)

    def test_native_entries_preserve_app_counts_and_unavailable_evidence(self):
        apps = [{"appId": "one", "displayName": "One", "status": "FAIL"},
                {"appId": "two", "displayName": "Two", "status": "PASS",
                 "recentSignIns": {"status": "UNAVAILABLE", "items": []}}]
        result = build_results({"applications": apps, "mode": "SNAPSHOT"}, self.now)
        self.assertEqual(result["TotalCount"], 3)
        self.assertEqual((result["FailedCount"], result["PassedCount"], result["InvestigateCount"]), (1, 1, 1))
        self.assertEqual([entry["Title"] for entry in result["Tests"]], ["One", "Two", "Tenant evidence and report scope"])
        self.assertIn("Sign-in evidence unavailable", result["Tests"][1]["ResultDetail"]["TestResult"])


if __name__ == "__main__":
    unittest.main()
