# Findings

Short, human-readable notes on what we've learned. Details and sources are in `AGENTS.md`.

## 🏁 Decision
- **We're doing S-Pankki's "Personal Economic Trainer"**: an AI coach that lets people chat with their own bank transactions.
- Prizes: 1st €2,000, 2nd €1,000, 3rd €500, as **Airbnb gift cards**. 53 signups.
- Why: a consumer product that's easy to demo on a phone, decent prizes, and a lot of real-world reach (S-mobiili is used weekly by 1 in 3 Finnish adults).

## 👥 How we work
- Everyone vibe codes across the whole repo. There's no frontend/backend split.
- Pull before you start, push small and often, and post one line in chat about what you're working on.
- Repo: https://github.com/aminecheikh/s-pankki-money-coach (renamed from `trading-agent-hackjunction-2026`).

## 🎯 How we get scored (each 20%)
- Teaching people about money (financial literacy)
- Originality of the AI
- A clear mobile UX
- Feasibility (could a bank actually ship this?)
- How easily it fits into the S-mobiili app

## 🧺 The idea they care about most: three baskets
- **Mandatory and regular:** rent, bills, subscriptions.
- **Mandatory and irregular:** a broken washing machine, car repair, dentist.
- **Everyday leaks:** coffees, snacks, takeaway.
- "Help people understand where their money really goes" is what they say will "go far with us".

## 💡 Our angle (draft)
- **Trustworthy numbers:** the AI never makes up figures. Real calculations do the maths, and the app shows how each number was worked out.
- The home screen shows **"safe to spend this week"**, with a buffer for surprise costs and an explanation of why.
- Charts are **generated from your question**, not a fixed dashboard (they want a "MyData" spirit).
- **"What if" sliders**, e.g. "cut dining out by 20%" → saving per year.
- A **"What kind of spender am I?"** profile.
- Stretch: compare with similar Finnish households (Statistics Finland), and a multi-bank view (PSD2).
- Make it **mobile-first** and styled like S-mobiili.

## 📊 Data
- **Get it:** run `./scripts/fetch_data.sh` (no Git LFS needed). It downloads into `data/`, which isn't committed.
- **3.6M transactions, 5,100 customers, 24 months** (Oct 2024 – Sep 2026), one account each.
- **Columns:** customer, date, category, amount (negative = money out), balance after, transaction type, merchant code, MCC code.
- **15 categories**, e.g. Housing, Utilities, Groceries, Restaurants, Transportation, Health, Home & Tech, Lifestyle, Travel, Entertainment, Salary, Invest.
- **Merchants are anonymous codes** (`MRC-RES-0087`), not names like "Starbucks".
- **Everyone has a salary,** usually paid on the 15th. Median about €3,175/month.
- **69% of customers drop below €0 at some point** → a strong case for "safe to spend".
- **781 young adults (18–30),** the group S-Bank cares about most.
- To spot "coffee" leaks, **use the amount, not the MCC code.** In this synthetic data, all restaurant types have the same typical amount. 18% of restaurant spends are under €8.
- **Customers 5001–5100 look special:** all the crazy one-off spends (> €10k) are theirs. Ask the mentors.
- **The three baskets map fairly well onto categories:** Housing and Utilities = regular bills, Health and big Home & Tech = irregular must-pays, Restaurants, Entertainment and Lifestyle = everyday leaks. (Draft, see `AGENTS.md`.)
- **Bonus data:** 200 mortgage applications (150 approved, 50 rejected, with reasons). A possible "am I ready to buy a home?" feature.
- **264 customers move most of their salary out** ("Salary Sweep"), probably to another bank. That fits the multi-bank (PSD2) bonus angle.
- **Gotchas:** the CSVs start with a BOM (read with `utf-8-sig`), and timestamps look like `03OCT24:09:04:04`, so use the `tx_date` column instead.
- **Build tip:** the file is too big for the app. Pre-process it into small per-customer data for a few demo personas.

## ❓ Open questions for mentors
- Are customers 5001–5100 an intentional outlier or persona group?
- Do they agree with our mapping of categories to the three baskets (e.g. is Groceries a "must" and Transportation a "leak")?
- What is "Salary Sweep": a transfer to another bank?
- Is there an S-mobiili design system or brand guide we can follow?
- Are there rules about which AI providers can touch bank data (e.g. EU hosting)?
- Finnish UI, English UI, or both?

## 🗂️ Challenges we compared (for the record)
| Challenge | Prizes | Signups | Why not |
|---|---|---|---|
| **S-Pankki: Economic Trainer** ✅ | €2,000 / €1,000 / €500 (gift cards) | 53 | **Chosen** |
| Valio: Trusted Trade Agents | €4,000 / €1,500 / €1,000 | 105 | Most crowded, and it's B2B back-office work that's harder to demo |
| Espoo: Rethinking Recruitment | €1,500 / €1,000 / €500 | 41 | Mostly concept and design work |
| Context.dev: Real-Time Web | €2,000 / €500 / swag | 36 | Basically 1st place or nothing |
| MariaDB: Wikipedia Through Time | €1,000 / €500 / €250 | 41 | Smaller prizes |
| AstraZeneca: Equal Care | €1,000 / €750 / €250 | 53 | Lowest prizes, little data |
| Aalto: Humanoid robot | €2,000 | 13 | No robotics person on the team |
