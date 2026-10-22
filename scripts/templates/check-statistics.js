function EntraCheckStatistics({rows, onSelect, selection}) {
    const columns = [
        ["Check", "Check"], ["PASS", "PASS"], ["FAIL", "FAIL"],
        ["WARN", "WARN"], ["UNKNOWN", "UNKNOWN"],
        ["SKIPPED", "Excluded / disabled"], ["NOT_APPLICABLE", "Not applicable"]
    ];
    const colors = {PASS: "#10b981", FAIL: "#f43f5e", WARN: "#f59e0b", UNKNOWN: "#a855f7"};
    const choose = (check, status) => {
        onSelect(check ? { check, ...(status ? { status } : {}) } : null);
        window.requestAnimationFrame(() => document.getElementById('entra-application-results')?.scrollIntoView({ behavior: gs(), block: 'start' }));
    };
    return (0,z.jsxs)("section", {
        className: "mb-6 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 p-6",
        children: [
            (0,z.jsx)("h2", {className: "text-lg font-semibold mb-2", children: "Results by check"}),
            (0,z.jsx)("p", {className: "text-sm text-gray-500 dark:text-gray-400 mb-4", children: "Each application is counted once per check. Matching app registrations are included with their enterprise application. Report scope is excluded."}),
            onSelect && (0,z.jsxs)("div", {className: "entra-graph-controls", children: [
                (0,z.jsx)("span", {children: selection?.check ? `Filter: ${selection.check}${selection.status ? ' / ' + selection.status : ' / all results'}` : 'Select a check or result to filter the application list.'}),
                selection?.check && (0,z.jsx)("button", {type: "button", onClick: () => choose(), children: "Clear check filter"})
            ]}),
            (0,z.jsx)("div", {style: {overflowX: "auto"}, children:
                (0,z.jsxs)("table", {style: {width: "100%", textAlign: "left", borderCollapse: "collapse"}, children: [
                    (0,z.jsx)("thead", {children: (0,z.jsx)("tr", {children: columns.map(([key,label]) =>
                        (0,z.jsx)("th", {style: {padding: "10px", whiteSpace: "nowrap"}, scope: "col", children: label}, key))})}),
                    (0,z.jsx)("tbody", {children: rows.map(row =>
                        (0,z.jsx)("tr", {className: "border-t border-gray-200 dark:border-gray-700", children: columns.map(([key]) =>
                            (0,z.jsx)("td", {style: {padding: onSelect ? 0 : "10px", color: key === "Check" || !row[key] ? undefined : colors[key], fontWeight: row[key] ? 600 : undefined}, children: onSelect ? (0,z.jsx)("button", {
                                type: "button", className: "entra-check-filter",
                                "aria-label": key === "Check" ? `Show all ${row.Check} results` : `Show ${row.Check} ${key} applications (${row[key]})`,
                                "aria-pressed": selection?.check === row.Check && (key === "Check" ? !selection.status : selection.status === key),
                                onClick: () => choose(row.Check, key === "Check" ? undefined : key), children: row[key]
                            }) : row[key]}, key))}, row.Check))})
                ]})
            })
        ]
    });
}
