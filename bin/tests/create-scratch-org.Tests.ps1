param([switch]$RequireWindows)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -ne 7) { throw 'Run this harness with PowerShell 7 LTS (pwsh).' }
if ($RequireWindows -and -not $IsWindows) { throw '-RequireWindows must run on Windows; skipping Windows coverage is not allowed.' }

$BinDirectory = Split-Path -Parent $PSScriptRoot
$ScriptPath = Join-Path $BinDirectory 'create-scratch-org.ps1'
$LauncherPath = Join-Path $BinDirectory 'create-scratch-org.bat'
$HostPath = (Get-Process -Id $PID).Path
$NodePath = (Get-Command node -ErrorAction Stop).Source
$NpmPath = if ($IsWindows) { (Get-Command npm.cmd -ErrorAction Stop).Source } else { $null }
$TempRoot = if ($env:TMPDIR) { $env:TMPDIR } else { [IO.Path]::GetTempPath() }
$WorkDirectory = Join-Path $TempRoot ('scratch-tests-' + [guid]::NewGuid().ToString('N'))
$ProjectDirectory = Join-Path $WorkDirectory 'project with spaces ø'
$FakeBin = Join-Path $WorkDirectory 'fake-bin'
$RulePath = Join-Path $WorkDirectory 'rules.json'
$LogPath = Join-Path $WorkDirectory 'calls.jsonl'
$Failures = 0
$Passed = 0
$Skipped = 0
$Calls = @()
$Config = $null
$Rules = @()
$Overrides = @{}
$VersionJson = '{"status":0,"result":[{"MajorVersion":1,"MinorVersion":0,"PatchVersion":0,"BuildNumber":3,"VersionNumber":"1.0.0.3","SubscriberPackageVersionId":"offline-version"}]}'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { $script:Passed++; Write-Host "PASS: $Message" }
    else { $script:Failures++; Write-Host "FAIL: $Message" }
}

function Write-Json {
    param([string]$Path, $Value)
    ConvertTo-Json -InputObject $Value -Depth 50 | Set-Content -LiteralPath $Path -Encoding utf8
}

function Reset-Scenario {
    $script:Config = @{
        defaultOrgAlias = 'offline-org'
        postSteps = @('deploy')
        pool = @{ use = $false; tag = 'dev'; fallbackToCreate = $false }
    }
    $script:Rules = @()
    $script:Overrides = @{}
    Write-Json (Join-Path $ProjectDirectory 'sfdx-project.json') @{
        packageDirectories = @(@{ path = 'force-app' })
        packageAliases = @{}
    }
}

function Add-Rule {
    param([string]$Tool, [string[]]$Prefix, [string]$Output = '{"status":0,"result":{}}', [int]$ExitCode = 0, [string]$ErrorOutput = '', [int]$DelaySeconds = 0)
    $script:Rules += @{ tool = $Tool; prefix = $Prefix; output = $Output; exitCode = $ExitCode; stderr = $ErrorOutput; delaySeconds = $DelaySeconds }
}

function Set-PackageProject {
    Write-Json (Join-Path $ProjectDirectory 'sfdx-project.json') @{
        packageDirectories = @(@{ path = 'force-app'; dependencies = @(@{ package = 'offline-package'; versionNumber = '1.0.0.LATEST' }) })
        packageAliases = @{ 'offline-package' = 'offline-package-id' }
        packageKeyConfig = @{ 'offline-package' = $false }
    }
    Add-Rule sf @('package', 'version', 'list') $VersionJson
    Add-Rule sf @('package', 'version', 'report') '{"status":0,"result":{"SubscriberPackageVersionId":"offline-version","Package2Id":"offline-package-id","MajorVersion":1,"MinorVersion":0,"PatchVersion":0,"BuildNumber":3,"SubscriberPackageVersion":{"Dependencies":null}}}'
    Add-Rule sf @('package', 'installed', 'list') '{"status":0,"result":[]}'
}

function Invoke-Scenario {
    param(
        [string[]]$Options = @(),
        [string]$Executable = $HostPath,
        [string[]]$LeadingArguments = @('-NoLogo', '-NoProfile', '-File', $ScriptPath),
        [switch]$AllowUnexpected,
        [switch]$WithoutRuntime,
        [switch]$ObserveProgress
    )
    Write-Json (Join-Path $ProjectDirectory 'sf-project.config.json') $Config
    Write-Json $RulePath @($Rules)
    [IO.File]::WriteAllText($LogPath, '')
    $info = [Diagnostics.ProcessStartInfo]::new($Executable)
    $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.WorkingDirectory = $ProjectDirectory
    if ($IsWindows -and $Executable -eq $env:ComSpec) {
        $info.Arguments = '/d /s /c "' + $LeadingArguments[-1] + '"'
    } else {
        foreach ($argument in @($LeadingArguments) + @($Options)) { $info.ArgumentList.Add($argument) }
    }
    foreach ($name in @($info.Environment.Keys)) {
        if ($name -match '^(ORG_ALIAS|DURATION_DAYS|PROJECT_FILE|SF_|SFDX_|SCRATCH_|DUMMY_|COMMUNITY_|PERMISSION_|POST_STEPS|PACKAGE_|PACKAGES_|POOL_|USE_POOL|COVERAGE_|FALLBACK_|RUN_|INSTALL_|VERIFY_|DRY_RUN|FULL_DEPLOY|NO_COLOR|FORCE_COLOR|VERBOSE|CI|TERM|LC_ALL|LC_CTYPE|LANG)') {
            $info.Environment.Remove($name) | Out-Null
        }
    }
    $paths = @($FakeBin)
    $paths += Split-Path -Parent $NodePath
    if ($IsWindows) {
        $paths += Join-Path $env:SystemRoot 'System32'
        if (-not $WithoutRuntime) { $paths += $PSHOME }
    }
    $info.Environment['PATH'] = $paths -join [IO.Path]::PathSeparator
    $info.Environment['HOME'] = $WorkDirectory
    $info.Environment['TMPDIR'] = $WorkDirectory
    $info.Environment['TEMP'] = $WorkDirectory
    $info.Environment['TMP'] = $WorkDirectory
    $info.Environment['USERPROFILE'] = $WorkDirectory
    $info.Environment['SF_CONFIG_DIR'] = $WorkDirectory
    $info.Environment['SF_DISABLE_TELEMETRY'] = 'true'
    $info.Environment['SCRATCH_TEST_RULES'] = $RulePath
    $info.Environment['SCRATCH_TEST_LOG'] = $LogPath
    $info.Environment['SCRATCH_TEST_HOST'] = $HostPath
    $info.Environment['SCRATCH_TEST_FIXTURE'] = Join-Path $PSScriptRoot 'fixtures/scratch-cli.ps1'
    $info.Environment['PACKAGE_INSTALL_MAX_ATTEMPTS'] = '1'
    $info.Environment['TERM'] = 'dumb'
    foreach ($entry in $Overrides.GetEnumerator()) { $info.Environment[$entry.Key] = $entry.Value }
    $process = [Diagnostics.Process]::Start($info)
    try {
        $stderr = $process.StandardError.ReadToEndAsync()
        $prefix = ''
        $liveProgress = $false
        if ($ObserveProgress) {
            $watch = [Diagnostics.Stopwatch]::StartNew()
            while ($watch.Elapsed.TotalSeconds -lt 30) {
                $lineTask = $process.StandardOutput.ReadLineAsync()
                if (-not $lineTask.Wait(30000)) { $process.Kill($true); throw 'Timed out waiting for progress output.' }
                $line = $lineTask.Result
                if ($null -eq $line) { break }
                $prefix += $line + "`n"
                if ($line -match 'Still running:') { $liveProgress = -not $process.HasExited; break }
            }
        }
        $stdout = $process.StandardOutput.ReadToEndAsync()
        if (-not $process.WaitForExit(60000)) { $process.Kill($true); throw 'Offline scenario timed out.' }
        $result = [pscustomobject]@{ ExitCode = $process.ExitCode; Output = $prefix + $stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult(); LiveProgress = $liveProgress }
    } finally { $process.Dispose() }
    $script:Calls = @(Get-Content -LiteralPath $LogPath | ForEach-Object { $_ | ConvertFrom-Json })
    if (-not $AllowUnexpected) {
        $unexpected = @($Calls | Where-Object unexpected).Count -gt 0
        $message = if ($unexpected) { "Unexpected CLI calls: $($result.Output)" } else { 'no unexpected CLI calls' }
        Assert-True (-not $unexpected) $message
    }
    return $result
}

function Invoke-IntegrationScenario {
    Reset-Scenario
    $repositoryRoot = Split-Path -Parent $BinDirectory
    $script:Config = Get-Content -LiteralPath (Join-Path $repositoryRoot 'sf-project.config.json') -Raw | ConvertFrom-Json -AsHashtable
    $integrationProject = Get-Content -LiteralPath (Join-Path $repositoryRoot 'sfdx-project.json') -Raw | ConvertFrom-Json
    Write-Json (Join-Path $ProjectDirectory 'sfdx-project.json') $integrationProject
    $dependencies = @($integrationProject.packageDirectories | Where-Object package -eq 'crm-platform-integration' | ForEach-Object { $_.dependencies })
    Assert-True ($Config.defaultOrgAlias -eq 'crm-platform-integration' -and $Config.pool.use -and $Config.pool.tag -eq 'dev' -and -not $Config.pool.fallbackToCreate) 'integration config retains alias and pool-only contract'
    Assert-True (($Config.postSteps -join ',') -eq 'deploy' -and $Config.permissionSets.Count -eq 0 -and -not $Config.dummyDataPlan -and -not $Config.communityName -and -not $Config.dummyUsers) 'integration config has no application-specific post-steps or users'
    Assert-True ($dependencies.Count -gt 0) 'integration manifest declares package dependencies'
    foreach ($dependency in $dependencies) {
        $parts = $dependency.versionNumber.Split('.')
        $version = @{
            MajorVersion = [int]$parts[0]; MinorVersion = [int]$parts[1]; PatchVersion = [int]$parts[2]
            BuildNumber = 1; VersionNumber = "$($parts[0]).$($parts[1]).$($parts[2]).1"
            SubscriberPackageVersionId = "offline-$($dependency.package)"
        }
        Add-Rule sf @('package', 'version', 'list', '--packages', $dependency.package) (ConvertTo-Json -InputObject @{ status = 0; result = @($version) } -Depth 10 -Compress)
        $report = $version.Clone()
        $report.Package2Id = "offline-package-$($dependency.package)"
        $report.SubscriberPackageVersion = @{ Dependencies = $null }
        Add-Rule sf @('package', 'version', 'report', '--package', $version.SubscriberPackageVersionId) (ConvertTo-Json -InputObject @{ status = 0; result = $report } -Depth 10 -Compress)
    }
    $Overrides['PACKAGE_INSTALL_KEY'] = 'offline-integration-key'
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 1'
    Add-Rule sfp @('pool', 'fetch')
    Add-Rule sf @('org', 'delete', 'scratch')
    Add-Rule sf @('package', 'installed', 'list') '{"status":0,"result":[]}'
    Add-Rule sf @('package', 'install')
    Add-Rule sf @('project', 'deploy', 'start')
    Add-Rule sf @('project', 'reset', 'tracking')
    $result = Invoke-Scenario -Options @('-PoolDevHub', 'offline-hub')
    Assert-Exit $result 0 'actual PowerShell integration-config flow completes offline'
    Assert-True (@($Calls | Where-Object { $_.tool -eq 'sfp' -and $_.arguments[1] -eq 'fetch' }).Count -eq 1) 'integration flow fetches pool with sfp'
    Assert-True (@($Calls | Where-Object { $_.arguments[0] -eq 'package' -and $_.arguments[1] -eq 'install' }).Count -eq $dependencies.Count) 'integration flow installs every declared dependency'
    foreach ($dependency in $dependencies) {
        Assert-True (@($Calls | Where-Object { $_.arguments[0] -eq 'package' -and $_.arguments[1] -eq 'install' -and $_.arguments -contains "offline-$($dependency.package)" }).Count -eq 1) "integration flow installs selected version for $($dependency.package)"
    }
    $deployment = @($Calls | Where-Object { $_.arguments[0] -eq 'project' -and $_.arguments[1] -eq 'deploy' })
    Assert-True ($deployment.Count -eq 1 -and $deployment[0].arguments[4] -eq 'crm-platform-integration') 'integration deploy targets its own alias'
    Assert-True (@($Calls | Where-Object { ($_.arguments[0] -eq 'org' -and $_.arguments[1] -in @('create', 'assign')) -or $_.arguments[0] -in @('data', 'community') }).Count -eq 0) 'integration flow never creates scratch orgs or imports application data'
    Assert-True ($result.Output -notmatch 'offline-integration-key') 'integration output never exposes key'
    $result = Invoke-Scenario -Options @('-PoolDevHub', 'offline-hub', '-DryRun')
    Assert-Exit $result 0 'integration-config dry-run succeeds'
    Assert-True (@($Calls | Where-Object { -not ($_.arguments[0] -eq 'pool' -and $_.arguments[1] -eq 'list') -and -not ($_.arguments[0] -eq 'package' -and $_.arguments[1] -in @('version', 'installed')) }).Count -eq 0) 'integration dry-run executes reads only'
    $script:Rules = @($Rules | Where-Object { -not ($_.tool -eq 'sfp' -and $_.prefix[1] -eq 'list') })
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 0'
    $result = Invoke-Scenario -Options @('-PoolDevHub', 'offline-hub')
    Assert-Exit $result 1 'integration empty pool fails without fallback'
    Assert-True ($result.Output -match 'No unused scratch org') 'integration empty pool explains why setup stopped'
    Assert-True (@($Calls | Where-Object { -not ($_.arguments[0] -eq 'pool' -and $_.arguments[1] -eq 'list') -and -not ($_.arguments[0] -eq 'package' -and $_.arguments[1] -in @('version', 'installed')) }).Count -eq 0) 'integration empty pool fails before mutation'

}

function Assert-Exit {
    param($Result, [int]$Expected, [string]$Message)
    $detail = if ($Result.ExitCode -eq $Expected) { $Message } else { "$Message (exit $($Result.ExitCode)): $($Result.Output)" }
    Assert-True ($Result.ExitCode -eq $Expected) $detail
}

function Assert-InvalidConfig {
    param([string]$Name, [scriptblock]$Mutation, [string]$ExpectedMessage)
    Reset-Scenario
    & $Mutation
    $result = Invoke-Scenario -Options @('-DryRun')
    Assert-Exit $result 1 "invalid configuration is rejected: $Name"
    Assert-True ($result.Output.Contains($ExpectedMessage)) "invalid configuration explains $Name"
    Assert-True ($Calls.Count -eq 0) "invalid configuration has no CLI side effects: $Name"
}

try {
    New-Item -ItemType Directory -Path $ProjectDirectory, $FakeBin | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $ProjectDirectory 'config') | Out-Null
    Write-Json (Join-Path $ProjectDirectory 'config/project-scratch-def.json') @{ edition = 'Developer' }
    $fixture = Join-Path $PSScriptRoot 'fixtures/scratch-cli.ps1'
    foreach ($tool in @('sf', 'sfp')) {
        if ($IsWindows) {
            "@echo off`r`n`"%SCRATCH_TEST_HOST%`" -NoLogo -NoProfile -File `"%SCRATCH_TEST_FIXTURE%`" $tool %*`r`nexit /b %errorlevel%`r`n" |
                Set-Content -LiteralPath (Join-Path $FakeBin "$tool.cmd") -Encoding ascii
        } else {
            $wrapper = Join-Path $FakeBin $tool
            "#!/bin/sh`nexec '$($HostPath.Replace("'", "'\''"))' -NoLogo -NoProfile -File '$($fixture.Replace("'", "'\''"))' $tool `"`$@`"`n" |
                Set-Content -LiteralPath $wrapper -Encoding utf8NoBOM
            [IO.File]::SetUnixFileMode($wrapper, [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute)
        }
    }
    Write-Host "Runtime: $($PSVersionTable.PSVersion); OS: $([Runtime.InteropServices.RuntimeInformation]::OSDescription)"
    foreach ($file in @($ScriptPath, $PSCommandPath, $fixture)) {
        $parseErrors = $null; $tokens = $null
        [Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$parseErrors) | Out-Null
        Assert-True ($parseErrors.Count -eq 0) "parses: $file"
    }

    Reset-Scenario
    $result = Invoke-Scenario -Options @('-Help')
    Assert-Exit $result 0 'help succeeds without CLI calls'
    Assert-True ($Calls.Count -eq 0) 'help is offline'
    $guardCommand = "`$PSVersionTable.PSVersion = [version]'5.1'; & '$($ScriptPath.Replace("'", "''"))' -Help"
    $result = Invoke-Scenario -LeadingArguments @('-NoLogo', '-NoProfile', '-Command', $guardCommand)
    Assert-Exit $result 1 'runtime guard rejects simulated 5.1 before help or side effects'
    Assert-True ($result.Output -match 'PowerShell 7 LTS is required' -and $Calls.Count -eq 0) 'runtime guard gives migration guidance (not a real 5.1 test)'

    Reset-Scenario
    $result = Invoke-Scenario -Options @('-InitConfig', '-DryRun')
    Assert-Exit $result 0 'config preview succeeds with one post-step'
    Assert-True ($result.Output -match '"postSteps":\s*\[\s*"deploy"') 'single-item arrays remain arrays'
    Assert-True ($Calls.Count -eq 0) 'init-config preview is offline'
    $result = Invoke-Scenario -Options @('-InitConfig', '-Force', '-OrgAlias', 'written-org')
    Assert-Exit $result 0 'explicit config write succeeds in temporary project'
    $written = Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sf-project.config.json') -Raw | ConvertFrom-Json
    Assert-True ($written.defaultOrgAlias -eq 'written-org') 'config write persists CLI override'

    Reset-Scenario
    $Overrides['ORG_ALIAS'] = 'environment-org'
    $result = Invoke-Scenario -Options @('-InitConfig', '-DryRun', '-OrgAlias', 'cli-org')
    Assert-Exit $result 0 'CLI overrides environment and config'
    Assert-True ($result.Output -match '"defaultOrgAlias":\s*"cli-org"') 'CLI alias is used'
    $result = Invoke-Scenario -Options @('-InitConfig', '-DryRun')
    Assert-True ($result.Output -match '"defaultOrgAlias":\s*"environment-org"') 'environment overrides config'

    Reset-Scenario
    $Config['scratchDurationDays'] = 31
    $result = Invoke-Scenario -Options @('-InitConfig', '-DryRun')
    Assert-Exit $result 1 'invalid config fails'
    Assert-True ($result.Output -match 'scratchDurationDays') 'invalid config has actionable error'
    Assert-True ($Calls.Count -eq 0) 'invalid config fails before CLI'

    Reset-Scenario
    New-Item -ItemType Directory -Path (Join-Path $ProjectDirectory 'data') | Out-Null
    Write-Json (Join-Path $ProjectDirectory 'data/Plan.json') @()
    Write-Json (Join-Path $ProjectDirectory 'data/User.json') @{ records = @(@{ Username = 'handler@example.test' }) }
    $Config['dummyDataPlan'] = 'data/Plan.json'
    $Config.postSteps = @('data')
    $Config['dummyUsers'] = @{
        file = 'data/User.json'
        profileName = 'Standard User'
        profileAssignments = @(
            @{ profileName = 'Case Handler'; usernames = @('handler@example.test') },
            @{ profileName = 'Support User'; usernames = @('support@example.test') }
        )
    }
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-DryRun')
    Assert-Exit $result 0 'dummy-user profile preview succeeds'
    Assert-True ($result.Output -match '(?s)(?=.*Case Handler)(?=.*Standard User)(?=.*Support User)') 'profile preview includes configured and fallback profiles'
    $Config.dummyUsers.profileAssignments[1].usernames = @('handler@example.test')
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-DryRun')
    Assert-Exit $result 1 'duplicate profile mappings fail'
    Assert-True ($result.Output -match 'only one profile assignment') 'duplicate mappings have actionable error'

    Reset-Scenario
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-PostSteps', 'deploy', '-DryRun')
    Assert-Exit $result 0 'deploy preview succeeds without CLI'
    Assert-True ($Calls.Count -eq 0) 'deploy preview makes no calls'

    Reset-Scenario
    Add-Rule sf @('project', 'deploy', 'start')
    Add-Rule sf @('project', 'reset', 'tracking')
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-PostSteps', 'deploy')
    Assert-Exit $result 0 'deploy succeeds'
    Assert-True ($Calls.Count -eq 2 -and $Calls[0].arguments[1] -eq 'deploy') 'deploy precedes tracking reset'

    Reset-Scenario
    Add-Rule sf @('project', 'deploy', 'start') '' 9 'offline deployment failed'
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-PostSteps', 'deploy')
    Assert-Exit $result 1 'deploy failure propagates'
    Assert-True ($Calls.Count -eq 1 -and $result.Output -match 'offline deployment failed') 'no tracking reset after failure'

    Reset-Scenario
    $Config.pool.use = $true
    $Config.pool.devHub = 'offline-hub'
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 1'
    Add-Rule sfp @('pool', 'fetch')
    Add-Rule sf @('org', 'delete', 'scratch')
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 0 'configured pool uses sfp fetch'
    Assert-True (@($Calls | Where-Object { $_.tool -eq 'sfp' -and $_.arguments[1] -eq 'fetch' }).Count -eq 1) 'pool fetch uses sfp, not sf'

    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none', '-DryRun')
    Assert-Exit $result 0 'pool dry-run succeeds'
    Assert-True ($Calls.Count -eq 1 -and $Calls[0].arguments[1] -eq 'list') 'pool dry-run only reads pool status, never deletes org'

    Reset-Scenario
    $Config.pool.use = $true; $Config.pool.devHub = 'offline-hub'
    Add-Rule sfp @('pool', 'list') '' 6 'offline pool listing failed'
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 1 'pool list failure propagates without create fallback'
    Assert-True ($Calls.Count -eq 1 -and $result.Output -match 'offline pool listing failed') 'pool list error is visible without mutations'

    Reset-Scenario
    $Config.pool.use = $true; $Config.pool.devHub = 'offline-hub'
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 0'
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 1 'empty pool without fallback fails'
    Assert-True ($Calls.Count -eq 1) 'empty pool does not create or delete an org'

    Reset-Scenario
    $Config.pool.use = $true; $Config.pool.devHub = 'offline-hub'
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 1'
    Add-Rule sf @('org', 'delete', 'scratch')
    Add-Rule sfp @('pool', 'fetch') '' 8 'offline fetch failed'
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 1 'pool fetch failure propagates'
    Assert-True ($result.Output -match 'offline fetch failed') 'pool fetch error is visible'

    Reset-Scenario
    Set-PackageProject
    Add-Rule sf @('package', 'install')
    $result = Invoke-Scenario -Options @('-SkipOrg', '-PostSteps', 'none')
    Assert-Exit $result 0 'missing package installs'
    Assert-True (@($Calls | Where-Object { $_.arguments[1] -eq 'install' }).Count -eq 1) 'package install was executed'
    $result = Invoke-Scenario -Options @('-PackagePlan')
    Assert-Exit $result 0 'package plan succeeds'
    Assert-True (@($Calls | Where-Object { $_.arguments[1] -eq 'install' }).Count -eq 0) 'package plan never installs'
    $result = Invoke-Scenario -Options @('-UpdatePackages')
    Assert-Exit $result 0 'package update installs missing package'

    Reset-Scenario
    Set-PackageProject
    $script:Rules = @($Rules | Where-Object { $_.prefix[1] -ne 'installed' })
    Add-Rule sf @('package', 'installed', 'list') '{"status":0,"result":[{"SubscriberPackageName":"offline-package","SubscriberPackageVersionNumber":"1.0.0.3"}]}'
    $result = Invoke-Scenario -Options @('-UpdatePackages')
    Assert-Exit $result 0 'current package is not reinstalled'
    Assert-True (@($Calls | Where-Object { $_.arguments[1] -eq 'install' }).Count -eq 0) 'current package skipped'

    foreach ($output in @("CLI warning`n$VersionJson", 'not JSON', '', '{"broken":', '{"status":1,"message":"offline JSON failure"}')) {
        Reset-Scenario
        Set-PackageProject
        $script:Rules = @($Rules | Where-Object { $_.prefix[1] -ne 'version' })
        Add-Rule sf @('package', 'version', 'list') $output
        $result = Invoke-Scenario -Options @('-CheckVersions')
        $expected = if ($output.StartsWith('CLI warning')) { 0 } else { 1 }
        Assert-Exit $result $expected "JSON output handling: $output"
        Assert-True ($Calls.Count -eq 1) 'JSON scenario reached the fake CLI'
        if ($output -eq 'not JSON' -or $output -eq '') {
            Assert-True ($result.Output -match 'returned no JSON') 'empty/invalid output has actionable JSON error'
        } elseif ($output -eq '{"broken":') {
            Assert-True ($result.Output -match 'Could not parse JSON') 'malformed JSON has actionable error'
        } elseif ($output.StartsWith('{"status":1')) {
            Assert-True ($result.Output -match 'offline JSON failure') 'failed JSON status is surfaced'
        }
    }

    Reset-Scenario
    Set-PackageProject
    $project = Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Raw | ConvertFrom-Json
    $project.packageDirectories[0].dependencies[0].versionNumber = '0.9.0.LATEST'
    $project.packageDirectories += [pscustomobject]@{
        path = 'second-package'
        dependencies = @([pscustomobject]@{ package = 'offline-package'; versionNumber = '0.9.0.NEXT' })
    }
    Write-Json (Join-Path $ProjectDirectory 'sfdx-project.json') $project
    $originalProject = Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Raw
    $result = Invoke-Scenario -Options @('-CheckVersions')
    Assert-Exit $result 0 'version preview succeeds'
    Assert-True ($result.Output -match '0\.9\.0\.LATEST -> 1\.0\.0\.LATEST') 'preview reports version change'
    Assert-True ((Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Raw) -ceq $originalProject) 'version preview preserves project file exactly'
    $result = Invoke-Scenario -Options @('-ApplyProjectVersions')
    Assert-Exit $result 0 'explicit version apply succeeds'
    Assert-True ((Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json.backup') -Raw) -ceq $originalProject) 'version apply preserves exact backup'
    $updatedProject = Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Raw | ConvertFrom-Json
    Assert-True ($updatedProject.packageDirectories[1].dependencies[0].versionNumber -eq '1.0.0.LATEST') 'version apply updates duplicate dependency declarations'

    Reset-Scenario
    $Config.postSteps = @('capture')
    $expectedArguments = @('capture', 'two words', '', 'say "hello"', 'norsk ø')
    $Config['customPostSteps'] = @(@{ name = 'capture'; executable = 'sf'; arguments = $expectedArguments })
    Add-Rule sf @('capture')
    $result = Invoke-Scenario -Options @('-PostStepsOnly')
    Assert-Exit $result 0 'custom post-step succeeds'
    Assert-True (($Calls[0].arguments | ConvertTo-Json -Compress) -ceq ($expectedArguments | ConvertTo-Json -Compress)) "native argument boundaries preserved: $($Calls[0].arguments | ConvertTo-Json -Compress)"

    Reset-Scenario
    Set-PackageProject
    $project = Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Raw | ConvertFrom-Json
    $project.packageKeyConfig.'offline-package' = $true
    Write-Json (Join-Path $ProjectDirectory 'sfdx-project.json') $project
    $Overrides['PACKAGE_INSTALL_KEY'] = 'offline-secret-marker'
    Add-Rule sf @('package', 'install') 'failure echoed offline-secret-marker' 5
    $result = Invoke-Scenario -Options @('-SkipOrg', '-PostSteps', 'none')
    Assert-Exit $result 1 'install failure propagates'
    Assert-True ($result.Output -notmatch 'offline-secret-marker') 'install key never appears in output'
    Assert-True ((Get-Content -LiteralPath $LogPath -Raw) -notmatch 'offline-secret-marker') 'fake CLI journal redacts key arguments'
    $script:Rules = @($Rules | Where-Object { $_.prefix[1] -ne 'install' })
    Add-Rule sf @('package', 'install') 'successful install echoed offline-secret-marker'
    $result = Invoke-Scenario -Options @('-SkipOrg', '-PostSteps', 'none', '-Verbose')
    Assert-Exit $result 0 'verbose install succeeds'
    Assert-True ($result.Output -match 'successful install echoed \*\*\*' -and $result.Output -notmatch 'offline-secret-marker') 'verbose successful CLI output redacts the install key'

    Reset-Scenario
    Add-Rule sf @('--version')
    Add-Rule sf @('org', 'list')
    Add-Rule sf @('org', 'display') '' 4 'offline sf failure'
    $result = Invoke-Scenario -Options @('-SelfCheck')
    Assert-Exit $result 1 'self-check propagates CLI failures'
    Assert-True ($result.Output -match 'offline sf failure') 'self-check surfaces stderr'

    Reset-Scenario
    $result = Invoke-Scenario -Options @('-CoverageCheck', '-DryRun', '-CoveragePackageId', 'offline-version')
    Assert-Exit $result 0 'coverage preview succeeds offline'
    Assert-True ($result.Output -match 'Query % aggregate coverage' -and $Calls.Count -eq 0) 'coverage preview never invokes CLI'

    Reset-Scenario
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-PostSteps', 'deploy') -AllowUnexpected
    Assert-Exit $result 1 'unexpected fake CLI command fails closed'
    Assert-True (@($Calls | Where-Object unexpected).Count -eq 1) 'unexpected call is recorded, not sent to real CLI'

    Reset-Scenario
    Set-PackageProject
    Add-Rule sf @('org', 'delete', 'scratch')
    Add-Rule sf @('org', 'create', 'scratch')
    Add-Rule sf @('package', 'install') 'successful install detail'
    Add-Rule sf @('project', 'deploy', 'start')
    Add-Rule sf @('project', 'reset', 'tracking')
    $result = Invoke-Scenario
    Assert-Exit $result 0 'full setup output succeeds'
    foreach ($text in @('Scratch org setup', 'Target', 'offline-org', 'Active modes', '[1/3] Scratch org', '[2/3] Packages', '[3/3] Post-steps', '[1/1] offline-package', '[1/1] deploy', 'Run summary', 'SUCCESS', 'Installed', 'Duration', 'Started', 'Ended')) {
        Assert-True ($result.Output.Contains($text)) "output includes $text"
    }
    Assert-True ($result.Output -notmatch 'successful install detail|SubscriberPackageVersionId') 'default output hides successful raw CLI/JSON noise'
    Assert-True ($result.Output -notmatch "`e\[|`r(?!`n)") 'redirected output has no ANSI codes or animation'
    Assert-True ($result.Output -match 'Installed\s+1' -and $result.Output -match 'Ran\s+deploy') 'summary counts only completed install and post-step'
    $result = Invoke-Scenario -Options @('-Verbose')
    Assert-True ($result.Output -match 'successful install detail') 'verbose includes successful CLI details'

    Reset-Scenario
    Set-PackageProject
    $script:Rules = @($Rules | Where-Object { $_.prefix[1] -ne 'installed' })
    Add-Rule sf @('package', 'installed', 'list') '{"status":0,"result":[{"SubscriberPackageName":"offline-package","SubscriberPackageVersionNumber":"2.0.0.1"}]}'
    $result = Invoke-Scenario -Options @('-UpdatePackages')
    Assert-Exit $result 0 'higher installed version is preserved'
    Assert-True ($result.Output -match 'Higher\s+1' -and $result.Output -match 'Not downgrading') 'higher-version skip is visible in summary'
    Assert-True (@($Calls | Where-Object { $_.arguments[1] -eq 'install' }).Count -eq 0) 'output changes never trigger a downgrade'

    Reset-Scenario
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-PostSteps', 'permsets')
    Assert-Exit $result 0 'unconfigured post-step is explicitly skipped'
    Assert-True ($result.Output -match 'Skipped: permsets' -and $result.Output -match 'Ran\s+none') 'skipped post-step is not counted as run'
    Assert-True ($result.Output -match 'COMPLETED WITH WARNINGS' -and $Calls.Count -eq 0) 'warnings are not presented as unconditional success'

    Reset-Scenario
    $Config.Remove('defaultOrgAlias')
    Add-Rule sf @('config', 'get', 'target-org') '{"status":0,"result":[{"name":"target-org","value":"offline-default"}]}'
    Add-Rule sf @('project', 'deploy', 'start')
    Add-Rule sf @('project', 'reset', 'tracking')
    $result = Invoke-Scenario -Options @('-PostStepsOnly')
    Assert-Exit $result 0 'partial run resolves CLI default target'
    Assert-True ($result.Output -match 'Effective target org\s+offline-default') 'resolved CLI default is shown before work'
    Assert-True ($result.Output.IndexOf('Effective target org') -lt $result.Output.IndexOf('Deploying metadata')) 'effective target appears before deployment starts'

    Reset-Scenario
    Add-Rule sf @('project', 'deploy', 'start') 'offline deployment detail' 9
    $result = Invoke-Scenario -Options @('-PostStepsOnly')
    Assert-Exit $result 1 'failed output scenario fails'
    Assert-True ($result.Output -match 'FAILED' -and $result.Output -match 'offline deployment detail') 'failure summary includes CLI details'
    Assert-True ($result.Output -notmatch 'Post-steps completed|Ran\s+deploy|SUCCESS') 'failed step is not reported completed'

    Reset-Scenario
    Add-Rule sf @('project', 'deploy', 'start') -DelaySeconds 7
    Add-Rule sf @('project', 'reset', 'tracking')
    $result = Invoke-Scenario -Options @('-PostStepsOnly') -ObserveProgress
    Assert-Exit $result 0 'delayed deployment succeeds'
    Assert-True $result.LiveProgress 'elapsed progress is emitted before the subprocess exits'
    Assert-True ($result.Output -match 'Still running:.*[0-9]+s') 'long operation reports elapsed seconds'

    foreach ($style in @('default', 'force', 'no-color', 'explicit-color', 'explicit-no-color')) {
        Reset-Scenario
        $options = @('-PostStepsOnly', '-DryRun')
        if ($style -ne 'default') { $Overrides['FORCE_COLOR'] = '1' }
        if ($style -in @('no-color', 'explicit-color')) { $Overrides['NO_COLOR'] = '1' }
        if ($style -eq 'explicit-color') { $options += '-Color' }
        if ($style -eq 'explicit-no-color') { $options += '-NoColor' }
        $result = Invoke-Scenario -Options $options
        Assert-Exit $result 0 "$style output succeeds"
        $expectedColor = $style -in @('force', 'explicit-color')
        Assert-True (($result.Output -match "`e\[") -eq $expectedColor) "$style color precedence"
        Assert-True ($Calls.Count -eq 0 -and $result.Output -match 'DRY RUN') 'dry-run is labelled as planned, not executed'
    }

    Reset-Scenario
    $Overrides['LC_ALL'] = 'C'
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-DryRun', '-DurationDays', '7')
    Assert-True ($result.Output -notmatch '[✔✖⚠▸•○]') 'non-UTF8 locale uses readable ASCII status markers'
    Assert-True ($result.Output -match 'Duration days\s+7') 'settings show the effective CLI override'
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-DryRun', '-Color', '-NoColor')
    Assert-Exit $result 1 'conflicting color options fail before CLI'
    Assert-True ($Calls.Count -eq 0) 'output option validation has no org side effects'

    Invoke-IntegrationScenario

    Reset-Scenario
    Set-PackageProject
    $script:Rules[0].delaySeconds = 6
    $result = Invoke-Scenario -Options @('-CheckDependencies') -ObserveProgress
    Assert-Exit $result 0 'standalone dependency check succeeds after a slow metadata read'
    Assert-True $result.LiveProgress 'dependency check heartbeat is visible before the subprocess exits'
    Assert-True ($result.Output -match '\[1/1\] offline-package' -and $result.Output -match 'Selected 1.0.0.3') 'dependency progress names the active package and selected version'
    Assert-True (([regex]::Matches($result.Output, 'Package dependency check')).Count -eq 1) 'dependency output is streamed once, not replayed'
    Assert-True ($result.Output -notmatch "`e\[|`r(?!`n)") 'redirected dependency progress contains no terminal control sequences'
    Assert-True ((Get-Content -LiteralPath (Join-Path $ProjectDirectory 'package-dependencies-report.md') -Raw) -match '```mermaid') 'completed dependency check writes a Mermaid Markdown report'
    Assert-True ((Get-Content -LiteralPath (Join-Path $ProjectDirectory 'package-dependencies-report.html') -Raw) -match 'Dependency graph explorer') 'completed dependency check writes the offline interactive HTML companion'
    $script:Rules[0].delaySeconds = 0
    foreach ($style in @('Color', 'NoColor')) {
        $Overrides['NO_COLOR'] = '1'
        $Overrides['FORCE_COLOR'] = '1'
        $result = Invoke-Scenario -Options @('-CheckDependencies', "-$style")
        Assert-Exit $result 0 "$style dependency check succeeds"
        Assert-True (($result.Output -match "`e\[1;36mDependency graph") -eq ($style -eq 'Color')) "$style is forwarded to the streamed dependency graph"
        Assert-True ($result.Output -match 'Missing packages: 0') 'dependency output separates missing packages from other problems'
    }
    $report = Join-Path $ProjectDirectory 'custom dependency report.md'
    $result = Invoke-Scenario -Options @('-CheckDependencies', '-DependencyReport', $report)
    Assert-Exit $result 0 'custom dependency report path is forwarded'
    Assert-True ((Get-Content -LiteralPath $report -Raw) -match 'Version inventory') 'custom report includes exact version inventory'
    Assert-True ((Get-Content -LiteralPath ([IO.Path]::ChangeExtension($report, '.html')) -Raw) -match 'data-action="clear"') 'custom report basename is used for the interactive HTML companion'
    $result = Invoke-Scenario -Options @('-DependencyReport', (Join-Path $ProjectDirectory 'absent/report.md'))
    Assert-Exit $result 1 'report write failure blocks setup'
    Assert-True (@($Calls | Where-Object { $_.arguments[0] -ne 'package' -or $_.arguments[1] -ne 'version' }).Count -eq 0) 'report write failure starts no org mutations'

    Reset-Scenario
    Set-PackageProject
    $project = Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Raw | ConvertFrom-Json
    $project.packageAliases | Add-Member -NotePropertyName 'offline-child' -NotePropertyValue 'offline-child-package'
    Write-Json (Join-Path $ProjectDirectory 'sfdx-project.json') $project
    $original = Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Raw
    $script:Rules = @($Rules | Where-Object { $_.prefix[2] -ne 'report' })
    Add-Rule sf @('package', 'version', 'report', '--package', 'offline-version') '{"status":0,"result":{"SubscriberPackageVersionId":"offline-version","Package2Id":"offline-package-id","MajorVersion":1,"MinorVersion":0,"PatchVersion":0,"BuildNumber":3,"SubscriberPackageVersion":{"Dependencies":{"ids":[{"subscriberPackageVersionId":"offline-child-version"}]}}}}'
    Add-Rule sf @('package', 'version', 'report', '--package', 'offline-child-version') '{"status":0,"result":{"SubscriberPackageVersionId":"offline-child-version","Package2Id":"offline-child-package","MajorVersion":1,"MinorVersion":0,"PatchVersion":0,"BuildNumber":1,"SubscriberPackageVersion":{"Dependencies":null}}}'
    $result = Invoke-Scenario
    Assert-Exit $result 1 'missing transitive dependency blocks full setup'
    Assert-True ($result.Output -match 'offline-child' -and $result.Output -match '1.0.0.1') 'preflight reports requiring package and missing exact version'
    Assert-True (@($Calls | Where-Object { $_.arguments[0] -ne 'package' -or $_.arguments[1] -ne 'version' }).Count -eq 0) 'failed dependency preflight runs no deletion, creation, pool fetch or install'
    Assert-True ((Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Raw) -ceq $original) 'default check preserves original manifest bytes'
    $result = Invoke-Scenario -Options @('-ApplyDependencies')
    Assert-Exit $result 0 'explicit dependency apply updates manifest without org mutations'
    Assert-True ((Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json.dependencies.backup') -Raw) -ceq $original) 'dependency apply preserves exact backup'
    $applied = Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Raw | ConvertFrom-Json
    Assert-True ($applied.packageDirectories[0].dependencies[0].package -eq 'offline-child' -and $applied.packageDirectories[0].dependencies[0].versionNumber -eq '1.0.0.1') 'apply inserts exact child version before parent'
    $result = Invoke-Scenario -Options @('-ApplyDependencies', '-DryRun')
    Assert-Exit $result 1 'dependency apply and dry-run cannot be combined'

    foreach ($case in @(
        @{ Name = 'schema version'; Expected = 'Unsupported schemaVersion'; Change = { $script:Config['schemaVersion'] = 2 } },
        @{ Name = 'duration type'; Expected = 'scratchDurationDays must be an integer'; Change = { $script:Config['scratchDurationDays'] = 14.5 } },
        @{ Name = 'permissionSets array'; Expected = 'permissionSets must be an array'; Change = { $script:Config['permissionSets'] = 'Admins' } },
        @{ Name = 'permissionSets values'; Expected = 'permissionSets must contain non-empty strings'; Change = { $script:Config['permissionSets'] = @('') } },
        @{ Name = 'postSteps values'; Expected = "Unknown post step"; Change = { $script:Config['postSteps'] = @('not-a-step') } },
        @{ Name = 'customPostSteps array'; Expected = 'customPostSteps must be an array'; Change = { $script:Config['customPostSteps'] = 'capture' } },
        @{ Name = 'customPostSteps entry'; Expected = 'require non-empty name and executable'; Change = { $script:Config['customPostSteps'] = @(@{ name = ''; executable = 'sf' }) } },
        @{ Name = 'customPostSteps arguments'; Expected = 'customPostSteps.arguments must be a string array'; Change = { $script:Config['customPostSteps'] = @(@{ name = 'capture'; executable = 'sf'; arguments = @('ok', 2) }) } },
        @{ Name = 'customPostSteps label'; Expected = 'customPostSteps.label must be a non-empty string'; Change = { $script:Config['customPostSteps'] = @(@{ name = 'capture'; executable = 'sf'; label = '' }) } },
        @{ Name = 'customPostSteps built-in conflict'; Expected = "conflicts with a built-in step"; Change = { $script:Config['customPostSteps'] = @(@{ name = 'deploy'; executable = 'sf' }) } },
        @{ Name = 'pool object'; Expected = 'pool must be an object'; Change = { $script:Config['pool'] = @() } },
        @{ Name = 'pool boolean'; Expected = 'pool.use must be a boolean'; Change = { $script:Config.pool.use = 'true' } },
        @{ Name = 'pool fallback boolean'; Expected = 'pool.fallbackToCreate must be a boolean'; Change = { $script:Config.pool.fallbackToCreate = 'false' } },
        @{ Name = 'pool string'; Expected = 'pool.tag must be a non-empty string'; Change = { $script:Config.pool.tag = '' } },
        @{ Name = 'dependencySourcePolicy object'; Expected = 'dependencySourcePolicy must be an object'; Change = { $script:Config['dependencySourcePolicy'] = @() } },
        @{ Name = 'dependencySourcePolicy boolean'; Expected = 'requireLocalDirectories must be a boolean'; Change = { $script:Config['dependencySourcePolicy'] = @{ requireLocalDirectories = 'yes' } } },
        @{ Name = 'dependencySourcePolicy values'; Expected = 'preserveRootFiles must be an array of non-empty strings'; Change = { $script:Config['dependencySourcePolicy'] = @{ preserveRootFiles = @('') } } },
        @{ Name = 'commandTimeouts object'; Expected = 'commandTimeouts must be an object'; Change = { $script:Config['commandTimeouts'] = @() } },
        @{ Name = 'commandTimeouts readMs'; Expected = 'commandTimeouts.readMs must be a positive integer'; Change = { $script:Config['commandTimeouts'] = @{ readMs = 0 } } },
        @{ Name = 'commandTimeouts mutationMs'; Expected = 'commandTimeouts.mutationMs must be a positive integer'; Change = { $script:Config['commandTimeouts'] = @{ mutationMs = 1.5 } } },
        @{ Name = 'coverage object'; Expected = 'coverage must be an object'; Change = { $script:Config['coverage'] = @() } },
        @{ Name = 'coverage threshold'; Expected = 'coverage.minimumPercent must be a number from 0 to 100'; Change = { $script:Config['coverage'] = @{ minimumPercent = 101 } } },
        @{ Name = 'coverage testClass'; Expected = 'coverage.testClass must be a non-empty string or null'; Change = { $script:Config['coverage'] = @{ testClass = '' } } },
        @{ Name = 'coverage classNamePattern'; Expected = 'coverage.classNamePattern must be a non-empty string'; Change = { $script:Config['coverage'] = @{ classNamePattern = '' } } },
        @{ Name = 'dummyUsers object'; Expected = 'dummyUsers must be an object'; Change = { $script:Config['dummyUsers'] = @() } },
        @{ Name = 'dummyUsers file'; Expected = 'dummyUsers.file is required'; Change = { $script:Config['dummyUsers'] = @{ file = '' } } },
        @{ Name = 'dummyUsers profileAssignments'; Expected = 'dummyUsers.profileAssignments must be an array'; Change = { $script:Config['dummyUsers'] = @{ file = 'users.json'; profileAssignments = 'bad' } } },
        @{ Name = 'dummyUsers profile assignment'; Expected = 'requires profileName and at least one username'; Change = { $script:Config['dummyUsers'] = @{ file = 'users.json'; profileAssignments = @(@{ profileName = 'Admin'; usernames = @() }) } } },
        @{ Name = 'dummyUsers username values'; Expected = 'usernames must be non-empty strings'; Change = { $script:Config['dummyUsers'] = @{ file = 'users.json'; profileAssignments = @(@{ profileName = 'Admin'; usernames = @('') }) } } },
        @{ Name = 'dummyUsers permissionSetAssignments'; Expected = 'dummyUsers.permissionSetAssignments must be an array'; Change = { $script:Config['dummyUsers'] = @{ file = 'users.json'; permissionSetAssignments = 'bad' } } },
        @{ Name = 'dummyUsers permission-set assignment'; Expected = 'requires permissionSets and usernames'; Change = { $script:Config['dummyUsers'] = @{ file = 'users.json'; permissionSetAssignments = @(@{ permissionSets = @(); usernames = @('user@example.test') }) } } },
        @{ Name = 'dummyUsers permission-set values'; Expected = 'permissionSetAssignments values must be non-empty strings'; Change = { $script:Config['dummyUsers'] = @{ file = 'users.json'; permissionSetAssignments = @(@{ permissionSets = @(''); usernames = @('user@example.test') }) } } }
    )) {
        Assert-InvalidConfig -Name $case.Name -Mutation $case.Change -ExpectedMessage $case.Expected
    }

    Reset-Scenario
    $Config.pool.use = $true
    $Config.pool.tag = 'tag with spaces'
    $Config.pool.fallbackToCreate = $true
    Add-Rule sf @('config', 'get', 'target-dev-hub') '{"status":0,"result":[{"name":"target-dev-hub","value":"NAV DevHub"}]}'
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 0'
    Add-Rule sf @('org', 'delete', 'scratch')
    Add-Rule sf @('org', 'create', 'scratch')
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 0 'empty pool falls back to scratch creation'
    Assert-True (@($Calls | Where-Object { $_.tool -eq 'sf' -and $_.arguments[0] -eq 'config' -and $_.arguments[1] -eq 'get' -and $_.arguments[2] -eq 'target-dev-hub' }).Count -eq 1) 'pool resolves configured default Dev Hub'
    $poolList = @($Calls | Where-Object { $_.tool -eq 'sfp' -and $_.arguments[1] -eq 'list' }) | Select-Object -First 1
    Assert-True ($poolList.arguments[3] -eq 'tag with spaces' -and $poolList.arguments[6] -eq 'NAV DevHub') 'pool list preserves spaced tag and resolved Dev Hub as single arguments'
    Assert-True (@($Calls | Where-Object { $_.tool -eq 'sf' -and $_.arguments[1] -eq 'create' -and $_.arguments[2] -eq 'scratch' }).Count -eq 1) 'empty-pool fallback invokes sf org create scratch'

    Reset-Scenario
    $Config.pool.use = $true
    Add-Rule sf @('config', 'get', 'target-dev-hub') '{"status":0,"result":[]}'
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 1 'pool without a Dev Hub fails clearly'
    Assert-True ($result.Output -match 'Pool use requires -PoolDevHub or sf target-dev-hub configuration') 'missing pool Dev Hub has actionable error'
    Assert-True (@($Calls | Where-Object { $_.tool -eq 'sf' -and $_.arguments[1] -in @('delete', 'create') }).Count -eq 0) 'missing Dev Hub causes no org mutation'

    foreach ($fallback in @($true, $false)) {
        Reset-Scenario
        $Config.pool.use = $true
        $Config.pool.devHub = 'offline hub'
        $Config.pool.fallbackToCreate = $fallback
        Add-Rule sfp @('pool', 'list') 'list output did not contain a count'
        if ($fallback) { Add-Rule sf @('org', 'delete', 'scratch'); Add-Rule sf @('org', 'create', 'scratch') }
        $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
        Assert-Exit $result ([int](-not $fallback)) "unparseable pool listing fallback=$fallback"
        if ($fallback) {
            Assert-True (@($Calls | Where-Object { $_.tool -eq 'sf' -and $_.arguments[1] -eq 'create' }).Count -eq 1) 'unparseable pool count with fallback creates org'
        } else {
            Assert-True ($result.Output -match 'No unused scratch org is available in the pool' -and @($Calls | Where-Object { $_.tool -eq 'sf' -and $_.arguments[1] -in @('delete', 'create') }).Count -eq 0) 'unparseable pool count without fallback fails before mutation'
        }
    }

    Reset-Scenario
    $Config.pool.use = $true; $Config.pool.tag = 'fetch tag with spaces'; $Config.pool.fallbackToCreate = $false
    Add-Rule sf @('config', 'get', 'target-dev-hub') '{"status":0,"result":[{"name":"target-dev-hub","value":"NAV DevHub"}]}'
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 1'
    Add-Rule sfp @('pool', 'fetch')
    Add-Rule sf @('org', 'delete', 'scratch')
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 0 'pool fetch resolves a default Dev Hub with spaces'
    $poolFetch = @($Calls | Where-Object { $_.tool -eq 'sfp' -and $_.arguments[1] -eq 'fetch' }) | Select-Object -First 1
    Assert-True ($poolFetch.arguments[3] -eq 'fetch tag with spaces' -and $poolFetch.arguments[5] -eq 'NAV DevHub' -and $poolFetch.arguments[7] -eq 'offline-org') 'pool fetch forwards spaced tag and Dev Hub as one argument each'

    Reset-Scenario
    $Config.pool.use = $true; $Config.pool.devHub = 'hub with spaces'; $Config.pool.tag = 'dry tag'
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 1'
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none', '-DryRun')
    Assert-Exit $result 0 'pool fetch dry-run succeeds'
    Assert-True ($Calls.Count -eq 1 -and $Calls[0].arguments[1] -eq 'list') 'pool dry-run performs no fetch or delete mutation'
    Assert-True ($result.Output.Contains('sfp pool fetch --tag dry tag --targetdevhubusername hub with spaces --alias offline-org --setdefaultusername')) 'pool dry-run prints the complete planned fetch arguments'

    Reset-Scenario
    $Config.pool.use = $true; $Config.pool.devHub = 'offline hub'
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 1'
    Add-Rule sfp @('pool', 'fetch') '' 23 'offline pool fetch failed'
    Add-Rule sf @('org', 'delete', 'scratch')
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 1 'non-zero sfp fetch exits as a failed setup'
    Assert-True ($result.Output -match 'offline pool fetch failed' -and $result.Output -match 'Could not fetch pool org') 'sfp fetch failure details propagate'

    Reset-Scenario
    $Config.pool.use = $true; $Config.pool.tag = 'config tag'; $Config.pool.devHub = 'config hub'; $Config.pool.fallbackToCreate = $false
    $Overrides['USE_POOL'] = 'true'; $Overrides['POOL_TAG'] = 'env tag'; $Overrides['POOL_DEVHUB_USERNAME'] = 'env hub'; $Overrides['FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY'] = 'true'
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 0'
    Add-Rule sf @('org', 'delete', 'scratch'); Add-Rule sf @('org', 'create', 'scratch')
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 0 'environment pool settings override config'
    $poolList = @($Calls | Where-Object { $_.tool -eq 'sfp' -and $_.arguments[1] -eq 'list' }) | Select-Object -First 1
    Assert-True ($poolList.arguments[3] -eq 'env tag' -and $poolList.arguments[6] -eq 'env hub') 'environment tag and Dev Hub override config in intact argument slots'
    Assert-True (@($Calls | Where-Object { $_.tool -eq 'sf' -and $_.arguments[1] -eq 'create' }).Count -eq 1) 'environment fallback=true overrides config false'

    Reset-Scenario
    $Config.pool.use = $true; $Config.pool.devHub = 'config hub'
    $Overrides['USE_POOL'] = 'false'
    Add-Rule sf @('org', 'delete', 'scratch'); Add-Rule sf @('org', 'create', 'scratch')
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 0 'USE_POOL=false overrides config true'
    Assert-True (@($Calls | Where-Object { $_.tool -eq 'sfp' }).Count -eq 0 -and @($Calls | Where-Object { $_.tool -eq 'sf' -and $_.arguments[1] -eq 'create' }).Count -eq 1) 'USE_POOL=false selects direct scratch creation'

    Reset-Scenario
    $Config.pool.use = $false; $Config.pool.devHub = 'config hub'; $Config.pool.fallbackToCreate = $true
    $Overrides['USE_POOL'] = 'false'; $Overrides['POOL_TAG'] = 'environment tag'; $Overrides['POOL_DEVHUB_USERNAME'] = 'environment hub'; $Overrides['FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY'] = 'true'
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 0'
    $result = Invoke-Scenario -Options @('-UsePool', '-PoolTag', 'cli tag', '-PoolDevHub', 'CLI hub', '-NoFallbackToCreate', '-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 1 'explicit no-fallback switch overrides environment and config'
    $poolList = @($Calls | Where-Object { $_.tool -eq 'sfp' -and $_.arguments[1] -eq 'list' }) | Select-Object -First 1
    Assert-True ($poolList.arguments[3] -eq 'cli tag' -and $poolList.arguments[6] -eq 'CLI hub') 'command-line pool tag and Dev Hub override environment and config'
    Assert-True (@($Calls | Where-Object { $_.tool -eq 'sf' -and $_.arguments[1] -in @('delete', 'create') }).Count -eq 0) '-NoFallbackToCreate blocks the environment fallback and all mutations'

    Reset-Scenario
    $Config.pool.use = $true; $Config.pool.devHub = 'config hub'; $Config.pool.fallbackToCreate = $true
    $Overrides['FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY'] = 'false'
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 0'
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 1 'environment fallback=false overrides config true'
    Assert-True (@($Calls | Where-Object { $_.tool -eq 'sf' -and $_.arguments[1] -in @('delete', 'create') }).Count -eq 0) 'environment fallback=false prevents org mutations'

    Reset-Scenario
    $Config['customPostSteps'] = @(@{ name = 'capture'; executable = 'sf'; arguments = @('capture', 'argument with spaces') })
    $Config.postSteps = @('capture')
    Add-Rule sf @('capture') '' 23 'custom step failed'
    $result = Invoke-Scenario -Options @('-PostStepsOnly')
    Assert-Exit $result 1 'custom post-step non-zero exit fails setup'
    Assert-True ($result.Output -match 'Custom step .capture. failed \(23\)' -and $result.Output -match 'custom step failed') 'custom step failure retains its exact CLI exit code and output'

    $coverageJson = '{"status":0,"result":{"records":[{"covered":80,"uncovered":20}]}}'
    Reset-Scenario
    $Config['coverage'] = @{ minimumPercent = 79; classNamePattern = '%' }
    Add-Rule sf @('apex', 'run', 'test')
    Add-Rule sf @('data', 'query') $coverageJson
    $result = Invoke-Scenario -Options @('-CoverageCheck', '-CoveragePackageId', 'ignored-package', '-CoverageSkipInstall', '-CoverageSkipDeploy')
    Assert-Exit $result 0 'coverage succeeds at threshold while install and deploy are skipped'
    Assert-True ($result.Output -match 'Apex coverage: 80%.*required 79%') 'coverage threshold comparison reports success'
    Assert-True (@($Calls | Where-Object { $_.tool -eq 'sf' -and $_.arguments[1] -in @('install', 'deploy') }).Count -eq 0) 'coverage skip switches prevent package install and source deploy'
    Assert-True (@($Calls | Where-Object { $_.tool -eq 'sf' -and $_.arguments[0] -eq 'apex' -and $_.arguments[2] -eq 'test' }).Count -eq 1) 'coverage still runs Apex tests'
    Assert-True (@($Calls | Where-Object { $_.tool -eq 'sf' -and $_.arguments[0] -eq 'data' -and $_.arguments[1] -eq 'query' }).Count -eq 1) 'coverage queries aggregate coverage after the test run'

    Reset-Scenario
    $Config['coverage'] = @{ minimumPercent = 81; classNamePattern = '%' }
    Add-Rule sf @('apex', 'run', 'test')
    Add-Rule sf @('data', 'query') $coverageJson
    $result = Invoke-Scenario -Options @('-CoverageCheck', '-CoverageSkipInstall', '-CoverageSkipDeploy')
    Assert-Exit $result 1 'coverage below the configured threshold fails'
    Assert-True ($result.Output -match 'Coverage 80% is below the required 81%') 'coverage failure reports measured and required values'

    function Set-DependencyFolderScenario {
        param([string]$DependencyPath = 'offline-package')
        Write-Json (Join-Path $ProjectDirectory 'sfdx-project.json') @{
            packageDirectories = @(
                @{ path = 'force-app'; dependencies = @(@{ package = 'offline-package'; versionNumber = '1.0.0.LATEST' }) },
                @{ path = $DependencyPath; package = 'offline-package' }
            )
            packageAliases = @{}
        }
    }

    Reset-Scenario
    Set-DependencyFolderScenario
    $dependencyDirectory = Join-Path $ProjectDirectory 'offline-package'
    New-Item -ItemType Directory -Path $dependencyDirectory -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dependencyDirectory 'README.md') -Value 'preserved'
    Set-Content -LiteralPath (Join-Path $dependencyDirectory 'source.xml') -Value 'remove during refresh'
    Add-Rule sf @('org', 'delete', 'scratch')
    Add-Rule sf @('org', 'create', 'scratch')
    Add-Rule sf @('project', 'retrieve', 'start')
    $result = Invoke-Scenario -Options @('-RefreshDependencySources', '-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 0 'dependency refresh clears and retrieves local dependency sources'
    Assert-True ((Test-Path -LiteralPath (Join-Path $dependencyDirectory 'README.md')) -and -not (Test-Path -LiteralPath (Join-Path $dependencyDirectory 'source.xml'))) 'refresh preserves configured root file and clears other root entries'
    Assert-True (@($Calls | Where-Object { $_.tool -eq 'sf' -and $_.arguments[0] -eq 'project' -and $_.arguments[1] -eq 'retrieve' }).Count -eq 1) 'dependency refresh invokes sf project retrieve'

    Reset-Scenario
    Set-DependencyFolderScenario
    $dependencyDirectory = Join-Path $ProjectDirectory 'offline-package'
    New-Item -ItemType Directory -Path $dependencyDirectory -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dependencyDirectory 'README.md') -Value 'preserved'
    Set-Content -LiteralPath (Join-Path $dependencyDirectory 'source.xml') -Value 'remove'
    $result = Invoke-Scenario -Options @('-ClearDependencySourcesOnly')
    Assert-Exit $result 0 'dependency clear keeps configured root files'
    Assert-True ((Test-Path -LiteralPath (Join-Path $dependencyDirectory 'README.md')) -and -not (Test-Path -LiteralPath (Join-Path $dependencyDirectory 'source.xml'))) 'default README preserve list is honored'

    Reset-Scenario
    Set-DependencyFolderScenario
    $Config['dependencySourcePolicy'] = @{ preserveRootFiles = @() }
    $dependencyDirectory = Join-Path $ProjectDirectory 'offline-package'
    New-Item -ItemType Directory -Path $dependencyDirectory -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dependencyDirectory 'README.md') -Value 'remove too'
    Set-Content -LiteralPath (Join-Path $dependencyDirectory 'source.xml') -Value 'remove'
    $result = Invoke-Scenario -Options @('-ClearDependencySourcesOnly')
    Assert-Exit $result 0 'empty dependency preserve list is accepted'
    Assert-True (@(Get-ChildItem -LiteralPath $dependencyDirectory -Force).Count -eq 0) 'empty preserve list removes every dependency root file'

    Reset-Scenario
    Set-DependencyFolderScenario
    $linkTarget = Join-Path $ProjectDirectory 'real-dependency'
    $linkPath = Join-Path $ProjectDirectory 'offline-package'
    if (Test-Path -LiteralPath $linkPath) { Remove-Item -LiteralPath $linkPath -Recurse -Force }
    New-Item -ItemType Directory -Path $linkTarget -Force | Out-Null
    $linkCreated = $false
    try {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $linkTarget -ErrorAction Stop | Out-Null
        $linkCreated = $true
    } catch {
        if ($IsWindows) { Write-Host 'SKIP: Windows symbolic-link creation requires unavailable privilege.' }
        else { Assert-True $false "could not create required dependency symlink: $($_.Exception.Message)" }
    }
    if ($linkCreated) {
        $result = Invoke-Scenario -Options @('-ClearDependencySourcesOnly')
        Assert-Exit $result 1 'dependency cleanup refuses a reparse-point directory'
        Assert-True ($result.Output -match 'Refusing to use linked dependency directory|Refusing to clear linked dependency directory') 'linked dependency directory is explicitly refused'
    }

    Reset-Scenario
    Set-DependencyFolderScenario -DependencyPath '../outside dependency'
    $result = Invoke-Scenario -Options @('-ClearDependencySourcesOnly')
    Assert-Exit $result 1 'dependency cleanup refuses a path outside project root'
    Assert-True ($result.Output -match 'Refusing to modify path outside project root') 'outside dependency path has actionable error'
    Assert-True (@(Get-ChildItem -LiteralPath $ProjectDirectory -Directory | Where-Object { $_.Name -eq 'outside dependency' }).Count -eq 0) 'outside dependency refusal does not create or modify an outside folder'

    if ($IsWindows) {
        Reset-Scenario
        Write-Json (Join-Path $ProjectDirectory 'package.json') @{
            private = $true
            scripts = @{ 'scratch-org' = "node `"$(Join-Path $BinDirectory 'create-scratch-org.js')`"" }
        }
        $result = Invoke-Scenario -Executable $env:ComSpec -LeadingArguments @('/d', '/c', "`"$LauncherPath`" -Help")
        Assert-Exit $result 0 'CMD launcher actually starts PowerShell help'
        Reset-Scenario
        $Config.pool.use = $true; $Config.pool.tag = 'shim tag with spaces'; $Config.pool.devHub = 'shim hub with spaces'; $Config.pool.fallbackToCreate = $true
        Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 0'
        Add-Rule sf @('org', 'delete', 'scratch'); Add-Rule sf @('org', 'create', 'scratch')
        $sfpShimPath = Join-Path $FakeBin 'sfp.ps1'
        $sfpShimMarker = Join-Path $WorkDirectory 'sfp-ps1-shim-used.txt'
        @'
if ($env:SCRATCH_TEST_SFP_SHIM_MARKER) { [IO.File]::WriteAllText($env:SCRATCH_TEST_SFP_SHIM_MARKER, 'used') }
& $env:SCRATCH_TEST_HOST -NoLogo -NoProfile -File $env:SCRATCH_TEST_FIXTURE sfp @args
exit $LASTEXITCODE
'@ | Set-Content -LiteralPath $sfpShimPath -Encoding utf8
        $Overrides['SCRATCH_TEST_SFP_SHIM_MARKER'] = $sfpShimMarker
        $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
        Assert-Exit $result 0 'PowerShell sfp shim succeeds alongside sfp.cmd'
        Assert-True ((Test-Path -LiteralPath $sfpShimMarker) -and $Calls[0].tool -eq 'sfp') 'PowerShell sfp.ps1 shim was selected'
        $sfpArguments = @($Calls | Where-Object { $_.tool -eq 'sfp' })[0].arguments
        Assert-True ($sfpArguments[3] -eq 'shim tag with spaces' -and $sfpArguments[6] -eq 'shim hub with spaces') 'PowerShell sfp shim preserves spaced arguments'
        Remove-Item -LiteralPath $sfpShimPath -Force
        Reset-Scenario
        $Config.postSteps = @('deploy')
        Add-Rule sf @('project', 'deploy', 'start'); Add-Rule sf @('project', 'reset', 'tracking')
        $specialAlias = 'alias ø & caret^ percent% and "quoted"'
        $cmdAlias = $specialAlias.Replace('"', '\"')
        $specialCommand = "`"$LauncherPath`" -PostStepsOnly -OrgAlias `"$cmdAlias`""
        $result = Invoke-Scenario -Executable $env:ComSpec -LeadingArguments @('/d', '/c', $specialCommand)
        $deployCall = @($Calls | Where-Object { $_.tool -eq 'sf' -and $_.arguments[0] -eq 'project' -and $_.arguments[1] -eq 'deploy' }) | Select-Object -First 1
        $targetIndex = if ($null -ne $deployCall) { [Array]::IndexOf([object[]]$deployCall.arguments, '--target-org') } else { -1 }
        $forwardedExactly = $result.ExitCode -eq 0 -and $targetIndex -ge 0 -and $deployCall.arguments[$targetIndex + 1] -ceq $specialAlias
        $cleanFailure = $result.ExitCode -ne 0 -and $result.Output -match 'ERROR:' -and $Calls.Count -eq 0
        Assert-True ($forwardedExactly -or $cleanFailure) 'CMD launcher forwards special/non-ASCII alias exactly or fails cleanly'
        $result = Invoke-Scenario -Executable $env:ComSpec -LeadingArguments @('/d', '/c', "`"$NpmPath`" run scratch-org -- --help")
        Assert-Exit $result 0 'npm run actually starts PowerShell help'
        $npmScriptPath = (Get-Command npm.ps1 -CommandType ExternalScript -ErrorAction Stop | Select-Object -First 1).Source
        $result = Invoke-Scenario -LeadingArguments @('-NoLogo', '-NoProfile', '-Command', "& '$npmScriptPath' run scratch-org '--' -Help")
        Assert-Exit $result 0 'npm.ps1 from PowerShell 7 starts help with quoted separator'
        Assert-True ($result.Output -match 'Options:' -and $Calls.Count -eq 0) 'npm.ps1 forwards -Help to the PowerShell script'
        $Config.postSteps = @('deploy')
        $script:Rules = @()
        Add-Rule sf @('project', 'deploy', 'start') '' 9 'offline npm.ps1 deployment failed'
        $result = Invoke-Scenario -LeadingArguments @('-NoLogo', '-NoProfile', '-Command', "& '$npmScriptPath' run scratch-org '--' -PostStepsOnly -OrgAlias 'alias with spaces'")
        Assert-Exit $result 1 'npm.ps1 propagates script failure'
        Assert-True ($Calls.Count -eq 1 -and $Calls[0].arguments[4] -eq 'alias with spaces') 'npm.ps1 preserves spaced argument after quoted separator'
        Reset-Scenario
        foreach ($launcher in @('cmd', 'npm')) {
            $Config.postSteps = @('deploy')
            $script:Rules = @()
            Add-Rule sf @('project', 'deploy', 'start') '' 9 'offline Windows deployment failed'
            $command = if ($launcher -eq 'cmd') {
                "`"$LauncherPath`" -PostStepsOnly -OrgAlias `"alias with spaces`""
            } else { "`"$NpmPath`" run scratch-org -- -PostStepsOnly -OrgAlias `"alias with spaces`"" }
            $result = Invoke-Scenario -Executable $env:ComSpec -LeadingArguments @('/d', '/c', $command)
            Assert-Exit $result 1 "$launcher propagates script failure"
            Assert-True ($Calls.Count -eq 1 -and $Calls[0].arguments[4] -eq 'alias with spaces') "$launcher preserves spaced argument"
            Assert-True ($result.Output -match 'offline Windows deployment failed') "$launcher surfaces script failure details"
            if ($launcher -eq 'cmd') {
                $result = Invoke-Scenario -Executable $env:ComSpec -LeadingArguments @('/d', '/c', "`"$LauncherPath`" -Help") -WithoutRuntime
            } else {
                $result = Invoke-Scenario -Executable $env:ComSpec -LeadingArguments @('/d', '/c', "`"$NpmPath`" run scratch-org -- --help") -WithoutRuntime
            }
            Assert-Exit $result 1 "$launcher rejects missing pwsh"
            Assert-True ($result.Output -match 'PowerShell 7 LTS' -and $result.Output -match 'Install') "$launcher gives installation guidance"
            Assert-True ($Calls.Count -eq 0) "$launcher never contacts CLI without runtime"
        }
    } else {
        $Skipped += 1
        Write-Host 'SKIP: Windows CMD/npm execution and missing-runtime scenarios require Windows; not verified on Mac.'
    }
} finally {
    Remove-Item -LiteralPath $WorkDirectory -Recurse -Force
}
Write-Host "Passed: $Passed; failed: $Failures; skipped groups: $Skipped"
if ($RequireWindows -and $Skipped -gt 0) { throw 'Mandatory Windows coverage was skipped.' }
if ($Failures -gt 0) { exit 1 }
