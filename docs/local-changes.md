# 本分支相对上游的改动说明

> 上游项目：[ZhuLinsen/daily_stock_analysis](https://github.com/ZhuLinsen/daily_stock_analysis)
> 本仓库：`a550123605/daily_stock_analysis`（同一份代码 + 下列 3 处源码补丁、3 个脚本）
> 记录时间：2026-10-24，环境：Windows + Python 3.13 + 本地代理

所有改动都遵循一个原则：**能用环境变量开关控制的一律给开关，默认行为保持与上游一致**，方便随时 `git pull` 上游后重新套用。

---

## 1. 代理配置以 .env 为准（`src/config.py`）

### 问题
`setup_env()` 调用 `load_dotenv(override=False)`，系统环境变量优先级高于 `.env`。当宿主环境里残留一个失效代理（例如 `HTTP_PROXY=127.0.0.1:1608`）时，`.env` 里写的可用代理完全不生效，表现为「东财 000 / Yahoo 403」，且日志里看不出任何线索。

### 改动
`setup_env()` 读取 `.env` 原始值后，对 `HTTP_PROXY / HTTPS_PROXY / NO_PROXY` 三个键强制写入 `os.environ`，覆盖系统环境变量。

### 验证
修复前：`os.getenv('HTTP_PROXY')` = 失效代理，Yahoo 403。
修复后：`os.getenv('HTTP_PROXY')` = `.env` 中的可用代理，Yahoo 200。

---

## 2. 东财是否走代理可配置（`src/config.py`）

### 问题
原代码只要检测到代理，就把 `eastmoney.com` 硬编码进 `NO_PROXY`（设计意图是国内站直连更快）。但在部分网络环境下**东财直连是被阻断的、只有走代理才通**，这个硬编码等于把东财永久排除在代理之外，且无从覆盖。

### 改动
新增两个开关：

| 变量 | 作用 |
|---|---|
| `EASTMONEY_VIA_PROXY=true` | 把 `eastmoney.com` 从 `NO_PROXY` 中移除，让东财走代理 |
| `PROXY_BYPASS_DOMAINS=域名1,域名2` | 任意其它需要走代理（从 `NO_PROXY` 剔除）的域名 |

默认 `EASTMONEY_VIA_PROXY=false`，与上游行为一致。

### 实测结论（重要）
东财走本地代理**能通，但不稳定**：

- 首次测试 5 个接口（实时 / 日 K / 资金流）全部 200，拿到真实数据；
- 随后连续 10 次请求全部连接被重置，`curl`、`requests`、`curl_cffi` 三种客户端表现一致 → 排除客户端因素，是代理出口线路问题。

因此本仓库默认仍让东财走直连（快速失败），A 股行情由腾讯承担（0.5 秒取到 38 根日 K，比东财更快）。资金流/筹码字段在东财不可达时为空，属预期。

---

## 3. 大盘复盘跨查询复用（`src/services/daily_market_context.py`）

### 问题
项目本身设计了「大盘复盘生成一次 → 存库 → 个股复用」的机制（`analysis_history` 中 `code=MARKET` 的记录 + 内存缓存 + 跨进程文件锁）。但缓存键里绑定了 `query_id`，而**每触发一次分析都会生成新的 query_id**，导致历史记录永远判定为不匹配、缓存永远 miss。

实测：一天内触发 7 次个股分析，库里躺了 7 份大盘复盘，每份约 **5.4k tokens + 2.5 分钟**，全部是重复劳动。

### 改动
在 `_load_same_day_history()` 末尾新增 `_load_cross_query_reuse()`：按「记录创建时间落在 `MARKET_CONTEXT_REUSE_MINUTES` 窗口内」复用，不再要求 `query_id` 一致。

判定条件：
- 报告的 `region`、`report_language` 与本次请求一致；
- 记录创建时间在复用窗口内（默认 240 分钟，设 0 关闭）；
- 记录中的交易日与本次分析目标日的偏差不超过 7 天（周末/节假日复盘按当日生成、个股用上一交易日，两者天然差 1~2 天）；
- 有多条时取最新一条。

### 验证
连续触发 BRK.B、QQQM（美股）与 600519（A 股），日志均输出：

```
[大盘复用] 命中已有大盘复盘，跳过重复生成 region=us target_date=2026-10-23
[大盘复用] 命中已有大盘复盘，跳过重复生成 region=cn target_date=2026-10-23
```

`analysis_history` 中 `MARKET` 记录数保持 13 条不变，即零重复生成。

### 收益
14 只标的每天只跑 1 次大盘，可省约 13 × 5.4k ≈ **7 万 tokens / 天**，以及约 30 分钟等待时间。

---

## 4. 美股代码格式兼容（`data_provider/yfinance_fetcher.py`）

### 问题
`BRK.B` 这类含股票类别的代码，Yahoo Finance 要求写成 `BRK-B`。原实现原样透传，导致 404，`BRK.B` 取不到任何日线。

### 改动
`_convert_stock_code()` 中美股分支：检测到 `.` 时替换为 `-`。

### 验证
`BRK.B` 修复前后：`rows=0` → `rows=30`，最新收盘 542.19。

---

## 5. 新增脚本

| 文件 | 说明 |
|---|---|
| `预热大盘.py` | 先跑一次大盘复盘并入库，后续所有个股分析直接复用。用法：`python 预热大盘.py` / `python 预热大盘.py us --force` |
| `预热大盘.bat` | Windows 双击版预热（含代理环境变量设置） |
| `启动股票仪表盘.bat` | Windows 双击启动 Web 工作台并自动打开浏览器 |

`.bat` 里的 `dsa-env` 是本机虚拟环境目录名，换机器时按实际路径调整，或直接 `python main.py --serve`。

---

## 回滚方式

三处源码补丁都能通过环境变量关闭，无需回滚代码：

```bash
EASTMONEY_VIA_PROXY=false          # 东财恢复走直连（默认值）
MARKET_CONTEXT_REUSE_MINUTES=0     # 恢复"每次分析都重算大盘复盘"
```

需要彻底回到上游版本：`git fetch upstream && git reset --hard upstream/main`。

---

## 安全提示

- **`.env` 含 API Key 与邮箱授权码，已被 `.gitignore` 忽略，请勿提交**。
- 本仓库为 public，`reports/` 与 `data/*.db` 也已被忽略——里面含个人持仓与分析记录。
