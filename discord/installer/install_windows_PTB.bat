@echo off
REM Just run a powershell command.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0%win_ps.ps1' -isPTB"
pause

