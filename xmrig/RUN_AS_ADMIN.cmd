@echo off
title Modest Fermi XMRig - Run as Administrator
echo.
echo ============================================================
echo   MODEST FERMI XMRIG - MONERO MINING SETUP
echo ============================================================
echo.
echo This will:
echo   1. Install WinRing0 driver for MSR access (performance)
echo   2. Configure XMRig for laptop-safe mining (50% CPU max)
echo   3. Create auto-start task (runs hidden on boot)
echo   4. Start mining immediately in background
echo.
echo Wallet: 435swUE8htb96xMwWXbfnzCXCkiKWQhcVKpQzjAHwNMkiWxPnzJiaiH82ucpvnfgpebBJ9QMjyVWnFdF6ih42LVLJY587wv
echo Pool:   MoneroOcean (gulf.moneroocean.stream:10001)
echo Dashboard: https://moneroocean.stream/
echo.
echo Press any key to run as Administrator...
pause >nul

powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"C:\mining\xmrig\setup_and_run.ps1\"' -Verb RunAs"