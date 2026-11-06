@echo off
setlocal
cd /d "%~dp0"
curl.exe --silent --fail http://127.0.0.1:3000/api/health >nul 2>&1
if errorlevel 1 (
  start "" /min cmd.exe /c "cd /d ""%~dp0backend"" && node server.js"
  timeout /t 5 /nobreak >nul
)
start "" "http://127.0.0.1:3000/"