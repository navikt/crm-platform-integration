$ErrorActionPreference = 'Stop'

$BinDirectory = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ScriptPath = Join-Path $BinDirectory 'create-scratch-org.ps1'
$LauncherPath = Join-Path $BinDirectory 'create-scratch-org.bat'
$ProjectDirectory = Join-Path ([IO.Path]::GetTempPath()) ('scratch-org-tests-' + [guid]::NewGuid().ToString('N'))
$Failures = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        $script:Failures++
        Write-Host "FAIL: $Message" -ForegroundColor Red
    } else {
        Write-Host "PASS: $Message"
    }
}

function Write-Config {
    param($Value)
    $Value | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath (Join-Path $ProjectDirectory 'sf-project.config.json') -Encoding UTF8
}

try {
    New-Item -ItemType Directory -Path $ProjectDirectory | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $ProjectDirectory 'config') | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $ProjectDirectory 'data') | Out-Null
    '{"packageDirectories":[{"path":"force-app"}]}' | Set-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Encoding UTF8
    '{"edition":"Developer"}' | Set-Content -LiteralPath (Join-Path $ProjectDirectory 'config/project-scratch-def.json') -Encoding UTF8
    '[]' | Set-Content -LiteralPath (Join-Path $ProjectDirectory 'data/Plan.json') -Encoding UTF8
    @'
{"records":[
 {"attributes":{"type":"User","referenceId":"Handler"},"Username":"handler@example.test","ProfileId":"org-specific"},
 {"attributes":{"type":"User","referenceId":"Support"},"Username":"support@example.test","ProfileId":"org-specific"}
]}
'@ | Set-Content -LiteralPath (Join-Path $ProjectDirectory 'data/User.json') -Encoding UTF8

    $config = [ordered]@{
        schemaVersion = 1
        defaultOrgAlias = 'profile-test-org'
        dummyDataPlan = 'data/Plan.json'
        postSteps = @('data')
        customPostSteps = @([ordered]@{ name = 'seed'; executable = 'echo'; arguments = @('ready') })
        dummyUsers = [ordered]@{
            file = 'data/User.json'
            profileName = 'Standard User'
            profileAssignments = @(
                [ordered]@{ profileName = 'Case Handler'; usernames = @('handler@example.test') },
                [ordered]@{ profileName = 'Support User'; usernames = @('support@example.test') }
            )
        }
    }
    Write-Config $config

    $parseErrors = $null
    $tokens = $null
    [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$parseErrors) | Out-Null
    Assert-True ($parseErrors.Count -eq 0) 'PowerShell script parses without syntax errors'

    $hostPath = Join-Path $PSHOME $(if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh.exe' } else { 'powershell.exe' })
    $output = @(& $hostPath -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -ProjectFile (Join-Path $ProjectDirectory 'sfdx-project.json') -PostStepsOnly -PostSteps data -DryRun 2>&1 | ForEach-Object { $_.ToString() })
    $exitCode = $LASTEXITCODE
    Assert-True ($exitCode -eq 0) 'configured data post-step dry-run succeeds without Salesforce CLI'
    $profileOutput = $output -join "`n"
    Assert-True ($profileOutput -match '(?s)(?=.*Case Handler)(?=.*Standard User)(?=.*Support User)') 'dry-run reports fallback and per-user profiles'

    $initOutput = @(& $hostPath -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -ProjectFile (Join-Path $ProjectDirectory 'sfdx-project.json') -InitConfig -DryRun -OrgAlias 'preview-org' 2>&1 | ForEach-Object { $_.ToString() })
    Assert-True ($LASTEXITCODE -eq 0) 'init-config dry-run succeeds'
    $initText = $initOutput -join "`n"
    Assert-True ($initText -match '"defaultOrgAlias":\s+"preview-org"') 'init-config uses CLI alias override'

    $config.dummyUsers.profileAssignments = @(
        [ordered]@{ profileName = 'One'; usernames = @('duplicate@example.test') },
        [ordered]@{ profileName = 'Two'; usernames = @('duplicate@example.test') }
    )
    Write-Config $config
    $invalidOutput = @(& $hostPath -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -ProjectFile (Join-Path $ProjectDirectory 'sfdx-project.json') -DryRun 2>&1 | ForEach-Object { $_.ToString() })
    Assert-True ($LASTEXITCODE -ne 0) 'duplicate username profile assignments are rejected'
    Assert-True (($invalidOutput -join "`n") -match 'only one profile assignment') 'duplicate mapping has an actionable error'

    $config.dummyUsers.profileAssignments = @(
        [ordered]@{ profileName = 'Case Handler'; usernames = @('handler@example.test') },
        [ordered]@{ profileName = 'Support User'; usernames = @('support@example.test') }
    )
    Write-Config $config

    $fakeBin = Join-Path $ProjectDirectory 'fake-bin'
    New-Item -ItemType Directory -Path $fakeBin | Out-Null
    @'
@echo off
if /I "%SF_MODE%"=="versions" (
  echo {"status":0,"result":[{"MajorVersion":1,"MinorVersion":0,"PatchVersion":0,"BuildNumber":3,"SubscriberPackageVersionId":"04t000000000001"}]}
  exit /b 0
)
echo {"status":1,"message":"mock sf failure","result":{}}
exit /b 1
'@ | Set-Content -LiteralPath (Join-Path $fakeBin 'sf.cmd') -Encoding ASCII
    $oldPath = $env:PATH
    try {
        $env:PATH = "$fakeBin;$oldPath"
        $versionProjectPath = Join-Path $ProjectDirectory 'sfdx-project.json'
        @'
{"packageDirectories":[
 {"path":"force-app","dependencies":[{"package":"pkg-one","versionNumber":"0.9.0.LATEST"}]},
 {"path":"second-package","dependencies":[{"package":"pkg-one","versionNumber":"0.9.0.NEXT"}]}
],"packageAliases":{"pkg-one":"0Ho000000000001"}}
'@ | Set-Content -LiteralPath $versionProjectPath -Encoding UTF8
        $originalProject = Get-Content -LiteralPath $versionProjectPath -Raw
        $env:SF_MODE = 'versions'
        $versionPreview = @(& $hostPath -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -ProjectFile $versionProjectPath -CheckVersions 2>&1 | ForEach-Object { $_.ToString() })
        Assert-True ($LASTEXITCODE -eq 0) 'package version check preview succeeds'
        Assert-True (($versionPreview -join "`n") -match '0\.9\.0\.LATEST -> 1\.0\.0\.LATEST') 'preview reports latest version constraint'
        Assert-True ((Get-Content -LiteralPath $versionProjectPath -Raw) -eq $originalProject) 'version preview does not modify project file'

        $versionApply = @(& $hostPath -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -ProjectFile $versionProjectPath -ApplyProjectVersions 2>&1 | ForEach-Object { $_.ToString() })
        Assert-True ($LASTEXITCODE -eq 0) 'explicit package version apply succeeds'
        Assert-True ((Get-Content -LiteralPath "$versionProjectPath.backup" -Raw) -eq $originalProject) 'version apply creates exact backup'
        $updatedProject = Get-Content -LiteralPath $versionProjectPath -Raw | ConvertFrom-Json
        Assert-True ($updatedProject.packageDirectories[1].dependencies[0].versionNumber -eq '1.0.0.LATEST') 'version apply updates duplicate dependency declarations'

        $coveragePlan = @(& $hostPath -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -ProjectFile (Join-Path $ProjectDirectory 'sfdx-project.json') -CoverageCheck -DryRun -OrgAlias 'scratch-a' -CoveragePackageId '04t-package' 2>&1 | ForEach-Object { $_.ToString() })
        Assert-True ($LASTEXITCODE -eq 0) 'coverage dry-run plan succeeds without invoking Salesforce'
        Assert-True (($coveragePlan -join "`n") -match 'Query % aggregate coverage') 'coverage dry-run shows the configured aggregate coverage pattern'

        $env:SF_MODE = 'failure'
        $failureOutput = @(& $hostPath -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -ProjectFile (Join-Path $ProjectDirectory 'sfdx-project.json') -SelfCheck 2>&1 | ForEach-Object { $_.ToString() })
        Assert-True ($LASTEXITCODE -ne 0) 'Salesforce CLI command failures produce a nonzero script exit code'
        Assert-True (($failureOutput -join "`n") -match 'mock sf failure') 'Salesforce CLI failure details are surfaced'

        $cmdOutput = @(& $env:ComSpec /d /c "`"$LauncherPath`" -Help" 2>&1 | ForEach-Object { $_.ToString() })
        Assert-True ($LASTEXITCODE -eq 0) 'CMD launcher starts the PowerShell help path'
        Assert-True (($cmdOutput -join "`n") -match 'sf-project') 'CMD launcher displays standalone script help'

        $cmdFailure = @(& $env:ComSpec /d /c "`"$LauncherPath`" -ProjectFile `"$(Join-Path $ProjectDirectory 'sfdx-project.json')`" -SelfCheck" 2>&1 | ForEach-Object { $_.ToString() })
        Assert-True ($LASTEXITCODE -ne 0) 'CMD launcher propagates PowerShell failure exit codes'
    } finally {
        $env:PATH = $oldPath
        Remove-Item Env:SF_MODE -ErrorAction SilentlyContinue
    }

    $launcher = Get-Content -LiteralPath $LauncherPath -Raw
    Assert-True ($launcher -match '%\*' -and $launcher -match 'exit /b %SCRIPT_EXIT_CODE%') 'CMD launcher forwards arguments and exit code'
} finally {
    Remove-Item -LiteralPath $ProjectDirectory -Recurse -Force -ErrorAction SilentlyContinue
}

if ($Failures -gt 0) {
    Write-Error "$Failures PowerShell test(s) failed."
    exit 1
}
Write-Host 'All PowerShell scratch-org tests passed.' -ForegroundColor Green
