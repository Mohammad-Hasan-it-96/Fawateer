# Plan 019 — V1 Field-Feedback Fixes, Round 3

> **Status:** 🚧 **IN PROGRESS.** ✅ **#1 shipped.**
> Source: the shop, after months of real trading. Successor to Plan 011
> (round 1) and Plan 013 (round 2), same spirit — **what the counter actually
> trips over**, not new features.
>
> Round 2 is complete except Plan 015 Case A (shared barcodes), which is
> waiting on the branch-merge order with `feat/multi-device-sync`, not on work.

---

## #1 — A credit sale on the account does not say what was sold ✅ SHIPPED

> **The shop's words:** reviewing a customer's account shows a credit sale of,
> say, 5,000 — but not *which products* made up that 5,000.

**This was a reporting hole, not a data hole.** `ledger_entries.invoiceId` has
linked a `charge` back to its invoice since the ledger was built (v6→v7); the
link was simply never surfaced. So: **no schema change, no new query, no new
BLoC.**

What was actually missing is worse than inconvenience. A debt is the one number
in this app a *customer* argues with, and the shopkeeper had no way to answer.
"You owe 5,000" against "for what?" is not a conversation a shop can win from a
list of totals.

### What shipped

- A credit row in the account **expands in place** to show its lines — product,
  quantity × unit price, and line total.
- Manual charges and payments have no invoice behind them and are **left
  exactly as they were**, with no chevron. An affordance that leads nowhere is
  worse than none.
- The panel carries a **reprint** button. This is the moment it is wanted: the
  customer is disputing the amount and the answer is the original receipt.
  Reprint runs from the account, without navigating to the Reports tab.

### Decisions worth keeping

- **It reuses the app-wide `HistoryBloc` item cache**, not a new loader in
  `LedgerBloc`. One cache means an invoice opened here is already loaded on the
  detail page, and a deleted sale drops out of both at once (`_onDelete`
  evicts it). A second cache would be a second thing to invalidate — and the
  one that got missed would render a sale that no longer exists.
- **Reprint uses the ledger entry's own `amount` as the total**, never a re-sum
  of the lines. The sale path books the charge as *exactly* the invoice total,
  which is already net of line and cart discounts; re-summing would print a
  pre-discount figure and disagree with the paper the customer is holding.
- **Expanding is per-row and stateful in the row**, so several sales can be open
  at once — comparing two months of a customer's purchases is a real thing to
  want, and forcing one-at-a-time would fight it.

Two properties of the shared cache became load-bearing here and are pinned by
`test/invoice_items_cache_test.dart`: a **failed** load is recorded but never
cached (otherwise the row's retry tap could never succeed), and a **cached**
invoice is not re-fetched (the row opens and closes freely while a customer
argues).

### Deliberately not done

- **The printed/shared statement still shows totals only.** Adding every line of
  every sale would turn a one-page WhatsApp reminder into something nobody
  reads, and the statement's job is "you owe this much", not "here is your
  year". Worth revisiting only if the shop asks — and then as an option on the
  share menu, not a change to the default.

---

## Deferred from this round

- **[018 — In-app user guide](018-in-app-user-guide.md)** — agreed, postponed
  until there is a second customer who cannot phone the developer.
