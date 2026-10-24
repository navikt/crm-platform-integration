const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');

const project = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../../sfdx-project.json'), 'utf8'));

test('the shared version updater targets the integration package at packageDirectories[0]', () => {
    const target = project.packageDirectories[0];
    assert.equal(target.path, 'force-app');
    assert.equal(target.package, 'crm-platform-integration');
    assert.match(target.versionNumber, /^\d+\.\d+\.\d+\.NEXT$/);
});

test('src-temp remains the default directory without a package version', () => {
    const defaults = project.packageDirectories.filter((directory) => directory.default);
    assert.equal(defaults.length, 1);
    assert.equal(defaults[0].path, 'src-temp');
    assert.equal(Object.hasOwn(defaults[0], 'versionNumber'), false);
    assert.equal(Object.hasOwn(defaults[0], 'package'), false);
});
