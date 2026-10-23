@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "POWERSHELL_EXE=powershell.exe"
where pwsh.exe >nul 2>&1 && set "POWERSHELL_EXE=pwsh.exe"
"%POWERSHELL_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%create-scratch-org.ps1" %*
set "SCRIPT_EXIT_CODE=%ERRORLEVEL%"
exit /b %SCRIPT_EXIT_CODE%
