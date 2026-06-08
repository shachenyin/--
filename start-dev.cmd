@echo off
setlocal

set "PROJECT_DIR=%~dp0"
set "PORTABLE_NPM=D:\tools\node-v24.15.0-win-x64\npm.cmd"
set "PORTABLE_NODE=D:\tools\node-v24.15.0-win-x64\node.exe"

cd /d "%PROJECT_DIR%"

if not exist ".env.local" (
  copy ".env.example" ".env.local" >nul
  echo First start: .env.local has been created.
  echo The web page will open and show the setup guide.
)

echo Starting Student Project Tracker...
echo Browser URL: http://localhost:3000
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
  set "LAN_IP=%%a"
  goto :showLanUrl
)

:showLanUrl
if defined LAN_IP (
  set "LAN_IP=%LAN_IP: =%"
  echo LAN URL: http://%LAN_IP%:3000
)
start "" "http://localhost:3000"

if exist "%PORTABLE_NODE%" (
  "%PORTABLE_NODE%" ".\node_modules\next\dist\bin\next" dev --webpack -H 0.0.0.0
) else if exist "%PORTABLE_NPM%" (
  "%PORTABLE_NPM%" run dev
) else (
  npm run dev
)

pause
