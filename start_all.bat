@echo off
echo Starting all passive income streams...

echo [1] Kryptex GPU Mining...
start "" "%LOCALAPPDATA%\Kryptex\Kryptex.exe" 2>nul

echo [2] Salad GPU Compute...
start "" "%LOCALAPPDATA%\Salad\Salad.exe" 2>nul

echo [3] Honeygain Bandwidth...
start "" "%LOCALAPPDATA%\Programs\Honeygain\Honeygain.exe" 2>nul

echo [4] EarnApp Bandwidth...
start "" "%LOCALAPPDATA%\Programs\EarnApp\EarnApp.exe" 2>nul

echo [5] Peer2Profit Bandwidth...
start "" "%LOCALAPPDATA%\Programs\Peer2Profit\Peer2Profit.exe" 2>nul

echo [6] Pawns.app Bandwidth...
start "" "%LOCALAPPDATA%\Programs\Pawns\Pawns.exe" 2>nul

echo [7] ProxyBase Bandwidth...
start "" "%LOCALAPPDATA%\Programs\ProxyBase\ProxyBase.exe" 2>nul

echo [8] Titan Network...
start "" "%LOCALAPPDATA%\Titan\titan.exe" 2>nul

echo [9] Owlrun Compute...
start "" "%LOCALAPPDATA%\Programs\Owlrun\Owlrun.exe" 2>nul

echo [10] Pasiv Mining...
start "" "%LOCALAPPDATA%\Programs\Pasiv\Pasiv.exe" 2>nul

echo [11] CPU Mining (XMRig)...
start "" "C:\mining\xmrig\start.bat"

echo.
echo Desktop apps started!
echo Browser extensions: Grass, Brave, Presearch, Freecash, StormX
echo Nielsen Panel: install from website
echo.
pause
