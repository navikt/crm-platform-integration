const assert = require('node:assert/strict');
const path = require('node:path');
const { test } = require('node:test');
const { getLauncher, main } = require('../create-scratch-org');

test('selects PowerShell and forwards PowerShell parameters on Windows', () => {
    const launcher = getLauncher('win32', ['-DryRun']);

    assert.equal(launcher.command, 'pwsh.exe');
    assert.deepEqual(launcher.args, [
        '-NoProfile',
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

test('preserves forwarded argument boundaries without modifying the caller array', () => {
    const argumentsToForward = ['-OrgAlias', 'alias with spaces', '', 'say "hello"'];
    const launcher = getLauncher('win32', argumentsToForward);

    assert.deepEqual(launcher.args.slice(-argumentsToForward.length), argumentsToForward);
    assert.deepEqual(argumentsToForward, ['-OrgAlias', 'alias with spaces', '', 'say "hello"']);
});

for (const platform of ['win32', 'darwin', 'linux']) {
    for (const helpOption of ['-Help', '--Help', '--help', '-h']) {
        test(`normalizes ${helpOption} for ${platform}`, () => {
            const launcher = getLauncher(platform, [helpOption]);

            assert.equal(launcher.args.at(-1), platform === 'win32' ? '-Help' : '--help');
        });
    }
}

test('main reports spawn errors and includes PowerShell 7 LTS guidance on Windows', () => {
    const errors = [];
    let exitCode;
    const result = main({
        platform: 'win32',
        forwardedArgs: [],
        spawn: () => ({ error: new Error('spawn failed') }),
        writeError: (message) => errors.push(message),
        setExitCode: (code) => {
            exitCode = code;
        }
    });

    assert.equal(result, 1);
    assert.equal(exitCode, 1);
    assert.match(errors.join('\n'), /Unable to start pwsh\.exe: spawn failed/);
    assert.match(errors.join('\n'), /PowerShell 7 LTS/);
});

test('main reports spawn errors without Windows guidance on other platforms', () => {
    const errors = [];
    const result = main({
        platform: 'darwin',
        forwardedArgs: [],
        spawn: () => ({ error: new Error('missing bash') }),
        writeError: (message) => errors.push(message),
        setExitCode() {}
    });

    assert.equal(result, 1);
    assert.match(errors.join('\n'), /Unable to start bash: missing bash/);
    assert.doesNotMatch(errors.join('\n'), /PowerShell 7 LTS/);
});

test('main converts a signal-terminated child status to exit code 1', () => {
    let exitCode;
    const result = main({
        platform: 'linux',
        forwardedArgs: [],
        spawn: () => ({ status: null, signal: 'SIGTERM' }),
        writeError() {},
        setExitCode: (code) => {
            exitCode = code;
        }
    });

    assert.equal(result, 1);
    assert.equal(exitCode, 1);
});

test('main propagates non-zero child status', () => {
    let exitCode;
    const result = main({
        platform: 'linux',
        forwardedArgs: [],
        spawn: () => ({ status: 7 }),
        writeError() {},
        setExitCode: (code) => {
            exitCode = code;
        }
    });

    assert.equal(result, 7);
    assert.equal(exitCode, 7);
});

test('main propagates a successful child status', () => {
    let exitCode;
    const result = main({
        platform: 'linux',
        forwardedArgs: [],
        spawn: () => ({ status: 0 }),
        writeError() {},
        setExitCode: (code) => {
            exitCode = code;
        }
    });

    assert.equal(result, 0);
    assert.equal(exitCode, 0);
});
