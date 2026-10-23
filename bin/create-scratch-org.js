const { spawnSync } = require('node:child_process');
const path = require('node:path');

function getLauncher(platform, forwardedArgs) {
    const isWindows = platform === 'win32';
    const scriptPath = path.resolve(__dirname, isWindows ? 'create-scratch-org.ps1' : 'create-scratch-org.sh');
    const normalizedArgs = forwardedArgs.map((argument) =>
        /^--?h(elp)?$/i.test(argument) ? (isWindows ? '-Help' : '--help') : argument
    );

    return {
        command: isWindows ? 'powershell.exe' : 'bash',
        args: isWindows
            ? ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', scriptPath, ...normalizedArgs]
            : [scriptPath, ...normalizedArgs]
    };
}

function main() {
    const launcher = getLauncher(process.platform, process.argv.slice(2));
    const result = spawnSync(launcher.command, launcher.args, { stdio: 'inherit' });

    if (result.error) {
        console.error(`Unable to start ${launcher.command}: ${result.error.message}`);
        process.exitCode = 1;
        return;
    }

    process.exitCode = result.status ?? 1;
}

if (require.main === module) {
    main();
}

module.exports = { getLauncher };
