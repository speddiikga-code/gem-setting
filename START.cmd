@echo off
rem Double-click entry point. Runs bootstrap.ps1 with the stock Windows PowerShell; execution policy
rem is bypassed for this one process only. Arguments are passed on to setup.ps1.
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0bootstrap.ps1" %*
set result=%errorlevel%
echo.
pause
exit /b %result%
