#!/usr/bin/env bash
# Download the Valio Aimo challenge datasets into data/.
# Requires VALIO_API_KEY (read from .env if present).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$ROOT/.env" ] && set -a && . "$ROOT/.env" && set +a

: "${VALIO_API_KEY:?Set VALIO_API_KEY in .env}"
BASE="${VALIO_API_BASE:-https://junction26.valioaimo.fi/api}"
OUT="$ROOT/data"
mkdir -p "$OUT"

fetch() {
  local endpoint="$1" file="$2"
  echo "-> $file"
  curl -fsSL -H "X-API-Key: $VALIO_API_KEY" -o "$OUT/$file" "$BASE/$endpoint"
}

fetch products/download             product_data.json
fetch delivery-reliability/download delivery_reliability.csv
fetch carbon-footprint/download     carbon_footprint.csv

ls -lh "$OUT"
