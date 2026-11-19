const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

async function main() {
    const rows = JSON.parse(fs.readFileSync(process.argv[2], 'utf8').replace(/^\uFEFF/, ''));
    let message, copied;
    const tenant = { Tests: [{ ExcelRows: rows }, { Result: 'Passed', ExcelRows: [] }, { Title: 'Report rules and scope' }] };
    const context = vm.createContext({
        cs: () => ({ selectedTenant: tenant }),
        y: { useState: () => ['', value => { message = value; }] },
        z: { jsx: (type, props) => ({ type, ...props }) },
        Q9: 'button',
        navigator: { clipboard: { writeText: async text => { copied = text; } } }
    });
    vm.runInContext(fs.readFileSync(path.join(__dirname, '../templates/excel-export.js'), 'utf8'), context);
    const text = context.EntraExcelText(rows);
    const lines = text.split('\r\n').map(line => line.split('\t'));
    assert.equal(lines.length, 7);
    assert.equal(lines[0].length, 14);
    assert.ok(lines.every(line => line.length === lines[0].length));
    assert.equal(lines[1][0], "'=Example");
    assert.equal(lines[1][7], 'Missing notes with a tab and text');
    assert.equal(lines[1][11], 'azadmu.owner@example.test');
    assert.equal(lines[1][12], 'owner@example.test');
    assert.equal(lines[3][12], '');
    assert.equal(lines[3][13], 'AMBIGUOUS');
    for (const value of ['=1+1', '+1', '-1', '@SUM(A1)', '  =1']) {
        assert.ok(context.EntraExcelText([{ Application: value }]).split('\r\n')[1].startsWith("'"));
    }
    assert.ok(!context.EntraExcelText([{ Application: 'normal@example.test' }]).split('\r\n')[1].startsWith("'"));
    const view = context.EntraExcelExport();
    const button = view.children[0].children[1];
    assert.equal(button.disabled, false);
    const table = view.children[3].children;
    assert.equal(table.children[1].children.length, rows.length);
    assert.equal(table.children[1].children[0].children[12].children, rows[0].UserEmail);
    await button.onClick();
    assert.equal(copied, text);
    assert.match(message, /^Copied/);
    context.navigator.clipboard.writeText = async () => { throw new Error('denied'); };
    await button.onClick();
    assert.match(message, /^Copy failed/);
    tenant.Tests = [];
    const empty = context.EntraExcelExport();
    assert.equal(empty.children[0].children[1].disabled, true);
    assert.equal(empty.children[3].children, 'No failed checks to export.');
    console.log('Excel clipboard and view checks passed.');
}

main().catch(error => { console.error(error); process.exitCode = 1; });
