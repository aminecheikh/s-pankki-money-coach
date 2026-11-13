# Findings

Short, human-readable notes on what we've learned. Newest section first within each heading. Details and sources are in `CLAUDE.md`.

## 🚨 Big picture
- Valio gives us **only read APIs**: price and availability. There is **no order, cart or approval API**.
- So the order flow, permissions, human approval and audit log are **ours to design and mock**. That gap is the actual challenge.
- Scored core: (1) search for products, prices and availability, (2) inquiry → order at fixed prices, (3) what the agent may do alone vs. what needs a human.
- Optional extras: delivery reliability and sustainability comparison, substitutions, an audit trail of what the agent did and why.

## 🔌 APIs
- Every `/api/*` call needs the header `X-API-Key`. The key goes in `.env`. **Never commit it, because the repo is public.**
- `POST /api/price` and `POST /api/availability` take 1–1000 product ids per call.
- The `customer` field is required but ignored. Any value works.
- **Don't fetch prices for the whole catalog.** There are hidden rate limits. Filter with the local product data first, then call the APIs for the shortlist only.
- The API spec (`/openapi.json`) is behind the portal login. A copy is in `docs/valio_openapi.json`.

## 💶 Prices
- Prices are **per one sales unit** (one carton, one box, …).
- Use `comparisonPrice` (per **L** or **KG**) to compare packs of different sizes.
- `catalogPrice` = what we pay. `listPrice` = the price before discount. `netPriceFound` = a customer-specific price applied.
- `error: true` = no price found.

## 📦 Availability
- **Stock** products are in Valio's own warehouse and have real quantities. Some are effectively unlimited (`9999999999`), others limited (e.g. `51`).
- **Terminal** products ship from the supplier and the quantity is unknown (always `999999`). They're a riskier choice.
- Empty `scheduleLines` = can't be delivered at all.
- `availableDate` = the earliest possible delivery date. It doesn't change with the date we ask for.
- `closingTime` = the order cut-off.
- ⚠️ Some Terminal products show a cut-off **in the past** but still offer a future delivery date. This looks like a mock bug; ask the mentors.

## 🥛 Product data (17,546 products)
- It's a static file. Download it once with `./scripts/fetch_data.sh`.
- Names are always in Finnish and almost always in English. Search both (Finnish example: `laktoositon` = lactose-free).
- Diet claims include `FREE_FROM_LACTOSE` (4,178 products), `FREE_FROM_GLUTEN`, `VEGAN`, `VEGETARIAN`, `LOW_LACTOSE`.
- Allergens are marked **CONTAINS**, **MAY_CONTAIN**, **UNDECLARED** or **FREE_FROM**. This is good for the allergen-safe scenario.
- Sustainability labels include EU Organic, Svanen, Rainforest Alliance, MSC, ASC, Fair Trade, EU Ecolabel, KRAV, and Finnish origin marks.
- Valio's own substitute mapping covers **only 189 products**, so we need our own substitution logic.
- `allowedLotSize`: the order quantity must be a multiple of it.
- Category codes, unit codes and temperature codes come **without names**.

## 🌱 Extra datasets
- **Delivery reliability** is a score from 0 to 1 for 4,425 products. 291 of them score below 0.9.
- **Carbon footprint** is in kg CO2-eq per kg. It's a **category average** rather than a per-product measurement.

## 🧪 Worked example: 1,000 L lactose-free milk by Monday
- 68 matching products in the catalog.
- The cheapest is €1.33/L (Valio skimmed milk 1 L, Terminal).
- The cheapest from Valio's own stock is €1.40/L (Valio Eila 3%).
- An Arla option is €2.57/L with only 51 in stock.

## ❓ Open questions for mentors
- Is the past cut-off time on Terminal products intentional?
- Do they prefer MCP, OpenAPI, or both for the agent interface?
- Are there names for the category, unit and temperature codes?
- What spend limits and approval roles are realistic for a hotel chain or a hospital?
- Will the webshop test accounts matter for the demo?
