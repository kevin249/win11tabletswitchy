@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Z13Mode.ps1"
if errorlevel 1 (
  echo.
  echo Installation failed. Press any key to close.
  pause >nul
)
endlocal
