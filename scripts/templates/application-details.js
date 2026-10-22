// Keep the original Markdown exports; use the same content in separate object panels.
function EntraMarkdownPreview({ text }) {
    const limit = 65536;
    let preview = text.slice(0, limit);
    if (text.length > limit && preview.lastIndexOf('\n') > 0) preview = preview.slice(0, preview.lastIndexOf('\n'));
    return z.jsxs(z.Fragment, { children: [
        text.length > limit ? z.jsx('p', { role: 'status', className: 'mb-4 text-sm', children: 'Preview limited to the first 64K characters to keep large reports responsive. The Markdown source and Copy Markdown still contain the complete report.' }) : null,
        z.jsx(J5, { remarkPlugins: [S7], children: preview })
    ] });
}

function EntraEvidenceTable({ node, children, ...props }) {
    const text = item => item?.type === 'text' ? item.value : (item?.children || []).map(text).join('');
    const header = node.children.find(item => item.tagName === 'thead')?.children.find(item => item.tagName === 'tr');
    const headers = (header?.children || []).filter(item => item.tagName === 'th').map(text);
    const statusIndex = headers.findIndex(value => value === 'Observation' || value === 'Policy observation');
    if (statusIndex < 0) return z.jsx('table', { ...props, children });
    const rows = (node.children.find(item => item.tagName === 'tbody')?.children || []).filter(item => item.tagName === 'tr');
    let index = 0;
    const content = y.Children.map(children, group => {
        if (!y.isValidElement(group) || group.type !== 'tbody') return group;
        return y.cloneElement(group, {}, y.Children.map(group.props.children, row => {
            if (!y.isValidElement(row) || row.type !== 'tr') return row;
            const cells = (rows[index++]?.children || []).filter(item => item.tagName === 'td');
            const status = text(cells[statusIndex]).trim().replace(/^[^A-Z]+/, '');
            return y.cloneElement(row, { 'data-check-status': ['FAIL', 'WARN', 'PASS', 'UNKNOWN', 'SKIPPED', 'NOT_APPLICABLE'].includes(status) ? status : undefined });
        }));
    });
    return z.jsx('table', { ...props, children: content });
}

function EntraApplicationDetails({ Item, fallback }) {
    const h = z.jsx;
    const panels = Item.ApplicationPanels;
    const markdown = value => h('div', { className: 'prose dark:prose-invert entra-detail-markdown', children: h(J5, { remarkPlugins: [S7], components: { table: EntraEvidenceTable }, children: value }) });
    const identifiers = objectId => h('dl', { className: 'entra-object-identifiers', children: [
        h('dt', { children: 'Object ID' }), h('dd', { children: h('code', { children: objectId || 'Not collected' }) }),
        h('dt', { children: 'Application (client) ID / appId' }), h('dd', { children: h('code', { children: Item.AppId || 'Not collected' }) })
    ] });
    if (!panels) return markdown(fallback);
    return h('div', { className: 'entra-application-details', children: [
        panels.failures ? h('section', { className: 'entra-object-panel entra-failed-checks', 'aria-label': 'Failed checks', children: markdown(panels.failures) }) : null,
        h('div', { className: 'entra-object-columns', children: [
            h('section', { className: 'entra-object-panel', 'aria-label': 'Enterprise application / SPN', children: [
                h('h2', { className: 'entra-object-title', children: 'Enterprise application / SPN' }),
                identifiers(Item.ServicePrincipalId),
                markdown(panels.servicePrincipal)
            ] }),
            h('section', { className: 'entra-object-panel', 'aria-label': 'App registration', children: [
                h('h2', { className: 'entra-object-title', children: 'App registration' }),
                identifiers(Item.RegistrationId),
                markdown(panels.registration)
            ] })
        ] }),
        h('section', { className: 'entra-object-panel entra-combined-assessment', 'aria-label': 'Combined assessment', children: [
            h('h2', { className: 'entra-object-title', children: 'Combined assessment' }),
            markdown(panels.shared)
        ] })
    ] });
}
