<#
.SYNOPSIS
Creates and configures a Salesforce scratch org without sf-project tooling.

.DESCRIPTION
Uses PowerShell 7 and Salesforce CLI with the project's shared configuration.
#>
[CmdletBinding()]
param(
    [Alias('Alias')][string]$OrgAlias,
    [int]$DurationDays,
    [string]$DefinitionFile,
    [string]$ProjectFile,
    [string]$ConfigFile,
    [switch]$NoConfig,
    [switch]$InitConfig,
    [switch]$CheckVersions,
    [switch]$ApplyProjectVersions,
    [switch]$CoverageCheck,
    [string]$CoveragePackageId,
    [double]$MinimumCoverage,
    [string]$CoverageTestClass,
    [string]$CoverageClassNamePattern,
    [switch]$CoverageRunAll,
    [switch]$CoverageSkipInstall,
    [switch]$CoverageSkipDeploy,
    [switch]$Force,
    [switch]$DryRun,
    [string[]]$PostSteps,
    [string]$CommunityName,
    [string]$DummyDataPlan,
    [string[]]$PermissionSets,
    [switch]$Help,
    [switch]$InstallLatest,
    [switch]$UpdatePackages,
    [switch]$PackagePlan,
    [switch]$DeleteOrgOnly,
    [switch]$SelfCheck,
    [switch]$UsePool,
    [string]$PoolTag,
    [string]$PoolDevHub,
    [switch]$NoFallbackToCreate,
    [switch]$SkipOrg,
    [switch]$SkipPackages,
    [switch]$SkipVersionCheck,
    [switch]$PostStepsOnly,
    [switch]$FullDeploy,
    [switch]$Redeploy,
    [switch]$Color,
    [switch]$NoColor,
    [switch]$RefreshDependencySources,
    [switch]$ClearDependencySourcesOnly
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -ne 7) {
    throw 'PowerShell 7 LTS is required. Install it through your approved software channel and run this script with pwsh.'
}
$script:BoundParameters = $PSBoundParameters
$script:StartedAt = Get-Date
$script:RunWatch = [Diagnostics.Stopwatch]::StartNew()
$script:PhaseIndex = 0
$script:PhaseTotal = 0
$script:CurrentOperation = 'Configuration'
$script:OrgAction = 'No org action recorded.'
$script:PackageResults = [ordered]@{ Installed = @(); Updated = @(); Current = @(); Higher = @(); Planned = @() }
$script:CompletedSteps = @()
$script:SkippedSteps = @()
$script:SummaryEnabled = -not ($Help -or $InitConfig)
$script:HadWarnings = $false
$script:UseColor = $false
$script:InteractiveOutput = $false
$script:Icons = @{ Info = '-'; Step = '>'; Success = '+'; Warning = '!'; Failure = 'x'; Skip = 'o' }

function Protect-OutputText {
    param([string]$Text)
    if ($script:InstallationKey) { return $Text.Replace($script:InstallationKey, '***') }
    return $Text
}

function Initialize-Output {
    if ($Color -and $NoColor) { throw '-Color and -NoColor cannot be combined.' }
    $script:InteractiveOutput = -not [Console]::IsOutputRedirected -and -not $env:CI -and $env:TERM -ne 'dumb'
    $script:UseColor = if ($NoColor) { $false } elseif ($Color) { $true } elseif ($env:NO_COLOR) { $false } elseif ($env:FORCE_COLOR -and $env:FORCE_COLOR -ne '0') { $true } else { $script:InteractiveOutput }
    $script:ShowDetails = $VerbosePreference -eq 'Continue' -or $env:VERBOSE -eq 'true'
    $locale = if ($env:LC_ALL) { $env:LC_ALL } elseif ($env:LC_CTYPE) { $env:LC_CTYPE } else { $env:LANG }
    if (($IsWindows -and -not $locale -and [Console]::OutputEncoding.WebName -eq 'utf-8') -or $locale -match '(?i)utf-?8') {
        $script:Icons = @{ Info = '•'; Step = '▸'; Success = '✔'; Warning = '⚠'; Failure = '✖'; Skip = '○' }
    }
}

function Write-RunLine {
    param([string]$Text, [ValidateSet('Info', 'Step', 'Success', 'Warning', 'Failure', 'Skip')][string]$Kind = 'Info')
    $textToWrite = "$($script:Icons[$Kind]) $(Protect-OutputText $Text)"
    if ($script:UseColor) {
        $code = switch ($Kind) { 'Success' { 32 } 'Warning' { 33 } 'Failure' { 31 } 'Step' { 36 } default { 90 } }
        $textToWrite = "`e[${code}m$textToWrite`e[0m"
    }
    [Console]::Out.WriteLine($textToWrite)
}

function Write-RunSection {
    param([string]$Title)
    [Console]::Out.WriteLine()
    Write-RunLine ("-- {0} {1}" -f $Title, ('-' * [Math]::Max(3, 53 - $Title.Length))) Step
}

function Write-RunValue {
    param([string]$Name, $Value)
    $displayValue = if ($null -eq $Value -or "$Value" -eq '') { 'none' } else { "$Value" }
    [Console]::Out.WriteLine(("  {0,-25} {1}" -f $Name, (Protect-OutputText $displayValue)))
}

function Write-RunWarning {
    param([string]$Text)
    $script:HadWarnings = $true
    Write-RunLine "Warning: $Text" Warning
}

function Write-Phase {
    param([string]$Name)
    $script:PhaseIndex++
    Write-RunSection "[$script:PhaseIndex/$script:PhaseTotal] $Name"
}

function Get-ActiveModes {
    $modes = @(
        if ($DryRun) { 'dry-run' }
        if ($SelfCheck) { 'self-check' }
        if ($PackagePlan) { 'package-plan' }
        if ($UpdatePackages) { 'update-packages' }
        if ($DeleteOrgOnly) { 'delete-org-only' }
        if ($PostStepsOnly) { 'post-steps-only' }
        if ($FullDeploy) { 'full-deploy' }
        if ($CheckVersions -or $ApplyProjectVersions) { 'check-versions' }
        if ($CoverageCheck) { 'coverage-check' }
        if ($script:UsePool) { 'use-pool' }
        if ($RefreshDependencySources) { 'refresh-dependency-sources' }
        if ($ClearDependencySourcesOnly) { 'clear-dependency-sources-only' }
        if ($script:ShowDetails) { 'verbose' }
    )
    if ($modes.Count -eq 0) { return 'standard' }
    return $modes -join ', '
}

function Write-RunSettings {
    param([string]$ConfigPath)
    Write-RunSection 'Scratch org setup'
    Write-RunValue 'Active modes' (Get-ActiveModes)
    Write-RunValue 'Configuration file' $(if ($NoConfig) { 'disabled' } else { $ConfigPath })
    if ($DryRun) { Write-RunLine 'DRY RUN: mutations are planned, not executed. Read commands may still contact Salesforce.' Warning }
    Write-RunSection 'Target'
    Write-RunValue $(if ($script:TargetOrgIsExplicit) { 'Effective target org' } else { 'Fallback org alias' }) $script:TargetOrg
    Write-RunValue 'Dev Hub' $(if ($script:PoolDevHub) { $script:PoolDevHub } elseif ($env:SF_TARGET_DEV_HUB) { $env:SF_TARGET_DEV_HUB } else { 'Salesforce CLI default' })
    Write-RunSection 'Scratch org'
    Write-RunValue 'Definition file' $script:DefinitionFile
    Write-RunValue 'Duration days' $script:EffectiveDurationDays
    Write-RunValue 'Use pool / tag' "$script:UsePool / $script:PoolTag"
    Write-RunSection 'Project and packages'
    Write-RunValue 'Project file' $script:ProjectFilePath
    Write-RunValue 'Dependencies' @(Get-PackageDependencies).Count
    Write-RunValue 'Wait minutes / attempts' "$script:PackageWaitMinutes / $script:InstallMaxAttempts"
    Write-RunValue 'Install key variable' $script:KeyEnvironmentVariable
    Write-RunValue 'Install key available' ([bool]$script:InstallationKey)
    Write-RunSection 'Post-steps'
    Write-RunValue 'Configured' ($script:Config.postSteps -join ', ')
    Write-RunValue 'Permission sets' ($script:Config.permissionSets -join ', ')
    Write-RunValue 'Dummy data plan' $script:Config.dummyDataPlan
    Write-RunValue 'Community' $script:Config.communityName
}

function Write-RunSummary {
    param([int]$ExitCode)
    if (-not $script:SummaryEnabled) { return }
    Write-RunSection 'Run summary'
    $status = if ($ExitCode -ne 0) { "FAILED (exit code $ExitCode)" } elseif ($DryRun) { 'DRY RUN completed (planned mutations only)' } elseif ($script:HadWarnings) { 'COMPLETED WITH WARNINGS - inspect the details above.' } else { 'SUCCESS' }
    Write-RunLine $status $(if ($ExitCode -ne 0) { 'Failure' } elseif ($script:HadWarnings) { 'Warning' } else { 'Success' })
    Write-RunValue 'Duration' $script:RunWatch.Elapsed.ToString('hh\:mm\:ss')
    Write-RunValue 'Started' $script:StartedAt.ToString('yyyy-MM-dd HH:mm:ss zzz')
    Write-RunValue 'Ended' (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')
    Write-RunValue 'Org alias' $script:TargetOrg
    Write-RunValue 'Active modes' (Get-ActiveModes)
    Write-RunValue 'Org' $script:OrgAction
    if ($ExitCode -ne 0) { Write-RunValue 'Failed during' $script:CurrentOperation }
    Write-RunSection 'Packages'
    foreach ($category in $script:PackageResults.Keys) {
        Write-RunValue $category @($script:PackageResults[$category]).Count
        foreach ($entry in $script:PackageResults[$category]) { Write-RunLine "  $entry" }
    }
    Write-RunSection 'Post steps'
    Write-RunValue $(if ($DryRun) { 'Would run' } else { 'Ran' }) ($script:CompletedSteps -join ', ')
    Write-RunValue 'Skipped' ($script:SkippedSteps -join ', ')
    if ($ExitCode -ne 0) { Write-RunLine 'Setup did not complete. Inspect the failed step and current org state before retrying.' Warning }
}

function Get-OperationLabel {
    param([string]$Executable, [string[]]$Arguments)
    $command = ($Arguments | Select-Object -First 3) -join ' '
    switch -Regex ($command) {
        '^org create scratch' { return 'Creating scratch org' }
        '^org delete scratch' { return 'Removing previous scratch org (if present)' }
        '^pool list' { return 'Checking scratch org pool' }
        '^pool fetch' { return 'Fetching scratch org from pool' }
        '^package version list' { return "Resolving package versions: $($Arguments[[Array]::IndexOf($Arguments, '--packages') + 1])" }
        '^package installed list' { return 'Reading installed packages' }
        '^package install' { return 'Installing package' }
        '^project deploy start' { return 'Deploying metadata' }
        '^project reset tracking' { return 'Resetting source tracking after deployment' }
        '^project delete tracking' { return 'Clearing local source tracking for full deployment' }
        '^org assign permset' { return 'Assigning permission sets' }
        '^data import tree' { return 'Importing configured data' }
        '^community publish' { return 'Publishing community' }
        '^apex run test' { return 'Running Apex tests' }
        '^data query' { return 'Querying Salesforce data' }
        default { return "$Executable $command" }
    }
}

function Get-ObjectProperty {
    param($Object, [string]$Name, $Default = $null)
    if ($null -eq $Object) { return ,$Default }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return ,$Default }
    return ,$property.Value
}

function Test-HasProperty {
    param($Object, [string]$Name)
    return ($null -ne $Object -and $null -ne $Object.PSObject.Properties[$Name])
}

function Set-ObjectProperty {
    param($Object, [string]$Name, $Value)
    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
}

function Test-NonEmptyString {
    param($Value)
    return ($Value -is [string] -and -not [string]::IsNullOrWhiteSpace($Value))
}

function ConvertTo-StringArray {
    param($Value)
    if ($null -eq $Value) { return @() }
    return @($Value | ForEach-Object { [string]$_ })
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "File not found: $Path" }
    try {
        return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
    } catch {
        throw "Invalid JSON in $Path`: $($_.Exception.Message)"
    }
}

function Write-Utf8JsonFile {
    param([string]$Path, $Value)
    $json = $Value | ConvertTo-Json -Depth 100
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, $encoding)
}

function Test-Configuration {
    param($Config)
    if ($null -eq $Config -or $Config -isnot [pscustomobject]) { throw 'sf-project.config.json must contain a JSON object.' }
    $schemaVersion = Get-ObjectProperty $Config 'schemaVersion' 1
    if ($schemaVersion -ne 1) { throw "Unsupported schemaVersion '$schemaVersion'; expected 1." }
    foreach ($name in @('defaultOrgAlias', 'scratchDefinition', 'packageInstallKeyEnvironmentVariable')) {
        $value = Get-ObjectProperty $Config $name
        if ((Test-HasProperty $Config $name) -and -not (Test-NonEmptyString $value)) { throw "$name must be a non-empty string." }
    }
    $duration = Get-ObjectProperty $Config 'scratchDurationDays' 14
    if ($duration -isnot [int] -and $duration -isnot [long]) { throw 'scratchDurationDays must be an integer from 1 to 30.' }
    if ($duration -lt 1 -or $duration -gt 30) { throw 'scratchDurationDays must be an integer from 1 to 30.' }
    foreach ($name in @('permissionSets', 'postSteps', 'customPostSteps')) {
        if ((Test-HasProperty $Config $name) -and (Get-ObjectProperty $Config $name) -isnot [array]) { throw "$name must be an array." }
    }
    $steps = ConvertTo-StringArray (Get-ObjectProperty $Config 'postSteps' @('deploy'))
    $customSteps = Get-ObjectProperty $Config 'customPostSteps' @()
    $knownSteps = @('deploy', 'permsets', 'data', 'community') + @($customSteps | ForEach-Object { $_.name })
    foreach ($step in $steps) {
        if ($step -notin $knownSteps) { throw "Unknown post step '$step'." }
    }
    $arrays = @('permissionSets', 'postSteps')
    foreach ($name in $arrays) {
        $value = Get-ObjectProperty $Config $name
        if (@($value | Where-Object { -not (Test-NonEmptyString $_) }).Count -gt 0) { throw "$name must contain non-empty strings." }
    }
    foreach ($name in @('dummyDataPlan', 'communityName')) {
        $value = Get-ObjectProperty $Config $name
        if ((Test-HasProperty $Config $name) -and $null -ne $value -and -not (Test-NonEmptyString $value)) {
            throw "$name must be a non-empty string or null."
        }
    }
    $customNames = @($customSteps | ForEach-Object { $_.name })
    if (@($customNames | Select-Object -Unique).Count -ne $customNames.Count) { throw 'customPostSteps names must be unique.' }
    foreach ($name in $customNames) {
        if ($name -in @('deploy', 'permsets', 'data', 'community')) { throw "customPostSteps name '$name' conflicts with a built-in step." }
    }
    foreach ($custom in $customSteps) {
        if (-not (Test-NonEmptyString $custom.name) -or -not (Test-NonEmptyString $custom.executable)) { throw 'customPostSteps entries require non-empty name and executable values.' }
        if ((Test-HasProperty $custom 'arguments') -and ($custom.arguments -isnot [array] -or @($custom.arguments | Where-Object { $_ -isnot [string] }).Count -gt 0)) { throw 'customPostSteps.arguments must be a string array.' }
        if ((Test-HasProperty $custom 'label') -and -not (Test-NonEmptyString $custom.label)) { throw 'customPostSteps.label must be a non-empty string.' }
    }
    $pool = Get-ObjectProperty $Config 'pool'
    if ((Test-HasProperty $Config 'pool') -and $null -eq $pool) { throw 'pool must be an object.' }
    if ($null -ne $pool) {
        if ($pool -isnot [pscustomobject]) { throw 'pool must be an object.' }
        foreach ($name in @('use', 'fallbackToCreate')) {
            $value = Get-ObjectProperty $pool $name
            if ((Test-HasProperty $pool $name) -and $value -isnot [bool]) { throw "pool.$name must be a boolean." }
        }
        foreach ($name in @('tag', 'devHub')) {
            $value = Get-ObjectProperty $pool $name
            if ((Test-HasProperty $pool $name) -and -not (Test-NonEmptyString $value)) { throw "pool.$name must be a non-empty string." }
        }
    }
    $dependencyPolicy = Get-ObjectProperty $Config 'dependencySourcePolicy'
    if ((Test-HasProperty $Config 'dependencySourcePolicy') -and $null -eq $dependencyPolicy) { throw 'dependencySourcePolicy must be an object.' }
    if ($null -ne $dependencyPolicy) {
        if ($dependencyPolicy -isnot [pscustomobject]) { throw 'dependencySourcePolicy must be an object.' }
        $requireLocal = Get-ObjectProperty $dependencyPolicy 'requireLocalDirectories'
        if ((Test-HasProperty $dependencyPolicy 'requireLocalDirectories') -and $requireLocal -isnot [bool]) { throw 'dependencySourcePolicy.requireLocalDirectories must be a boolean.' }
        $preserved = Get-ObjectProperty $dependencyPolicy 'preserveRootFiles'
        if ((Test-HasProperty $dependencyPolicy 'preserveRootFiles') -and ($preserved -isnot [array] -or @($preserved | Where-Object { -not (Test-NonEmptyString $_) }).Count -gt 0)) { throw 'dependencySourcePolicy.preserveRootFiles must be an array of non-empty strings.' }
    }
    $timeouts = Get-ObjectProperty $Config 'commandTimeouts'
    if ((Test-HasProperty $Config 'commandTimeouts') -and $null -eq $timeouts) { throw 'commandTimeouts must be an object.' }
    if ($null -ne $timeouts) {
        if ($timeouts -isnot [pscustomobject]) { throw 'commandTimeouts must be an object.' }
        foreach ($name in @('readMs', 'mutationMs')) {
            $value = Get-ObjectProperty $timeouts $name
            if ((Test-HasProperty $timeouts $name) -and ($value -isnot [ValueType] -or $value -is [bool] -or [double]$value -le 0 -or [double]$value -ne [math]::Floor([double]$value))) {
                throw "commandTimeouts.$name must be a positive integer."
            }
        }
    }
    $coverage = Get-ObjectProperty $Config 'coverage'
    if ((Test-HasProperty $Config 'coverage') -and $null -eq $coverage) { throw 'coverage must be an object.' }
    if ($null -ne $coverage) {
        if ($coverage -isnot [pscustomobject]) { throw 'coverage must be an object.' }
        $minimum = Get-ObjectProperty $coverage 'minimumPercent'
        if ((Test-HasProperty $coverage 'minimumPercent') -and ($minimum -isnot [ValueType] -or $minimum -is [bool] -or [double]$minimum -lt 0 -or [double]$minimum -gt 100)) { throw 'coverage.minimumPercent must be a number from 0 to 100.' }
        $testClass = Get-ObjectProperty $coverage 'testClass'
        if ((Test-HasProperty $coverage 'testClass') -and $null -ne $testClass -and -not (Test-NonEmptyString $testClass)) { throw 'coverage.testClass must be a non-empty string or null.' }
        $classPattern = Get-ObjectProperty $coverage 'classNamePattern'
        if ((Test-HasProperty $coverage 'classNamePattern') -and -not (Test-NonEmptyString $classPattern)) { throw 'coverage.classNamePattern must be a non-empty string.' }
    }
    $dummyUsers = Get-ObjectProperty $Config 'dummyUsers'
    if ((Test-HasProperty $Config 'dummyUsers') -and $null -eq $dummyUsers) { throw 'dummyUsers must be an object.' }
    if ($null -ne $dummyUsers) {
        if ($dummyUsers -isnot [pscustomobject]) { throw 'dummyUsers must be an object.' }
        if (-not (Test-NonEmptyString (Get-ObjectProperty $dummyUsers 'file'))) { throw 'dummyUsers.file is required.' }
        $defaultProfileName = Get-ObjectProperty $dummyUsers 'profileName'
        if ((Test-HasProperty $dummyUsers 'profileName') -and -not (Test-NonEmptyString $defaultProfileName)) { throw 'dummyUsers.profileName must be a non-empty string.' }
        foreach ($name in @('profileAssignments', 'permissionSetAssignments')) {
            if ((Test-HasProperty $dummyUsers $name) -and (Get-ObjectProperty $dummyUsers $name) -isnot [array]) { throw "dummyUsers.$name must be an array." }
        }
        $profileUsernames = @()
        foreach ($assignment in (Get-ObjectProperty $dummyUsers 'profileAssignments' @())) {
            if (-not (Test-NonEmptyString $assignment.profileName) -or $assignment.usernames -isnot [array] -or @($assignment.usernames).Count -eq 0) {
                throw 'Each dummyUsers.profileAssignments entry requires profileName and at least one username.'
            }
            if (@($assignment.usernames | Where-Object { -not (Test-NonEmptyString $_) }).Count -gt 0) {
                throw 'dummyUsers.profileAssignments usernames must be non-empty strings.'
            }
            $profileUsernames += @($assignment.usernames)
        }
        if (@($profileUsernames | Select-Object -Unique).Count -ne $profileUsernames.Count) {
            throw 'Each dummy user can have only one profile assignment.'
        }
        foreach ($assignment in (Get-ObjectProperty $dummyUsers 'permissionSetAssignments' @())) {
            if ($assignment.permissionSets -isnot [array] -or $assignment.usernames -isnot [array] -or
                @($assignment.permissionSets).Count -eq 0 -or @($assignment.usernames).Count -eq 0) {
                throw 'Each dummyUsers.permissionSetAssignments entry requires permissionSets and usernames.'
            }
            if (@($assignment.permissionSets | Where-Object { -not (Test-NonEmptyString $_) }).Count -gt 0 -or
                @($assignment.usernames | Where-Object { -not (Test-NonEmptyString $_) }).Count -gt 0) {
                throw 'dummyUsers.permissionSetAssignments values must be non-empty strings.'
            }
        }
    }
}

function Invoke-External {
    param(
        [Parameter(Mandatory)][string]$Executable,
        [string[]]$Arguments = @(),
        [switch]$PlanOnly,
        [string]$Label
    )
    if (-not $Label) { $Label = Get-OperationLabel $Executable $Arguments }
    $script:CurrentOperation = $Label
    if ($PlanOnly) {
        Write-RunLine "[dry-run] $Executable $($Arguments -join ' ')" Warning
        return [pscustomobject]@{ ExitCode = 0; Output = @() }
    }
    Write-RunLine "$Label ..." Step
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $job = Start-ThreadJob -ScriptBlock {
        param($File, $NativeArguments, $Directory, $Key)
        $ErrorActionPreference = 'Stop'
        $LASTEXITCODE = 0
        Set-Location -LiteralPath $Directory
        $output = @(& $File @NativeArguments 2>&1 | ForEach-Object { $_.ToString() })
        $code = $LASTEXITCODE
        if ($Key) { $output = @($output | ForEach-Object { $_.Replace($Key, '***') }) }
        [pscustomobject]@{ ExitCode = $code; Output = $output }
    } -ArgumentList $Executable, $Arguments, (Get-Location).Path, $script:InstallationKey
    $lastHeartbeat = 0
    $frame = 0
    $frames = @('|', '/', '-', '\')
    try {
        while ($job.State -in @('NotStarted', 'Running')) {
            $seconds = [int][Math]::Floor($watch.Elapsed.TotalSeconds)
            if ($script:InteractiveOutput) {
                [Console]::Out.Write("`r  $($frames[$frame % $frames.Count]) $(Protect-OutputText $Label) ${seconds}s   ")
                $frame++
            } elseif ($seconds -ge $lastHeartbeat + 5) {
                Write-RunLine "Still running: $Label (${seconds}s)" Info
                $lastHeartbeat = $seconds
            }
            Start-Sleep -Milliseconds 100
        }
        $result = Receive-Job -Job $job -Wait -ErrorAction Stop
    } finally {
        if ($script:InteractiveOutput) {
            [Console]::Out.Write("`r$(' ' * ($Label.Length + 32))`r")
        }
        Stop-Job -Job $job
        Remove-Job -Job $job -Force
    }
    $seconds = [int][Math]::Floor($watch.Elapsed.TotalSeconds)
    Write-RunLine "$Label $(if ($result.ExitCode -eq 0) { 'completed' } else { "failed (exit $($result.ExitCode))" }) in ${seconds}s" $(if ($result.ExitCode -eq 0) { 'Success' } else { 'Failure' })
    if ($script:ShowDetails -or $result.ExitCode -ne 0) {
        foreach ($line in $result.Output) { [Console]::Out.WriteLine("    $(Protect-OutputText $line)") }
    }
    return $result
}

function Invoke-SfJson {
    param([string[]]$Arguments, [switch]$PlanOnly, [switch]$AllowFailure)
    $result = Invoke-External -Executable 'sf' -Arguments ($Arguments + @('--json')) -PlanOnly:$PlanOnly
    if ($PlanOnly) { return $null }
    if ($result.ExitCode -ne 0 -and -not $AllowFailure) { throw "sf $($Arguments -join ' ') failed (exit $($result.ExitCode)): $($result.Output -join "`n")" }
    $jsonStart = -1
    for ($index = 0; $index -lt $result.Output.Count; $index++) {
        if ($result.Output[$index].TrimStart().StartsWith('{')) { $jsonStart = $index; break }
    }
    if ($jsonStart -lt 0) {
        if ($AllowFailure) { return [pscustomobject]@{ status = $result.ExitCode; message = ($result.Output -join "`n"); result = $null } }
        throw "sf $($Arguments -join ' ') returned no JSON."
    }
    try { $parsed = ($result.Output[$jsonStart..($result.Output.Count - 1)] -join "`n") | ConvertFrom-Json }
    catch { throw "Could not parse JSON from sf $($Arguments -join ' '): $($_.Exception.Message)" }
    if ((Get-ObjectProperty $parsed 'status' 0) -ne 0 -and -not $AllowFailure) {
        throw "sf $($Arguments -join ' ') returned a failed JSON response: $($parsed.message)"
    }
    return $parsed
}

function Invoke-Sf {
    param([string[]]$Arguments, [switch]$PlanOnly, [switch]$AllowFailure)
    $result = Invoke-External -Executable 'sf' -Arguments $Arguments -PlanOnly:$PlanOnly
    if (-not $PlanOnly -and $result.ExitCode -ne 0 -and -not $AllowFailure) {
        throw "sf $($Arguments -join ' ') failed (exit $($result.ExitCode)): $($result.Output -join "`n")"
    }
    return $result
}

function ConvertTo-SoqlLiteral {
    param([string]$Value)
    $escaped = $Value.Replace('\', '\\').Replace("'", "\'")
    return "'$escaped'"
}

function Get-PackageDependencies {
    $dependencies = @()
    foreach ($directory in @($script:SfdxProject.packageDirectories)) {
        foreach ($dependency in (Get-ObjectProperty $directory 'dependencies' @())) { $dependencies += $dependency }
    }
    return $dependencies
}

function Get-PackageVersionData {
    param([string]$PackageName)
    $response = Invoke-SfJson @('package', 'version', 'list', '--packages', $PackageName, '--released', '--order-by', 'CreatedDate')
    return @($response.result | Where-Object { $_.SubscriberPackageVersionId } | Sort-Object -Property @(
        @{ Expression = { [int]$_.MajorVersion } },
        @{ Expression = { [int]$_.MinorVersion } },
        @{ Expression = { [int]$_.PatchVersion } },
        @{ Expression = { [int]$_.BuildNumber } }
    ))
}

function Get-ProjectVersionChanges {
    $dependencies = @(Get-PackageDependencies)
    $changes = @()
    $latestByPackage = @{}
    foreach ($dependency in $dependencies) {
        $name = [string]$dependency.package
        if ($latestByPackage.ContainsKey($name)) { continue }
        $alias = Get-ObjectProperty $script:SfdxProject.packageAliases $name
        if (-not $alias) { throw "No package alias found for '$name'." }
        $versions = @(Get-PackageVersionData $alias)
        if ($versions.Count -eq 0) { throw "No released version found for '$name'." }
        $latest = $versions[-1]
        $latestBase = "{0}.{1}.{2}" -f $latest.MajorVersion, $latest.MinorVersion, $latest.PatchVersion
        $latestByPackage[$name] = "$latestBase.LATEST"
        $current = [string](Get-ObjectProperty $dependency 'versionNumber' '')
        $comparable = $current -replace '\.LATEST$|\.NEXT$', ''
        if ($comparable -ne $latestBase) {
            $changes += [pscustomobject]@{ packageName = $name; currentVersion = $current; latestVersion = "$latestBase.LATEST" }
        }
    }
    return [pscustomobject]@{ Changes = $changes; LatestByPackage = $latestByPackage }
}

function Invoke-ProjectVersionCheck {
    $versionCheck = Get-ProjectVersionChanges
    if ($versionCheck.Changes.Count -eq 0) {
        Write-RunLine 'All configured package versions are current.' Success
        return
    }
    foreach ($change in $versionCheck.Changes) {
        $current = if ($change.currentVersion) { $change.currentVersion } else { '(unset)' }
        Write-RunLine "$($change.packageName): $current -> $($change.latestVersion)"
    }
    if (-not $script:ApplyProjectVersions -or $DryRun) {
        Write-RunLine "Preview only: $($versionCheck.Changes.Count) package constraint(s) can be updated. Use -ApplyProjectVersions to write."
        return
    }

    foreach ($directory in $script:SfdxProject.packageDirectories) {
        foreach ($dependency in @($directory.dependencies)) {
            if ($null -eq $dependency) { continue }
            $name = [string]$dependency.package
            if ($versionCheck.LatestByPackage.ContainsKey($name)) { $dependency.versionNumber = $versionCheck.LatestByPackage[$name] }
        }
    }
    $backupPath = "$script:ProjectFilePath.backup"
    $tempPath = "$script:ProjectFilePath.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        Write-Utf8JsonFile -Path $tempPath -Value $script:SfdxProject
        Copy-Item -LiteralPath $script:ProjectFilePath -Destination $backupPath -Force
        Move-Item -LiteralPath $tempPath -Destination $script:ProjectFilePath -Force
    } finally { Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue }
    Write-RunLine "Updated project constraints. Backup: $backupPath" Success
}

function Select-PackageVersion {
    param([string]$PackageName, [string]$RequestedVersion)
    $versions = @(Get-PackageVersionData $PackageName)
    if ($versions.Count -eq 0) { throw "No released version found for package '$PackageName'." }
    if ($script:InstallLatest -or [string]::IsNullOrWhiteSpace($RequestedVersion)) { return $versions[-1] }
    $parts = $RequestedVersion -split '\.'
    if ($parts.Count -lt 3) { throw "Invalid version '$RequestedVersion' for package '$PackageName'." }
    $matchingVersions = @($versions | Where-Object {
        [int]$_.MajorVersion -eq [int]$parts[0] -and
        [int]$_.MinorVersion -eq [int]$parts[1] -and
        [int]$_.PatchVersion -eq [int]$parts[2]
    })
    if ($parts.Count -ge 4 -and $parts[3] -match '^\d+$') {
        $matchingVersions = @($matchingVersions | Where-Object { [int]$_.BuildNumber -eq [int]$parts[3] })
    }
    if ($matchingVersions.Count -eq 0) { throw "Could not resolve requested version '$RequestedVersion' for '$PackageName'." }
    return $matchingVersions[-1]
}

function Get-InstalledPackages {
    $response = Invoke-SfJson @('package', 'installed', 'list', '--target-org', $script:TargetOrg)
    return @($response.result)
}

function Get-PackageNameFromInstall {
    param($Installed)
    foreach ($name in @('SubscriberPackageName', 'PackageName', 'Name', 'Package')) {
        $value = Get-ObjectProperty $Installed $name
        if ($value) { return [string]$value }
    }
    return ''
}

function Invoke-PackageInstall {
    param([string]$PackageName, [string]$VersionId)
    $arguments = @('package', 'install', '--package', $VersionId, '--target-org', $script:TargetOrg, '--wait', [string]$script:PackageWaitMinutes, '--publish-wait', [string]$script:PackageWaitMinutes, '--no-prompt')
    $requiresKey = $PackageName -notin @($script:NoKeyPackages)
    if ($requiresKey) { $requiresKey = (Get-ObjectProperty $script:SfdxProject.packageKeyConfig $PackageName $true) -ne $false }
    if ($requiresKey) {
        if ([string]::IsNullOrEmpty($script:InstallationKey)) { throw "An install key is required for '$PackageName'. Set $($script:KeyEnvironmentVariable)." }
        $arguments += @('--installation-key', $script:InstallationKey)
    }
    for ($attempt = 1; $attempt -le $script:InstallMaxAttempts; $attempt++) {
        if ($script:DryRun) {
            $displayArguments = @($arguments)
            $keyIndex = [Array]::IndexOf($displayArguments, '--installation-key')
            if ($keyIndex -ge 0) { $displayArguments[$keyIndex + 1] = '***' }
            Invoke-External -Executable 'sf' -Arguments $displayArguments -PlanOnly | Out-Null
            return
        }
        $result = Invoke-External -Executable 'sf' -Arguments $arguments -Label "Installing $PackageName (attempt $attempt/$script:InstallMaxAttempts)"
        if ($result.ExitCode -eq 0) { return }
        $text = $result.Output -join "`n"
        $transient = $text -match 'ECONNRESET|ETIMEDOUT|ENOTFOUND|socket hang up|TypeError: terminated|UND_ERR_'
        if (-not $transient -or $attempt -eq $script:InstallMaxAttempts) { throw "Installing '$PackageName' failed (exit $($result.ExitCode)): $text" }
        Write-RunWarning "Transient install failure for $PackageName; retry $attempt/$($script:InstallMaxAttempts) after $($script:RetryDelaySeconds)s."
        Start-Sleep -Seconds $script:RetryDelaySeconds
    }
}

function Resolve-TargetOrg {
    param([switch]$ForPartialRun)
    if ($ForPartialRun -and -not $script:TargetOrgIsExplicit) {
        $response = Invoke-SfJson @('config', 'get', 'target-org')
        $entry = @($response.result | Where-Object { $_.name -eq 'target-org' }) | Select-Object -First 1
        $script:TargetOrg = [string]$entry.value
        if (-not $script:TargetOrg) { throw 'No Salesforce default target org is configured. Pass -OrgAlias or set defaultOrgAlias.' }
        Write-RunValue 'Effective target org' $script:TargetOrg
    }
    if (-not $script:TargetOrg) { throw 'No target org is configured. Pass -OrgAlias or set defaultOrgAlias.' }
}

function Invoke-PostStep {
    param([string]$Step)
    switch ($Step) {
        'deploy' {
            if ($FullDeploy) {
                Invoke-Sf @('project', 'delete', 'tracking', '--target-org', $script:TargetOrg, '--no-prompt') -PlanOnly:$script:DryRun | Out-Null
            }
            Invoke-Sf @('project', 'deploy', 'start', '--target-org', $script:TargetOrg, '--ignore-conflicts') -PlanOnly:$script:DryRun | Out-Null
            Invoke-Sf @('project', 'reset', 'tracking', '--target-org', $script:TargetOrg, '--no-prompt') -PlanOnly:$script:DryRun | Out-Null
            if (-not $FullDeploy) {
                Write-RunLine 'Only tracked changes were deployed. If metadata is missing in the org, run: create-scratch-org.bat -Redeploy'
            }
        }
        'permsets' {
            if (@($script:Config.permissionSets).Count -eq 0) { Write-RunWarning 'No permission sets configured; skipping.'; return $false }
            $arguments = @('org', 'assign', 'permset', '--target-org', $script:TargetOrg)
            foreach ($name in @($script:Config.permissionSets)) { $arguments += @('--name', [string]$name) }
            Invoke-Sf $arguments -PlanOnly:$script:DryRun | Out-Null
        }
        'data' {
            if (-not $script:Config.dummyDataPlan) { Write-RunWarning 'No dummy data plan configured; skipping.'; return $false }
            Invoke-Sf @('data', 'import', 'tree', '--target-org', $script:TargetOrg, '--plan', $script:Config.dummyDataPlan) -PlanOnly:$script:DryRun | Out-Null
            Invoke-DummyUsers
        }
        'community' {
            if (-not $script:Config.communityName) { Write-RunWarning 'No community configured; skipping.'; return $false }
            Invoke-Sf @('community', 'publish', '--target-org', $script:TargetOrg, '--name', $script:Config.communityName) -PlanOnly:$script:DryRun | Out-Null
        }
        default {
            $custom = @($script:Config.customPostSteps | Where-Object { $_.name -eq $Step }) | Select-Object -First 1
            if ($null -eq $custom) { throw "Unknown post-step '$Step'." }
            $result = Invoke-External -Executable $custom.executable -Arguments @($custom.arguments) -PlanOnly:$script:DryRun -Label "Running custom post-step $Step"
            if ($result.ExitCode -ne 0) { throw "Custom step '$Step' failed ($($result.ExitCode)): $($result.Output -join "`n")" }
        }
    }
    return $true
}

function Invoke-DummyUsers {
    $dummy = $script:Config.dummyUsers
    if ($null -eq $dummy) { return }
    $file = [IO.Path]::GetFullPath((Join-Path $script:ProjectRoot $dummy.file))
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { Write-RunWarning "Dummy user file not found: $file"; return }
    $tree = Read-JsonFile $file
    $profileByUsername = @{}
    foreach ($assignment in @($dummy.profileAssignments)) {
        foreach ($username in @($assignment.usernames)) { $profileByUsername[[string]$username] = [string]$assignment.profileName }
    }
    $profileNames = @($dummy.profileName) + @($dummy.profileAssignments | ForEach-Object { $_.profileName }) | Select-Object -Unique
    $profileIds = @{}
    foreach ($name in $profileNames) {
        if ($script:DryRun) { Write-RunLine "[dry-run] Resolve profile '$name'" Warning; continue }
        $response = Invoke-SfJson @('data', 'query', '--target-org', $script:TargetOrg, '--query', "SELECT Id FROM Profile WHERE Name = $(ConvertTo-SoqlLiteral $name) LIMIT 1")
        $profileId = [string](@($response.result.records) | Select-Object -First 1 | ForEach-Object { $_.Id })
        if ($profileId) { $profileIds[$name] = $profileId } else { Write-RunWarning "Profile '$name' is missing in $script:TargetOrg; users mapped to it will be skipped." }
    }
    if ($script:DryRun) {
        Write-RunLine "[dry-run] Import missing dummy users from $file; profiles: $($profileNames -join ', ')" Warning
        foreach ($assignment in @($dummy.permissionSetAssignments)) {
            $arguments = @('org', 'assign', 'permset', '--target-org', $script:TargetOrg)
            foreach ($permissionSet in @($assignment.permissionSets)) { $arguments += @('--name', [string]$permissionSet) }
            foreach ($username in @($assignment.usernames)) { $arguments += @('--on-behalf-of', [string]$username) }
            Invoke-Sf $arguments -PlanOnly | Out-Null
        }
        return
    }
    $usernames = @($tree.records | ForEach-Object { $_.Username } | Where-Object { $_ })
    $existing = @()
    if ($usernames.Count -gt 0) {
        $inClause = ($usernames | ForEach-Object { ConvertTo-SoqlLiteral ([string]$_) }) -join ','
        $response = Invoke-SfJson @('data', 'query', '--target-org', $script:TargetOrg, '--query', "SELECT Username FROM User WHERE Username IN ($inClause)")
        $existing = @($response.result.records | ForEach-Object { $_.Username })
    }
    $newRecords = @()
    foreach ($record in @($tree.records)) {
        $username = [string]$record.Username
        if ($existing -contains $username) { continue }
        $profileName = if ($profileByUsername.ContainsKey($username)) { $profileByUsername[$username] } else { [string]$dummy.profileName }
        if (-not $profileIds.ContainsKey($profileName)) { continue }
        $record.ProfileId = $profileIds[$profileName]
        $newRecords += $record
    }
    if ($newRecords.Count -gt 0) {
        $tempFile = Join-Path ([IO.Path]::GetTempPath()) ("sf-dummy-users-{0}.json" -f [guid]::NewGuid())
        try {
            Write-Utf8JsonFile -Path $tempFile -Value @{ records = $newRecords }
            Invoke-Sf @('data', 'import', 'tree', '--target-org', $script:TargetOrg, '--files', $tempFile) | Out-Null
        } finally { Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue }
    }
    $permissionAssignments = @($dummy.permissionSetAssignments)
    if ($env:DUMMY_USER_PERMSET_ASSIGNMENTS) {
        $permissionAssignments = @()
        foreach ($group in ($env:DUMMY_USER_PERMSET_ASSIGNMENTS -split ';')) {
            if ([string]::IsNullOrWhiteSpace($group)) { continue }
            $separator = $group.IndexOf(':')
            if ($separator -lt 1) { throw 'DUMMY_USER_PERMSET_ASSIGNMENTS entries must use PermissionSet1,PermissionSet2:user1,user2 format.' }
            $names = @($group.Substring(0, $separator) -split '[,\s]+' | Where-Object { $_ })
            $users = @($group.Substring($separator + 1) -split '[,\s]+' | Where-Object { $_ })
            if ($names.Count -eq 0 -or $users.Count -eq 0) { throw 'DUMMY_USER_PERMSET_ASSIGNMENTS groups require permission-set names and usernames.' }
            $permissionAssignments += [pscustomobject]@{ permissionSets = $names; usernames = $users }
        }
    }
    foreach ($assignment in $permissionAssignments) {
        $arguments = @('org', 'assign', 'permset', '--target-org', $script:TargetOrg)
        foreach ($permissionSet in @($assignment.permissionSets)) { $arguments += @('--name', [string]$permissionSet) }
        foreach ($username in @($assignment.usernames)) { $arguments += @('--on-behalf-of', [string]$username) }
        $result = Invoke-SfJson $arguments -AllowFailure
        if ($result.status -ne 0) {
            $failures = @($result.result.failures)
            if ($failures.Count -eq 0 -or @($failures | Where-Object { $_.message -notmatch 'Duplicate PermissionSetAssignment' }).Count -gt 0) {
                throw "Could not assign dummy user permission sets: $($result.message)"
            }
        }
    }
}

function Get-SelectedPostSteps {
    if ($script:BoundParameters.ContainsKey('PostSteps')) { $requested = @($PostSteps | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
    else { $requested = @($script:Config.postSteps) }
    $canonicalSteps = @('deploy', 'permsets', 'data', 'community') + @($script:Config.customPostSteps | ForEach-Object { $_.name })
    if ($requested.Count -eq 1 -and $requested[0] -eq 'all') { return $canonicalSteps }
    if ($requested.Count -eq 1 -and $requested[0] -eq 'none') { return @() }
    foreach ($step in $requested) { if ($step -notin $canonicalSteps) { throw "Unknown post-step '$step'." } }
    return @($canonicalSteps | Where-Object { $_ -in $requested })
}

function Invoke-Packages {
    param([switch]$PlanOnly, [switch]$Update)
    $dependencies = @(Get-PackageDependencies)
    if ($dependencies.Count -eq 0) { Write-RunLine 'No package dependencies are declared.' Skip; return }
    $installed = @()
    if (-not $script:DryRun) { $installed = @(Get-InstalledPackages) }
    $packageIndex = 0
    foreach ($dependency in $dependencies) {
        $packageIndex++
        $name = [string]$dependency.package
        Write-RunSection "[$packageIndex/$($dependencies.Count)] $name"
        $target = Select-PackageVersion $name ([string]$dependency.versionNumber)
        $latest = @(Get-PackageVersionData $name)[-1]
        if (-not $script:SkipVersionCheck -and $target -and $latest -and
            ([int]$target.MajorVersion -ne [int]$latest.MajorVersion -or
             [int]$target.MinorVersion -ne [int]$latest.MinorVersion -or
             [int]$target.PatchVersion -ne [int]$latest.PatchVersion)) {
            Write-RunWarning "$name is configured at $($target.VersionNumber); latest released is $($latest.VersionNumber)."
        }
        $current = @($installed | Where-Object { (Get-PackageNameFromInstall $_) -eq $name }) | Select-Object -First 1
        $currentVersion = [string](Get-ObjectProperty $current 'SubscriberPackageVersionNumber' (Get-ObjectProperty $current 'VersionNumber' ''))
        $state = if ($null -eq $current) { 'missing' } elseif ($currentVersion -eq $target.VersionNumber) { 'current' } else { 'different' }
        $installedLabel = if ($currentVersion) { $currentVersion } else { 'missing' }
        Write-RunValue 'Configured / selected' "$($dependency.versionNumber) / $($target.VersionNumber)"
        Write-RunValue 'Installed version' $installedLabel
        if ($PlanOnly) {
            $script:PackageResults.Planned += "${name}: installed=$installedLabel, selected=$($target.VersionNumber)"
            Write-RunLine "Plan only: $name ($state); no installation." Skip
            continue
        }
        if ($Update -and $state -eq 'different' -and (Compare-Version $currentVersion $target.VersionNumber) -ge 0) {
            $script:PackageResults.Higher += "$name ($currentVersion)"
            Write-RunWarning "Not downgrading $name ($currentVersion > $($target.VersionNumber))."
            continue
        }
        if ($state -eq 'current') {
            $script:PackageResults.Current += "$name ($currentVersion)"
            Write-RunLine "Already correct: $name ($currentVersion)" Skip
            continue
        }
        Invoke-PackageInstall $name ([string]$target.SubscriberPackageVersionId)
        $entry = "$name ($($target.VersionNumber))"
        if ($script:DryRun) { $script:PackageResults.Planned += $entry }
        elseif ($state -eq 'missing') { $script:PackageResults.Installed += $entry }
        else { $script:PackageResults.Updated += $entry }
    }
}

function Compare-Version {
    param([string]$Left, [string]$Right)
    try {
        $leftVersion = [version]($Left -replace '\.LATEST$|\.NEXT$', '')
        $rightVersion = [version]($Right -replace '\.LATEST$|\.NEXT$', '')
        return $leftVersion.CompareTo($rightVersion)
    }
    catch { return 0 }
}

function Invoke-PoolAcquire {
    $devHub = $script:PoolDevHub
    if (-not $devHub) {
        $hub = Invoke-SfJson @('config', 'get', 'target-dev-hub')
        $devHub = [string](@($hub.result | Where-Object { $_.name -eq 'target-dev-hub' } | Select-Object -First 1).value)
    }
    if (-not $devHub) { throw 'Pool use requires -PoolDevHub or sf target-dev-hub configuration.' }
    $result = Invoke-External -Executable 'sfp' -Arguments @('pool', 'list', '--tag', $script:PoolTag, '-a', '--targetdevhubusername', $devHub)
    if ($result.ExitCode -ne 0) { throw "Could not list pool: $($result.Output -join "`n")" }
    $text = $result.Output -join "`n"
    $match = [regex]::Match($text, 'Unused Scratch Orgs in the Pool\s*:\s*(\d+)', 'IgnoreCase')
    if ($match.Success -and [int]$match.Groups[1].Value -gt 0) {
        $script:OrgAction = if ($script:DryRun) { 'Would replace alias with pool org.' } else { 'Attempting to replace alias with pool org; fetch not yet complete.' }
        Invoke-Sf @('org', 'delete', 'scratch', '--target-org', $script:TargetOrg, '--no-prompt') -PlanOnly:$script:DryRun -AllowFailure | Out-Null
        $fetch = Invoke-External -Executable 'sfp' -Arguments @('pool', 'fetch', '--tag', $script:PoolTag, '--targetdevhubusername', $devHub, '--alias', $script:TargetOrg, '--setdefaultusername') -PlanOnly:$script:DryRun
        if ($fetch.ExitCode -ne 0) { throw "Could not fetch pool org: $($fetch.Output -join "`n")" }
        $script:OrgAction = if ($script:DryRun) { 'Would fetch scratch org from pool.' } else { 'Fetched scratch org from pool.' }
        return $true
    }
    if (-not $script:FallbackToCreate) { throw 'No unused scratch org is available in the pool.' }
    Write-RunWarning 'No unused scratch orgs found; falling back to direct creation.'
    return $false
}

function Resolve-DependencyFolders {
    $names = @((Get-PackageDependencies | ForEach-Object { $_.package }) | Select-Object -Unique)
    foreach ($name in $names) {
        $directory = @($script:SfdxProject.packageDirectories | Where-Object { $_.package -eq $name -or [IO.Path]::GetFileName($_.path.TrimEnd('/')) -eq $name }) | Select-Object -First 1
        if ($null -eq $directory) {
            if ($script:RequireLocalDirectories) { throw "Dependency package directory is not declared: $name" }
            Write-RunWarning "No local directory for dependency '$name'; skipping."
            continue
        }
        $path = [IO.Path]::GetFullPath((Join-Path $script:ProjectRoot $directory.path))
        if (-not $path.StartsWith($script:ProjectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "Refusing to modify path outside project root: $path" }
        if (Test-Path -LiteralPath $path -PathType Container) {
            $rootItem = Get-Item -LiteralPath $path -Force
            if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Refusing to use linked dependency directory: $path" }
        }
        [pscustomobject]@{ Name = $name; Path = $path }
    }
}

function Clear-DependencyFolders {
    $preserved = Get-ObjectProperty $script:Config.dependencySourcePolicy 'preserveRootFiles' @('README.md')
    foreach ($dependency in @(Resolve-DependencyFolders)) {
        if (-not (Test-Path $dependency.Path -PathType Container)) { continue }
        $rootItem = Get-Item -LiteralPath $dependency.Path -Force
        if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Refusing to clear linked dependency directory: $($dependency.Path)" }
        foreach ($item in Get-ChildItem -LiteralPath $dependency.Path -Force) {
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Refusing to clear linked dependency child: $($item.FullName)" }
            if ($preserved -contains $item.Name) { continue }
            if ($script:DryRun) { Write-RunLine "[dry-run] Remove $($item.FullName)" Warning }
            else { Remove-Item -LiteralPath $item.FullName -Recurse -Force }
        }
    }
}

function Refresh-DependencyFolders {
    $forceignore = Join-Path $script:ProjectRoot '.forceignore'
    $backup = "$forceignore.disabled"
    $moved = $false
    try {
        if (Test-Path -LiteralPath $forceignore) {
            if ($script:DryRun) { Write-RunLine '[dry-run] Temporarily disable .forceignore' Warning }
            else { Move-Item -LiteralPath $forceignore -Destination $backup -Force; $moved = $true }
        }
        foreach ($dependency in @(Resolve-DependencyFolders)) {
            Invoke-Sf @('project', 'retrieve', 'start', '--target-org', $script:TargetOrg, '-n', $dependency.Name) -PlanOnly:$script:DryRun | Out-Null
        }
    } finally {
        if ($moved -and (Test-Path -LiteralPath $backup)) { Move-Item -LiteralPath $backup -Destination $forceignore -Force }
    }
}

function Invoke-SelfCheck {
    if (-not (Test-Path -LiteralPath $script:ProjectFilePath -PathType Leaf)) { throw "Salesforce project file not found: $script:ProjectFilePath" }
    if (-not (Test-Path -LiteralPath $script:DefinitionFile -PathType Leaf)) { throw "Scratch definition not found: $script:DefinitionFile" }
    $null = Invoke-SfJson @('--version')
    $null = Invoke-SfJson @('org', 'list')
    if ($script:TargetOrgIsExplicit) {
        Resolve-TargetOrg -ForPartialRun
        $null = Invoke-SfJson @('org', 'display', '--target-org', $script:TargetOrg)
    }
    if ($script:UsePool) {
        $poolVersion = Invoke-External -Executable 'sfp' -Arguments @('--version')
        if ($poolVersion.ExitCode -ne 0) { throw 'sfp is required by the configured scratch-org pool.' }
    }
    Write-RunLine 'Self-check passed.' Success
}

function Invoke-CoverageCheck {
    $minimum = if ($script:BoundParameters.ContainsKey('MinimumCoverage')) { $MinimumCoverage } else { $script:CoverageMinimum }
    $testClass = if ($script:BoundParameters.ContainsKey('CoverageTestClass')) { $CoverageTestClass } else { $script:CoverageTestClass }
    $classPattern = if ($script:BoundParameters.ContainsKey('CoverageClassNamePattern')) { $CoverageClassNamePattern } else { $script:CoverageClassPattern }
    $runAll = $CoverageRunAll -or -not $testClass
    if ($minimum -lt 0 -or $minimum -gt 100) { throw 'MinimumCoverage must be between 0 and 100.' }
    if ($DryRun) {
        if ($CoveragePackageId -and -not $CoverageSkipInstall) { Write-RunLine "[dry-run] Install package $CoveragePackageId on $script:TargetOrg" Warning }
        if (-not $CoverageSkipDeploy) { Write-RunLine "[dry-run] Deploy force-app to $script:TargetOrg" Warning }
        if ($runAll) { Write-RunLine '[dry-run] Run all Apex tests with code coverage' Warning }
        else { Write-RunLine "[dry-run] Run Apex test $testClass with code coverage" Warning }
        Write-RunLine "[dry-run] Query $classPattern aggregate coverage and compare with threshold" Warning
        return
    }

    if ($CoveragePackageId -and -not $CoverageSkipInstall) {
        $installArguments = @('package', 'install', '--target-org', $script:TargetOrg, '--package', $CoveragePackageId, '-r', '--json')
        if ($script:InstallationKey) { $installArguments += @('--installation-key', $script:InstallationKey) }
        $installResult = Invoke-External -Executable 'sf' -Arguments $installArguments
        if ($installResult.ExitCode -ne 0) { throw "Coverage package installation failed (exit $($installResult.ExitCode)): $($installResult.Output -join "`n")" }
    }
    if (-not $CoverageSkipDeploy) {
        Invoke-Sf @('project', 'deploy', 'start', '--target-org', $script:TargetOrg, '--source-dir', 'force-app', '--ignore-conflicts', '--json') | Out-Null
    }
    if ($runAll) {
        $waitResult = Invoke-External -Executable 'sf' -Arguments @('apex', 'run', 'test', '--target-org', $script:TargetOrg, '--code-coverage', '--wait', '120', '--json')
        if ($waitResult.ExitCode -ne 0) {
            $runResult = Invoke-SfJson @('apex', 'run', 'test', '--target-org', $script:TargetOrg, '--code-coverage')
            $testRunId = [string]$runResult.result.testRunId
            if (-not $testRunId) { throw 'Could not parse testRunId from asynchronous Apex test run.' }
            Invoke-Sf @('apex', 'get', 'test', '--target-org', $script:TargetOrg, '--test-run-id', $testRunId, '--code-coverage', '--result-format', 'human') | Out-Null
        }
    } else {
        Invoke-Sf @('apex', 'run', 'test', '--target-org', $script:TargetOrg, '--tests', $testClass, '--code-coverage', '--synchronous', '--result-format', 'human') | Out-Null
    }

    $escapedPattern = $classPattern.Replace('\', '\\').Replace("'", "\'")
    $query = "SELECT SUM(NumLinesCovered) covered, SUM(NumLinesUncovered) uncovered FROM ApexCodeCoverageAggregate WHERE ApexClassOrTrigger.Name LIKE '$escapedPattern'"
    $coverageResult = Invoke-SfJson @('data', 'query', '--target-org', $script:TargetOrg, '--use-tooling-api', '--query', $query, '--result-format', 'json')
    $record = @($coverageResult.result.records) | Select-Object -First 1
    if ($null -eq $record) { throw 'Coverage query returned no aggregate row.' }
    $covered = [double]$record.covered
    $uncovered = [double]$record.uncovered
    $total = $covered + $uncovered
    $percentage = if ($total -gt 0) { [math]::Round(($covered / $total) * 100, 2) } else { 0 }
    Write-RunLine "Apex coverage: $percentage% ($covered covered, $uncovered uncovered); required $minimum%."
    if ($percentage -lt $minimum) { throw "Coverage $percentage% is below the required $minimum%." }
}

function Invoke-Main {
    if ($Help) {
        @'
create-scratch-org - create and configure a Salesforce scratch org for this project.

Usage: create-scratch-org.bat [options]   (or .\bin\create-scratch-org.ps1 [options])

Common tasks:
  New scratch org (full setup)          create-scratch-org.bat
  Preview without changing anything     create-scratch-org.bat -DryRun
  Check tools, login and config         create-scratch-org.bat -SelfCheck
  Re-run the post-steps on existing org create-scratch-org.bat -PostStepsOnly
  Re-run selected post-steps            create-scratch-org.bat -PostStepsOnly -PostSteps data,permsets
  Force a full redeploy of all source   create-scratch-org.bat -Redeploy
  Install missing/outdated packages     create-scratch-org.bat -UpdatePackages
  See what packages would change        create-scratch-org.bat -PackagePlan
  Delete the scratch org                create-scratch-org.bat -DeleteOrgOnly
  Create sf-project.config.json         create-scratch-org.bat -InitConfig

Options:
  Target:       -OrgAlias <alias> -DurationDays <1..30> -DefinitionFile <file> -UsePool
  What to run:  -PostStepsOnly -PostSteps <steps> -Redeploy -FullDeploy -SkipOrg -SkipPackages
  Packages:     -UpdatePackages -InstallLatest -PackagePlan -SkipVersionCheck
  Checks:       -DryRun -SelfCheck
  Maintenance:  -CheckVersions -ApplyProjectVersions -CoverageCheck -RefreshDependencySources
                -ClearDependencySourcesOnly
  Config:       -ConfigFile <file> -NoConfig -InitConfig -Force
  Output:       -Verbose -Color -NoColor

-FullDeploy deletes local source tracking before the deploy step so all local source is
deployed, not only tracked changes. -Redeploy = -PostStepsOnly -PostSteps deploy -FullDeploy.

Reads sf-project.config.json beside sfdx-project.json. Requires PowerShell 7 LTS,
jq for dependency cleanup, and Salesforce CLI (sf). It does not require sf-project.
'@ | Write-Host
        return
    }
    if ($Redeploy) {
        $script:PostStepsOnly = [switch]$true
        $script:FullDeploy = [switch]$true
        $script:PostSteps = @('deploy')
        $script:BoundParameters['PostSteps'] = $script:PostSteps
    }
    if (-not $ProjectFile) { $ProjectFile = if ($env:PROJECT_FILE) { $env:PROJECT_FILE } else { 'sfdx-project.json' } }
    $projectFilePath = [IO.Path]::GetFullPath($ProjectFile)
    $script:ProjectFilePath = $projectFilePath
    $script:ProjectRoot = Split-Path -Parent $projectFilePath
    if (-not $script:ProjectRoot) { $script:ProjectRoot = (Get-Location).Path }
    $script:SfdxProject = Read-JsonFile $projectFilePath
    if (-not $ConfigFile -and $env:SF_PROJECT_CONFIG) { $ConfigFile = $env:SF_PROJECT_CONFIG }
    $configPath = if ($ConfigFile) {
        if ([IO.Path]::IsPathRooted($ConfigFile)) { [IO.Path]::GetFullPath($ConfigFile) } else { [IO.Path]::GetFullPath((Join-Path $script:ProjectRoot $ConfigFile)) }
    } else { Join-Path $script:ProjectRoot 'sf-project.config.json' }
    $script:Config = [pscustomobject]@{
        schemaVersion = 1; scratchDefinition = 'config/project-scratch-def.json'; scratchDurationDays = 14
        permissionSets = @(); dummyDataPlan = $null; communityName = $null; postSteps = @('deploy')
        customPostSteps = @(); pool = [pscustomobject]@{ use = $false; tag = 'dev'; fallbackToCreate = $true }
        packageInstallKeyEnvironmentVariable = 'PACKAGE_INSTALL_KEY'
        coverage = [pscustomobject]@{ minimumPercent = 75; testClass = $null; classNamePattern = '%' }
        dependencySourcePolicy = [pscustomobject]@{ preserveRootFiles = @('README.md'); requireLocalDirectories = $true }
    }
    if (-not $NoConfig -and (Test-Path -LiteralPath $configPath)) {
        $loaded = Read-JsonFile $configPath
        foreach ($property in $loaded.PSObject.Properties) { $script:Config | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value -Force }
        Test-Configuration $script:Config
    } elseif (-not $NoConfig -and $ConfigFile) { throw "Configuration file not found: $configPath" }

    if ($null -eq $script:Config.pool) { $script:Config.pool = [pscustomobject]@{ use = $false; tag = 'dev'; fallbackToCreate = $true } }
    if ($null -eq $script:Config.coverage) { $script:Config.coverage = [pscustomobject]@{ minimumPercent = 75; testClass = $null; classNamePattern = '%' } }
    if ($null -eq $script:Config.customPostSteps) { $script:Config.customPostSteps = @() }
    if ($null -eq $script:Config.postSteps) { $script:Config.postSteps = @('deploy') }
    if ($null -eq $script:Config.permissionSets) { $script:Config.permissionSets = @() }
    if ($null -ne $script:Config.dummyUsers) {
        if (-not $script:Config.dummyUsers.profileName) { $script:Config.dummyUsers | Add-Member -NotePropertyName profileName -NotePropertyValue 'Standard User' -Force }
        if ($null -eq $script:Config.dummyUsers.profileAssignments) { $script:Config.dummyUsers | Add-Member -NotePropertyName profileAssignments -NotePropertyValue @() -Force }
        if ($null -eq $script:Config.dummyUsers.permissionSetAssignments) { $script:Config.dummyUsers | Add-Member -NotePropertyName permissionSetAssignments -NotePropertyValue @() -Force }
        if ($env:DUMMY_USER_FILE) { $script:Config.dummyUsers.file = $env:DUMMY_USER_FILE }
        if ($env:DUMMY_USER_PROFILE_NAME) { $script:Config.dummyUsers.profileName = $env:DUMMY_USER_PROFILE_NAME }
    }

    $envAlias = [Environment]::GetEnvironmentVariable('ORG_ALIAS')
    $script:TargetOrgIsExplicit = $script:BoundParameters.ContainsKey('OrgAlias') -or [bool]$envAlias -or [bool]$script:Config.defaultOrgAlias
    $script:TargetOrg = if ($script:BoundParameters.ContainsKey('OrgAlias')) { $OrgAlias } elseif ($envAlias) { $envAlias } elseif ($script:Config.defaultOrgAlias) { [string]$script:Config.defaultOrgAlias } else { Split-Path -Leaf $script:ProjectRoot }
    $duration = if ($DurationDays -gt 0) { $DurationDays } elseif ($env:DURATION_DAYS) { [int]$env:DURATION_DAYS } else { [int]$script:Config.scratchDurationDays }
    $script:EffectiveDurationDays = $duration
    if ($duration -lt 1 -or $duration -gt 30) { throw 'DurationDays must be from 1 to 30.' }
    $script:DefinitionFile = if ($DefinitionFile) { $DefinitionFile } elseif ($env:SCRATCH_DEF_FILE) { $env:SCRATCH_DEF_FILE } else { [string]$script:Config.scratchDefinition }
    if (-not [IO.Path]::IsPathRooted($script:DefinitionFile)) { $script:DefinitionFile = Join-Path $script:ProjectRoot $script:DefinitionFile }
    $script:DefinitionFile = [IO.Path]::GetFullPath($script:DefinitionFile)
    if ($script:BoundParameters.ContainsKey('CommunityName')) { $script:Config.communityName = $CommunityName }
    elseif ($env:COMMUNITY_NAME) { $script:Config.communityName = $env:COMMUNITY_NAME }
    if ($script:BoundParameters.ContainsKey('DummyDataPlan')) { $script:Config.dummyDataPlan = $DummyDataPlan }
    elseif ($env:DUMMY_DATA_PLAN) { $script:Config.dummyDataPlan = $env:DUMMY_DATA_PLAN }
    if ($script:BoundParameters.ContainsKey('PermissionSets')) { $script:Config.permissionSets = @($PermissionSets | ForEach-Object { $_ -split '[,\s]+' } | Where-Object { $_ }) }
    elseif ($env:PERMISSION_SETS) { $script:Config.permissionSets = @($env:PERMISSION_SETS -split '[,\s]+' | Where-Object { $_ }) }
    if (-not $script:BoundParameters.ContainsKey('PostSteps') -and $env:POST_STEPS) { $script:Config.postSteps = @($env:POST_STEPS -split ',' | Where-Object { $_ }) }
    $script:PackageWaitMinutes = if ($env:PACKAGE_WAIT_MINUTES) { [int]$env:PACKAGE_WAIT_MINUTES } else { 10 }
    $script:InstallMaxAttempts = if ($env:PACKAGE_INSTALL_MAX_ATTEMPTS) { [int]$env:PACKAGE_INSTALL_MAX_ATTEMPTS } else { 3 }
    $script:RetryDelaySeconds = if ($env:PACKAGE_INSTALL_RETRY_DELAY_SECONDS) { [int]$env:PACKAGE_INSTALL_RETRY_DELAY_SECONDS } else { 5 }
    $script:CoverageMinimum = if ($env:COVERAGE_MINIMUM) { [double]$env:COVERAGE_MINIMUM } else { [double]$script:Config.coverage.minimumPercent }
    $script:CoverageTestClass = if ($env:COVERAGE_TEST_CLASS) { $env:COVERAGE_TEST_CLASS } else { [string]$script:Config.coverage.testClass }
    $script:CoverageClassPattern = if ($env:COVERAGE_CLASS_NAME_PATTERN) { $env:COVERAGE_CLASS_NAME_PATTERN } else { [string]$script:Config.coverage.classNamePattern }
    $script:InstallLatest = $InstallLatest.IsPresent -or $env:INSTALL_LATEST_PACKAGES -eq 'true'
    $script:SkipVersionCheck = $SkipVersionCheck.IsPresent -or $env:VERIFY_PACKAGE_VERSIONS -eq 'false'
    $script:DryRun = $DryRun.IsPresent
    $script:PoolTag = if ($PoolTag) { $PoolTag } elseif ($env:POOL_TAG) { $env:POOL_TAG } else { [string]$script:Config.pool.tag }
    $script:PoolDevHub = if ($PoolDevHub) { $PoolDevHub } elseif ($env:POOL_DEVHUB_USERNAME) { $env:POOL_DEVHUB_USERNAME } else { [string]$script:Config.pool.devHub }
    $script:FallbackToCreate = -not $NoFallbackToCreate -and [bool]$script:Config.pool.fallbackToCreate
    $script:UsePool = if ($UsePool.IsPresent) { $true } elseif ($env:USE_POOL -eq 'false') { $false } elseif ($env:USE_POOL -eq 'true') { $true } else { [bool]$script:Config.pool.use }
    $script:RequireLocalDirectories = [bool](Get-ObjectProperty $script:Config.dependencySourcePolicy 'requireLocalDirectories' $true)
    $script:KeyEnvironmentVariable = [string]$script:Config.packageInstallKeyEnvironmentVariable
    if ($env:PACKAGE_INSTALL_KEY_ENV_VAR) { $script:KeyEnvironmentVariable = $env:PACKAGE_INSTALL_KEY_ENV_VAR }
    $script:InstallationKey = [Environment]::GetEnvironmentVariable($script:KeyEnvironmentVariable)
    if (-not $script:InstallationKey) { $script:InstallationKey = $env:PACKAGE_INSTALL_KEY }
    if ($env:PACKAGE_INSTALL_MAX_ATTEMPTS) { $script:InstallMaxAttempts = [int]$env:PACKAGE_INSTALL_MAX_ATTEMPTS }
    if ($env:PACKAGE_INSTALL_RETRY_DELAY_SECONDS) { $script:RetryDelaySeconds = [int]$env:PACKAGE_INSTALL_RETRY_DELAY_SECONDS }
    if ($script:InstallMaxAttempts -lt 1) { throw 'PACKAGE_INSTALL_MAX_ATTEMPTS must be at least 1.' }
    if ($script:RetryDelaySeconds -lt 0) { throw 'PACKAGE_INSTALL_RETRY_DELAY_SECONDS cannot be negative.' }
    if ($script:PackageWaitMinutes -lt 0) { throw 'PACKAGE_WAIT_MINUTES cannot be negative.' }
    $script:PackageWaitMinutes = [Math]::Max(1, $script:PackageWaitMinutes)
    $script:NoKeyPackages = @()
    if ($env:PACKAGES_NOT_REQUIRING_INSTALL_KEY) { $script:NoKeyPackages = @($env:PACKAGES_NOT_REQUIRING_INSTALL_KEY -split '[,\s]+' | Where-Object { $_ }) }
    if ($env:FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY -eq 'false') { $script:FallbackToCreate = $false }
    elseif ($env:FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY -eq 'true' -and -not $NoFallbackToCreate) { $script:FallbackToCreate = $true }
    $script:ProjectRoot = [IO.Path]::GetFullPath($script:ProjectRoot)
    $script:CheckProjectVersions = $CheckVersions.IsPresent -or $ApplyProjectVersions.IsPresent
    $script:ApplyProjectVersions = $ApplyProjectVersions.IsPresent

    if ($InitConfig) {
        if ($NoConfig) { throw '-InitConfig cannot be combined with -NoConfig.' }
        if ((Test-Path -LiteralPath $configPath) -and -not $Force -and -not $DryRun) { throw "Config exists; pass -Force to update: $configPath" }
        Set-ObjectProperty $script:Config 'defaultOrgAlias' $script:TargetOrg
        Set-ObjectProperty $script:Config 'scratchDurationDays' $duration
        if ($script:BoundParameters.ContainsKey('PermissionSets')) { $script:Config.permissionSets = @($PermissionSets | ForEach-Object { $_ -split '[,\s]+' } | Where-Object { $_ }) }
        if ($script:BoundParameters.ContainsKey('DummyDataPlan')) { $script:Config.dummyDataPlan = $DummyDataPlan }
        if ($script:BoundParameters.ContainsKey('CommunityName')) { $script:Config.communityName = $CommunityName }
        if ($script:BoundParameters.ContainsKey('PostSteps')) { $script:Config.postSteps = @($PostSteps | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
        if ($DryRun) { $script:Config | ConvertTo-Json -Depth 100; return }
        Write-Utf8JsonFile -Path $configPath -Value $script:Config
        Write-RunLine "Wrote $configPath" Success
        return
    }

    Push-Location $script:ProjectRoot
    try {
        Write-RunSettings $configPath
        if ($ClearDependencySourcesOnly) { $script:PhaseTotal = 1; Write-Phase 'Dependency source cleanup'; Clear-DependencyFolders; return }
        if ($SelfCheck) { $script:PhaseTotal = 1; Write-Phase 'Self-check'; Invoke-SelfCheck; return }
        if ($script:CheckProjectVersions) { $script:PhaseTotal = 1; Write-Phase 'Package versions'; Invoke-ProjectVersionCheck; return }
        if ($DeleteOrgOnly) {
            $script:PhaseTotal = 1
            Write-Phase 'Scratch org deletion'
            Resolve-TargetOrg -ForPartialRun
            $deletion = Invoke-Sf @('org', 'delete', 'scratch', '--target-org', $script:TargetOrg, '--no-prompt') -PlanOnly:$script:DryRun -AllowFailure
            $script:OrgAction = if ($script:DryRun) { 'Would delete scratch org.' } elseif ($deletion.ExitCode -eq 0) { 'Deleted scratch org.' } else { 'Delete attempt failed; inspect CLI details.' }
            return
        }
        if ($PackagePlan) {
            $script:PhaseTotal = 1
            Write-Phase 'Package plan'
            Resolve-TargetOrg -ForPartialRun
            Invoke-Packages -PlanOnly
            return
        }
        $specialMode = $UpdatePackages -or $CoverageCheck
        $steps = if ($specialMode) { @() } else { @(Get-SelectedPostSteps) }
        $setupOrg = -not ($SkipOrg -or $PostStepsOnly -or $specialMode)
        $installPackages = -not $SkipPackages -and -not $PostStepsOnly -and -not $specialMode
        $script:PhaseTotal = [int]$setupOrg + [int]($installPackages -or $UpdatePackages) + [int]($steps.Count -gt 0) + [int][bool]$CoverageCheck + [int][bool]$RefreshDependencySources
        $allSteps = @('deploy', 'permsets', 'data', 'community') + @($script:Config.customPostSteps | ForEach-Object { $_.name })
        $script:SkippedSteps = @($allSteps | Where-Object { $_ -notin $steps })
        Write-RunValue 'Selected post-steps' ($steps -join ', ')
        Write-RunValue 'Not selected' ($script:SkippedSteps -join ', ')
        if (-not $setupOrg -and ($installPackages -or $specialMode -or $steps.Count -gt 0)) { Resolve-TargetOrg -ForPartialRun }
        if ($RefreshDependencySources -and $setupOrg) { Clear-DependencyFolders }
        if ($setupOrg) {
            Write-Phase 'Scratch org'
            if ($UsePool) { $acquired = Invoke-PoolAcquire } else { $acquired = $false }
            if (-not $acquired) {
                if (-not $DryRun -and -not (Test-Path -LiteralPath $script:DefinitionFile -PathType Leaf)) { throw "Scratch definition not found: $script:DefinitionFile" }
                $script:OrgAction = if ($script:DryRun) { 'Would replace scratch org.' } else { 'Attempting to replace scratch org; setup not yet complete.' }
                Invoke-Sf @('org', 'delete', 'scratch', '--target-org', $script:TargetOrg, '--no-prompt') -PlanOnly:$script:DryRun -AllowFailure | Out-Null
                Invoke-Sf @('org', 'create', 'scratch', '--set-default', '--definition-file', $script:DefinitionFile, '--duration-days', [string]$duration, '--alias', $script:TargetOrg) -PlanOnly:$script:DryRun | Out-Null
                $script:OrgAction = if ($script:DryRun) { 'Would create scratch org.' } else { 'Created scratch org.' }
            }
        }
        if ($installPackages -or $UpdatePackages) { Write-Phase 'Packages' }
        if ($UpdatePackages) { Invoke-Packages -Update }
        elseif ($installPackages) { Invoke-Packages }
        if ($CoverageCheck) { Write-Phase 'Coverage'; Invoke-CoverageCheck; return }
        if ($steps.Count -gt 0) { Write-Phase 'Post-steps' }
        $stepIndex = 0
        foreach ($step in $steps) {
            $stepIndex++
            Write-RunSection "[$stepIndex/$($steps.Count)] $step"
            $script:CurrentOperation = "Post-step $step"
            if (Invoke-PostStep $step) {
                $script:CompletedSteps += $step
                Write-RunLine "$(if ($script:DryRun) { 'Would run' } else { 'Completed' }): $step" Success
            } else {
                $script:SkippedSteps += $step
                Write-RunLine "Skipped: $step" Skip
            }
        }
        if ($RefreshDependencySources) { Write-Phase 'Dependency sources'; Refresh-DependencyFolders }
        Write-RunLine $(if ($script:DryRun) { 'Scratch-org setup plan completed.' } else { 'Scratch-org setup completed.' }) Success
    } finally { Pop-Location }
}

$exitCode = 1
try {
    Initialize-Output
    Invoke-Main
    $exitCode = 0
} catch {
    Write-RunLine "ERROR: $($_.Exception.Message)" Failure
} finally {
    Write-RunSummary $exitCode
}
exit $exitCode
