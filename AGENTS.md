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

- **A large synthetic transaction dataset modelled on the structure of real S-Bank data.**
- ⚠️ **We don't have it yet.** The challenge page says "You may find the data through here", but the link didn't come through in the copy-paste. **Get the link from the Junction platform challenge page** and record the location and format here.
- Once we have it, document: file format and size, columns, date range, number of customers, how categories and merchants are represented, and quirks.
- Open data for benchmarks: Statistics Finland publishes household consumption statistics. Its PxWeb API is at `pxdata.stat.fi` (not yet verified for our needs).

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
- Where's the dataset, and what exactly is in it (categories, merchant names, income transactions, multiple accounts)?
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
- **Secrets:** API keys go in `.env` (gitignored), never in code or commits. **This repo is public on GitHub.**
- **Data:** the dataset goes in `data/` (gitignored). Don't commit it.
- **Commits:** conventional commits (`feat:`, `fix:`, `docs:`, …). Use a branch per feature (`feat/...`) and keep `main` working.
- **Correctness:** every function that produces a number (totals, baskets, safe-to-spend, simulations) gets tests with known inputs. The LLM must not do arithmetic.
- **One source of truth:** put all agent instructions in `AGENTS.md`. `CLAUDE.md` only imports it, so don't add content there.
- **Keep this file current,** and add a short bullet to `FINDINGS.md` for every new learning.

## 9. Decisions log
| Date | Decision | Why |
|---|---|---|
| 2026-11-14 | Repo created | — |
| 2026-11-14 | First picked Valio Aimo "Trusted Trade Agents"; **switched to S-Pankki "Personal Economic Trainer"** | The team prefers a consumer product: it's easy to demo, judges understand it at a glance, and the prizes are reasonable (€2,000 / €1,000 / €500). The full challenge comparison is in `FINDINGS.md`. The Valio research stays in git history (commit `804ec0e`). |
