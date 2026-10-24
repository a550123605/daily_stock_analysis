@echo off
chcp 65001 >nul
title DSA 预热大盘复盘
cd /d "%~dp0daily_stock_analysis"

rem 先生成一份大盘复盘并入库，之后 4 小时内所有个股分析直接复用，
rem 不必每只股票都重跑一次大盘（省 ~5k tokens / 只，省 2~3 分钟 / 只）。

set HTTP_PROXY=http://127.0.0.1:15732
set HTTPS_PROXY=http://127.0.0.1:15732
set NO_PROXY=localhost,127.0.0.1,qt.gtimg.cn,web.ifzq.gtimg.cn,hq.sinajs.cn,money.finance.sina.com.cn,baostock.com,api.tushare.pro

echo 正在预热大盘复盘（A股 + 美股），约需 3~6 分钟...
echo.
"%~dp0dsa-env\Scripts\python.exe" 预热大盘.py %*

echo.
pause
