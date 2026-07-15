# Plan 004 — Historical Invoice Price Recalculation

> **Status:** Design plan (no code). Prepared by CTO/Architect + accounting review.
> **Decision (locked with the owner): ❌ ABSOLUTELY NOT — do not build this, now
> or as a near-term feature.** Historical invoices and debts are immutable.
> Recalculation is rejected outright.
> **Related:** extends and defends Plan 003's locked rule — invoices book in SP,
> `sales_items` snapshots `price`/`cost`/`fxRate`, debt is SP fixed at sale-time
> rate. See `docs/plans/003-dual-currency.md`.

---

## ⭐ Decision up front

> **A completed sale is a finished fact. Nothing — not a product price change, not
> an exchange-rate change — ever alters a historical invoice or debt.**

The question "should historical unpaid invoices change when price/rate changes?"
is answered **no** on every trigger. The immutability + per-line snapshotting
already implemented in Plan 003 is the correct design; this plan confirms and
locks it rather than adding a recalculation feature.

The real business pain hiding inside the request (currency risk on unpaid credit)
is genuine, but it is **not** solved by recalculating invoices — it's solved, if
ever, by a *different, non-destructive* model (USD-denominated debt chosen at sale
time), which stays deferred (§7).

---

## 1. Split the question — three different things, opposite answers

The brief bundles triggers that deserve different treatment:

1. **Product price change** → should past invoices change? **No, never.**
2. **Exchange-rate change** → should past (USD-priced) invoices/debts change?
   **No, never.**
3. *(Hidden, the real driver)* **Should an unpaid debt be held in USD** so
   currency risk sits with the buyer, not the shop? **Legitimate — but that is
   not "recalculation," and it stays out of V1.**

Conflating #3 with recalculation is the trap this plan exists to avoid.

## 2. Product price change → never recalculates anything

A completed sale is a **contract at an agreed price**. Changing a product's price
is a statement about *future* sales; it says nothing about a transaction that
already happened.

- **Accounting-forbidden:** rewrites realized revenue. Daily totals, the audit
  center, customer statements, and reprinted receipts would all silently change —
  nothing reconciles.
- **Universally not done:** no shop reprices last week's sales because today's
  price went up.
- **Trust bomb:** "my bill went up *after* I bought it" ends the relationship.

Already correct in the app: `sales_items` snapshots `price`/`cost` at sale time.
**Locked: product price is forward-only; zero recalculation, paid or unpaid.**

## 3. Exchange-rate change → never recalculates a historical invoice

Same principle. A USD-priced sale is converted to SP and **snapshots its
`fxRate`** (Plan 003); that invoice is now a booked **SP** fact. Re-running it at a
new rate mutates an immutable record and detonates the identical
audit/reconciliation/trust problems as §2. The fxRate snapshot exists precisely to
make retroactive revaluation *impossible* — don't undo it.

## 4. Business / accounting analysis

- **Real business practice:** In dollarized, high-inflation economies (Syria,
  Lebanon, Venezuela, Argentina) it's common to *price* durable goods in USD and
  to *hold debts* in USD. But the shop's **books and cash are local currency**,
  and **no one retroactively reprices a booked sale.** The practice that exists is
  "the debt is denominated in USD," fixed **at sale**, not "old invoices get
  re-run."
- **Accounting correctness:** A booked sale is realized revenue — immutable. A
  USD-denominated receivable is a foreign-currency monetary asset; settling it
  later correctly produces an **FX gain/loss** between booking and payment. Full
  FX-gain/loss accounting is real weight for a small shop.
- **Customer expectations:** Two parties. The **owner** wants protection from
  currency loss. The **debtor** who bought a "$100" item usually accepts owing
  $100 — *if that was the deal at purchase*. A debtor who believed they owed a
  fixed SP amount would (rightly) dispute a silent increase. So the debt's unit of
  account must be **agreed at sale time**, never toggled retroactively.
- **Technical complexity:**
  - Price-change recalc — low code effort, **catastrophic correctness**. Reject.
  - Exchange-rate recalc of invoices — mutating immutable records; breaks
    history/audit/summary/reprints. **High risk.** Reject.
  - USD-denominated debt (revalue only at payment) — moderate; needs debt currency
    + original amount on `ledger_entries`, payment-day conversion, and an FX
    gain/loss home in the cashbox. Defensible but weighty → deferred.

## 5. Risks (why recalculation is dangerous, not just unnecessary)

| Risk | Impact |
|---|---|
| Mutating a booked invoice/debt | Audit integrity lost; totals & statements no longer reconcile; **legal/trust exposure** |
| Reprints change after the fact | The paper the customer holds no longer matches the system |
| Silent balance changes | Customer disputes ("my debt grew!"); trust destroyed |
| Summary/report drift | Historical daily/period figures shift retroactively — books become unauditable |
| "It's just unpaid ones" carve-out | Still mutates a booked sale; still breaks reconciliation; a false sense of safety |

## 6. Alternatives considered

1. **Recalculate all invoices on price/rate change.** ❌ Rewrites realized
   revenue; universally wrong. Rejected.
2. **Recalculate only *unpaid* invoices.** ❌ Still mutates a booked sale and its
   revenue/summary; "unpaid" is not a license to rewrite history. Rejected.
3. **Explicit adjustment entry** (a *new*, visible, reversible ledger line that
   tops up an existing SP debt for currency loss — never an edit to the original
   charge). ⚠️ Non-destructive and audit-safe, but invites disputes and
   complicates the derived balance. **Discouraged for V1**; noted only as the one
   legitimate escape hatch if ever pressed.
4. **✅ Chosen: no recalculation at all.** History is immutable. Currency risk, if
   it ever must be addressed, is handled by denominating the debt in USD *at sale
   time* (§7) — not by touching past records.

## 7. Final recommendation

1. **Reject recalculation as a feature — now and as a near-term item.** No product-
   price or exchange-rate change ever alters a historical invoice or debt.
2. **Product price is forward-only, always.** No knob, no exception.
3. **Confirm Plan 003's immutability** (SP booking + `price`/`cost`/`fxRate`
   snapshots) as the permanent design.
4. **The genuine currency-risk need is met — only if real paying demand
   appears — by opt-in USD-denominated debt chosen at sale time**, never by
   recalculation. That is Plan 003's already-reserved additive V2 path
   (`ledger_entries` gains a currency + original-USD amount; each repayment
   converts at its **own** date; the FX difference posts to the cashbox). History
   is still never mutated — each payment is a new transaction.
5. **If ever forced to "top up" an SP debt for currency loss**, the *only*
   permitted shape is an **explicit new adjustment entry** (visible + reversible),
   never an edit to the original charge — and even this is discouraged for V1.

**Bottom line:** history is sacred. The correct lever for currency risk is *what
currency a debt is denominated in at sale time* — not *re-running old invoices*.
Plan 004's feature, as described, must not be built.

## 8. Roadmap

**Now — do nothing (correct by construction).**
- No code. The immutability this plan defends already ships in Plan 003.
- Guardrail to preserve: never add an "edit invoice" or "recalculate" action; keep
  `sales_items` snapshots and the ledger append-only.

**Later — only on real paying demand (not scheduled):**
- Opt-in **USD-denominated debt** (Plan 003's deferred V2): debt currency +
  original amount on `ledger_entries`, payment-day conversion, FX gain/loss to
  cashbox. Additive; never mutates history. This — not recalculation — is the
  future answer to currency risk.

---

### Open decisions for sign-off
1. **Recalculation feature** — ✅ **RESOLVED: rejected. Do not build (now or
   near-term).** History is immutable.
2. **Product-price mutability of past sales** — ✅ **RESOLVED: forward-only,
   never retroactive.**
3. **Currency risk on credit** — deferred to a possible V2 **USD-denominated
   debt** (opt-in at sale), not recalculation. Build only on demand.
