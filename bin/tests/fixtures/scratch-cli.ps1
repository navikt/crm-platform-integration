$ErrorActionPreference = 'Stop'
$tool = $args[0]
$arguments = @($args | Select-Object -Skip 1)
$rules = @(Get-Content -LiteralPath $env:SCRATCH_TEST_RULES -Raw | ConvertFrom-Json)
$rule = $rules | Where-Object {
    if ($_.tool -ne $tool -or $_.prefix.Count -gt $arguments.Count) { return $false }
    for ($index = 0; $index -lt $_.prefix.Count; $index++) {
        if ($_.prefix[$index] -cne $arguments[$index]) { return $false }
    }
    return $true
} | Select-Object -First 1
$record = [ordered]@{
    tool = $tool
    arguments = @($arguments | ForEach-Object {
        if ($env:PACKAGE_INSTALL_KEY) { $_.Replace($env:PACKAGE_INSTALL_KEY, '***') } else { $_ }
    })
    unexpected = ($null -eq $rule)
    exitCode = $(if ($null -eq $rule) { 97 } else { $rule.exitCode })
}
$record | ConvertTo-Json -Compress | Add-Content -LiteralPath $env:SCRATCH_TEST_LOG -Encoding utf8
if ($null -eq $rule) {
    [Console]::Error.WriteLine("Unexpected fake CLI call: $tool $($arguments -join ' ')")
    exit 97
}
if ($rule.delaySeconds) { Start-Sleep -Seconds $rule.delaySeconds }
if ($rule.stderr) { [Console]::Error.WriteLine($rule.stderr) }
if ($rule.output) { [Console]::Out.WriteLine($rule.output) }
exit $rule.exitCode
