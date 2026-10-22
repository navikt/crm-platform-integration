const assert = require('node:assert/strict');
const { spawnSync, execFileSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');

const script = path.resolve(__dirname, '../pre-commit.cjs');

function fixture(t) {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'pre-commit test-'));
    t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const git = (...args) =>
        execFileSync('git', ['-c', `core.hooksPath=${path.join(directory, 'no-hooks')}`, ...args], {
            cwd: directory,
            encoding: 'utf8'
        });
    const write = (name, content) => {
        const target = path.join(directory, name);
        fs.mkdirSync(path.dirname(target), { recursive: true });
        fs.writeFileSync(target, content);
    };
    git('init', '--quiet');
    write(
        'sfdx-project.json',
        JSON.stringify({
            packageDirectories: [{ path: 'force-app' }, { path: 'reference.package' }, { path: 'reference space' }]
        })
    );
    write(
        'node_modules/lint-staged/package.json',
        JSON.stringify({ name: 'lint-staged', exports: { './bin': './cli.cjs' } })
    );
    write(
        'node_modules/lint-staged/cli.cjs',
        `
        require('node:fs').writeFileSync('lint-staged-ran', 'yes');
        process.exit(Number(process.env.FIXTURE_LINT_EXIT || 0));
    `
    );
    const run = (env = {}) =>
        spawnSync(process.execPath, [script], {
            cwd: directory,
            encoding: 'utf8',
            env: { ...process.env, ALLOW_PACKAGE_DIR_COMMIT: '0', ...env }
        });
    return { directory, git, write, run, lintRan: () => fs.existsSync(path.join(directory, 'lint-staged-ran')) };
}

test('allows main-package and documentation files and runs the local lint-staged CLI', (t) => {
    const f = fixture(t);
    f.write('force-app/file with spaces.txt', 'fixture');
    f.write('docs/readme.md', 'fixture');
    f.git('add', 'force-app', 'docs');
    const result = f.run();
    assert.equal(result.status, 0, result.stderr);
    assert.equal(f.lintRan(), true);
});

for (const name of [
    'reference.package/file.txt',
    'reference space/file with spaces.txt',
    'reference.package/line\nbreak.txt'
]) {
    test(
        `blocks a staged dependency file: ${JSON.stringify(name)}`,
        { skip: process.platform === 'win32' && name.includes('\n') },
        (t) => {
            const f = fixture(t);
            f.write(name, 'fixture');
            f.git('add', '--', name);
            const result = f.run();
            assert.equal(result.status, 1, result.stderr);
            assert.match(result.stderr, /Commit blokkert/);
            assert.ok(result.stderr.includes(name));
            assert.equal(f.lintRan(), false);
        }
    );
}

test('does not interpret package paths as regular expressions or partial directory names', (t) => {
    const f = fixture(t);
    f.write('referenceXpackage/file.txt', 'fixture');
    f.write('reference.package-extra/file.txt', 'fixture');
    f.git('add', '.');
    const result = f.run();
    assert.equal(result.status, 0, result.stderr);
    assert.equal(f.lintRan(), true);
});

test('explicit package override still runs lint-staged', (t) => {
    const f = fixture(t);
    f.write('reference.package/file.txt', 'fixture');
    f.git('add', 'reference.package');
    assert.equal(f.run({ ALLOW_PACKAGE_DIR_COMMIT: '1' }).status, 0);
    assert.equal(f.lintRan(), true);
});

test('propagates lint-staged failure to Git', (t) => {
    const f = fixture(t);
    assert.equal(f.run({ FIXTURE_LINT_EXIT: '7' }).status, 7);
    assert.equal(f.lintRan(), true);
});

for (const configuration of [
    'invalid JSON',
    '{}',
    '{"packageDirectories": "invalid"}',
    '{"packageDirectories": [{}]}'
]) {
    test(`fails explicitly on invalid configuration: ${configuration}`, (t) => {
        const f = fixture(t);
        f.write('sfdx-project.json', configuration);
        const result = f.run();
        assert.equal(result.status, 1);
        assert.match(result.stderr, /Feil:/);
        assert.equal(f.lintRan(), false);
    });
}

test('allows an empty dependency list', (t) => {
    const f = fixture(t);
    f.write('sfdx-project.json', '{"packageDirectories": []}');
    assert.equal(f.run().status, 0);
    assert.equal(f.lintRan(), true);
});

test('normalizes configured directory separators and trailing slashes', (t) => {
    const f = fixture(t);
    f.write('sfdx-project.json', JSON.stringify({ packageDirectories: [{ path: '.\\reference.package\\' }] }));
    f.write('reference.package/file.txt', 'fixture');
    f.git('add', 'reference.package');
    const result = f.run();
    assert.equal(result.status, 1, result.stderr);
    assert.match(result.stderr, /Commit blokkert/);
    assert.equal(f.lintRan(), false);
});

for (const operation of ['rename', 'delete']) {
    test(`${operation === 'rename' ? 'blocks renames into' : 'preserves existing allowance for deletions from'} dependency directories`, (t) => {
        const f = fixture(t);
        const original = operation === 'rename' ? 'force-app/file.txt' : 'reference.package/file.txt';
        f.write(original, 'fixture');
        f.git('add', original);
        f.git(
            '-c',
            'user.name=Fixture',
            '-c',
            'user.email=fixture@example.invalid',
            '-c',
            'commit.gpgSign=false',
            'commit',
            '--quiet',
            '-m',
            'fixture'
        );
        if (operation === 'rename') {
            fs.mkdirSync(path.join(f.directory, 'reference.package'), { recursive: true });
            f.git('mv', original, 'reference.package/file.txt');
        } else {
            f.git('rm', original);
        }
        const result = f.run();
        assert.equal(result.status, operation === 'rename' ? 1 : 0, result.stderr);
        assert.equal(f.lintRan(), operation === 'delete');
    });
}

test('fails explicitly if the local lint-staged entry point is missing', (t) => {
    const f = fixture(t);
    fs.unlinkSync(path.join(f.directory, 'node_modules/lint-staged/cli.cjs'));
    const result = f.run();
    assert.equal(result.status, 1);
    assert.match(result.stderr, /Feil:/);
    assert.equal(f.lintRan(), false);
});

test('fails explicitly if Git cannot inspect the repository', (t) => {
    const f = fixture(t);
    fs.renameSync(path.join(f.directory, '.git'), path.join(f.directory, 'git-backup'));
    const failed = f.run();
    assert.equal(failed.status, 1);
    assert.match(failed.stderr, /Feil:/);
    assert.equal(f.lintRan(), false);
});

test('fails explicitly on a corrupt Git index', (t) => {
    const f = fixture(t);
    fs.writeFileSync(path.join(f.directory, '.git/index'), 'invalid index');
    const result = f.run();
    assert.equal(result.status, 1);
    assert.match(result.stderr, /Feil:/);
    assert.equal(f.lintRan(), false);
});

test('hook uses LF and delegates to Node without jq, grep or npx', () => {
    const hook = fs.readFileSync(path.resolve(__dirname, '../../.husky/pre-commit'), 'utf8');
    assert.ok(!hook.includes('\r'));
    assert.match(hook, /node scripts\/pre-commit\.cjs/);
    assert.doesNotMatch(hook, /\b(jq|grep|npx)\b/);
});
