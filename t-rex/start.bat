@echo off
title Ravencoin Mining
set RVN_ADDRESS=YOUR_RVN_ADDRESS
set POOL=stratum+tcp://rvn.2miners.com:6060
"C:\mining\t-rex\t-rex.exe" -a kawpow -o %POOL% -u %RVN_ADDRESS% -p x --intensity 80
pause
