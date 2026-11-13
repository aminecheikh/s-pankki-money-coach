#!/usr/bin/env bash
# Download the S-Pankki Junction 2026 dataset into data/ (gitignored).
# No Git LFS needed: files come straight from GitHub's raw/media endpoints.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/data"
SRC_RAW="https://raw.githubusercontent.com/hackjunction/Junction-2026-S-pankki/main"
SRC_LFS="https://media.githubusercontent.com/media/hackjunction/Junction-2026-S-pankki/main"
TX_SHA256="49b3265d8e44e751de305a074dcffcda732bb79aa1e07b46fcca774ce76f1e63"

mkdir -p "$OUT"

for f in README.md tx_customers_junction.csv mtg_negotiation_history.csv mtg_tx_customer_link_and_final_mtg_infio.csv; do
  echo "-> $f"
  curl -fsSL -o "$OUT/$f" "$SRC_RAW/$f"
done

TX="$OUT/tx_junction_transactions.csv"
if [ -f "$TX" ] && [ "$(shasum -a 256 "$TX" | cut -d' ' -f1)" = "$TX_SHA256" ]; then
  echo "-> tx_junction_transactions.csv already downloaded and verified"
else
  echo "-> tx_junction_transactions.csv (~346 MB)"
  curl -fL --progress-bar -o "$TX" "$SRC_LFS/tx_junction_transactions.csv"
  [ "$(shasum -a 256 "$TX" | cut -d' ' -f1)" = "$TX_SHA256" ] || { echo "Checksum mismatch for $TX" >&2; exit 1; }
  echo "   checksum OK"
fi

ls -lh "$OUT"
