@echo off
chcp 65001 >nul
title DSA Dashboard - http://127.0.0.1:8000
cd /d "%~dp0daily_stock_analysis"

if not exist "%~dp0dsa-env\Scripts\python.exe" (
    echo [ERROR] Python venv not found: %~dp0dsa-env
    pause
    exit /b 1
)

rem 代理：A股走直连(腾讯)，美股/东财补数据走代理；代理没开时A股照常，美股会失败
set HTTP_PROXY=http://127.0.0.1:15732
set HTTPS_PROXY=http://127.0.0.1:15732
set NO_PROXY=localhost,127.0.0.1,qt.gtimg.cn,web.ifzq.gtimg.cn,hq.sinajs.cn,money.finance.sina.com.cn,baostock.com,api.tushare.pro

start "" /min cmd /c "timeout /t 18 >nul & start http://127.0.0.1:8000"

echo ==================================================
echo   Dashboard : http://127.0.0.1:8000
echo   Stocks    : 10 A股/ETF + KO BRK.B VOO QQQM  (.env STOCK_LIST)
echo   Auto run  : 每个交易日 18:00
echo   Stop      : close this window or Ctrl+C
echo ==================================================
echo.

"%~dp0dsa-env\Scripts\python.exe" main.py --serve

pause
