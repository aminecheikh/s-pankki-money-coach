# Valio Aimo Agent Ordering Interface (Junction 2026)

Shared context file for the team and for AI coding assistants. **Codex** reads this file directly, and **Claude Code** loads it through `CLAUDE.md`. Edit only this file. Read it before you start working, and update it when we learn something new about the data or APIs, or when we make a decision.

> **Rule for every AI assistant (Claude, Codex, …): keep `FINDINGS.md` updated.** Every time we learn something new (data quirks, API behaviour, mentor answers, design decisions), add a short, plain-language bullet to the right section of `FINDINGS.md`. That file is the quick human-readable summary. This file (`AGENTS.md`) holds the details. Fix or remove bullets that turn out to be wrong.

## 1. The challenge in one paragraph

Valio Aimo is a Finnish food-service wholesaler: 20k professional kitchens, about 25k products, 700 suppliers. They want to know how an **external purchasing agent** (for example a hotel chain's AI buyer) could safely find products, compare offers, and place orders against their systems. The agent works within its authority, and anything outside that authority goes to a human for approval. We are **not** building a marketplace or a chatbot. We are defining the **interface and operating model**: what an agent can see, what it can decide, what needs a human, and how every step is recorded. It should be built on open, verifiable standards.

Canonical example: *"I need 1,000 litres of lactose-free milk by Monday. Find an option that meets our requirements based on price and availability."* The system returns structured products, prices and availability. The agent then either orders within its authority or escalates for human approval.

## 2. What gets scored

**Core (must have)**
1. **Product, price & availability lookup**: a structured way for an agent to search and retrieve.
2. **Inquiry → order**: a defined flow from request to commitment, at **fixed prices** (no negotiation).
3. **Permissions & human approval**: what the agent may decide alone vs. what needs a human sign-off.

**Optional (nice to have, not required to win)**
- Delivery time / reliability and sustainability comparison (certificates and labels; carbon footprint is a stretch goal)
- Substitution and exception handling (partial availability, "good / better / best" ranking)
- Traceability: a human-readable audit trail of what the agent did and why

**Themes Valio flagged as interesting:** trust protocol (how an agent can trust stock, price and origin claims without a manual check), guardrails model, response logic for partial availability, and an audit trail that is useful to **both** buyer and Valio Aimo.

**Example scenarios they suggested:** need → recipe → order; last-minute event; supplier stock-out with a recipe-compatible substitute; proactive selling agent; allergen-safe substitution (schools and hospitals); standing-order drift detection.

**Framing to keep in mind:** "how a European wholesaler can be safely and openly readable by autonomous agents, before that interface gets defined by someone else's platform." Open standards (OpenAPI, MCP, JSON Schema, verifiable credentials, signed responses) fit that framing better than a proprietary black box.

## 3. What Valio actually gives us

Everything is synthetic. Portal: https://junction26.valioaimo.fi/. The event password is on the Junction platform challenge page.

| Resource | What | Notes |
|---|---|---|
| `POST /api/price` | Price per product for a date | 1–1000 products per call |
| `POST /api/availability` | Can it be delivered, how much, earliest date | 1–1000 products per call |
| `GET /api/ping` | Health check | |
| `GET /api/products/download` | Product catalog JSON (~87 MB, 17,546 products) | Static, fetch once |
| `GET /api/delivery-reliability/download` | CSV `productId,deliveryReliability` (0–1) | 4,425 products |
| `GET /api/carbon-footprint/download` | CSV `productId,AVG kg CO2-eq/kg` | ~11k products, a **category average** rather than a per-product value |
| `/docs`, `/redoc`, `/openapi.json` | API docs (behind the portal login) | Copies in the repo: `docs/valio_openapi.json`, `docs/product_data_schema.json` |

**Auth:** every `/api/*` call needs the header `X-API-Key: $VALIO_API_KEY`. The key is on the Junction platform, so ask in the team chat. Put it in `.env` (gitignored). **Never commit it. This repo is on GitHub.**

### ⚠️ There is NO order, cart or approval API

Valio only provides **read** APIs (price and availability). Order placement, permissions, approvals, audit log, and the agent-facing interface itself are **ours to design and mock**. That gap *is* the challenge.

### API rules from the docs
- **Don't bulk-poll price or availability for the whole catalog.** In real life these are customer-specific and change constantly. Undisclosed rate limits apply. Narrow candidates down with the **static product data first**, then query the APIs only for the shortlist.
- The `customer` field is required but ignored. Any string works (we use `"123"`).
- `requestedDate` is `YYYY-MM-DD`.

## 4. Data: facts and gotchas (verified 2026-11-14)

### Product catalog (`valio_aimo_junction26_product_data.json`)
Top-level array. The key fields:
- `id`: product code. Use it in API calls and to join with the CSVs.
- `vendorName` (648 vendors), `category` (349 codes, **names not provided**), `countryOfOrigin` (ISO alpha-2, lowercase).
- `salesUnit` / `baseUnit` / `units[]`: the packaging hierarchy. `units[].sizeInBaseUnits` converts between levels. Example: `KI` = 5 × `ST`, `PAL` = 160 × `ST`.
- `allowedLotSize`: order quantity must be a multiple of this, in sales units. It's 0.01 for about 96% of products.
- `substitutions[]`: Valio's own substitute mapping. **Only 189 products have one**, so we'll need our own substitution logic for anything serious.
- `deposits[]`: returnable packaging charged with the product (506 products).
- `temperatureCondition`: integer code (1–9). Meanings are not provided.
- `synkkaData`: manufacturer data from GS1 Synkka. Quality varies a lot, since fresh produce often has little data.
  - `names[]`: fi always present, en almost always, sv mostly. **Search on fi + en.**
  - `classifications[]` groups (by `name`):
    - `allergen`: `unit` ∈ `CONTAINS` / `MAY_CONTAIN` / `UNDECLARED`. (The schema says CONTAINS/FREE_FROM, but the data says otherwise.)
    - `nonAllergen`: `unit` = `FREE_FROM`
    - `nutritionalClaim`: e.g. `FREE_FROM_LACTOSE` (4,178), `FREE_FROM_GLUTEN`, `VEGAN`, `VEGETARIAN`, `LOW_LACTOSE`, …
    - `packagingMarkedLabel`: the **sustainability / certificate labels**: `EU_ORGANIC_FARMING`, `SVANEN`, `RAINFOREST_ALLIANCE`, `MARINE_STEWARDSHIP_COUNCIL_LABEL`, `FAIR_TRADE_MARK`, `AQUACULTURE_STEWARDSHIP_COUNCIL`, `EU_ECO_LABEL`, `KRAV_MARK`, Finnish origin marks (`GOODS_FROM_FINLAND_BLUE_SWAN`, `MADE_IN_FINLAND_FLAG_WITH_KEY`, `FINNISH_HEART_SYMBOL`), plus temperature markers.
    - also `nutritionFact`, `gda`, `composition`, `mineral`, `vitamin`, `packaging`
  - Allergen codes appear to follow the GS1 AllergenTypeCode list (our reading, unconfirmed): `AM` milk, `ML` lactose, `AW` gluten cereals, `UW` wheat, `GB` barley, `NR` rye, `GO` oats, `AE` egg, `AY` soy, `AN` tree nuts, `AP` peanuts, `AS` sesame, `AF` fish, `AC` crustaceans, `UM` molluscs, `BM` mustard, `BC` celery, `NL` lupin, `AU` sulphites.
  - `ingredients[]`, `keyIngredients[]`, `nutritionalContent[]`, `fishingReports[]`, `producers[]`, `vatCode` (STANDARD 25.5% / MEDIUM 13.5% / LOW 10%).

**Unit codes** are technical codes without translations. Our best guesses: `ST` piece, `KI` carton/case, `PAK` pack, `PRK` tub/jar, `RAS` box, `BOT` bottle, `KG` kilo, `PAL` pallet, `KRS` pallet layer, `SK` sack, `CS` case, `KAN` canister. **Volume and weight per unit come from `synkkaData.unitConversions` or the comparison price, not from the unit code.**

### Price API: how to read it
- Prices are **per one sales unit** (`quantity` is always 1.0).
- `comparisonPrice` + `comparisonUnit` (`L` or `KG` only) is the **apples-to-apples** number. Use it to compare a 1 L carton with a 10 L box.
- `catalogPrice.value` excludes tax and `valueWithTax` includes it. `listPrice` is the pre-discount price. `netPriceFound=true` means a customer-specific price applied.
- `error=true` means no price was found.

### Availability API: how to read it
- `logisticModel`: `Stock` (Valio's own warehouse, real quantities) or `Terminal` (shipped from the supplier, so quantity is unknown and always `999999`).
- `availableAmount`: `9999999999` effectively means unlimited stock. Real numbers show up too, e.g. `51`. `0` means not available.
- `scheduleLines` is empty when the product can't be delivered on any date. Otherwise it has exactly 1 line.
- `availableDate` is the **earliest** date and can differ from `requestedDate`. In our tests it **did not change** when we asked for an earlier or later date.
- `closingTime` is the order cut-off for that delivery. ⚠️ Some Terminal products returned a `closingTime` already in the past while still showing an `availableDate` in the future. Treat this as a mock quirk and confirm with the mentors.
- `salesBlock=true` means the product can't be ordered right now.

### Worked example: lactose-free milk (real API responses, 2026-11-14, requestedDate 2026-11-16)

| id | product | model | unit price | €/L |
|---|---|---|---|---|
| 464119 | Valio skimmed milk 1 l lactose free UHT (sold per KI) | Terminal | 13.32 | **1.33** |
| 463335 | Valio Eila 3% milk drink 1 l lactose free | Stock | 1.40 | 1.40 |
| 463038 | Valio Eila semi-skimmed 10 l novobox lactose free (KI) | Terminal | 31.31 | 1.57 |
| 464073 | Valio whole milk 1 l lactose free UHT | Stock | 1.64 | 1.64 |
| 462775 | Arla milkdrink 1 L lactose free fat free UHT | Stock (only 51) | 2.57 | 2.57 |

Search: Finnish name contains `laktoositon` + `maito`, **or** `nutritionalClaim` has `FREE_FROM_LACTOSE`. This returns 68 name hits. The quantity maths (1,000 L → number of sales units → respecting `allowedLotSize`) is something our layer must handle.

## 5. What we build (draft, decide as a team)

The likely shape is a gateway that sits between external agents and Valio's (mock) systems:

```
External buyer agent ──(MCP tools / OpenAPI)──▶  OUR GATEWAY  ──▶ Valio mock price/availability APIs
                                                   │  catalog index (static data, searchable)
                                                   │  quote → order flow (fixed price, expiry)
                                                   │  policy engine (spend limits, substitution rules, allergens)
                                                   │  approval queue (human UI)
                                                   └  audit log (human-readable + machine-verifiable)
```

Candidate building blocks (not yet decided):
- **Catalog search**: local index over the product JSON (fi/en names, claims, allergens, labels, category), a pre-filter before calling the APIs.
- **Quote / offer object**: binds product, quantity, unit price, delivery date, cut-off and validity window. It's signed, so the agent can verify it hasn't been tampered with (the "trust protocol" theme).
- **Order flow**: `search → quote → (policy check) → place_order | request_approval → confirm`.
- **Policy / mandate**: per buyer-agent rules such as max spend per order, allowed categories, required claims (e.g. lactose-free), allergen exclusions, whether substitution is allowed, and when to escalate.
- **Approval UI**: a human sees the pending order, the agent's reasoning, the alternatives considered, and approve/reject.
- **Audit trail**: an append-only log of every agent action with the reasoning, readable by both buyer and Valio.
- **Ranking**: price (€/L or €/kg), delivery date vs. need-by, delivery reliability, labels and certificates, carbon, and stock vs. terminal risk.

## 6. Open questions for mentors
- Is the past `closingTime` on Terminal products intentional?
- Will webshop test accounts matter for the demo? ("shared separately")
- Do they prefer MCP, OpenAPI, or both for the agent interface?
- Is there an official mapping for category codes, unit codes, or `temperatureCondition`?
- What spend thresholds or approval roles are realistic for a hotel chain or a hospital kitchen?

## 7. Mentors
- Marketplace/Commercial: Hanna Forsström, Pirjo Kaartinen
- Online Sales: Minni Ruhtinas
- IT/Tech integrations & data governance: Tommi Nurmi-Aro, Ville Takanen, Riku Tapper

## 8. Working in this repo

- **Setup:** `cp .env.example .env`, paste the API key into `.env`, then run `./scripts/fetch_data.sh` to download the datasets into `data/` (gitignored, about 87 MB).
- **Secrets:** the API key and portal password are never committed. Read the key from the `VALIO_API_KEY` environment variable.
- **Data files** live in `data/` and are not committed. Re-fetch them with the script.
- **Commits:** conventional commits (`feat:`, `fix:`, `docs:`, …). Use a branch per feature (`feat/...`) and keep `main` working.
- **Be gentle with the API:** cache responses during development, and batch up to 1000 ids per call.
- **Keep this file current.** When you learn a data quirk or make a design decision, add it here, and add a short bullet to `FINDINGS.md`.
- **One source of truth:** put all agent instructions in `AGENTS.md`. `CLAUDE.md` only imports it, so don't add content there.

## 9. Decisions log
| Date | Decision | Why |
|---|---|---|
| 2026-11-14 | Repo created; context captured in this file | — |
| 2026-11-14 | **Challenge chosen: Valio Aimo "Trusted Trade Agents"** (over MariaDB "Wikipedia Through Time") | Prizes €4,000 / €1,500 / €1,000 vs. €1,000 / €500 / €250. About €62 per signup vs. €43, even with 105 vs. 41 signups. Open-ended design is easier to stand out in, and we already have the data mapped. |
