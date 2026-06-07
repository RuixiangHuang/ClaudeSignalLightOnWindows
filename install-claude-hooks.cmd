@echo off
node.exe "%~dp0tools\configure-claude-hooks.js" "%USERPROFILE%\.claude\settings.json"
if errorlevel 1 pause
