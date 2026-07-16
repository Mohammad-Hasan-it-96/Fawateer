# Plan 009 — Smart Business Assistant & Intelligent Alerts

> **Status:** ⏸️ **DEFERRED TO V2 — do not build for the 1.0 launch** (decided
> 2026-07-16, owner call: "not a basic requirement"; launch is ~1 week out).
> **Nothing is pulled forward.** This is a sequencing decision, not just a
> time-boxing one — see "Why waiting makes it better" below.
>
> **The brief was discussed, not designed.** The notes below are the output of
> that discussion so V2 restarts from a position, not a blank page. No code, no
> schema, no ARB keys exist for this plan.

---

## Deferral rationale (read this first in V2)

### 1. Plan 008 already ships the passive version of the top-3 alerts
The Reports/Dashboard tab **already** gives the owner: the **low-stock
mini-list** (= "low stock products" alert), the **top-debtors mini-list** (=
"customer owes you" alert), and **KPI delta arrows** (= "is today better than
yesterday"). 009 would convert those from **pull** to **push** — a real
improvement, but a polish increment on something that exists, not a missing
capability. That is what makes it deferrable.

### 2. Why waiting makes it *better* (the load-bearing argument)
009's entire value rests on **self-calibrating thresholds** — what counts as a
"large expense" or a "significant sales drop" *for this shop*. Building it
pre-launch means guessing those numbers with **zero real shops on the app**.
Guess wrong → ship noise → the owner learns the strip is usually wrong, stops
reading it, and **every future real alert dies with it**. Noise is the one
failure mode that permanently burns the feature.

Post-launch there is real transaction data to calibrate against. **009 is
strictly better built in V2.** Do not treat this as "we ran out of time."

### 3. Four things the brief asks for that this schema *cannot* support
Do not attempt these under launch pressure; they need real data-model work:

| Brief item | Blocker |
|---|---|
| **All Purchase Alerts** (reorder, supplier prices changed) | **No purchases/suppliers module exists.** `purchasePayment`/`supplierPayment` are reserved cashbox types with nothing writing to them. |
| "Product cost increased significantly" | `products.cost` is a single current value — **no cost history**. Needs a new table. |
| "Customer has overdue debt" | The ledger has **no due dates**. "Overdue" does not exist in this schema. Honest proxy = **debt aging** ("owes 40,000, no payment in 45 days"). |
| "Inventory turnover" / "inventory value dropped" | Stock is **never snapshotted over time** — no baseline to compare against. Same gap Plan 008 hit. |

---

## Design conclusions reached (carry these into V2)

**The reframe:** Plan 008's enemy was *clutter*; 009's enemy is **noise**. The
design question is not "which alerts can we compute" (we can compute nearly all
of them) — it is **"what earns the right to interrupt."** The brief's own
example proves the trap: *"Sales today are lower than yesterday"* fires ~half of
all days. It is noise wearing an alert's clothes.

**Thresholds must self-calibrate against the shop's own history.** "Large
expense" is meaningless as a constant — a grocery turning 500k/day and a phone
shop turning 50k/day cannot share a number. Use **median / percentiles over a
trailing window, not mean + standard deviation**: with a handful of
transactions, one outlier wrecks a mean-based threshold, and these shops have
handfuls.

**Priority is computed, not hardcoded per rule.** Each rule declares a base
severity, then **escalates on magnitude relative to that shop's scale**. Low
stock → medium; out of stock → high; out of stock **on a top-5 seller** →
critical. Negative cash balance is the one unconditional **critical**.

**Insights are derived, never stored.** Rules are pure functions over a
`BusinessSnapshot` built from the aggregates `DashboardDao` already computes.
Nothing persists → **no migration, no sync, no stale-alert cleanup**, and a rule
change ships as a code change rather than a data backfill.

**V1 of 009 can stay at the then-current schema version.** The only two pieces
of state needed — **snooze/dismiss** and (optionally) a **sales target** — both
fit the existing `AppSettings` key-value table.

**Snooze is core, not optional.** Without it, the alert the owner has
consciously decided to ignore ("yes, that stock is seasonal") sits there forever
and teaches them to ignore the whole strip. It is the cheapest anti-noise
mechanism available.

**AI compatibility falls out for free** (the brief's "design for future AI"
ask): make `BusinessSnapshot` **JSON-serializable**, define `InsightSource` as
`generate(snapshot) → List<Insight>`, and the rules engine is simply the first
source. A future AI source is a second implementation returning the same
`Insight` type — **the snapshot *is* the request body you would POST**. Zero
refactor.

**Localization seam to design up front:** the no-English-in-BLoC rule means
insights must be **typed** (`InsightType` + typed params), with the page
rendering `l10n.insightSlowMoving(name, days)`. AI-generated free text cannot
be — so `Insight` needs a `source` field (`rule` | `ai`) and a raw-text escape
hatch used **only** when `source == ai`. Better designed now than retrofitted.

**No background jobs.** Scheduled alert computation means WorkManager, battery,
and OEM task-killers — the single biggest complexity trap here, and the brief
does not need it. This is a POS; the owner opens it every day. Compute in the
**foreground** off Plan 008's existing `watchChanges()` ticker, **debounced** so
one sale does not recompute ten times. Also honors the brief's own "this is NOT
a notification system."

**Health score — the number is fake precision.** A weighted 0–100 is arbitrary,
and a non-technical owner's first question is "why 73?", which we cannot answer
convincingly. Recommendation: **compute** it (5 weighted pillars — sales trend,
profitability, cash runway, debt load, stock health) but **display a band and a
reason, not a number** ("Good" / "Needs attention", always naming the one or two
pillars dragging it down). Its value is **directional** (is it improving?),
never absolute.

**Placement (recommended, not ratified):** not a 6th tab (the shell is full at
five), not OS notifications. A **top-3 "needs attention" strip above the KPIs**
in the Dashboard view, "see all" → a full Assistant page with the health band and
grouped list, **plus a badge on the Reports nav icon when something critical is
live**. The badge is what makes it proactive — the owner sees the red dot without
opening anything, which is the brief's actual success criterion.

## Open decisions (unanswered — deferred with the plan)

1. **Scope** — Lean (~8 rules: out-of-stock, low-stock, dead stock,
   negative/low cash, large expense, debt aging, significant sales drop, one
   positive/record + health band + strip + Assistant page) vs Fuller (adds sales
   targets and a first-open-of-day digest sheet).
2. **Health score** — band + reason only, or the 0–100 number visible?
3. **Placement** — strip-on-dashboard + badge, or a third segment in the Reports
   toggle (Assistant | Dashboard | Sales)?
4. **The unbuildable four** — document and defer (recommended), or bring a
   cost-history table into scope?

---

# Original brief (unchanged, below)

Act as the CTO, Product Architect, Product Manager, and Business Intelligence Expert.

Design a Smart Business Assistant for an offline-first Flutter POS application.

This feature is NOT a notification system.

It is an intelligent assistant that continuously analyzes the business and provides useful recommendations to the shop owner.

The target users are:

* Small shops
* Grocery stores
* Mobile shops
* Clothing stores
* Cosmetic stores

Most users have little accounting knowledge.

The assistant should explain business insights in very simple language.

---

# Main Goal

The application should proactively tell the owner:

* What requires attention.
* What should be done today.
* Which problems may occur soon.
* Which opportunities exist.

The owner should not need to search through reports.

---

# Alert Categories

Design a complete alert system.

Examples include:

## Inventory Alerts

* Low stock products.
* Out of stock products.
* Products that haven't sold for a long time.
* Products selling unusually fast.
* Inventory value dropped significantly.

Recommend additional useful alerts.

---

## Sales Alerts

Examples:

* Sales today are lower than yesterday.
* Sales this week are lower than last week.
* Highest sales day this month.
* New sales record.
* Sales target achieved.
* Sales target missed.

Suggest additional useful business alerts.

---

## Cashbox Alerts

Examples:

* Large expense detected.
* Cash balance is unusually low.
* Cash withdrawals exceed daily average.
* Negative cash balance.
* Missing opening balance.

Recommend additional financial alerts.

---

## Customer Alerts

Examples:

* Customer has overdue debt.
* Customer has not made a payment recently.
* Customer is becoming a loyal customer.
* Customer reached a high purchase volume.

Recommend additional customer insights.

---

## Purchase Alerts

Examples:

* Frequently purchased products should be reordered.
* Product cost increased significantly.
* Supplier prices changed.

Recommend additional purchasing insights.

---

## Business Health Score

Design a simple Business Health Score.

The score should summarize the overall condition of the business.

Example factors:

* Sales trend.
* Cash balance.
* Outstanding debts.
* Inventory status.
* Stock turnover.

Recommend the best calculation method.

The result must be understandable by non-technical users.

---

## Smart Recommendations

Instead of only showing alerts,

the assistant should also provide recommendations.

Examples:

"Consider reordering Product X."

"Customer Ahmed should be contacted regarding overdue payment."

"Today's expenses are much higher than normal."

"Product Y has not sold in 60 days."

Generate many practical recommendation ideas.

---

## Priority Levels

Every alert should have a priority.

Examples:

Critical

High

Medium

Low

Explain how priority should be calculated.

---

## Dashboard Integration

Study where these alerts should appear.

Possibilities include:

* Home Dashboard
* Notification Center
* Business Assistant Screen
* Daily Summary

Recommend the best user experience.

---

## Technical Analysis

Analyze:

* How alerts should be generated.
* Should calculations happen instantly or periodically?
* How to avoid slowing down the application.
* How to cache calculated insights.
* How to work completely offline.

Recommend the cleanest architecture.

---

## Future AI Compatibility

Design this module so future versions can easily integrate AI features.

Examples:

* AI business recommendations.
* AI inventory forecasting.
* AI demand prediction.
* AI purchase suggestions.
* AI sales trend analysis.

Do NOT implement AI now.

Simply design the architecture so future AI integration requires minimal changes.

---

## Success Criteria

The assistant should make the owner feel that the application is actively helping them run their business instead of simply storing invoices.

The feature must remain extremely simple, fast, offline-first, and suitable for users with little technical knowledge.

Do NOT write any code.

Produce a complete Product Design Plan with architecture, UX, business rules, roadmap, and implementation phases.
