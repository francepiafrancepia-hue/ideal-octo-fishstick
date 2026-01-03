import datetime as _dt
import json
import math
import statistics
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

BASE_URL = "https://api.coingecko.com/api/v3"
EXCLUSION_SYMBOLS = {"usdt", "usdc", "fdusd", "dai", "weth", "wbtc"}


def _fetch_json(path: str, params: dict | None = None) -> dict:
    query = f"?{urllib.parse.urlencode(params)}" if params else ""
    url = f"{BASE_URL}{path}{query}"
    req = urllib.request.Request(url, headers={"User-Agent": "weekend-scanner"})
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.load(resp)


def _safe_fetch(path: str, params: dict | None = None) -> dict | None:
    try:
        return _fetch_json(path, params)
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError):
        return None


def fetch_market_snapshot(count: int = 20) -> list[dict]:
    params = {
        "vs_currency": "usd",
        "order": "volume_desc",
        "per_page": str(count),
        "page": "1",
        "sparkline": "false",
        "price_change_percentage": "1h,24h,7d",
    }
    data = _safe_fetch("/coins/markets", params=params)
    if data is None:
        raise RuntimeError("Real-time data unavailable; aborting.")
    return data[:count]


def fetch_daily_prices(asset_id: str) -> list[float]:
    data = _safe_fetch(
        f"/coins/{asset_id}/market_chart",
        params={"vs_currency": "usd", "days": "30", "interval": "daily"},
    )
    if data is None:
        raise RuntimeError("Real-time data unavailable; aborting.")
    return [price[1] for price in data.get("prices", [])]


def fetch_hourly_prices(asset_id: str) -> list[float]:
    data = _safe_fetch(
        f"/coins/{asset_id}/market_chart",
        params={"vs_currency": "usd", "days": "3", "interval": "hourly"},
    )
    if data is None:
        raise RuntimeError("Real-time data unavailable; aborting.")
    return [price[1] for price in data.get("prices", [])]


def moving_average(prices: list[float], window: int) -> float | None:
    if len(prices) < window:
        return None
    return sum(prices[-window:]) / window


def pct_change(current: float, past: float) -> float | None:
    if current is None or past is None or past == 0:
        return None
    return (current - past) / past * 100


def detect_squeeze(hourly_prices: list[float]) -> bool:
    if len(hourly_prices) < 24:
        return False
    recent = hourly_prices[-6:]
    base = hourly_prices[-24:]
    if len(set(base)) <= 1:
        return False
    base_std = statistics.pstdev(base)
    recent_std = statistics.pstdev(recent)
    return recent_std < 0.6 * base_std if base_std > 0 else False


def format_number(value: float | None, prefix: str = "", suffix: str = "") -> str:
    if value is None or isinstance(value, bool) or math.isnan(value):
        return "n/a"
    if abs(value) >= 1:
        formatted = f"{value:,.2f}"
    else:
        formatted = f"{value:.6f}".rstrip("0").rstrip(".")
    return f"{prefix}{formatted}{suffix}"


def select_high_conviction(candidates: list[dict], btc_change: float | None) -> list[dict]:
    scored = []
    for asset in candidates:
        score = 0.0
        if asset.get("above_ma"):
            score += 1.0
        if asset.get("four_h_change", 0) > 0:
            score += 1.0
        if asset.get("squeeze"):
            score += 0.5
        if btc_change is not None and asset.get("change_24h") is not None:
            if asset["change_24h"] > btc_change:
                score += 0.5
        if asset.get("change_24h") and abs(asset["change_24h"]) >= 5:
            score += 1.0
        asset["score"] = score
        scored.append(asset)
    scored.sort(key=lambda a: (a["score"], a.get("volume", 0)), reverse=True)
    return scored[:2]


def build_asset_profile(raw: dict, btc_change: float | None) -> dict:
    daily = fetch_daily_prices(raw["id"])
    hourly = fetch_hourly_prices(raw["id"])
    ma20 = moving_average(daily, 20)
    above_ma = ma20 is not None and raw["current_price"] > ma20
    four_h_change = None
    if len(hourly) >= 5:
        four_h_change = pct_change(hourly[-1], hourly[-5])
    squeeze = detect_squeeze(hourly)
    rel_strength = (
        btc_change is not None
        and raw.get("price_change_percentage_24h") is not None
        and raw["price_change_percentage_24h"] > btc_change
    )
    return {
        "id": raw["id"],
        "symbol": raw["symbol"].upper(),
        "price": raw["current_price"],
        "volume": raw.get("total_volume"),
        "change_24h": raw.get("price_change_percentage_24h"),
        "change_1h": raw.get("price_change_percentage_1h_in_currency"),
        "change_7d": raw.get("price_change_percentage_7d_in_currency"),
        "ma20": ma20,
        "above_ma": above_ma,
        "four_h_change": four_h_change,
        "squeeze": squeeze,
        "relative_strength": rel_strength,
    }


def render_market_universe(top_assets: list[dict]) -> str:
    lines = ["1) Market Universe (Top 15 by 24h Volume)"]
    for asset in top_assets:
        lines.append(
            f"- {asset['symbol']} | Price {format_number(asset['price'], '$')} | "
            f"24h Vol {format_number(asset.get('volume'), '$')} | "
            f"24h Change {format_number(asset.get('change_24h'), suffix='%')}"
        )
    return "\n".join(lines)


def render_regime(btc_asset: dict | None, fear_greed: str | None, dominance_hint: str) -> str:
    btc_trend = "Trending" if btc_asset and btc_asset.get("above_ma") else "Ranging/Correcting"
    lines = ["\n2) Broad Market Regime & Sentiment"]
    price = format_number(btc_asset.get("price") if btc_asset else None, "$")
    change = format_number(btc_asset.get("change_24h") if btc_asset else None, suffix="%")
    lines.append(f"- BTC: {btc_trend} | Price {price} | 24h {change}")
    lines.append(f"- Sentiment (Fear & Greed): {fear_greed or 'n/a'}")
    lines.append(f"- BTC Dominance Flow: {dominance_hint}")
    return "\n".join(lines)


def render_filter_section(assets: list[dict], btc_change: float | None) -> str:
    lines = ["\n3) Individual Asset Screening (Structure/Volatility/Strength)"]
    for asset in assets:
        squeeze_label = "Yes" if asset.get("squeeze") else "No"
        trend_label = "Above MA20" if asset.get("above_ma") else "Below MA20"
        rs_label = "Outperforming BTC" if asset.get("relative_strength") else "Lagging BTC"
        lines.append(
            f"- {asset['symbol']}: {trend_label}, 4H {format_number(asset.get('four_h_change'), suffix='%')}, "
            f"Squeeze {squeeze_label}, {rs_label}"
        )
    return "\n".join(lines)


def render_candidates(candidates: list[dict], btc_change: float | None) -> str:
    lines = ["\n4) High-Conviction Weekend Candidates"]
    timestamp = _dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    for asset in candidates:
        price = asset["price"]
        bull_target = price * 1.05
        bear_invalidation = asset["ma20"] if asset["ma20"] else price * 0.97
        probability = min(90, 50 + int(asset.get("score", 0) * 10))
        narrative = []
        if asset.get("above_ma"):
            narrative.append("holding above MA20")
        if asset.get("squeeze"):
            narrative.append("volatility squeeze forming")
        if asset.get("relative_strength"):
            narrative.append("showing relative strength vs BTC")
        if abs(asset.get("change_24h") or 0) >= 5:
            narrative.append("momentum >5% last 24h")
        lines.append(
            f"- {asset['symbol']}/USD @ {format_number(price, '$')} (as of {timestamp})\n"
            f"  • Key Narrative: {', '.join(narrative) or 'solid liquidity setup'}\n"
            f"  • Pattern/Structure: 4H bias {'Bullish' if asset.get('four_h_change', 0) >= 0 else 'Neutral-Range'}\n"
            f"  • **Trigger Condition:** 4H close above {format_number(price * 1.01, '$')} with volume sustaining above prior 4H bar\n"
            f"  • Bull Case Target: {format_number(bull_target, '$')}\n"
            f"  • Bear/Invalidation: {format_number(bear_invalidation, '$')}\n"
            f"  • Probability Score: {probability}%"
        )
    return "\n".join(lines)


def render_risks() -> str:
    lines = [
        "\n5) Weekend Risk Factors & Summary",
        "- Trap zones: prior day highs/lows on BTC and ETH; watch liquidity hunts around round numbers.",
        "- Liquidity dries up on weekend: widen stops; size down.",
        "- News risk: exchange/ETF headlines can spike volatility without warning.",
    ]
    return "\n".join(lines)


def fetch_fear_greed() -> str | None:
    try:
        req = urllib.request.Request(
            "https://api.alternative.me/fng/",
            headers={"User-Agent": "weekend-scanner"},
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.load(resp)
        value = data["data"][0]["value"]
        classification = data["data"][0]["value_classification"]
        return f"{value} ({classification})"
    except Exception:
        return None


def build_report() -> str:
    snapshot = fetch_market_snapshot(count=20)
    top_15 = snapshot[:15]

    btc_row = next((a for a in snapshot if a["symbol"].lower() == "btc"), None)
    btc_change = btc_row.get("price_change_percentage_24h") if btc_row else None

    enriched = [build_asset_profile(asset, btc_change) for asset in top_15]
    btc_profile = next((a for a in enriched if a["symbol"] == "BTC"), enriched[0] if enriched else None)

    non_excluded = [
        asset
        for asset in enriched
        if asset["symbol"].lower() not in EXCLUSION_SYMBOLS
    ]

    dominance_hint = "Alts gaining traction" if any(
        (a.get("relative_strength") for a in non_excluded)
    ) else "BTC retaining dominance"

    fear_greed = fetch_fear_greed()

    candidates = select_high_conviction(non_excluded, btc_change)

    sections = [
        render_market_universe(enriched),
        render_regime(btc_profile, fear_greed, dominance_hint),
        render_filter_section(enriched, btc_change),
        render_candidates(candidates, btc_change),
        render_risks(),
    ]
    return "\n".join(sections)


def main() -> None:
    try:
        report = build_report()
    except RuntimeError as exc:
        sys.stderr.write(str(exc) + "\n")
        sys.exit(1)
    except Exception as exc:
        sys.stderr.write(f"Unexpected error: {exc}\n")
        sys.exit(1)

    print(report)


if __name__ == "__main__":
    main()
