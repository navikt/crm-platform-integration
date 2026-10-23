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
    assert.match(result.stdout, /--dry-run/);
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
        const versions = dependencies.map((dependency) => {
            const [MajorVersion, MinorVersion, PatchVersion] = dependency.versionNumber.split('.').map(Number);
            return {
                MajorVersion,
                MinorVersion,
                PatchVersion,
                BuildNumber: 1,
                SubscriberPackageVersionId: 'offline-version'
            };
        });
        const readResponses = {
            sf: `"package version list"*) printf '%s\\n' '${JSON.stringify({ result: versions })}' ;;`,
            sfp: `"pool list"*) printf '%s\\n' 'Unused Scratch Orgs in the Pool: 1' ;;`
        };
        for (const [command, response] of Object.entries(readResponses)) {
            fs.writeFileSync(
                path.join(directory, command),
                `#!/bin/sh\ncase "$*" in\n${response}\n*) printf "%s\\n" "$*" >> "$UNEXPECTED_CALL"; exit 99 ;;\nesac\n`,
                { mode: 0o755 }
            );
        }
        const result = spawnSync(
            process.execPath,
            ['bin/create-scratch-org.js', '--dry-run', '--pool-devhub', 'offline-test-hub', '--no-color'],
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
