@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ops\push_dep.ps1" %*
exit /b %errorlevel%
