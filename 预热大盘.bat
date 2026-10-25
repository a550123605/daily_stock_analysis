@echo off
chcp 65001 >nul
title 预热大盘复盘
cd /d "%~dp0daily_stock_analysis"
if errorlevel 1 (
    echo [错误] 无法进入 daily_stock_analysis 目录
    pause
    exit /b 1
)
if not exist "%~dp0dsa-env\Scripts\python.exe" (
    echo [错误] 未找到虚拟环境: %~dp0dsa-env
    pause
    exit /b 1
)

rem 先生成一份大盘复盘并入库, 之后 4 小时内所有个股分析直接复用
set "HTTP_PROXY=http://127.0.0.1:15732"
set "HTTPS_PROXY=http://127.0.0.1:15732"
set "NO_PROXY=localhost,127.0.0.1,qt.gtimg.cn,web.ifzq.gtimg.cn,hq.sinajs.cn,money.finance.sina.com.cn,baostock.com,api.tushare.pro"

echo 正在预热大盘复盘 (A股 + 美股), 约需 3-6 分钟...
echo.
"%~dp0dsa-env\Scripts\python.exe" 预热大盘.py %*

echo.
pause
