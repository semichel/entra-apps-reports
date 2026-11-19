const EntraExcelColumns = ['Application', 'AppId', 'ServicePrincipalId', 'RegistrationId', 'Check', 'Status', 'AppliesTo', 'Evidence', 'OwnerSource', 'OwnerId', 'OwnerName', 'OwnerAccount', 'UserEmail', 'ContactMatchStatus'];

function EntraExcelText(rows) {
    const cell = value => {
        const text = String(value ?? '').replace(/[\t\r\n]/g, ' ');
        return /^[\s]*[=+@-]/.test(text) ? "'" + text : text;
    };
    return [EntraExcelColumns, ...rows.map(row => EntraExcelColumns.map(column => row[column]))]
        .map(row => row.map(cell).join('\t')).join('\r\n');
}

function EntraExcelExport() {
    const { selectedTenant } = cs();
    const [message, setMessage] = y.useState('');
    const rows = selectedTenant.Tests.flatMap(test => test.ExcelRows || []);
    const copy = async () => {
        try {
            await navigator.clipboard.writeText(EntraExcelText(rows));
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
        h('p', { className: 'mb-4 text-sm', children: 'One row per failed check and owner of the affected object. Combined checks include owners from both objects. Filter UserEmail to nonempty values and ContactMatchStatus to MATCHED for email automation. Rows with missing contacts remain visible.' }),
        h('p', { role: 'status', className: 'mb-4 text-sm', children: message || `${rows.length} failed check / owner rows.` }),
        rows.length ? h('div', { className: 'overflow-x-auto rounded-md border border-gray-200 dark:border-gray-700', children:
            h('table', { className: 'min-w-full border-collapse text-left text-sm text-gray-600 dark:text-gray-300', children: [
                h('thead', { className: 'bg-gray-50 text-xs text-gray-700 dark:bg-gray-800 dark:text-gray-300', children:
                    h('tr', { children: EntraExcelColumns.map(column => h('th', { scope: 'col', className: 'border-b border-gray-200 p-2 dark:border-gray-700', children: column }, column)) })
                }),
                h('tbody', { children: rows.map((row, index) => h('tr', { className: 'border-b border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900', children:
                    EntraExcelColumns.map(column => h('td', { className: 'min-w-40 max-w-md whitespace-normal break-words p-2', children: row[column] ?? '' }, column))
                }, index)) })
            ] })
        }) : h('p', { children: 'No failed checks to export.' })
    ] });
}
