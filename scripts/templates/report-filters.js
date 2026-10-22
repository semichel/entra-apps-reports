// Tag options follow the other filters; selected tags do not limit their own options.
function EntraAvailableTags(entries, statuses, categories, severities, matchesSearch, restrictCheckStatus) {
    const checkStatuses = {
        Passed: ["PASS"], Failed: ["FAIL"], Investigate: ["WARN", "UNKNOWN"],
        Skipped: ["SKIPPED"], NotRun: ["NOT_APPLICABLE"], Error: ["UNKNOWN"]
    };
    const allowed = new Set(statuses.flatMap(status => checkStatuses[status] || []));
    const tags = entries.filter(entry =>
        (!statuses.length || statuses.includes(entry.Result)) &&
        (!categories.length || categories.includes(entry.Block)) &&
        (!severities.length || severities.includes(entry.Severity || "None")) &&
        matchesSearch(entry)
    ).flatMap(entry => (entry.Tag || []).filter(tag => {
        if (!restrictCheckStatus) return true;
        if (tag.startsWith('Requested permission: ') || tag.startsWith('Granted permission: ') || tag.startsWith('Graph access: ')) return true;
        const separator = tag.lastIndexOf(": ");
        return separator >= 0 && allowed.has(tag.slice(separator + 2));
    }));
    return [...new Set(tags)].sort();
}

// Statistics selections narrow the data, without sorting or depending on overall app status.
function EntraFilterApplications(entries, selection) {
    if (!selection?.severity && !selection?.check) return entries;
    return entries.filter(entry => entry.GraphAccess &&
        (!selection.severity || entry.Severity === selection.severity) &&
        (!selection.check || (entry.Tag || []).some(tag => selection.status ? tag === `${selection.check}: ${selection.status}` : tag.startsWith(`${selection.check}: `)))
    );
}
