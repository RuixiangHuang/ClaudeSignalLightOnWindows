@echo off
start "Code Agent Light" powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0app\CodeAgentLight.ps1"
