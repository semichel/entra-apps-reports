# Native Maester report site

ReportTemplate.html comes from the installed Maester 2.2.0 PowerShell module, the version used in C:/jobb/maester. Upstream: https://github.com/maester365/maester. See LICENSE and provenance.json.

The bundled React site is retained. The sample result payload is removed, inventory labels replace test labels, and the native advanced-details card renders as a collapsed React details element. Main application evidence stays visible in the standard Maester detail panel.

render_maester_report.py inserts the Entra inventory using the same result-placeholder boundary as Maester's Get-MtHtmlReport. This adapter collects no additional Graph data, does not invoke Maester's test suite, and does not infer business risk scores. One native report entry represents each application; a separate entry contains tenant evidence and collection scope.

ReportTemplate.md is the same installation's Actions-compatible Markdown template. Its totals table, logo, summary table and detail layout are used by write_action_summary.py, with application labels and one expandable section per entry. Status badges use Maester's report images. Raw configuration remains in the HTML artifact; the Actions summary retains application evidence and stays within GitHub's per-step size limit.
