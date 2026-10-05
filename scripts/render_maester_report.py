"""Adapt collected Entra inventory to the pinned native Maester 2.2 report site."""

import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from publish_report import cell, table, evidence
from render_report import items, owner_rows, permission_rows, requested_rows, credential_rows, utc_date, expiry


def section(title, headers, rows, empty='No records in the available evidence.'):
    rows = list(rows)
    return '\n### ' + title + '\n\n' + (table(headers, rows) if rows else empty) + '\n'


def app_details(app, now, by_id, by_app_id):
    registration = app.get('registration') or {}
    text = section('Application profile', ['Property', 'Value'], [
        ('Client ID', app.get('appId')), ('Enterprise application ID', app.get('servicePrincipalId')),
        ('Enabled', app.get('accountEnabled')), ('SSO hint', app.get('protocol')),
        ('Publisher', app.get('publisherName')), ('Home tenant', app.get('appOwnerOrganizationId')),
        ('Assignment required', app.get('assignmentRequired')), ('Login URL', app.get('loginUrl')),
        ('Logout URL', app.get('logoutUrl')), ('Sign-in audience', registration.get('signInAudience'))])
    text += section('Owners', ['Source', 'Name', 'Type', 'Object ID'], owner_rows(app), 'No owners recorded in the available evidence.')
    if (registration.get('owners') or {}).get('status') == 'UNAVAILABLE':
        text += '\nApp registration owner evidence is unavailable.\n'
    text += section('Certificates and client secrets', ['Credential', 'Source', 'Type', 'Valid from UTC', 'Expires UTC', 'Days left', 'Expiry state', 'Lifetime days', 'Policy observation', 'Key ID'], credential_rows(app, now), 'No local credential metadata recorded. Credentials may live in an external home tenant.')
    text += section('Granted API permissions', ['Resource API', 'Type', 'Granted permission', 'Consent / grant', 'Role or grant ID'], permission_rows(app, by_id))
    for key, label in [('applicationPermissionGrants', 'Application permission grants'), ('delegatedConsentGrants', 'Delegated consent')]:
        if (app.get(key) or {}).get('status') != 'AVAILABLE':
            text += '\n' + label + ': evidence unavailable.\n'
    text += section('Requested API permissions and consent', ['Resource API', 'Type', 'Requested permission', 'Consent evidence', 'Permission ID'], requested_rows(app, by_app_id))
    text += section('Assigned users and groups', ['Name', 'Type', 'Principal ID', 'Role ID'], [(item.get('principalDisplayName'), item.get('principalType'), item.get('principalId'), item.get('appRoleId')) for item in items(app.get('assignments'))])
    text += section('Redirect / callback URLs', ['URL'], [(value,) for value in items(app.get('redirectUris'))])
    federation = registration.get('federatedIdentityCredentials') or {}
    text += section('Federated credentials', ['Name', 'Issuer', 'Subject', 'Audiences'], [(value.get('name'), value.get('issuer'), value.get('subject'), '; '.join(items(value.get('audiences')))) for value in items(federation.get('items'))], 'No federation records.' if federation.get('status') == 'AVAILABLE' else 'Federation evidence unavailable or registration belongs to another tenant.')
    signins = app.get('recentSignIns') or {}
    text += section('Recent sign-ins', ['UTC time', 'User', 'Error code', 'Failure reason', 'Conditional Access'], [(utc_date(value.get('createdDateTime')), value.get('userPrincipalName') or value.get('userId'), (value.get('status') or {}).get('errorCode'), (value.get('status') or {}).get('failureReason'), value.get('conditionalAccessStatus')) for value in items(signins.get('items'))], 'No sign-ins in the collected window.' if signins.get('status') == 'AVAILABLE' else 'Sign-in evidence unavailable.')
    text += section('Policy findings and manual validation', ['Check', 'Observation', 'Evidence / next action'], [(value.get('rule'), value.get('status'), value.get('evidence')) for value in items(app.get('findings'))])
    return text


def native_result(index, title, result, category, tags, content, advanced):
    identifier = f'APP.{index:04d}'
    return {'Index': index, 'Id': identifier, 'Title': title, 'Name': title, 'HelpUrl': None,
            'Severity': 'Info', 'Tag': tags, 'Result': result, 'ScriptBlock': '',
            'ScriptBlockFile': 'Collected Entra inventory', 'ErrorRecord': [], 'Block': category,
            'Duration': '00:00:00', 'ResultDetail': {'TestTitle': title, 'TestResult': content,
                'TestDescription': advanced, 'TestInvestigate': result == 'Investigate',
                'Service': 'Microsoft Graph', 'Severity': 'Info', 'SkippedReason': None, 'TestSkipped': ''}}


def build_results(report, now):
    apps = sorted(items(report.get('applications')), key=lambda app: (app.get('displayName') or '').casefold())
    by_id = {app.get('servicePrincipalId'): app for app in apps}
    by_app_id = {app.get('appId'): app for app in apps}
    mode = report.get('mode', 'UNKNOWN')
    scope = (f'Inventory mode: **{cell(mode)}**. Collected UTC: **{cell(utc_date(report.get("generatedAtUtc")))}**. '
             f'Expiry calculations UTC: **{cell(utc_date(now.isoformat()))}**. '
             'This is collected application evidence. Failed denotes recorded configuration findings, not a completed sign-in or compliance test. '
             'Info severity is the inventory entry classification, not an assigned business risk rating. '
             'Snapshot runs do not query Entra again. Microsoft/platform/resource applications require an applicability review.\n')
    tests = []
    matched = {app.get('appId') for app in apps}
    for registration in items(report.get('registrations')):
        if registration.get('appId') not in matched:
            apps.append({'displayName': registration.get('displayName'), 'appId': registration.get('appId'),
                         'registration': registration, 'credentials': registration.get('credentials'),
                         'status': 'MANUAL', 'findings': []})
    for app in apps:
        result = 'Failed' if app.get('status') == 'FAIL' else 'Passed' if app.get('status') == 'PASS' else 'Investigate'
        tags = [mode, 'Application inventory', app.get('protocol') or 'Protocol unknown']
        if any(expiry(value, now)[0] == 'Expired' for value in items(app.get('credentials'))):
            tags.append('Expired credential')
        if len(items(app.get('owners'))) < 2:
            tags.append('Enterprise owner gap')
        category = 'Local app registrations' if app.get('registration') else 'External / platform applications'
        tests.append(native_result(len(tests) + 1, app.get('displayName') or app.get('appId'), result, category, tags,
            scope + app_details(app, now, by_id, by_app_id), scope + '\n### Complete application configuration\n' + evidence(app)))
    tenant = report.get('tenantEvidence') or {}
    coverage = section('Evidence coverage', ['Evidence', 'Availability', 'Records', 'Reason'], [(key, value.get('status'), len(items(value.get('items'))), value.get('reason')) for key, value in tenant.items() if isinstance(value, dict)])
    policies = (tenant.get('conditionalAccessPolicies') or {}).get('items')
    coverage += section('Conditional Access policies', ['Policy', 'State', 'Policy ID'], [(value.get('displayName'), value.get('state'), value.get('id')) for value in items(policies)])
    tests.append(native_result(len(tests) + 1, 'Tenant evidence and report scope', 'Investigate', 'Tenant evidence', [mode, 'Report scope'], scope + coverage,
        scope + '\n### Complete tenant policies, consent and log evidence\n' + evidence(tenant)))
    counts = Counter(test['Result'] for test in tests)
    blocks = []
    for category in sorted({test['Block'] for test in tests}):
        subset = [test for test in tests if test['Block'] == category]
        category_counts = Counter(test['Result'] for test in subset)
        blocks.append({'Name': category, 'Result': 'Failed' if category_counts['Failed'] else 'Investigate',
                       'TotalCount': len(subset), 'Tag': [], **{status + 'Count': category_counts[status] for status in ['Failed', 'Passed', 'Error', 'Investigate', 'Skipped', 'NotRun']}})
    return {'Result': 'Failed' if counts['Failed'] else 'Investigate', 'TotalCount': len(tests),
            **{status + 'Count': counts[status] for status in ['Failed', 'Passed', 'Error', 'Investigate', 'Skipped', 'NotRun']},
            'ExecutedAt': utc_date(report.get('generatedAtUtc')) or now.isoformat(), 'TotalDuration': '00:00:00',
            'UserDuration': '00:00:00', 'DiscoveryDuration': '00:00:00', 'FrameworkDuration': '00:00:00',
            'TenantId': report.get('tenantId'), 'TenantName': 'MichelAB · ' + mode, 'TenantLogos': None,
            'Account': None, 'CurrentVersion': {'Major': 2, 'Minor': 2, 'Build': 0, 'Revision': -1},
            'LatestVersion': 'Unknown', 'SystemInfo': {}, 'PowerShellInfo': {}, 'LoadedModules': [],
            'InvokeCommand': 'Read-only Entra application inventory adapter', 'MgContext': None,
            'PesterConfig': None, 'MaesterConfig': None, 'Tests': tests, 'Blocks': blocks,
            'EndOfJson': 'EndOfJson', 'OutputFiles': {}}


def render(report, now=None):
    now = now or datetime.now(timezone.utc)
    template = (Path(__file__).parent / 'vendor/maester-2.2.0/ReportTemplate.html').read_text(encoding='utf-8')
    sentinel = re.search(r'EndOfJson:(?:"EndOfJson"|`EndOfJson`)\}', template)
    if not sentinel:
        raise ValueError('Pinned Maester template has no result placeholder')
    assignments = list(re.finditer(r'(?:var|const|let)\s+\w+\s*=', template[:sentinel.start()]))
    if not assignments:
        raise ValueError('Pinned Maester template has no result assignment')
    payload = json.dumps(build_results(report, now), ensure_ascii=False, separators=(',', ':'))
    payload = payload.replace('<', '\\u003c').replace('>', '\\u003e').replace('\u2028', '\\u2028').replace('\u2029', '\\u2029')
    output = template[:assignments[-1].end()] + payload + template[sentinel.end():]
    output = output.replace('</head>', '<style>.prose{max-width:100%;min-width:0}.prose table{display:block;max-width:100%;overflow-x:auto}</style></head>')
    license_text = (Path(__file__).parent / 'vendor/maester-2.2.0/LICENSE').read_text(encoding='utf-8')
    return '<!-- Native Maester report UI license\n' + license_text + '\n-->\n' + output
