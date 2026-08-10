# Plan 016 — Manager Lock, Invoice Delete, and the Invoice-Edit Question

> **Status:** 🚧 **IN PROGRESS.** ✅ **A (delete a sale)** and ✅ **C-a (change
> customer / cash↔credit)** are built. Remaining: **B** (the PIN guard).
>
> **C-a landed as designed — it touches no snapshot column.** `SalesDao.
> setInvoicePayment` clears whatever money record the sale posted and writes
> exactly one row for the payment type now being asked for, in one transaction.
> Three details were decided while building it:
>
> - **It re-derives instead of diffing.** Every direction — cash→credit,
>   credit→cash, customer A→B — is the same code path, and re-applying the same
>   choice is a no-op rather than a second charge.
> - **The new row is dated at the sale, not at today.** This corrects something
>   that already happened; dating it now would leave the sale's own day short
>   *and* make today's cash report wrong. A customer actually paying a debt is
>   a ledger `payment`, and the sheet says so.
> - **`InvoiceListItem` gained `customerId`.** The audit query already joined
>   the customer for their name, but a correction has to pre-select *that row*,
>   and two customers can share a name.
>
> The customer picker (search + inline quick-add) was **extracted out of
> checkout** into `ledger/presentation/widgets/customer_picker.dart` and is now
> shared: booking a credit sale and correcting one ask the same question, and a
> shop with eighty customers needs the same search box either way.
>
> Pinned by `integration_test/invoice_payment_change_test.dart` (11 tests,
> verified against the host's SQLite; still owed a device run) and
> `test/history_payment_change_test.dart` (8).
>

> **The "verify the ledger reversal first" warning below was right, and it was
> worse than written.** `SalesDao.deleteInvoice` reversed the cashbox entry and
> released serialized units, but it did **neither** of these:
>
> - it never removed the credit sale's `charge`, so the customer kept owing
>   money for a sale that no longer existed — the balance is derived from those
>   rows, so the error was permanent and invisible (the DAO carried an explicit
>   "do not wire this to a UI as-is" warning for exactly this);
> - it never gave **ordinary stock** back. Only serialized SKUs were restored.
>   Every deleted sale silently walked the shop's counts down by one basket.
>
> Both are fixed inside the one transaction, and pinned by
> `integration_test/invoice_delete_test.dart` (7 tests, verified against the
> host's SQLite; still owed a device run).
>
> **Known asymmetry, accepted:** the sale's deduction floors at zero because
> overselling is allowed, so a line that sold 5 with 1 on hand only took 1 —
> and the restore gives back 5. That over-credits in the rare oversell case;
> restoring nothing under-credits in *every* case.

> **Original study.** Source: `docs/v1-fixes-2.txt` #3 —
> *"add delete order + edit order, only from the main device, or with a password
> the main device chooses."*
>
> Three separate things are packed into that one line, and they have very
> different sizes and risks. They are separated here on purpose.

---

## The three things

| | Ask | Today | Risk |
|---|---|---|---|
| **A** | Delete an invoice | repository method exists, **no UI calls it** | low |
| **B** | Gate it (manager only / password) | no role and no password exist here | medium |
| **C** | **Edit** an invoice | **impossible by design** | **high** |

---

## A — Delete an invoice (small, and half-built)

`InvoiceRepository.deleteInvoice` and `SalesDao.deleteInvoice` already exist and
already do the hard part correctly, in one transaction:

- delete the invoice and its `sales_items` (no orphans),
- **reverse the cashbox entry** it posted (`deleteByRelatedId`),
- **release serialized units** back to stock (Plan 012),
- (on the sync branch) tombstone rows and stock movements instead of hard delete.

So this is a **UI-only** change: an action on `InvoiceDetailPage`, a confirmation
dialog that says plainly what will be undone, and a message on success.

**The confirmation must list the consequences**, because they are not obvious:
the cash entry disappears from the drawer, the stock comes back, and if it was a
credit sale the customer's debt drops. A shopkeeper who deletes an invoice
expecting only the paper to vanish will think the app corrupted their books.

⚠️ **Credit sales:** check whether `deleteInvoice` also reverses the ledger
`charge` entry. The cashbox reversal is documented; the ledger side must be
verified before shipping this button, or deleting a credit invoice leaves the
customer owing money for a sale that no longer exists.

---

## B — The gate (manager only, or a password)

**"Main device" (الجهاز الرئيسي) does not exist on this branch.** Owner/member
roles are part of multi-device sync (`feat/multi-device-sync`, not merged). On
`refactor/architecture-hardening` every install is simply "the app".

So the two halves of the ask land in different places:

- **Password → buildable now.** A 4–6 digit PIN, set in Settings, stored in
  `AppSettings` (**hashed, not plain**). Asked for before a protected action.
- **"Main device only" → free later.** When sync merges, the same guard reads
  `SyncSession.isOwner` and a member device is simply refused. No new mechanism.

**Recommendation: build the PIN now, with the check behind one small service**
(e.g. `ManagerGuard.require(context, action)`), so adding the role check later is
one line inside it and not a change at every call site.

Design notes:
- **Hash the PIN** (`sha256` + a per-install salt, same shape as
  `DeviceIdentityService`). A plain PIN in `app_settings` also travels inside
  every Google Drive backup and every sync snapshot.
- **Not a login.** No session, no user list. It is a speed bump on destructive
  actions, and it should be described that way to the shop, or they will expect
  it to protect more than it does.
- **Forgot-PIN is a real support case.** Decide now: reset via the operator
  (device id + contact, like activation), or accept that no reset exists. Do not
  discover this later from an angry shop.
- **What else should it protect?** Delete product, edit price, restore backup,
  unlink a device. Ask the owner — the list should be theirs, and it should be
  short. Every protected action is a wall the *owner* also walks into all day.

---

## C — Editing an invoice (the critical one)

### Why it is not just "another screen"

**Sales invoices are immutable in this app. That is a design rule, not a gap.**
The whole system leans on it:

1. `salesItems` **snapshots** `price`, `cost`, `fxRate`, `priceOriginal`,
   `discount`, `saleType`, `attributesSnapshot`, `serialSnapshot` at sale time —
   precisely so an old receipt reprints exactly as it was printed.
2. A cash sale posted a **cashbox** entry; a credit sale posted a ledger
   **charge**. Both link back by `relatedId` / `invoiceId`.
3. The sale **deducted stock** (and, on the sync branch, wrote a stock movement
   whose id is derived from the sale line's uuid).
4. Reports and profit read all of the above.
5. **Plan 002 (multi-device) explicitly depends on it**: *"Invoices are
   immutable, so this rarely arises: creates never collide, deletes use
   tombstones."* Editable invoices reintroduce exactly the conflict class that
   plan avoided.

So "edit an invoice" is really: *rewrite a financial record and every derived
record that came from it, consistently, possibly on two devices at once.*

### Option C1 — do not edit. Delete and re-enter. **(recommended)**

The cashier deletes the wrong invoice (gated, per A + B) and rings it again.

- ✅ No new rules. Every reversal path already exists and is tested.
- ✅ Honest history: a mistake and its correction both leave a trace.
- ✅ Safe under multi-device.
- ❌ More taps for a big invoice.
- ❌ The invoice number changes. Ask whether the shop cares (they might, if a
  customer is holding the printed copy).

### Option C2 — edit as "reverse + replace", one invoice number kept

Under the hood: delete the old and create the new inside one transaction,
carrying the same visible number. History shows one invoice; the app does the
delete/re-create dance for the user.

- ✅ Feels like editing to the shopkeeper.
- ✅ Reuses the reversal code that already exists.
- ❌ Non-trivial: needs a real transaction across invoice, items, cashbox,
   ledger, stock and units.
- ❌ Under sync it is a delete plus a create with the same identity — needs
  careful thought about what the other device sees.

### Option C3 — true in-place edit of lines

- ❌ Every snapshot column above must be re-decided. Reprint fidelity is gone.
- ❌ Cashbox/ledger/stock must be diffed, not reversed.
- ❌ Under LWW sync, two devices editing one invoice produce a mixed row.
- **Not recommended in any form.**

### Recommendation

**C1 now.** It costs one dialog and delivers the actual need ("fix a mistake").
Revisit C2 only if the shop reports that re-entering big invoices is a real daily
cost — and never C3.

The question to settle with the owner is *why* they want edit. Almost always it
is one of:
- **wrong price on one line** → better solved by Plan 013 #4 (edit the product
  from POS) plus delete-and-re-enter;
- **wrong quantity** → same;
- **wrong customer / cash-vs-credit** → this is the one case where re-entering is
  genuinely painful, and it may deserve a narrow "change payment type" action
  instead of full editing.

That last one may be the whole real request. Worth asking before building
anything.

---

---

# Decision (after the owner's answer)

> **Asked:** when you want to edit an order, what is usually wrong?
> **Answered:** **the quantity**, or **the customer / cash-vs-credit**.

Those two are not the same size, and the split is the whole decision.

## C-a — customer / cash-vs-credit → **build it, as a narrow action** ✅

This one is genuinely painful to fix by re-entering (the cashier must retype
every line), and — importantly — **it does not touch a single snapshot column**.

What actually changes:

| | Cash → Credit | Credit → Cash |
|---|---|---|
| `sales_items` | untouched | untouched |
| `totalAmount`, discounts | untouched | untouched |
| Reprint | **identical** | **identical** |
| Stock / units | untouched | untouched |
| Cashbox | reverse the `cashSale` inflow | post a `cashSale` inflow |
| Ledger | post a `charge` for the customer | reverse the `charge` |

So the money *record* is corrected while the *sale* stays exactly what it was.
No history is rewritten, no receipt changes, and the invoice number survives —
which is what the customer is holding.

**Build it as one transaction** in `SalesDao` / `InvoiceRepository`, reusing the
pieces that already exist (`CashboxDao.deleteByRelatedId`, the ledger `charge`
companion the sale path already builds). Changing the *customer* on an existing
credit sale is the same shape: reverse one charge, post another.

⚠️ **Under multi-device this is an invoice-row edit**, so it is last-write-wins
like any other row. Two devices changing payment type on the same invoice is
vanishingly rare and LWW is an acceptable answer — but the linked cashbox/ledger
rows are *separate* rows, so a badly-timed merge could leave both. Worth a note in
the sync tables registry when the branches meet.

## C-b — wrong quantity → **delete and re-enter** ❌ (do not edit)

Changing a quantity is a different animal, because it changes the **total**, and
the total is the root of everything downstream:

- the cashbox inflow amount, or the customer's debt,
- the stock deducted (and the stock-movement row on the sync branch),
- profit in every report,
- **the printed receipt no longer matches the paper the customer holds.**

All the reversal code for a full delete already exists and is tested. A partial
edit path would be new, and it would be the one path that can silently
de-synchronise the books.

**In practice this is fine:** a wrong quantity is almost always caught within
seconds, at the counter, before the queue moves. Deleting and re-ringing is
seconds too.

**If it turns out to be a daily cost**, the honest feature is **not** editing —
it is a **partial return**: a new, separate event that returns N units, gives
money back, and restores stock. That keeps history true (the sale happened, then
part came back) and `StockMovementReason.saleReturn` is already reserved for it
on the sync branch. Revisit only with real evidence.

## Final shape

| Ask | Answer |
|---|---|
| Delete an invoice | ✅ build (UI only — the reversal exists) |
| Change customer / cash↔credit | ✅ build (narrow, safe, no snapshot touched) |
| Change quantity or price | ❌ delete + re-enter |
| Free-form line editing | ❌ never |

## Order of work

1. ✅ **A** — delete button + honest confirmation. **Done.** The ledger reversal
   was indeed missing (and so was ordinary stock restore); both are fixed. The
   confirmation lists the consequences per invoice — stock always, then either
   the cash drawer or the named customer's debt — because a shopkeeper who
   expects only the paper to vanish finds the drawer short at closing time and
   concludes the app lost their money.
2. ✅ **C-a** — change payment type / customer. **Done.** One transaction that
   swaps the cash entry for a customer debt or back; the invoice, its lines,
   the total, the stock and the reprint are all untouched, which is exactly why
   this action exists instead of delete-and-re-enter. The sheet leads with that
   promise, because "will this change the receipt my customer is holding?" is
   the first thing a shopkeeper asks.
3. **B** — the PIN guard, applied to both. See the PIN-reset note below.

## PIN reset — see Plan 017

The owner raised **email accounts** as the way to reset a forgotten PIN. That is a
much larger question than a PIN (it changes how the whole app identifies a shop),
so it is its own study: **[017 — Accounts and PIN Reset](017-accounts-and-pin-reset.md)**.
The short version: **do not build accounts for this**; use the operator channel
that activation already uses.
