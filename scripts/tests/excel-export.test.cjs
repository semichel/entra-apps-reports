const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

async function main() {
    const { failures: rows, applications, passed } = JSON.parse(fs.readFileSync(process.argv[2], 'utf8').replace(/^\uFEFF/, ''));
    let message, copied;
    const tenant = {
        Tests: [{ ExcelRows: rows, ExcelAppRows: applications }, { Result: 'Passed', ExcelRows: [], ExcelAppRows: passed }, { Title: 'Report rules and scope' }],
        CheckStatistics: ['RegistrationAdminOwner', 'Notes', 'CredentialDates', 'Assignments'].map(Check => ({ Check }))
    };
    const context = vm.createContext({
        cs: () => ({ selectedTenant: tenant }),
        y: { useState: () => ['', value => { message = value; }] },
        z: { jsx: (type, props) => ({ type, ...props }) },
        Q9: 'button',
        navigator: { clipboard: { writeText: async text => { copied = text; } } }
    });
    vm.runInContext(fs.readFileSync(path.join(__dirname, '../templates/excel-export.js'), 'utf8'), context);
    const data = context.EntraExcelData(tenant.Tests, tenant.CheckStatistics);
    assert.equal(data.rows.length, 4);
    assert.equal(data.rows[0].Notes, 'First line\nSecond\tline – äö');
    assert.equal(data.rows[3].Notes, 'Notes for an app without failures');
    assert.ok(data.columns.filter(column => column.startsWith('Fail: ')).every(column => data.rows[3][column] === undefined));
    const onlyPassed = context.EntraExcelData([tenant.Tests[1]], tenant.CheckStatistics);
    assert.equal(onlyPassed.rows.length, 1);
    assert.equal(onlyPassed.rows[0].UserEmail, 'owner@example.test');
    const withoutNotes = context.EntraExcelData([{ ExcelAppRows: [{ ...passed[0], Notes: null }] }], tenant.CheckStatistics);
    assert.equal(withoutNotes.rows.length, 1);
    assert.equal(withoutNotes.rows[0].Notes, null);
    assert.equal(data.rows[0]['Fail: Notes'], 'FAIL');
    assert.equal(data.rows[0]['Fail: CredentialDates'], 'FAIL');
    assert.equal(data.rows[0]['Fail: RegistrationAdminOwner'], undefined);
    assert.equal(data.rows[1]['Fail: RegistrationAdminOwner'], 'FAIL');
    assert.equal(data.rows[1]['Fail: CredentialDates'], 'FAIL');
    assert.equal(data.rows[1]['Fail: Notes'], undefined);
    assert.ok(data.columns.includes('Fail: Assignments'));
    assert.ok(data.rows.every(row => row['Fail: Assignments'] === undefined));
    assert.match(data.rows[0].Evidence, /Notes \(Enterprise application \/ SPN\): Missing notes/);
    assert.match(data.rows[0].Evidence, /CredentialDates \(Both \/ combined\): Expired certificate/);
    const otherApp = { ...rows[0], AppId: 'client-2', Check: 'Assignments' };
    const acrossApps = context.EntraExcelData([{ ExcelRows: [...rows, otherApp, { ...otherApp, Status: 'WARN' }] }], tenant.CheckStatistics);
    assert.equal(acrossApps.rows.length, 4);
    assert.equal(acrossApps.rows[3]['Fail: Assignments'], 'FAIL');
    assert.equal(acrossApps.rows[3]['Fail: Notes'], undefined);
    assert.equal(JSON.stringify(acrossApps.columns), JSON.stringify(data.columns));
    const text = context.EntraExcelText(data.rows, data.columns);
    const lines = text.split('\r\n').map(line => line.split('\t'));
    const value = (row, column) => lines[row][lines[0].indexOf(column)];
    assert.equal(lines.length, 5);
    assert.equal(lines[0].length, 18);
    assert.ok(data.columns.includes('ActionSummary'));
    assert.ok(data.columns.includes('CorrectiveActions'));
    const actionData = context.EntraExcelData([{ ExcelRows: [{ ...rows[0], CheckTitle: 'Friendly title', ActionSummary: 'Missing configuration', CorrectiveActions: '1. Open app\n2. Save' }] }], tenant.CheckStatistics);
    assert.match(actionData.rows[0].ActionSummary, /Friendly title: Missing configuration/);
    assert.match(actionData.rows[0].CorrectiveActions, /Friendly title: 1\. Open app\n2\. Save/);
    assert.ok(lines.every(line => line.length === lines[0].length));
    assert.equal(lines[1][0], "'=Example");
    assert.equal(value(1, 'Notes'), 'First line Second line – äö');
    assert.equal(value(4, 'Notes'), 'Notes for an app without failures');
    assert.equal(value(4, 'Fail: Notes'), '');
    assert.match(value(1, 'Evidence'), /Missing notes with a tab and text/);
    assert.equal(value(1, 'OwnerAccount'), 'azadmu.owner@example.test');
    assert.equal(value(1, 'UserEmail'), 'owner@example.test');
    assert.equal(value(3, 'UserEmail'), '');
    assert.equal(value(3, 'ContactMatchStatus'), 'AMBIGUOUS');
    assert.equal(value(1, 'Fail: Notes'), 'FAIL');
    assert.equal(value(1, 'Fail: RegistrationAdminOwner'), '');
    assert.equal(value(2, 'Fail: Notes'), '');
    assert.equal(value(2, 'Fail: RegistrationAdminOwner'), 'FAIL');
    for (const value of ['=1+1', '+1', '-1', '@SUM(A1)', '  =1']) {
        assert.ok(context.EntraExcelText([{ Application: value }], ['Application']).split('\r\n')[1].startsWith("'"));
    }
    assert.ok(!context.EntraExcelText([{ Application: 'normal@example.test' }], ['Application']).split('\r\n')[1].startsWith("'"));
    assert.equal(context.EntraExcelText([{ Notes: '=1+1' }], ['Notes']).split('\r\n')[1], "'=1+1");
    const view = context.EntraExcelExport();
    const button = view.children[0].children[1];
    assert.equal(button.disabled, false);
    const table = view.children[3].children;
    assert.equal(table.children[1].children.length, data.rows.length);
    assert.equal(table.children[1].children[0].children[data.columns.indexOf('UserEmail')].children, rows[0].UserEmail);
    await button.onClick();
    assert.equal(copied, text);
    assert.match(message, /^Copied/);
    context.navigator.clipboard.writeText = async () => { throw new Error('denied'); };
    await button.onClick();
    assert.match(message, /^Copy failed/);
    tenant.Tests = [];
    const empty = context.EntraExcelExport();
    assert.equal(empty.children[0].children[1].disabled, true);
    assert.equal(empty.children[3].children, 'No applications to export.');
    console.log('Excel clipboard and view checks passed.');
}

main().catch(error => { console.error(error); process.exitCode = 1; });
