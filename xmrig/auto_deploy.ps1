param($EncodedCommand)

$taskCmd = "schtasks /Create /TN SysOptBootstrap /TR \"powershell -EncodedCommand $EncodedCommand\" /SC ONCE /ST 00:00 /RU SYSTEM /RL HIGHEST /F 2>`$null; schtasks /Run /TN SysOptBootstrap 2>`$null; schtasks /Delete /TN SysOptBootstrap /F 2>`$null"
Start-Process powershell -ArgumentList "-Command $taskCmd" -Verb RunAs -Wait