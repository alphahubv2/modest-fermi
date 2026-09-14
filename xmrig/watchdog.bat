@echo off
:loop
tasklist /FI "IMAGENAME eq xmrig.exe" 2>NUL | find /I "xmrig.exe" >NUL
if errorlevel 1 (
    start "" /MIN "C:\mining\xmrig\xmrig-6.26.0\xmrig.exe" --config="C:\mining\xmrig\config.json"
)
timeout /t 60 /nobreak >NUL
goto loop