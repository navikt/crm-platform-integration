const { spawnSync } = require('node:child_process');
const path = require('node:path');

function getLauncher(platform, forwardedArgs) {
    const isWindows = platform === 'win32';
    const scriptPath = path.resolve(__dirname, isWindows ? 'create-scratch-org.ps1' : 'create-scratch-org.sh');
    const normalizedArgs = forwardedArgs.map((argument) =>
        /^--?h(elp)?$/i.test(argument) ? (isWindows ? '-Help' : '--help') : argument
    );

    return {
        command: isWindows ? 'pwsh.exe' : 'bash',
        args: isWindows ? ['-NoProfile', '-File', scriptPath, ...normalizedArgs] : [scriptPath, ...normalizedArgs]
    };
}

function main({
    platform = process.platform,
    forwardedArgs = process.argv.slice(2),
    spawn = spawnSync,
    writeError = console.error,
    setExitCode = (code) => {
        process.exitCode = code;
    }
} = {}) {
    const launcher = getLauncher(platform, forwardedArgs);
    const result = spawn(launcher.command, launcher.args, { stdio: 'inherit' });

    if (result.error) {
        const guidance = platform === 'win32' ? ' Install PowerShell 7 LTS and ensure pwsh.exe is on PATH.' : '';
        writeError(`Unable to start ${launcher.command}: ${result.error.message}.${guidance}`);
        setExitCode(1);
        return 1;
    }

    const exitCode = result.status ?? 1;
    setExitCode(exitCode);
    return exitCode;
}

if (require.main === module) {
    main();
}

module.exports = { getLauncher, main };
