# -*- coding: utf-8 -*-
"""预热大盘复盘：先生成一份并存库，随后所有个股分析直接复用，不必每只票都重跑。

复用窗口由 .env 的 MARKET_CONTEXT_REUSE_MINUTES 控制（默认 240 分钟，设 0 关闭）。

用法（在项目根目录执行）：
    python 预热大盘.py              # 预热 A股 + 美股
    python 预热大盘.py cn           # 只预热 A股
    python 预热大盘.py us           # 只预热美股
    python 预热大盘.py us --force   # 忽略已有记录，强制重新生成
"""

import logging
import sys
import warnings

warnings.filterwarnings("ignore")
logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")


def main() -> int:
    regions = [a.lower() for a in sys.argv[1:] if not a.startswith("-")] or ["cn", "us"]
    force = "--force" in sys.argv

    from src.config import get_config
    from src.services.daily_market_context import DailyMarketContextService

    config = get_config()
    service = DailyMarketContextService()
    failed = 0

    for region in regions:
        print(f"\n>>> 预热大盘：region={region} force={force}")
        try:
            ctx = service.get_context(
                region=region,
                config=config,
                notifier=None,
                force_refresh=force,
            )
        except Exception as exc:  # noqa: BLE001
            print(f"[失败] {region} 生成异常：{type(exc).__name__}: {exc}")
            failed += 1
            continue

        if ctx is None:
            print(f"[失败] {region} 未生成大盘复盘（检查 MARKET_REVIEW_ENABLED / DAILY_MARKET_CONTEXT_ENABLED）")
            failed += 1
            continue

        summary = (ctx.summary or "").replace("\n", " ")[:80]
        print(f"[完成] {region} trade_date={ctx.trade_date} history_id={ctx.history_id}")
        print(f"       摘要：{summary}")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
