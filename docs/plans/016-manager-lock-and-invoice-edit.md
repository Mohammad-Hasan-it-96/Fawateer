# Plan 016 — Manager Lock, Invoice Delete, and the Invoice-Edit Question

> **Status:** 🔬 **STUDY + PROPOSAL.** Source: `docs/v1-fixes-2.txt` #3 —
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

## Suggested order

1. **A** — delete button + honest confirmation (verify the ledger reversal first).
2. **B** — PIN guard behind `ManagerGuard`, applied to delete.
3. Ask the owner *why* they want edit; if it is the customer/payment case, scope
   a narrow action for it.
4. **C2** only if the answer justifies it. **C3 never.**

## Open questions for the owner

1. When you want to "edit an order", what is usually wrong — the price, the
   quantity, or the customer / cash-vs-credit?
2. Is it acceptable that fixing a mistake **deletes** the old invoice and makes a
   new one with a new number?
3. Besides deleting an order, what else should the password protect?
4. If someone forgets the password, what should happen?
