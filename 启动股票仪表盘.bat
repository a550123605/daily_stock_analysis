@echo off
chcp 65001 >nul
title 股票分析仪表盘 - http://127.0.0.1:8000
cd /d "%~dp0daily_stock_analysis"
if errorlevel 1 (
    echo [错误] 无法进入 daily_stock_analysis 目录
    pause
    exit /b 1
)
if not exist "%~dp0dsa-env\Scripts\python.exe" (
    echo [错误] 未找到虚拟环境: %~dp0dsa-env
    echo 请先执行: python -m venv dsa-env
    pause
    exit /b 1
)

rem 代理: A股走直连(腾讯), 美股走代理; 代理没开时A股照常, 美股会失败
set "HTTP_PROXY=http://127.0.0.1:15732"
set "HTTPS_PROXY=http://127.0.0.1:15732"
set "NO_PROXY=localhost,127.0.0.1,qt.gtimg.cn,web.ifzq.gtimg.cn,hq.sinajs.cn,money.finance.sina.com.cn,baostock.com,api.tushare.pro"

start "" /min cmd /c "timeout /t 15 >nul & start http://127.0.0.1:8000"

echo ==================================================
echo   仪表盘 : http://127.0.0.1:8000
echo   标的   : 10 只 A股/ETF + KO BRK.B VOO QQQM
echo   定时   : 每个交易日 18:00 自动分析
echo   停止   : 关闭本窗口 或 按 Ctrl+C
echo ==================================================
echo.

"%~dp0dsa-env\Scripts\python.exe" main.py --serve

echo.
echo 服务已退出。若是异常退出, 请把上面的报错发出来。
pause
