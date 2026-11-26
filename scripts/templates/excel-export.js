const EntraExcelColumns = ['Application', 'Notes', 'AppId', 'ServicePrincipalId', 'RegistrationId', 'OwnerSource', 'OwnerId', 'OwnerName', 'OwnerAccount', 'UserEmail', 'ContactMatchStatus'];

function EntraExcelData(tests, statistics = []) {
    const failures = tests.flatMap(test => test.ExcelRows || []).filter(row => row.Status === 'FAIL');
    const applications = tests.flatMap(test => test.ExcelAppRows || []);
    const checks = [...new Set([...statistics.map(item => item.Check), ...failures.map(row => row.Check)])].filter(Boolean).sort();
    const columns = [...EntraExcelColumns, ...checks.map(check => 'Fail: ' + check), 'ActionSummary', 'CorrectiveActions', 'Evidence'];
    const groups = new Map();
    for (const item of [...applications, ...failures]) {
        const key = JSON.stringify(EntraExcelColumns.map(column => item[column] ?? ''));
        if (!groups.has(key)) {
            groups.set(key, { ...Object.fromEntries(EntraExcelColumns.map(column => [column, item[column]])), ActionSummary: '', CorrectiveActions: '', Evidence: '' });
        }
        if (item.Check && item.Status === 'FAIL') {
            const row = groups.get(key);
            row['Fail: ' + item.Check] = 'FAIL';
            if (item.ActionSummary) row.ActionSummary += (row.ActionSummary ? '\n' : '') + (item.CheckTitle || item.Check) + ': ' + item.ActionSummary;
            if (item.CorrectiveActions) row.CorrectiveActions += (row.CorrectiveActions ? '\n' : '') + (item.CheckTitle || item.Check) + ': ' + item.CorrectiveActions;
            row.Evidence += (row.Evidence ? '\n' : '') + item.Check + ' (' + item.AppliesTo + '): ' + (item.Evidence ?? '');
        }
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
        h('p', { className: 'mb-4 text-sm', children: 'All applications are included, with one row per application and owner. Notes, failure columns, ActionSummary and CorrectiveActions can be filtered in Excel using Data → Filter. Failure columns contain FAIL or are blank for that owner source. The action columns explain what needs attention and how to fix it; Evidence keeps the collected details. For email automation, select the required failures and use a nonempty UserEmail with ContactMatchStatus MATCHED. Rows with missing notes or contacts remain visible.' }),
        h('p', { role: 'status', className: 'mb-4 text-sm', children: message || `${rows.length} application / owner rows.` }),
        rows.length ? h('div', { className: 'overflow-x-auto rounded-md border border-gray-200 dark:border-gray-700', children:
            h('table', { className: 'min-w-full border-collapse text-left text-sm text-gray-600 dark:text-gray-300', children: [
                h('thead', { className: 'bg-gray-50 text-xs text-gray-700 dark:bg-gray-800 dark:text-gray-300', children:
                    h('tr', { children: columns.map(column => h('th', { scope: 'col', className: 'border-b border-gray-200 p-2 dark:border-gray-700', children: column }, column)) })
                }),
                h('tbody', { children: rows.map((row, index) => h('tr', { className: 'border-b border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900', children:
                    columns.map(column => h('td', { className: 'min-w-40 max-w-md whitespace-normal break-words p-2', children: row[column] ?? '' }, column))
                }, index)) })
            ] })
        }) : h('p', { children: 'No applications to export.' })
    ] });
}
