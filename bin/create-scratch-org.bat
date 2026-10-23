@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
where pwsh.exe >nul 2>&1
if errorlevel 1 (
    echo PowerShell 7 LTS is required. Install it through your approved software channel and ensure pwsh.exe is on PATH. >&2
    exit /b 1
)
pwsh.exe -NoLogo -NoProfile -File "%SCRIPT_DIR%create-scratch-org.ps1" %*
set "SCRIPT_EXIT_CODE=%ERRORLEVEL%"
exit /b %SCRIPT_EXIT_CODE%
