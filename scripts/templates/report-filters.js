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
        const separator = tag.lastIndexOf(": ");
        return separator >= 0 && allowed.has(tag.slice(separator + 2));
    }));
    return [...new Set(tags)].sort();
}
