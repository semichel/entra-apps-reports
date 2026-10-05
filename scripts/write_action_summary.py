"""Render the pinned Maester Markdown layout on the GitHub Actions Summary page."""

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

from publish_report import cell
from render_maester_report import build_results


def status_badge(status):
    names = {'Passed': 'pass', 'Failed': 'fail', 'Skipped': 'notrun', 'NotRun': 'notrun', 'Error': 'fail'}
    if status == 'Investigate':
        return '🔍 Investigate'
    return f'<img src="https://maester.dev/img/test-result/pill-{names[status]}.png" height="25" alt="{status}"/>'


def render(report, artifact_url):
    results = build_results(report, datetime.now(timezone.utc))
    tests = results['Tests']
    summary = ['| Application / report entry | Severity | Status |', '|---|:---:|:---:|']
    details = []
    icons = {'Passed': '✅', 'Failed': '❌', 'Investigate': '🔍'}
    for test in tests:
        title = cell(test['Title'])
        badge = status_badge(test['Result'])
        summary.append(f'| {test["Id"]}: {title} | ⚪ Info | {badge} |')
        content = test['ResultDetail']['TestResult']
        # Collection scope is shown once above the result list, rather than repeated for every app.
        content = content[content.index('\n### '):].replace('\n### ', '\n#### ')
        details.append(f'<details>\n<summary><strong>{icons[test["Result"]]} {test["Id"]}: {title}</strong></summary>\n\n'
                       f'{badge}\n\n#### Overview\n\n'
                       f'**Category:** {cell(test["Block"])}  \n**Tags:** {cell(", ".join(test["Tag"]))}\n\n'
                       f'#### Application evidence\n\n{content}\n\n'
                       'Full raw configuration is available in the HTML report artifact.\n\n</details>\n')
    template = (Path(__file__).parent / 'vendor/maester-2.2.0/ReportTemplate.md').read_text(encoding='utf-8')
    values = {'TenantName': cell(results['TenantName']), 'TestDate': cell(results['ExecutedAt']) + ' (UTC)',
              'ModuleVersion': '2.2.0', 'TestSummary': '\n'.join(summary), 'TestDetails': '\n'.join(details)}
    values.update({key: str(results[key]) for key in ['TotalCount', 'PassedCount', 'FailedCount',
                  'InvestigateCount', 'SkippedCount', 'NotRunCount']})
    for key, value in values.items():
        template = template.replace('%' + key + '%', value)
    introduction = (f'**Tenant ID:** {cell(report.get("tenantId"))}\n\n'
                    f'**{len(report.get("applications") or [])} enterprise applications · '
                    f'{len(report.get("registrations") or [])} local registrations.** '
                    'Report totals also include one tenant evidence entry.\n\n'
                    '**Failed** means recorded configuration findings; these are inventory observations. '
                    '**Info** is the entry classification, not a business risk score.\n\n'
                    'Manual authentication validation and policy applicability review remain required. '
                    f'Expiry calculations UTC: {datetime.now(timezone.utc).isoformat()}.\n\n'
                    f'[Download the interactive HTML report and JSON/CSV evidence]({artifact_url}). '
                    'Extract the artifact and open report.html.\n\n')
    if report.get('mode') == 'SNAPSHOT':
        introduction += '**SNAPSHOT:** This run renders previously collected real tenant data; no fresh Entra query was made.\n\n'
    template = template.replace('## Application summary', introduction + '## Application summary', 1)
    if len(template.encode('utf-8')) >= 1024 * 1024:
        raise ValueError("Summary exceeds GitHub's 1 MiB per-step limit; split it before publishing")
    return template


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('--artifact-url', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    report = json.loads(args.report.read_text(encoding='utf-8-sig'))
    args.output.write_text(render(report, args.artifact_url), encoding='utf-8')
