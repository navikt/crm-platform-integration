const fs = require('node:fs');
const path = require('node:path');
const { spawn } = require('node:child_process');
const { createInteractiveReport } = require('./package-dependency-report');

function versionNumber(record) {
    const parts = ['MajorVersion', 'MinorVersion', 'PatchVersion', 'BuildNumber'].map((key) => record[key]);
    if (parts.some((part) => !Number.isInteger(part) || part < 0)) {
        throw new Error('Package report has invalid version components.');
    }
    return parts.join('.');
}

function compareVersionNumbers(left, right) {
    const leftParts = left.split('.').map(Number);
    const rightParts = right.split('.').map(Number);
    for (let index = 0; index < leftParts.length; index++) {
        if (leftParts[index] !== rightParts[index]) return leftParts[index] - rightParts[index];
    }
    return 0;
}

async function checkDependencies(project, provider, progress = () => {}) {
    if (!Array.isArray(project.packageDirectories)) throw new Error('packageDirectories must be an array.');
    const updated = structuredClone(project);
    updated.packageAliases ??= {};
    const errors = [];
    const issues = [];
    const graphs = [];
    const requirements = [];
    let fixable = true;
    const reports = new Map();
    const knownNames = new Map();
    const versions = {};
    const recordRequirement = (node, directory, requiredRecord, selectedRecord, parent, status) => {
        if (parent === directory) return;
        const minimum = requiredRecord.VersionNumber;
        if (node.requirements.some((entry) => entry.minimum === minimum && entry.requiredBy === parent)) return;
        node.requirements.push({ minimum, requiredBy: parent });
        requirements.push({
            directory,
            package: node.name,
            selected: selectedRecord?.VersionNumber ?? null,
            minimum,
            requiredBy: parent,
            status
        });
    };
    const report = async (id) => {
        if (!reports.has(id)) {
            const record = await provider.report(id);
            if (record.SubscriberPackageVersionId !== id || !record.Package2Id) {
                throw new Error(`Invalid package report for ${id}.`);
            }
            const subscriber = record.SubscriberPackageVersion;
            if (
                !subscriber ||
                !Object.hasOwn(subscriber, 'Dependencies') ||
                (subscriber.Dependencies !== null && !Array.isArray(subscriber.Dependencies?.ids))
            ) {
                throw new Error(`Missing dependency metadata for ${id}; completeness cannot be verified.`);
            }
            record.VersionNumber = versionNumber(record);
            reports.set(id, record);
        }
        return reports.get(id);
    };
    const total = updated.packageDirectories.reduce(
        (count, directory) => count + (directory.dependencies?.length ?? 0),
        0
    );
    let completed = 0;
    for (const directory of updated.packageDirectories) {
        if (!directory.dependencies?.length) continue;
        const selected = new Map();
        for (const dependency of directory.dependencies) {
            progress(`[${++completed}/${total}] ${dependency.package} (${directory.path})`);
            const id = await provider.resolve(dependency);
            const record = await report(id);
            progress(`  Selected ${versionNumber(record)}`);
            if (versions[dependency.package] && versions[dependency.package].SubscriberPackageVersionId !== id) {
                throw new Error(`Conflicting versions for ${dependency.package} across package directories.`);
            }
            knownNames.set(record.Package2Id, dependency.package);
            versions[dependency.package] = record;
            if (selected.has(record.Package2Id))
                throw new Error(`Duplicate package declaration: ${dependency.package}`);
            selected.set(record.Package2Id, { dependency, id });
        }
        const ordered = [];
        const declared = new Set(selected.keys());
        const graph = {
            directory: directory.path,
            roots: [...selected.values()].map(({ id }) => id),
            nodes: new Map()
        };
        graphs.push(graph);
        const visited = new Set();
        const visiting = new Set();
        progress(`Checking recursive requirements: ${directory.path}`);
        const visit = async (id, parent) => {
            let record = await report(id);
            const requiredRecord = record;
            const existing = selected.get(record.Package2Id);
            let selectedRecord = null;
            let versionComparison = 0;
            if (existing) {
                selectedRecord = await report(existing.id);
                versionComparison = compareVersionNumbers(selectedRecord.VersionNumber, record.VersionNumber);
                if (versionComparison < 0) {
                    const name = knownNames.get(record.Package2Id) ?? (await provider.name(record.Package2Id));
                    knownNames.set(record.Package2Id, name);
                    const node = {
                        name,
                        version: record.VersionNumber,
                        status: 'VERSION DIFF',
                        selected: selectedRecord.VersionNumber,
                        requirements: [],
                        children: []
                    };
                    recordRequirement(node, directory.path, requiredRecord, selectedRecord, parent, 'Below minimum');
                    graph.nodes.set(id, node);
                    errors.push(
                        `${directory.path}: selected ${name} ${selectedRecord.VersionNumber} is below the ${record.VersionNumber} minimum required by ${parent}.`
                    );
                    issues.push({
                        type: 'conflict',
                        directory: directory.path,
                        package: name,
                        parent,
                        required: record.VersionNumber,
                        requiredId: id,
                        selected: selectedRecord.VersionNumber,
                        selectedId: existing.id
                    });
                    fixable = false;
                    return id;
                }
                if (versionComparison > 0) {
                    progress(
                        `  Selected ${selectedRecord.VersionNumber} satisfies the ${record.VersionNumber} minimum.`
                    );
                }
                id = existing.id;
                record = selectedRecord;
            }
            if (visiting.has(id)) throw new Error(`Dependency cycle: ${[...visiting, id].join(' -> ')}`);
            const name = knownNames.get(record.Package2Id) ?? (await provider.name(record.Package2Id));
            knownNames.set(record.Package2Id, name);
            if (!graph.nodes.has(id)) {
                graph.nodes.set(id, {
                    name,
                    version: versionNumber(record),
                    status: !declared.has(record.Package2Id) ? 'MISSING' : versionComparison > 0 ? 'HIGHER' : 'OK',
                    selected: null,
                    requirements: [],
                    children: []
                });
            } else if (declared.has(record.Package2Id) && versionComparison > 0) {
                graph.nodes.get(id).status = 'HIGHER';
            }
            const declaredPackage = declared.has(record.Package2Id);
            recordRequirement(
                graph.nodes.get(id),
                directory.path,
                requiredRecord,
                declaredPackage ? selectedRecord : null,
                parent,
                !declaredPackage
                    ? 'Missing declaration'
                    : versionComparison > 0
                      ? 'Higher version satisfies minimum'
                      : 'Meets minimum'
            );
            if (!declared.has(record.Package2Id)) {
                errors.push(`${directory.path}: ${parent} requires missing ${name} ${versionNumber(record)} (${id}).`);
                issues.push({
                    type: 'missing',
                    directory: directory.path,
                    package: name,
                    parent,
                    required: versionNumber(record),
                    requiredId: id
                });
            }
            if (visited.has(id)) return id;
            if (!existing) {
                if (updated.packageAliases[name] && updated.packageAliases[name] !== record.Package2Id) {
                    throw new Error(`Alias collision for ${name}; resolve it manually.`);
                }
                updated.packageAliases[name] = record.Package2Id;
                selected.set(record.Package2Id, {
                    id,
                    dependency: { package: name, versionNumber: versionNumber(record) }
                });
            }
            visiting.add(id);
            progress(`  Checking requirements: ${name} ${versionNumber(record)}`);
            for (const entry of record.SubscriberPackageVersion.Dependencies?.ids ?? []) {
                if (typeof entry.subscriberPackageVersionId !== 'string' || !entry.subscriberPackageVersionId) {
                    throw new Error(`Invalid dependency metadata for ${id}.`);
                }
                const childId = await visit(entry.subscriberPackageVersionId, `${name} ${versionNumber(record)}`);
                graph.nodes.get(id).children.push(childId);
            }
            visiting.delete(id);
            visited.add(id);
            ordered.push(selected.get(record.Package2Id).dependency);
            return id;
        };
        for (const { id } of [...selected.values()]) await visit(id, directory.path);
        if (fixable && JSON.stringify(ordered) !== JSON.stringify(directory.dependencies)) {
            if (ordered.length === directory.dependencies.length) {
                errors.push(`${directory.path}: incorrect installation order; dependencies must precede dependants.`);
                issues.push({ type: 'order', directory: directory.path });
            }
            directory.dependencies = ordered;
        }
    }
    return { valid: errors.length === 0, fixable, errors, issues, graphs, project: updated, versions, requirements };
}

function createProvider(project, run, latest) {
    const aliases = project.packageAliases ?? {};
    const names = new Map(
        Object.entries(aliases)
            .filter(([, id]) => typeof id === 'string')
            .map(([name, id]) => [id, name])
    );
    let packagesLoaded = false;
    const latestVersions = new Map();
    return {
        async resolve(dependency) {
            const reference = aliases[dependency.package] ?? dependency.package;
            if (/^04t[a-zA-Z0-9]{12}(?:[a-zA-Z0-9]{3})?$/.test(reference)) return reference;
            const versions = await run([
                'package',
                'version',
                'list',
                '--packages',
                dependency.package,
                '--released',
                '--order-by',
                'CreatedDate'
            ]);
            if (!Array.isArray(versions)) throw new Error(`Invalid version list for ${dependency.package}.`);
            const requested = dependency.versionNumber;
            if (!latest && !/^\d+\.\d+\.\d+\.(?:LATEST|NEXT|\d+)$/.test(requested ?? '')) {
                throw new Error(`Invalid or missing versionNumber for ${dependency.package}.`);
            }
            const parts = requested?.split('.');
            const sorted = [...versions].sort((a, b) => {
                for (const key of ['MajorVersion', 'MinorVersion', 'PatchVersion', 'BuildNumber']) {
                    if (a[key] !== b[key]) return a[key] - b[key];
                }
                return 0;
            });
            const candidates = sorted.filter((record) => {
                const number = versionNumber(record).split('.');
                return (
                    latest ||
                    parts.every(
                        (part, index) => part === 'LATEST' || part === 'NEXT' || Number(part) === Number(number[index])
                    )
                );
            });
            const id = candidates.at(-1)?.SubscriberPackageVersionId;
            if (!id) throw new Error(`Cannot resolve released version for ${dependency.package} ${requested ?? ''}.`);
            const newest = sorted.at(-1);
            latestVersions.set(id, { ...newest, VersionNumber: versionNumber(newest) });
            return id;
        },
        report: async (id) => ({
            ...(await run(['package', 'version', 'report', '--package', id, '--verbose'])),
            LatestVersion: latestVersions.get(id)
        }),
        async name(id) {
            if (!names.has(id) && !packagesLoaded) {
                const packages = await run(['package', 'list']);
                if (!Array.isArray(packages)) throw new Error('Invalid package list response.');
                for (const entry of packages) if (entry.Id && entry.Name) names.set(entry.Id, entry.Name);
                packagesLoaded = true;
            }
            if (!names.has(id)) throw new Error(`Cannot resolve package name for ${id}; check Dev Hub access.`);
            return names.get(id);
        }
    };
}

function printFindings(result, write) {
    for (const [type, title] of [
        ['missing', 'Missing dependencies'],
        ['conflict', 'Selected versions below minimum']
    ]) {
        const groups = new Map();
        const issues = result.issues.filter((issue) => issue.type === type);
        for (const issue of issues) {
            const key = JSON.stringify([issue.directory, issue.package]);
            if (!groups.has(key)) groups.set(key, []);
            groups.get(key).push(issue);
        }
        if (!groups.size) continue;
        write(
            `\n${title} (${groups.size} package${groups.size === 1 ? '' : 's'}, ${issues.length} requirement${issues.length === 1 ? '' : 's'})`,
            type === 'missing' ? 'failure' : 'warning'
        );
        write('-'.repeat(72));
        for (const group of groups.values()) {
            const first = group[0];
            write(`\n  Package: ${first.package}`, type === 'missing' ? 'failure' : 'warning');
            write(`  Directory: ${first.directory}`);
            if (type === 'conflict') write(`  Selected: ${first.selected} (${first.selectedId})`, 'info');
            const requirements = new Map();
            for (const issue of group) {
                if (!requirements.has(issue.requiredId)) requirements.set(issue.requiredId, []);
                requirements.get(issue.requiredId).push(issue);
            }
            for (const entries of requirements.values()) {
                write(
                    `  Required: ${entries[0].required} (${entries[0].requiredId})`,
                    type === 'missing' ? 'failure' : 'warning'
                );
                write('    Required by:');
                for (const parent of new Set(entries.map((entry) => entry.parent))) write(`      - ${parent}`);
            }
        }
    }
    const ordering = result.issues.filter((issue) => issue.type === 'order');
    if (ordering.length) {
        write('\nInstallation order', 'warning');
        write('-'.repeat(72));
        for (const issue of ordering) write(`  ${issue.directory}: dependencies must precede dependants.`);
    }
}

function printGraph(graphs, write) {
    write('\nDependency graph', 'heading');
    write('-'.repeat(72), 'muted');
    write('Parent package -> selected dependency version. Shared subtrees expand once.');
    write(
        '[OK] exact minimum | [HIGHER] selected above minimum | [MISSING] no declaration | [VERSION DIFF] below minimum'
    );
    write('Only below-minimum branches are not expanded; their descendants are unchecked.', 'warning');
    if (!graphs.length) write('  No package dependencies declared.', 'muted');
    for (const graph of graphs) {
        write(`\n  ${graph.directory}`, 'heading');
        const expanded = new Set();
        const visit = (id, prefix) => {
            const node = graph.nodes.get(id);
            const shared = expanded.has(id) && node.children.length > 0;
            const selected = node.selected ? `; selected ${node.selected}` : '';
            const minimums = [...new Set((node.requirements ?? []).map((entry) => entry.minimum))];
            const minimumLabel = minimums.length ? `; minimum ${minimums.join(', ')}` : '';
            write(
                `${prefix}+-- ${node.name} ${node.version} [${node.status}${minimumLabel}${selected}]${shared ? ' (shared subtree)' : ''}`,
                node.status === 'MISSING' ? 'failure' : node.status === 'VERSION DIFF' ? 'warning' : 'success'
            );
            if (shared) return;
            expanded.add(id);
            for (const child of node.children) visit(child, prefix + '|   ');
        };
        for (const id of graph.roots) {
            write('');
            visit(id, '  ');
        }
    }
}

function mermaidGraph(nodes) {
    const label = (value) =>
        String(value).replace(/[^a-zA-Z0-9 ._:/;-]/g, (character) => `#${character.charCodeAt(0)};`);
    const ids = new Map([...nodes.keys()].map((id, index) => [id, `n${index}`]));
    const lines = [
        '```mermaid',
        'flowchart LR',
        '    classDef ok fill:#dcfce7,stroke:#166534,color:#14532d',
        '    classDef missing fill:#fee2e2,stroke:#991b1b,color:#7f1d1d',
        '    classDef conflict fill:#fef3c7,stroke:#92400e,color:#78350f'
    ];
    for (const [id, node] of nodes) {
        const status =
            node.status === 'OK' || node.status === 'HIGHER'
                ? 'ok'
                : node.status === 'MISSING'
                  ? 'missing'
                  : 'conflict';
        const minimums = [...new Set((node.requirements ?? []).map((entry) => entry.minimum))];
        const minimumLabel = minimums.length ? `; minimum ${minimums.join(', ')}` : '';
        const text = `${node.name} ${node.version} [${node.status}${minimumLabel}${node.selected ? `; selected ${node.selected}` : ''}]`;
        lines.push(`    ${ids.get(id)}["${label(text)}"]:::${status}`);
    }
    for (const [id, node] of nodes) {
        for (const child of node.children) {
            if (nodes.has(child)) lines.push(`    ${ids.get(id)} --> ${ids.get(child)}`);
        }
    }
    return [...lines, '```', ''];
}

function createMarkdownReport(result, projectName, htmlName) {
    const escape = (value) => String(value).replace(/[&<>"|`[\]\r\n]/g, (character) => `&#${character.charCodeAt(0)};`);
    const lines = [
        '# Package dependency report',
        '',
        `Generated: ${new Date().toISOString()}`,
        '',
        `Project: ${escape(projectName)}`,
        '',
        `Result: **${result.valid ? 'PASSED' : 'ACTION REQUIRED'}**`,
        '',
        `[Interactive HTML graph](${encodeURIComponent(htmlName)}) - open the companion file locally in a browser for hover, focus, pinning and zoom.`,
        '',
        '## Summary',
        ''
    ];
    for (const [type, title] of [
        ['missing', 'Missing packages'],
        ['conflict', 'Selected versions below minimum']
    ]) {
        const count = new Set(
            result.issues
                .filter((issue) => issue.type === type)
                .map((issue) => JSON.stringify([issue.directory, issue.package]))
        ).size;
        lines.push(`- ${title}: ${count}`);
    }
    lines.push(
        `- Installation-order problems: ${result.issues.filter((issue) => issue.type === 'order').length}`,
        '',
        'This report describes manifest declarations and required versions, not installed org packages.',
        'Versions are compared numerically as minimum requirements. A higher selected version satisfies a lower requirement.',
        'The selected version dependency graph is inspected; below-minimum branches are not expanded.',
        'A zero missing count does not certify completeness when below-minimum requirements remain.',
        ''
    );
    for (const [type, title] of [
        ['missing', 'Missing dependencies'],
        ['conflict', 'Selected versions below minimum']
    ]) {
        lines.push(
            `## ${title}`,
            '',
            '| Directory | Package | Selected | Required | Required by |',
            '| --- | --- | --- | --- | --- |'
        );
        const issues = result.issues.filter((issue) => issue.type === type);
        if (!issues.length) lines.push('| - | None found in inspected graph | - | - | - |');
        for (const issue of issues) {
            lines.push(
                `| ${escape(issue.directory)} | ${escape(issue.package)} | ${escape(issue.selected ? `${issue.selected} (${issue.selectedId})` : 'Not declared')} | ${escape(`${issue.required} (${issue.requiredId})`)} | ${escape(issue.parent)} |`
            );
        }
        lines.push('');
    }
    lines.push(
        '## Transitive minimum requirements',
        '',
        '| Package | Selected version | Required minimum | Required by | Result |',
        '| --- | --- | --- | --- | --- |'
    );
    if (!result.requirements.length) lines.push('| - | - | - | No transitive requirements inspected | - |');
    for (const requirement of result.requirements) {
        lines.push(
            `| ${escape(requirement.package)} | ${escape(requirement.selected ?? 'Not declared')} | ${escape(requirement.minimum)} | ${escape(requirement.requiredBy)} | ${escape(requirement.status)} |`
        );
    }
    lines.push('');
    lines.push('## Installation order', '');
    const ordering = result.issues.filter((issue) => issue.type === 'order');
    lines.push(
        ...(ordering.length
            ? ordering.map((issue) => `- ${escape(issue.directory)}: dependencies must precede dependants.`)
            : ['No installation-order problems reported in inspected branches.']),
        '',
        '## Dependency graph',
        '',
        'Arrows point from a package to its selected dependency version. Shared nodes retain all incoming edges.',
        'Green: selected version meets or exceeds the minimum. Red: missing declaration. Yellow: selected version is below minimum (not expanded).',
        ''
    );
    for (const graph of result.graphs) {
        lines.push(`### ${escape(graph.directory)}`, '', ...mermaidGraph(graph.nodes));
        lines.push(
            '#### Version inventory',
            '',
            '| Package | Version | Subscriber version ID | Status | Selected version |',
            '| --- | --- | --- | --- | --- |'
        );
        for (const [id, node] of graph.nodes) {
            lines.push(
                `| ${escape(node.name)} | ${escape(node.version)} | ${escape(id)} | ${node.status} | ${escape(node.selected ?? '-')} |`
            );
        }
        lines.push('');
    }
    lines.push(
        '## Dependency graphs per package',
        '',
        'Smaller views show one declared top-level package and its direct requirements only.',
        'The full graph above retains all inspected transitive edges. Status and incomplete-branch warnings still apply.',
        ''
    );
    for (const graph of result.graphs) {
        for (const root of graph.roots) {
            const node = graph.nodes.get(root);
            const nodes = new Map(
                [root, ...node.children].map((id) => [
                    id,
                    {
                        ...graph.nodes.get(id),
                        children: id === root ? node.children : []
                    }
                ])
            );
            lines.push(
                `### ${escape(graph.directory)}: ${escape(node.name)} ${escape(node.version)}`,
                '',
                ...mermaidGraph(nodes)
            );
            if (!node.children.length) lines.push('No direct requirements recorded for this declared version.', '');
        }
    }
    lines.push(
        '## Next steps',
        '',
        ...(result.valid
            ? ['No manifest corrections required by this check.']
            : result.fixable
              ? [
                    '1. Review missing declarations and installation order.',
                    '2. Explicitly apply with a backup, review the manifest diff and rerun the check.'
                ]
              : [
                    '1. Review selected and required versions.',
                    '2. Reconcile versions manually; do not downgrade just to silence this check.',
                    '3. Rerun the check. Automatic apply is disabled for version conflicts.'
                ]),
        ''
    );
    return lines.join('\n');
}

async function runCli(args) {
    const options = {};
    for (let index = 0; index < args.length; index++) {
        const argument = args[index];
        if (['--apply', '--latest', '--dry-run', '--color', '--no-color'].includes(argument)) options[argument] = true;
        else if (
            ['--project-file', '--dev-hub', '--plan-file', '--report'].includes(argument) &&
            args[index + 1] &&
            !args[index + 1].startsWith('--')
        ) {
            options[argument] = args[++index];
        } else throw new Error(`Unknown or incomplete option: ${argument}`);
    }
    if (options['--apply'] && options['--dry-run']) throw new Error('--apply cannot be combined with --dry-run.');
    if (options['--color'] && options['--no-color']) throw new Error('--color and --no-color cannot be combined.');
    const useColor = options['--no-color']
        ? false
        : options['--color']
          ? true
          : process.env.NO_COLOR
            ? false
            : process.env.FORCE_COLOR && process.env.FORCE_COLOR !== '0'
              ? true
              : Boolean(process.stdout.isTTY && process.env.TERM !== 'dumb');
    const tones = { heading: '1;36', info: '36', success: '32', warning: '33', failure: '31', muted: '90' };
    const file = path.resolve(options['--project-file'] ?? 'sfdx-project.json');
    const reportFile = path.resolve(
        options['--report'] ?? path.join(path.dirname(file), 'package-dependencies-report.md')
    );
    const htmlFile = reportFile.slice(0, -3) + '.html';
    if (path.extname(reportFile).toLowerCase() !== '.md' || reportFile === file) {
        throw new Error('Report must be a separate .md file, not the project file.');
    }
    for (const destination of [reportFile, htmlFile]) {
        if (fs.existsSync(destination) && fs.lstatSync(destination).isSymbolicLink()) {
            throw new Error('Report path must not be a symbolic link.');
        }
    }
    const original = fs.readFileSync(file, 'utf8');
    const project = JSON.parse(original);
    const hub = options['--dev-hub'] ?? process.env.SF_TARGET_DEV_HUB;
    const key = process.env[process.env.PACKAGE_INSTALL_KEY_ENV_VAR ?? 'PACKAGE_INSTALL_KEY'];
    const redact = (text) => (key ? text.replaceAll(key, '***') : text);
    const write = (text, tone) => {
        const lineOut = (line) => console.log(useColor && tone && line ? `\x1b[${tones[tone]}m${line}\x1b[0m` : line);
        for (const line of redact(text).split('\n')) {
            const indent = line.match(/^ */)[0].slice(0, 40);
            let remaining = line;
            while (remaining.length > 100) {
                let end = remaining.lastIndexOf(' ', 100);
                if (end <= indent.length) end = 100;
                lineOut(remaining.slice(0, end));
                remaining = indent + remaining.slice(end).trimStart();
            }
            lineOut(remaining);
        }
    };
    const started = Date.now();
    let reads = 0;
    const run = async (command) => {
        const label =
            command[1] === 'version'
                ? command[2] === 'list'
                    ? `Reading released versions: ${command[4]}`
                    : `Reading dependency metadata: ${command[4]}`
                : 'Reading package names';
        write(`  ${label} ...`, 'info');
        const readingStarted = Date.now();
        const heartbeat = setInterval(
            () => write(`  Still running: ${label} (${Math.floor((Date.now() - readingStarted) / 1000)}s)`, 'info'),
            5000
        );
        const arguments_ = [...command, ...(hub ? ['--target-dev-hub', hub] : []), '--json'];
        let result;
        try {
            const child =
                process.platform === 'win32'
                    ? spawn(
                          'pwsh.exe',
                          [
                              '-NoLogo',
                              '-NoProfile',
                              '-Command',
                              "$PSNativeCommandArgumentPassing='Standard'; $a=ConvertFrom-Json $env:PACKAGE_CHECK_ARGV; & sf @a; exit $LASTEXITCODE"
                          ],
                          {
                              cwd: path.dirname(file),
                              encoding: 'utf8',
                              env: { ...process.env, PACKAGE_CHECK_ARGV: JSON.stringify(arguments_) }
                          }
                      )
                    : spawn('sf', arguments_, { cwd: path.dirname(file) });
            result = await new Promise((resolve, reject) => {
                let stdout = '';
                let stderr = '';
                child.stdout.setEncoding('utf8');
                child.stderr.setEncoding('utf8');
                child.stdout.on('data', (chunk) => {
                    stdout += chunk;
                });
                child.stderr.on('data', (chunk) => {
                    stderr += chunk;
                });
                child.on('error', (error) => reject(new Error(`Cannot start Salesforce CLI: ${error.message}`)));
                child.on('close', (status) => resolve({ status, stdout, stderr }));
            });
        } finally {
            clearInterval(heartbeat);
        }
        const output = result.stdout;
        const start = output.indexOf('{');
        if (start < 0)
            throw new Error(
                redact(`Salesforce returned no JSON dependency metadata (exit ${result.status}): ${result.stderr}`)
            );
        const response = JSON.parse(output.slice(start));
        if (result.status !== 0 || response.status !== 0 || response.result === undefined) {
            throw new Error(redact(`Salesforce dependency read failed: ${response.message ?? 'invalid response'}`));
        }
        reads++;
        write(`  Read completed (${((Date.now() - readingStarted) / 1000).toFixed(1)}s)`, 'success');
        return response.result;
    };
    write('\nPackage dependency check', 'heading');
    write('='.repeat(72), 'muted');
    write(`Project: ${file}`);
    write(`Dev Hub: ${hub ?? 'Salesforce CLI packaging default'}`);
    write('Read-only metadata checks. No org mutations.');
    write('Progress counts declared packages; recursive metadata reads may add work.\n');
    const result = await checkDependencies(project, createProvider(project, run, options['--latest']), (text) =>
        write(text, 'info')
    );
    write(
        `\nResult: ${result.valid ? 'PASSED' : 'ACTION REQUIRED'} | ${reads} metadata reads | ${((Date.now() - started) / 1000).toFixed(1)}s`,
        result.valid ? 'success' : 'warning'
    );
    write('\nWhat is missing?', 'heading');
    write('-'.repeat(72), 'muted');
    const countPackages = (type) =>
        new Set(
            result.issues
                .filter((issue) => issue.type === type)
                .map((issue) => JSON.stringify([issue.directory, issue.package]))
        ).size;
    const missing = countPackages('missing');
    const conflicts = countPackages('conflict');
    write(`Missing packages: ${missing}`, missing ? 'failure' : 'success');
    if (!missing) write('No missing package declarations were found in the inspected graph.', 'success');
    write(
        `Selected versions below minimum: ${conflicts} (declared packages, NOT missing packages)`,
        conflicts ? 'warning' : 'success'
    );
    write(
        `Installation-order problems: ${result.issues.filter((issue) => issue.type === 'order').length}`,
        result.issues.some((issue) => issue.type === 'order') ? 'warning' : 'success'
    );
    if (conflicts) write('Below-minimum branches were not expanded; completeness is not certified.', 'warning');
    printFindings(result, write);
    printGraph(result.graphs, write);
    const safeGraphs = result.graphs.map((graph) => ({
        ...graph,
        directory: redact(graph.directory),
        roots: graph.roots.map(redact),
        nodes: new Map(
            [...graph.nodes].map(([id, node]) => [
                redact(id),
                {
                    ...node,
                    name: redact(node.name),
                    children: node.children.map(redact)
                }
            ])
        )
    }));
    fs.writeFileSync(htmlFile, createInteractiveReport(safeGraphs, redact(path.basename(file))));
    fs.writeFileSync(reportFile, redact(createMarkdownReport(result, path.basename(file), path.basename(htmlFile))));
    write(`\nFull Markdown / Mermaid report: ${reportFile}`, 'info');
    write(`Interactive HTML graph: ${htmlFile}`, 'info');
    if (result.valid) {
        if (options['--plan-file'])
            fs.writeFileSync(options['--plan-file'], JSON.stringify(result.versions), { flag: 'wx' });
        write(
            'Dependency preflight PASSED: complete, minimum-version-satisfied, dependency-first manifest.',
            'success'
        );
        return 0;
    }
    if (!options['--apply'] || !result.fixable) {
        write('\nNext steps', 'heading');
        write('-'.repeat(72));
        write(
            result.fixable
                ? '1. Review the missing dependencies and installation order above.\n2. To apply with a backup, rerun this command with --apply.\n   Bash wrapper: --apply-dependencies | PowerShell: -ApplyDependencies\n3. Review the manifest diff, then rerun the check.'
                : 'A selected version is below a transitive minimum requirement. Higher selected versions satisfy lower minimums.\n\n1. Review the selected version and the package requiring the newer minimum.\n2. Update the manifest to an approved version that meets the minimum; automatic apply does not downgrade or resolve this case.\n3. Rerun the check after reviewing the manifest.'
        );
        write(
            'No files changed in the manifest. Only the Markdown and HTML reports were written. No org mutations were started.'
        );
        return 1;
    }
    const backup = `${file}.dependencies.backup`;
    if (fs.existsSync(backup))
        throw new Error(`Backup already exists: ${backup}. Preserve or move it before applying.`);
    if (fs.readFileSync(file, 'utf8') !== original)
        throw new Error('Project file changed during dependency check; retry after reviewing it.');
    fs.writeFileSync(backup, original, { flag: 'wx' });
    const temporary = `${file}.dependencies-${process.pid}.tmp`;
    try {
        fs.writeFileSync(temporary, JSON.stringify(result.project, null, 4) + '\n', { flag: 'wx' });
        fs.renameSync(temporary, file);
    } finally {
        if (fs.existsSync(temporary)) fs.unlinkSync(temporary);
    }
    write(
        `Applied missing exact-version dependencies and dependency-first ordering. Backup: ${backup}. Review the diff and rerun setup.`
    );
    return 0;
}

if (require.main === module) {
    runCli(process.argv.slice(2))
        .then((code) => {
            process.exitCode = code;
        })
        .catch((error) => {
            console.error(
                `\nDependency preflight FAILED:\n  ${error.message}\n\nCheck did not complete. No org mutations were started.`
            );
            process.exitCode = 1;
        });
}

module.exports = { checkDependencies, createProvider, runCli };
