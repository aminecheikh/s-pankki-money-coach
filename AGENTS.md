# S-Pankki Personal Economic Trainer (Junction 2026)

Shared context file for the team and for AI coding assistants. **Codex** reads this file directly, and **Claude Code** loads it through `CLAUDE.md`. Edit only this file. Read it before you start working, and update it when we learn something new or make a decision.

> **Rule for every AI assistant (Claude, Codex, …): keep `FINDINGS.md` updated.** Every time we learn something new (data quirks, mentor answers, design decisions), add a short, plain-language bullet to the right section of `FINDINGS.md`. That file is the quick human-readable summary. This file (`AGENTS.md`) holds the details. Fix or remove bullets that turn out to be wrong.

## 1. The challenge in one paragraph

S-Bank (S-Pankki) is Finland's 4th-largest bank: 3.5M customers, and its **S-mobiili** app is used weekly by one in three Finnish adults. They want an **AI personal economic trainer**: people **chat with their own transaction data** and get insight, coaching and "what if" answers rather than plain statement lists. Questions range from simple (*"How much did I spend on taxis last month?"*) to deep (*"What kind of spender am I?"*, *"What is safe for me to spend this week?"*, *"How much could I save if I reduced dining out by 20%?"*). To their knowledge, no Finnish bank does this yet.

**Output they want:** a mobile app, or a **web app that can be embedded in a mobile app**. Their customers are on mobile.

## 2. What gets scored (5 × 20%)

| Criterion | What it means for us |
|---|---|
| **Impact on financial literacy (pedagogy)** | Teach, don't just report. Explain concepts in plain language and build better habits. |
| **Originality of AI integration** | More than a chat box over a chart. Show the AI doing something only AI can. |
| **Clarity of mobile UX** | Phone-first, simple, fast. Judges should get it in seconds. |
| **Feasibility** | Realistic for a bank to ship: privacy, cost, correctness. |
| **Potential to integrate into S-mobiili** | Look and feel like it belongs in their app, and be embeddable. |

**Prizes:** 1st €2,000, 2nd €1,000, 3rd €500, all as **Airbnb gift cards**. 53 signups.

## 3. What they explicitly asked for

- **The three-baskets teaching model** (the core idea, so build around it). All spending falls into:
  1. **Mandatory and regular**, e.g. rent, utilities, subscriptions
  2. **Mandatory and irregular**, e.g. a broken washing machine, car repairs, dentist
  3. **Everyday spending that slips through your fingers**, e.g. coffees, snacks, takeaway
  "Solutions that help people understand where their money really goes will go far with us."
- **MyData spirit:** let users **explore their own data freely**, not fixed charts the bank picked.
- **Conversational AI** that explains financial concepts in plain language.
- **"What if" simulations.**
- **Safe-to-spend and safe-to-save** guidance.
- **Benchmarks against open population data** (e.g. Statistics Finland). Encouraged but not required.
- **Optional bonus: multi-bank view.** Under PSD2, the customer lets the bank fetch account data from other banks. How would the coach use the full financial picture?
- **Target group to keep in mind:** young adults ("improving financial literacy, especially among young adults").

## 4. Data

**Source:** https://github.com/hackjunction/Junction-2026-S-pankki. Run `./scripts/fetch_data.sh` to download everything into `data/` (gitignored). It needs no Git LFS and verifies the checksum of the big file. All numbers below were profiled with DuckDB on 2026-11-14.

### Files
| File | Size | Contents |
|---|---|---|
| `tx_junction_transactions.csv` | 346 MB, **3,626,755 rows** | `customer_id, bank_account_id, tx_date, tx_timestamp, category, tx_amount_eur, balance_after_eur, transaction_type, merchant_id, mcc_code` |
| `tx_customers_junction.csv` | 5,100 rows | `customer_id, customer_postal_code, customer_age` |
| `mtg_negotiation_history.csv` | 3,452 events | Mortgage application event log per `mortgage_customer_id` (C0004 …) |
| `mtg_tx_customer_link_and_final_mtg_infio.csv` | 200 rows | Links `mortgage_customer_id` → `customer_id`, plus the final decision, loan, equity, LTV and required income |

### Gotchas
- **Every CSV starts with a UTF-8 BOM.** Read with `utf-8-sig` (Python), or the first column name gets a stray character.
- `tx_timestamp` uses a SAS-style format: `03OCT24:09:04:04`. Use `tx_date` (ISO) for dates.
- `mcc_code` and `merchant_id` must be read as **strings**: they're empty for non-purchases, and postal codes have leading zeros.
- **Merchants are anonymised codes** (`MRC-GRO-0035`), not names. 515 merchants; the middle part encodes the category (`GRO`, `RES`, `TRN`, `ENT`, `HEA`, `HMT`, `LIF`, `TRV`).
- Amounts: **negative = money out, positive = money in.** `balance_after_eur` is the running account balance.
- Synthetic quirk: **amounts don't differ by MCC within a category.** E.g. restaurants (5812), bars (5813) and fast food (5814) all have a median of €23.5. To spot "coffee-sized" leaks, use **amount** (18% of restaurant transactions are under €8), not MCC.
- **Customers `CUST05001`–`CUST05100` look special.** All 20 one-off spends over €10k are in this group (e.g. a €30,935 Home & Tech purchase). Probably a planted outlier or persona group; ask the mentors.

### Shape of the data
- **5,100 customers, 1 account each**, covering **2024-10-01 → 2026-09-30** (24 months). Median 700 transactions per customer (range 148–1,543).
- Ages 18–90 (median 44), with **781 young adults aged 18–30**, the target group S-Bank mentioned. 290 postal codes.
- **Everyone has a salary**, paid monthly, usually on the 15th. Median ~€3,175/month (10th–90th percentile: €1,876–€5,264).
- **3,526 of 5,100 customers (69%) drop below €0 at some point.** The median customer's lowest balance is −€126. That's a strong hook for "safe to spend".

### Categories → our three baskets (draft mapping, to be confirmed)
| Category | Rows | Median € | Behaviour in data | Basket (draft) |
|---|---|---|---|---|
| Housing | 113k | 1,037 | Exactly 1×/month, amount stable (CV 0.03) | 1. Mandatory regular |
| Utilities | 343k | 50 | ~3×/month, amount varies | 1. Mandatory regular |
| Groceries | 869k | 64 | Frequent | 1. Mandatory regular (a necessity, but its size can be influenced) |
| Transportation | 627k | 41 | Frequent: transit, taxi, fuel, parking | 1. or 3., depending on type (taxi = leak?) |
| Health | 152k | 54 | Irregular, high variance (CV 0.79) | 2. Mandatory irregular |
| Home & Tech | 115k | 111 | Irregular, big spikes (604 purchases > €2k) | 2. Mandatory irregular (large) or 3. (gadgets) |
| Restaurants | 759k | 23.5 | Very frequent, small | 3. Everyday leaks |
| Entertainment | 303k | 35 | Frequent | 3. Everyday leaks |
| Lifestyle | 111k | 103 | Shopping (clothes, sports, books, …) | 3. Everyday leaks |
| Travel | 65k | 130 | Occasional, large | 3. Discretionary (or its own "goals" bucket) |
| Invest Deposit / Withdraw | 36k / 0.5k | 296 | 1,500 customers invest monthly | Savings, not spending |
| Salary / Other Income | 122k / 6k | 3,362 | Monthly income | Income |
| Salary Sweep | 6k | 3,877 | 264 customers move most of their salary out | Transfer, probably to another bank → PSD2 multi-bank angle |

### Extra: mortgage data (optional angle)
- 200 mortgage applications linked to transaction customers: **150 approved, 50 rejected.** Rejection reasons: `insufficient_income`, `insufficient_equity`, `insufficient_collateral`, `existing_debt`.
- Possible feature: a "**am I ready to buy a home?**" coach that uses real spending to show the gap to the `required_monthly_income` and equity. A stretch goal only.

### Benchmarks
- Statistics Finland publishes household consumption statistics. Its PxWeb API is at `pxdata.stat.fi` (not yet verified). We can also benchmark **within the dataset**: same age group or postal area, which is cheap and works offline.

### Practical implication for the build
- 346 MB is too big to ship to a phone or load per request. **Pre-process once** (DuckDB or Python) into compact per-customer data, e.g. a SQLite/DuckDB file or JSON for a few **demo personas** (a young adult with leaks, someone who often overdraws, someone saving for a home, …).

## 5. Our strategy (draft, decide as a team)

How to win against ~50 others who will mostly build "a chat box that answers and draws a chart":

1. **Numbers you can trust.** The challenge says "*trusted* financial coach". The LLM **never computes or invents numbers itself**. It calls deterministic tools (SQL or pandas functions) that do the maths, and the app shows a "how I calculated this" view. A bank will care a lot about this, and it's our main angle for feasibility and originality.
2. **Three baskets at the centre.** Automatically sort every transaction into one of the three baskets (rules first, LLM only for unclear merchants). Let the user correct a classification, so they stay in control in the MyData spirit.
3. **"Safe to spend this week" as the home screen.** Income − upcoming fixed bills − a buffer for surprises = what's safe to spend. Explain *why* the buffer exists; that's the teaching hook.
4. **Charts generated from the question.** The answer comes with a small chart built for that question, not a fixed dashboard.
5. **"What if" sliders.** "Cut dining out by 20%" shows the saving per month and per year and what it adds up to (e.g. a trip).
6. **"What kind of spender am I?"** A friendly profile built from basket shares and patterns, with one or two concrete habit tips.
7. **Compare with similar households** using Statistics Finland data (stretch goal).
8. **S-mobiili look and feel,** as an embeddable mobile web app.

Possible architecture (to be decided):
```
Mobile web app (chat + cards + charts)
        │
   API backend ── LLM with tool calling (answers, explanations, "what if" setup)
        │            └─ tools: query_spending, basket_breakdown, safe_to_spend, simulate_change, compare_benchmark
        └── transaction store + basket classifier + calculation functions (deterministic, tested)
```

## 6. Open questions for mentors
- Are customers `CUST05001`–`CUST05100` (all the > €10k spikes) an intentional outlier or persona group?
- Do they agree with our category → three-baskets mapping (§4)? Especially Groceries, Transportation, and Home & Tech.
- What exactly is "Salary Sweep": a transfer to the customer's account at another bank?
- Is there an S-mobiili design system or brand guidelines we can follow for the look and feel?
- How should "safe to spend" treat irregular mandatory costs? Is there a buffer method they prefer?
- Are there limits on which LLM providers we can use for bank data (e.g. EU hosting) for the feasibility story?
- Do they want Finnish UI, English UI, or both?

## 7. Mentors
- Carl-Edvard (Calle) Holmberg, Chief Innovation Officer (main contact)
- Representative from S-Bank IT / AI development
- Data scientist (transaction data expert)
- 1–2 business representatives who own the customer problem

## 8. Working in this repo

**How the team works:** everyone vibe codes with AI assistants (Claude Code, Codex) across the whole codebase, with no fixed ownership of frontend vs. backend. That means:
- **One simple stack and one language where possible,** so any person or assistant can work anywhere.
- **Pull before you start, and push small and often.** Several people and agents edit the same files, and big diffs collide.
- **Say in the team chat what you're working on** (one line) to avoid two people building the same thing.
- **Assistants: read `AGENTS.md` and `FINDINGS.md` first, and check `git log` for recent changes** before making big edits. Don't rewrite code someone else just wrote without a reason.
- **Never leave `main` broken.** Run the app and the tests before pushing.

- **Secrets:** API keys go in `.env` (gitignored), never in code or commits. **This repo is public on GitHub.**
- **Data:** run `./scripts/fetch_data.sh` to download the dataset into `data/` (gitignored). Never commit it.
- **Commits:** conventional commits (`feat:`, `fix:`, `docs:`, …). Use a branch per feature (`feat/...`) and keep `main` working.
- **Correctness:** every function that produces a number (totals, baskets, safe-to-spend, simulations) gets tests with known inputs. The LLM must not do arithmetic.
- **One source of truth:** put all agent instructions in `AGENTS.md`. `CLAUDE.md` only imports it, so don't add content there.
- **Keep this file current,** and add a short bullet to `FINDINGS.md` for every new learning.

## 9. Decisions log
| Date | Decision | Why |
|---|---|---|
| 2026-11-14 | Repo created | — |
| 2026-11-14 | First picked Valio Aimo "Trusted Trade Agents"; **switched to S-Pankki "Personal Economic Trainer"** | The team prefers a consumer product: it's easy to demo, judges understand it at a glance, and the prizes are reasonable (€2,000 / €1,000 / €500). The full challenge comparison is in `FINDINGS.md`. The Valio research stays in git history (commit `804ec0e`). |
