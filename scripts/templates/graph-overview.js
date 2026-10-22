// Uses the report's existing React runtime, chart and navigation components.
function EntraSeverityChart({ Tests = [], Description = 'Observed access and configuration findings. Highest matching risk rule wins.', onSelect, TargetId = 'entra-application-results' }) {
    const [visible, setVisible] = y.useState(['Passed', 'Failed', 'Investigate', 'Skipped']);
    const statuses = ['Passed', 'Failed', 'Investigate', 'Skipped'];
    const rows = ['Critical', 'High', 'Medium', 'Low', 'Info'].map(name => {
        const row = { name, Passed: 0, Failed: 0, Investigate: 0, Skipped: 0 };
        Tests.filter(test => test.GraphAccess && test.Severity === name).forEach(test => {
            if (statuses.includes(test.Result)) row[test.Result]++;
        });
        return row;
    });
    const choose = value => {
        if (!onSelect) return;
        if (value && !rows.some(row => row.name === value.name && statuses.some(status => row[status] > 0))) return;
        onSelect(value ? { severity: value.name } : null);
        window.requestAnimationFrame(() => document.getElementById(TargetId)?.scrollIntoView({ behavior: gs(), block: 'start' }));
    };
    const maxCount = Math.max(1, ...rows.map(row => visible.reduce((sum, status) => sum + row[status], 0)));
    const seriesColors = { Passed: '#10b981', Failed: '#f43f5e', Investigate: '#8b5cf6', Skipped: '#94a3b8' };
    return z.jsxs(t1, { children: [
        z.jsx(D0, { children: 'By severity' }),
        z.jsx('p', { className: 'text-sm text-gray-500 dark:text-gray-400', children: Description }),
        z.jsx('div', { className: 'entra-graph-controls', children: statuses.map(status => z.jsxs('label', { children: [
            z.jsx('input', { type: 'checkbox', checked: visible.includes(status), onChange: event => setVisible(event.target.checked ? [...visible, status] : visible.filter(value => value !== status)) }), status
        ] }, status)) }),
        z.jsx('div', { className: 'entra-severity-rows', children: rows.map(row => {
            const total = statuses.reduce((sum, status) => sum + row[status], 0);
            return z.jsxs('button', { type: 'button', className: 'entra-severity-row', disabled: !onSelect || !total, onClick: () => choose({ name: row.name }), 'aria-label': `Show all ${row.name} applications (${total})`, title: statuses.map(status => `${status}: ${row[status]}`).join(' · '), children: [
                z.jsx('span', { children: row.name }),
                z.jsx('span', { className: 'entra-severity-track', 'aria-hidden': true, children: visible.map(status => z.jsx('span', { className: 'entra-severity-segment', 'data-status': status, 'data-count': row[status], style: { width: `${100 * row[status] / maxCount}%`, backgroundColor: seriesColors[status] } }, status)) }),
                z.jsx('strong', { children: total })
            ] }, row.name);
        }) }),
        onSelect ? z.jsxs('div', { className: 'entra-graph-controls', children: [
            z.jsx('span', { children: 'Select anywhere in a severity row to show all its applications, across all statuses.' }),
            z.jsx('button', { type: 'button', onClick: () => choose(null), children: 'Clear severity filter' })
        ] }) : null,
        z.jsx(kn, { to: '/graph', className: 'text-sm underline', children: 'View access and ranking rules' })
    ] });
}

function EntraGraphAccessChart({ Tests = [] }) {
    const counts = { 'Write / action': 0, 'Other granted': 0, 'Unresolved grants': 0, 'Requested / unverified': 0, 'Grant evidence missing': 0 };
    let noObservedAccess = 0;
    Tests.forEach(test => {
        const access = test.GraphAccess;
        const grants = access.permissions.filter(item => item.state === 'Granted');
        if (grants.some(item => item.isWrite)) counts['Write / action']++;
        else if (grants.some(item => !item.resolved)) counts['Unresolved grants']++;
        else if (grants.length) counts['Other granted']++;
        else if (test.ServicePrincipalId && access.grantStatus !== 'AVAILABLE') counts['Grant evidence missing']++;
        else if (access.permissions.length) counts['Requested / unverified']++;
        else noObservedAccess++;
    });
    const rows = Object.entries(counts).map(([name, Applications]) => ({ name, Applications }));
    return z.jsxs(t1, { children: [
        z.jsx(D0, { children: 'Graph access distribution' }),
        z.jsx('p', { className: 'text-sm text-gray-500 dark:text-gray-400', children: 'Tenant totals. Each application is counted once; granted write/action access takes precedence.' }),
        z.jsx(aP, { className: 'mt-4 h-60', data: rows, index: 'name', categories: ['Applications'], colors: ['blue'], layout: 'vertical', yAxisWidth: 155, showAnimation: true, showLegend: false, allowDecimals: false }),
        z.jsx('ul', { className: 'entra-graph-chart-counts', children: rows.map(row => z.jsx('li', { children: `${row.name}: ${row.Applications}` }, row.name)) }),
        z.jsx('p', { className: 'text-sm text-gray-500 dark:text-gray-400', children: `${noObservedAccess} applications have no observed Graph permissions and are outside these bars. Directory roles are counted separately. Requested access is not a verified grant; other granted access is not necessarily harmless.` })
    ] });
}

function EntraGraphOverview() {
    const { selectedTenant: report } = cs();
    const [search, setSearch] = y.useState('');
    const [kind, setKind] = y.useState('all');
    const [permission, setPermission] = y.useState('');
    const [severity, setSeverity] = y.useState('');
    const [page, setPage] = y.useState(0);
    const [status, setStatus] = y.useState('');
    const h = z.jsx;
    const apps = (report.Tests || []).filter(test => test.GraphAccess);
    const hasAccess = test => test.GraphAccess.permissions.length || test.GraphAccess.roles.length;
    const writes = test => test.GraphAccess.permissions.some(item => item.state === 'Granted' && item.isWrite);
    const permissionNames = [...new Set(apps.flatMap(test => test.GraphAccess.permissions.map(item => item.permission)))].sort();
    const matchesKind = item => kind === 'all' || (kind === 'granted' ? item.state === 'Granted' : kind === 'requested' ? item.state !== 'Granted' : kind === 'write' ? item.state === 'Granted' && item.isWrite : false);
    const query = search.trim().toLowerCase();
    const matchingPermissions = test => test.GraphAccess.permissions.filter(item => matchesKind(item) && (!permission || item.permission === permission));
    const filtered = apps.filter(test => {
        const access = test.GraphAccess;
        if (severity && test.Severity !== severity) return false;
        if (status && test.Result !== status) return false;
        if (permission && !access.permissions.some(item => item.permission === permission)) return false;
        if (kind === 'gaps') { if (!access.coverageGaps.length) return false; }
        else if (kind === 'roles') { if (!access.roles.length) return false; }
        else if ((kind !== 'all' || permission) && !matchingPermissions(test).length) return false;
        else if (kind === 'all' && !permission && !hasAccess(test)) return false;
        return !query || [test.Title, test.AppId, test.ServicePrincipalId, ...access.permissions.map(item => item.permission), ...access.roles.map(item => item.roleDefinition?.displayName || item.roleDefinitionId)].join(' ').toLowerCase().includes(query);
    });
    const pageSize = 25;
    const lastPage = Math.max(0, Math.ceil(filtered.length / pageSize) - 1);
    const currentPage = Math.min(page, lastPage);
    const update = setter => event => { setter(event.target.value); setPage(0); };
    const selectSeverity = selection => {
        setSeverity(selection?.severity || ''); setStatus('');
        setSearch(''); setKind('all'); setPermission(''); setPage(0);
    };
    const select = (label, value, setter, options) => h('label', { children: [label, h('select', { value, onChange: update(setter), children: options.map(([value, text]) => h('option', { value, children: text }, value)) })] }, label);
    const table = (headers, rows) => h('div', { className: 'entra-graph-table', children: h('table', { children: [
        h('thead', { children: h('tr', { children: headers.map(text => h('th', { scope: 'col', children: text }, text)) }) }),
        h('tbody', { children: rows.map((row, index) => h('tr', { children: row.map((value, cell) => h('td', { children: value || '—' }, cell)) }, index)) })
    ] }) });
    const gapCount = apps.filter(test => test.GraphAccess.coverageGaps.length).length;
    return h('section', { className: 'entra-graph', children: [
        h('h1', { className: 'text-2xl font-semibold tracking-tight text-gray-900 dark:text-gray-100', children: 'Graph overview' }),
        h('p', { children: 'Microsoft Graph permissions and direct active Entra directory roles for applications in this report.' }),
        h('div', { className: 'entra-graph-stats', children: [
            ['Applications with Graph access / directory roles', apps.filter(hasAccess).length],
            ['Granted Graph write / action access', apps.filter(writes).length],
            ['Applications with active directory roles', apps.filter(test => test.GraphAccess.roles.length).length],
            ['Applications with evidence gaps', gapCount]
        ].map(([label, count]) => h(t1, { children: [h('strong', { children: count }), h('span', { children: label })] }, label)) }),
        h('div', { className: 'entra-graph-charts', children: [
            h(EntraGraphAccessChart, { Tests: apps }),
            h(EntraSeverityChart, { Tests: apps.filter(hasAccess), Description: 'Tenant totals for applications with observed Graph permissions or directory roles. Includes their configuration findings.', onSelect: selectSeverity, TargetId: 'entra-graph-results' })
        ] }),
        h(t1, { children: [
            h('h2', { className: 'font-semibold', children: 'Scope and ranking rules' }),
            h('p', { children: 'Granted application access comes from servicePrincipal.appRoleAssignments. Requested permissions come from application.requiredResourceAccess. Delegated consent is not collected, so requested delegated permissions are never counted as verified grants. Read-only permission-name matches are not a guarantee that access is harmless.' }),
            h('p', { children: `Directory role evidence: ${report.DirectoryRoleCoverage?.status || 'NOT_COLLECTED'}. RoleManagement.Read.Directory is required. Only direct active service-principal assignments are collected; group inheritance, PIM eligibility and Azure RBAC are outside this view.` }),
            table(['Severity', 'Basic exposure rule'], [
                ['Critical', 'Granted RoleManagement.ReadWrite.Directory or AppRoleAssignment.ReadWrite.All; or active Global Administrator / Privileged Role Administrator.'],
                ['High', 'Any other granted Graph write/action permission, or any other direct active Entra directory role (conservative ranking, including reader roles).'],
                ['High', 'Failed certificate date policy or redirect URL security check.'],
                ['Medium', 'Requested Graph write/action access without a verified grant, or unresolved permission names.'],
                ['Medium', 'Other failed or UNKNOWN checks; secret, credential-date, implicit-flow or owner-match warnings. UNKNOWN indicates incomplete evidence, not a confirmed vulnerability.'],
                ['Low', 'Granted Graph permissions without a write/action name match.'],
                ['Low', 'Other warnings, including empty Notes.'],
                ['Info', 'No ranked access or configuration findings observed. Evidence gaps remain visible; this is not a clean bill of health.']
            ]),
            h('p', { children: 'The highest matching severity wins. These basic exposure rules do not change configuration Pass/Fail results. Write/action classification matches known operation names such as ReadWrite, Write, Create, Delete, Send, Manage and PrivilegedOperations; it is not a complete effective-access analysis.' })
        ] }),
        h('div', { id: 'entra-graph-results', className: 'entra-graph-controls', children: [
            h('label', { children: ['Search', h('input', { type: 'search', value: search, placeholder: 'Application, appId, permission or role', onChange: update(setSearch) })] }),
            select('Access', kind, setKind, [['all', 'All observed access'], ['granted', 'Granted application permissions'], ['write', 'Granted write / action'], ['requested', 'Requested without verified grant'], ['roles', 'Directory roles'], ['gaps', 'Evidence gaps']]),
            select('Permission', permission, setPermission, [['', 'All permissions'], ...permissionNames.map(name => [name, name])]),
            select('Severity', severity, setSeverity, [['', 'All severities'], ...['Critical', 'High', 'Medium', 'Low', 'Info'].map(value => [value, value])]),
            select('Status', status, setStatus, [['', 'All statuses'], ...['Passed', 'Failed', 'Investigate', 'Skipped'].map(value => [value, value])])
        ] }),
        h('p', { role: 'status', children: `${filtered.length} matching applications. Showing ${filtered.length ? currentPage * pageSize + 1 : 0}–${Math.min(filtered.length, (currentPage + 1) * pageSize)}.` }),
        ...filtered.slice(currentPage * pageSize, (currentPage + 1) * pageSize).map(test => {
            const access = test.GraphAccess;
            const permissions = kind === 'roles' || kind === 'gaps' ? access.permissions.filter(item => !permission || item.permission === permission) : matchingPermissions(test);
            return h('details', { children: [
                h('summary', { children: [h('strong', { children: test.Title }), h('span', { className: 'entra-risk-badge', 'data-severity': test.Severity, children: test.Severity }), h('span', { children: `${access.permissions.length} Graph permissions · ${access.roles.length} directory roles` }), access.coverageGaps.length ? h('span', { children: 'Evidence incomplete' }) : null, h('small', { children: `appId: ${test.AppId || 'Not available'}` })] }),
                h('p', { children: access.reasons.join(' ') }),
                ...access.coverageGaps.map(message => h('p', { className: 'entra-graph-gap', children: message }, message)),
                h(kn, { to: { pathname: '/', hash: hs(ms(test)) }, className: 'underline', children: 'Open full application details' }),
                h('h3', { className: 'font-semibold', children: 'Microsoft Graph permissions' }),
                permissions.length ? table(['Permission', 'Type', 'Grant evidence', 'Write / action name match', 'Source'], permissions.map(item => [item.permission, item.type, item.state, item.resolved ? item.isWrite ? 'Yes' : 'No' : 'Unresolved', item.source])) : h('p', { children: 'No matching Graph permissions in the collected evidence.' }),
                h('h3', { className: 'font-semibold', children: 'Entra directory roles' }),
                access.roles.length ? table(['Role', 'Role definition ID', 'Directory scope', 'App scope'], access.roles.map(item => [item.roleDefinition?.displayName || item.roleDefinitionId, item.roleDefinitionId, item.directoryScopeId, item.appScopeId])) : h('p', { children: access.roleStatus === 'AVAILABLE' ? 'No direct active assignments observed.' : `Evidence: ${access.roleStatus}` })
            ] }, test.Id);
        }),
        h('div', { className: 'entra-graph-controls', children: [
            h('button', { type: 'button', disabled: currentPage === 0, onClick: () => setPage(currentPage - 1), children: 'Previous' }),
            h('span', { children: `Page ${currentPage + 1} of ${lastPage + 1}` }),
            h('button', { type: 'button', disabled: currentPage >= lastPage, onClick: () => setPage(currentPage + 1), children: 'Next' })
        ] })
    ] });
}
