# ideal-octo-fishstick

Real-time crypto weekend scanner that pulls the top 15 assets by 24h volume (CoinGecko), filters out stablecoins/wrapped assets for conviction picks, and prints a tactical 24-48h outlook.

## Usage

1. Ensure you have Python 3.11+ and internet access (required for live data).
2. Run the scanner from the repo root:

```bash
python scanner.py
```

If live market data cannot be fetched, the tool will stop immediately as required.
