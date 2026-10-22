const fs = require('node:fs');
const path = require('node:path');
const { execFileSync, spawnSync } = require('node:child_process');

function checkPackageDirectories() {
    const configuration = JSON.parse(fs.readFileSync('sfdx-project.json', 'utf8'));
    if (!Array.isArray(configuration.packageDirectories)) {
        throw new Error('sfdx-project.json må innehalde packageDirectories som ei liste.');
    }

    const blockedDirectories = configuration.packageDirectories
        .map((entry) => {
            if (!entry || typeof entry.path !== 'string' || !entry.path.trim()) {
                throw new Error('Alle packageDirectories må ha ein gyldig path.');
            }
            const directory = path.posix.normalize(entry.path.replace(/\\/g, '/')).replace(/\/$/, '');
            if (
                directory === '.' ||
                directory === '..' ||
                directory.startsWith('../') ||
                path.posix.isAbsolute(directory) ||
                /^[A-Za-z]:/.test(directory)
            ) {
                throw new Error('packageDirectories må ha relative stiar innanfor repoet.');
            }
            return directory;
        })
        .filter((directory) => directory !== 'force-app');

    const stagedFiles = execFileSync('git', ['diff', '--cached', '--name-only', '--diff-filter=ACMR', '-z'], {
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'inherit']
    })
        .split('\0')
        .filter(Boolean);
    const blockedFiles = stagedFiles.filter((file) =>
        blockedDirectories.some((directory) => file.startsWith(`${directory}/`))
    );

    if (blockedFiles.length === 0) {
        return true;
    }

    console.error('Feil: Commit blokkert. Endringar i pakke/referanse-mapper er ikkje tillatt i pre-commit.');
    console.error('\nStaged filer som bryt policy:');
    console.error(blockedFiles.join('\n'));
    console.error('\nFjern frå stage (eksempel):\n  git restore --staged <fil>');
    console.error(
        '\nVed eksplisitt godkjent unntak: set ALLOW_PACKAGE_DIR_COMMIT=1 i miljøet og køyr git commit på nytt.'
    );
    return false;
}

function main() {
    if (process.env.ALLOW_PACKAGE_DIR_COMMIT !== '1' && !checkPackageDirectories()) {
        return 1;
    }

    const lintStaged = require.resolve('lint-staged/bin', { paths: [process.cwd()] });
    const result = spawnSync(process.execPath, [lintStaged], { stdio: 'inherit' });
    if (result.error) {
        throw result.error;
    }
    if (result.signal || result.status === null) {
        throw new Error(`lint-staged vart avbroten: ${result.signal || 'ukjend status'}`);
    }
    return result.status;
}

try {
    process.exitCode = main();
} catch (error) {
    console.error(`Feil: Pre-commit kunne ikkje fullførast: ${error.message}`);
    process.exitCode = 1;
}
