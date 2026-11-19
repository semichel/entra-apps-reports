const EntraExcelColumns = ['Application', 'AppId', 'ServicePrincipalId', 'RegistrationId', 'OwnerSource', 'OwnerId', 'OwnerName', 'OwnerAccount', 'UserEmail', 'ContactMatchStatus'];

function EntraExcelData(tests, statistics = []) {
    const failures = tests.flatMap(test => test.ExcelRows || []).filter(row => row.Status === 'FAIL');
    const checks = [...new Set([...statistics.map(item => item.Check), ...failures.map(row => row.Check)])].filter(Boolean).sort();
    const columns = [...EntraExcelColumns, ...checks.map(check => 'Fail: ' + check), 'Evidence'];
    const groups = new Map();
    for (const failure of failures) {
        const key = JSON.stringify(EntraExcelColumns.map(column => failure[column] ?? ''));
        if (!groups.has(key)) {
            groups.set(key, { ...Object.fromEntries(EntraExcelColumns.map(column => [column, failure[column]])), Evidence: '' });
        }
        const row = groups.get(key);
        row['Fail: ' + failure.Check] = 'FAIL';
        row.Evidence += (row.Evidence ? '\n' : '') + failure.Check + ' (' + failure.AppliesTo + '): ' + (failure.Evidence ?? '');
    }
    return { columns, rows: [...groups.values()] };
}

function EntraExcelText(rows, columns) {
    const cell = value => {
        const text = String(value ?? '').replace(/[\t\r\n]/g, ' ');
        return /^[\s]*[=+@-]/.test(text) ? "'" + text : text;
    };
    return [columns, ...rows.map(row => columns.map(column => row[column]))]
        .map(row => row.map(cell).join('\t')).join('\r\n');
}

function EntraExcelExport() {
    const { selectedTenant } = cs();
    const [message, setMessage] = y.useState('');
    const { columns, rows } = EntraExcelData(selectedTenant.Tests, selectedTenant.CheckStatistics);
    const copy = async () => {
        try {
            await navigator.clipboard.writeText(EntraExcelText(rows, columns));
            setMessage('Copied. Paste into Excel starting at cell A1.');
        } catch {
            setMessage('Copy failed. Allow clipboard access in your browser and try again.');
        }
    };
    const h = z.jsx;
    return h('div', { children: [
        h('div', { className: 'mb-6 flex items-center justify-between', children: [
            h('h1', { className: 'text-2xl font-semibold text-gray-900 dark:text-white', children: 'Excel' }),
            h(Q9, { variant: 'primary', onClick: copy, disabled: !rows.length, children: 'Copy to Excel' })
        ] }),
        h('p', { className: 'mb-4 text-sm', children: 'One row per application and owner, keeping owner sources separate. Each check has its own Fail column containing FAIL or blank for that owner source. Paste into Excel and enable Data → Filter to filter or sort by individual failures. Evidence lists each failure and its scope. For email automation, use a nonempty UserEmail with ContactMatchStatus MATCHED. Rows with missing contacts remain visible.' }),
        h('p', { role: 'status', className: 'mb-4 text-sm', children: message || `${rows.length} application / owner rows with failed checks.` }),
        rows.length ? h('div', { className: 'overflow-x-auto rounded-md border border-gray-200 dark:border-gray-700', children:
            h('table', { className: 'min-w-full border-collapse text-left text-sm text-gray-600 dark:text-gray-300', children: [
                h('thead', { className: 'bg-gray-50 text-xs text-gray-700 dark:bg-gray-800 dark:text-gray-300', children:
                    h('tr', { children: columns.map(column => h('th', { scope: 'col', className: 'border-b border-gray-200 p-2 dark:border-gray-700', children: column }, column)) })
                }),
                h('tbody', { children: rows.map((row, index) => h('tr', { className: 'border-b border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900', children:
                    columns.map(column => h('td', { className: 'min-w-40 max-w-md whitespace-normal break-words p-2', children: row[column] ?? '' }, column))
                }, index)) })
            ] })
        }) : h('p', { children: 'No failed checks to export.' })
    ] });
}
