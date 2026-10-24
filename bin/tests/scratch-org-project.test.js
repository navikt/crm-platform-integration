const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');

const projectRoot = path.resolve(__dirname, '../..');

test('provides standalone scratch-org entry points for all supported platforms', () => {
    for (const extension of ['sh', 'ps1', 'bat', 'js']) {
        assert.ok(fs.existsSync(path.join(projectRoot, `bin/create-scratch-org.${extension}`)));
    }
    const packageJson = JSON.parse(fs.readFileSync(path.join(projectRoot, 'package.json'), 'utf8'));
    assert.equal(packageJson.scripts['scratch-org'], 'node bin/create-scratch-org.js');
});

test('uses the integration project and dev pool without application-specific post-steps', () => {
    const config = JSON.parse(fs.readFileSync(path.join(projectRoot, 'sf-project.config.json'), 'utf8'));
    assert.equal(config.defaultOrgAlias, 'crm-platform-integration');
    assert.ok(fs.existsSync(path.join(projectRoot, config.scratchDefinition)));
    assert.deepEqual(config.postSteps, ['deploy']);
    assert.deepEqual(config.permissionSets, []);
    assert.equal(config.dummyDataPlan, null);
    assert.equal(config.communityName, null);
    assert.equal(config.pool.use, true);
    assert.equal(config.pool.tag, 'dev');
    assert.equal(config.pool.fallbackToCreate, false);
    assert.equal(config.dependencySourcePolicy.requireLocalDirectories, false);
});

test('shows npm launcher help without accessing Salesforce', () => {
    const result = spawnSync(process.execPath, ['bin/create-scratch-org.js', '--help'], {
        cwd: projectRoot,
        encoding: 'utf8'
    });
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, process.platform === 'win32' ? /-DryRun/ : /--dry-run/);
});

test(
    'plans pool acquisition, declared dependencies, and deploy without contacting Salesforce',
    {
        skip: process.platform === 'win32'
    },
    (context) => {
        const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'integration-scratch-test-'));
        context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
        const unexpectedCall = path.join(directory, 'unexpected-call');
        const project = JSON.parse(fs.readFileSync(path.join(projectRoot, 'sfdx-project.json'), 'utf8'));
        const dependencies = project.packageDirectories.find(
            (entry) => entry.package === 'crm-platform-integration'
        ).dependencies;
        const versions = Object.fromEntries(
            dependencies.map((dependency) => {
                const [MajorVersion, MinorVersion, PatchVersion] = dependency.versionNumber.split('.').map(Number);
                return [
                    dependency.package,
                    {
                        MajorVersion,
                        MinorVersion,
                        PatchVersion,
                        BuildNumber: 1,
                        SubscriberPackageVersionId: `offline-${dependency.package}`,
                        Package2Id: `offline-package-${dependency.package}`,
                        SubscriberPackageVersion: { Dependencies: null }
                    }
                ];
            })
        );
        const fixture = path.join(directory, 'fake-cli.cjs');
        fs.writeFileSync(
            fixture,
            `
const fs = require('node:fs');
const versions = ${JSON.stringify(versions)};
const [tool, ...args] = process.argv.slice(2);
if (tool === 'sfp' && args[0] === 'pool' && args[1] === 'list') {
    console.log('Unused Scratch Orgs in the Pool: 1');
} else if (tool === 'sf' && args.slice(0, 3).join(' ') === 'package version list') {
    console.log(JSON.stringify({ status: 0, result: [versions[args[4]]] }));
} else if (tool === 'sf' && args.slice(0, 3).join(' ') === 'package version report') {
    console.log(JSON.stringify({ status: 0, result: Object.values(versions).find(version => version.SubscriberPackageVersionId === args[4]) }));
} else {
    fs.appendFileSync(process.env.UNEXPECTED_CALL, tool + ' ' + args.join(' ') + '\\n');
    process.exitCode = 99;
}
`
        );
        for (const command of ['sf', 'sfp']) {
            fs.writeFileSync(
                path.join(directory, command),
                `#!/bin/sh\nexec "${process.execPath}" "${fixture}" ${command} "$@"\n`,
                { mode: 0o755 }
            );
        }
        const result = spawnSync(
            process.execPath,
            [
                'bin/create-scratch-org.js',
                '--dry-run',
                '--pool-devhub',
                'offline-test-hub',
                '--dependency-report',
                path.join(directory, 'dependencies.md'),
                '--no-color'
            ],
            {
                cwd: projectRoot,
                encoding: 'utf8',
                env: {
                    ...process.env,
                    PATH: `${directory}${path.delimiter}${process.env.PATH}`,
                    UNEXPECTED_CALL: unexpectedCall
                }
            }
        );
        assert.equal(result.status, 0, result.stdout + result.stderr);
        assert.equal(fs.existsSync(unexpectedCall), false, 'Dry-run must not execute mutations or unexpected reads');
        assert.match(result.stdout, /sfp pool fetch .*--tag dev .*--alias crm-platform-integration/);
        assert.match(result.stdout, /sf project deploy start --target-org crm-platform-integration/);
        for (const dependency of dependencies) {
            assert.ok(result.stdout.includes(dependency.package), `Missing dependency: ${dependency.package}`);
        }
        assert.doesNotMatch(
            result.stdout,
            /sf org create scratch|sf org assign permset|sf data import tree|sf community publish/
        );
    }
);
