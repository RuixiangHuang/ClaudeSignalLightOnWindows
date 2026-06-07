@echo off
node.exe "%~dp0tools\remove-claude-hooks.js" "%USERPROFILE%\.claude\settings.json"
if errorlevel 1 pause
