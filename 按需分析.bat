@echo off
chcp 936 >nul
setlocal
title 股票按需分析 - 跑一轮后自动退出
cd /d "%~dp0"

if not exist "%~dp0dsa-env\Scripts\python.exe" (
    echo [错误] 未找到虚拟环境: %~dp0dsa-env
    pause
    exit /b 1
)
if not exist "%~dp0daily_stock_analysis\main.py" (
    echo [错误] 未找到 daily_stock_analysis\main.py
    pause
    exit /b 1
)

rem 代理: A股走直连(腾讯), 美股走代理; 代理没开时A股照常, 美股会失败
set "HTTP_PROXY=http://127.0.0.1:15732"
set "HTTPS_PROXY=http://127.0.0.1:15732"
set "NO_PROXY=localhost,127.0.0.1,qt.gtimg.cn,web.ifzq.gtimg.cn,hq.sinajs.cn,money.finance.sina.com.cn,baostock.com,api.tushare.pro"

rem === 关键1: .env 里 RUN_IMMEDIATELY=false, 命令行模式默认不跑, 这里临时覆盖为 true ===
set "RUN_IMMEDIATELY=true"

rem === 关键2: .env 里 WEBUI_ENABLED=true 会让命令行也起 Web 服务并常驻, 关掉才能跑完就退出 ===
set "WEBUI_ENABLED=false"

echo ==================================================
echo   股票按需分析 - 立刻跑一轮, 跑完自动退出
echo --------------------------------------------------
echo   范围 : STOCK_LIST 全部标的 + 大盘复盘
echo   推送 : 合并为 1 封邮件
echo   成本 : 约 0.42 元 空闲时段, 0.84 元 高峰
echo   日期 : 忽略交易日限制, 周末/节假日照跑
echo   退出 : 分析完成后不常驻, 关窗口即结束
echo ==================================================
echo.

netstat -ano | findstr /C:":8000 " | findstr /C:"LISTENING" >nul 2>&1
if not errorlevel 1 echo [提示] 8000 端口有服务在跑, 若它正在分析则两边会重复消耗额度

echo.
echo 5 秒后开始, 按 Ctrl+C 可取消...
timeout /t 5 /nobreak >nul 2>&1
echo.

cd /d "%~dp0daily_stock_analysis"
"%~dp0dsa-env\Scripts\python.exe" main.py --force-run %*
set "RC=%ERRORLEVEL%"

echo.
echo ==================================================
if "%RC%"=="0" (
    echo   [完成] 本轮分析结束
    echo   报告目录: %~dp0daily_stock_analysis\reports
) else (
    echo   [失败] 返回码 %RC%
    echo   请把上面的报错内容发出来排查
)
echo ==================================================
echo.
pause
exit /b %RC%
