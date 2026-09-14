#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "=== Modest Fermi XMRig Setup ===" -ForegroundColor Cyan
Write-Host "Setting up Monero mining with crash protection..." -ForegroundColor Yellow

# Paths
$xmrigDir = "C:\mining\xmrig"
$xmrigExe = "$xmrigDir\xmrig-6.26.0\xmrig.exe"
$configFile = "$xmrigDir\config.json"
$driverPath = "$xmrigDir\xmrig-6.26.0\WinRing0x64.sys"
$logFile = "$xmrigDir\mfl.log"

# 1. Install WinRing0 driver for MSR access (required for performance)
Write-Host "`n[1/5] Installing WinRing0 driver for MSR access..." -ForegroundColor Green
if (Test-Path $driverPath) {
    try {
        $serviceName = "WinRing0_1_2_0"
        $existingService = Get-Service $serviceName -ErrorAction SilentlyContinue
        if ($existingService) {
            Write-Host "  Driver service exists, restarting..." -ForegroundColor Yellow
            Stop-Service $serviceName -Force -ErrorAction SilentlyContinue
            sc.exe delete $serviceName 2>$null
        }
        sc.exe create $serviceName binPath= "$driverPath" type= kernel start= demand
        Start-Service $serviceName -ErrorAction SilentlyContinue
        Write-Host "  WinRing0 driver installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "  Driver install failed (may already exist): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  WinRing0 driver not found at $driverPath" -ForegroundColor Red
}

# 2. Verify config exists
Write-Host "`n[2/5] Verifying configuration..." -ForegroundColor Green
if (-not (Test-Path $configFile)) {
    Write-Host "  Config not found!" -ForegroundColor Red
    exit 1
}
Write-Host "  Config OK: $configFile" -ForegroundColor Green

# 3. Verify xmrig.exe exists
Write-Host "`n[3/5] Verifying XMRig binary..." -ForegroundColor Green
if (-not (Test-Path $xmrigExe)) {
    Write-Host "  XMRig not found!" -ForegroundColor Red
    exit 1
}
Write-Host "  XMRig OK: $xmrigExe" -ForegroundColor Green

# 4. Create scheduled task for auto-start on boot (runs as SYSTEM, hidden)
Write-Host "`n[4/5] Creating scheduled task for background auto-start..." -ForegroundColor Green
$taskName = "ModestFermi_XMRig"
$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$xmrigDir\launch.vbs`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force -ErrorAction SilentlyContinue
Write-Host "  Scheduled task created: $taskName" -ForegroundColor Green

# 5. Start mining NOW (hidden, background)
Write-Host "`n[5/5] Starting XMRig in background..." -ForegroundColor Green
$wshell = New-Object -ComObject WScript.Shell
$wshell.Run("`"$xmrigExe`" --config=`"$configFile`"", 0, $false)
Write-Host "  XMRig started hidden in background" -ForegroundColor Green

Write-Host "`n=== SETUP COMPLETE ===" -ForegroundColor Cyan
Write-Host "Mining is now running in background." -ForegroundColor Yellow
Write-Host "Wallet: 435swUE8htb96xMwWXbfnzCXCkiKWQhcVKpQzjAHwNMkiWxPnzJiaiH82ucpvnfgpebBJ9QMjyVWnFdF6ih42LVLJY587wv" -ForegroundColor Cyan
Write-Host "Pool: MoneroOcean (gulf.moneroocean.stream:10001)" -ForegroundColor Cyan
Write-Host "Dashboard: https://moneroocean.stream/ (enter wallet address above)" -ForegroundColor Cyan
Write-Host "`nConfig: 50% CPU max, 1-2 threads, thermal yield enabled" -ForegroundColor Green
Write-Host "Auto-starts on boot via Task Scheduler (hidden)" -ForegroundColor Green
Write-Host "Log file: $logFile" -ForegroundColor Green