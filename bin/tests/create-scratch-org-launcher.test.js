const assert = require('node:assert/strict');
const path = require('node:path');
const { test } = require('node:test');
const { getLauncher } = require('../create-scratch-org');

test('selects PowerShell and forwards PowerShell parameters on Windows', () => {
    const launcher = getLauncher('win32', ['-DryRun']);

    assert.equal(launcher.command, 'powershell.exe');
    assert.deepEqual(launcher.args, [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        path.resolve(__dirname, '../create-scratch-org.ps1'),
        '-DryRun'
    ]);
});

test('selects Bash and forwards arguments on macOS', () => {
    const launcher = getLauncher('darwin', ['--dry-run']);

    assert.equal(launcher.command, 'bash');
    assert.deepEqual(launcher.args, [path.resolve(__dirname, '../create-scratch-org.sh'), '--dry-run']);
});

for (const platform of ['win32', 'darwin', 'linux']) {
    for (const helpOption of ['-Help', '--Help', '--help', '-h']) {
        test(`normalizes ${helpOption} for ${platform}`, () => {
            const launcher = getLauncher(platform, [helpOption]);

            assert.equal(launcher.args.at(-1), platform === 'win32' ? '-Help' : '--help');
        });
    }
}
