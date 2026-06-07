@echo off
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0app\CodeAgentLight.ps1"
if errorlevel 1 pause
