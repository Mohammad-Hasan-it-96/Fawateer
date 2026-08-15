# Two-phone field test (Plan 002)

The one thing no test on this machine can prove. `integration_test/` runs two
real databases through the real engine, but against a **fake server in the same
process**. This runs two real phones against **production**.

Backend state as of 2026-08-15: allowance is **3**, `PATCH /sync/devices/{seat}`
is live, `name` is returned on enroll/business/devices. Nothing is blocked.

**Install the same signed release APK on both phones** — not a debug build. The
thing you ship is the thing you test.

Below, **A** is the first phone (becomes the main phone) and **B** is the second.

---

## Before you start

- Both phones need a working subscription. Sync refuses a device with no live
  licence (`SUBSCRIPTION_REQUIRED`) — that is deliberate, not a bug.
- Put a few real products, one customer and one debt on **A** first. An empty
  shop makes step 3 look like it worked when it did nothing.
- Note roughly how many products A has. You will compare that number on B.

---

## 1 — A becomes the main phone

Settings → **الأجهزة والمزامنة** → enable.

- [ ] The screen changes to "main phone"
- [ ] The list shows **1 of 3 phones used**
- [ ] The one row is named after the handset (e.g. "Infinix X6833B"), not blank

> **If it says 1 of 1** the allowance did not apply — stop and tell
> evotech-core. Everything below would then fail for the wrong reason.

## 2 — A makes a join code

Tap **add a phone**.

- [ ] A progress line appears and moves (syncing → snapshot → uploading). It is
      not instant — it is uploading your whole shop
- [ ] A QR appears, **and** the same code in readable text below it
- [ ] The text code reads left-to-right and is not scrambled by the Arabic layout

## 3 — B joins (the most important step)

On B: Settings → **الأجهزة والمزامنة** → join → scan A's QR.

- [ ] B says it is preparing, then asks you to **restart the app**
- [ ] After restart, B shows **the whole shop** — the same products, the same
      customer, the same debt, the same past invoices

> **This is the step most likely to fail, and the failure is quiet.** If B comes
> up with an empty shop while A still looks fine, the snapshot did not arrive.
> Do not carry on — that is the bug worth reporting in full.

Now on A, reopen the sync screen:

- [ ] It shows **2 of 3 phones used**
- [ ] Two rows, each named after its handset, each with a "last used" line
- [ ] A's own row shows the "this phone" badge and no remove button

## 4 — Names

On A, tap B's row and rename it (try Arabic, e.g. `الكاشير`).

- [ ] The row spins briefly, then shows the new name
- [ ] Type 60 letters — the field stops you at 40
- [ ] Rename it to blank — the row goes back to "linked phone", not to a blank line
- [ ] Rename it again and press Cancel — the old name stays

## 5 — A sale moves between the phones

Sell something on **A**. Keep **B** open on the Reports tab.

- [ ] Within a few seconds B shows the sale
- [ ] **No notification banner pops up on B.** A sale must not ring like a message
- [ ] B's stock for that product went down

Now sell on **B** and watch **A**. Same two checks.

> If it takes up to 5 minutes instead of seconds, the sale still arrived — that
> is the backstop timer doing its job, and it means the instant wake-up
> (the "doorbell") did not reach the phone. Worth reporting, not a data problem.

## 6 — Products and customers, both directions

- [ ] Add a product on A → it appears on B
- [ ] Change its price on B → the new price appears on A
- [ ] **Delete it on A → it disappears on B and stays gone.** Close and reopen
      both apps and check again. A deleted product coming back is the single
      worst bug this design can have
- [ ] Sell on credit to a customer on A → the debt appears on that customer's
      account on B, with the products listed under it

## 7 — Selling the same thing at the same time

Pick a product with a small stock (say 3). Turn **both phones' internet off**.

- [ ] Sell 2 on A and 2 on B
- [ ] Turn the internet back on for both
- [ ] Both sales survive — the shop sold 4, and neither sale vanished
- [ ] The Reports tab shows a **red stock card** at the top saying the count went
      below zero

> This is working as designed, not a failure. Both sales were kept — which is
> exactly why the app can tell you the shelf count is now wrong. The fix is to
> count the shelf, and there is deliberately no button that makes the number
> disappear.

## 8 — Working with no internet

On B: turn off data, make 3 sales, then turn data back on.

- [ ] The 3 sales appear on A
- [ ] B never refused a sale while offline

## 9 — Shared barcodes (Plan 015, also new in this version)

- [ ] Open a product that has a barcode → **add another price**
- [ ] Scan that barcode at the till → a sheet asks which price
- [ ] Each of the two rows keeps its own stock count

## 10 — Removing a phone

On A, remove B.

- [ ] The row disappears and the count goes back to **1 of 3**
- [ ] On B, tap "sync now" → B says it was removed and offers the join screen
      again
- [ ] **B still has all the shop's data.** Removing a phone stops it syncing; it
      does not erase it. Check this — the wording promises it

Then join B again with a fresh code, to be sure the way back in works.

---

## What is NOT tested here, and why

- **The 60-day cursor limit.** Getting a `CURSOR_TOO_OLD` needs a phone whose
  position is older than the server's pruning window. A shop enrolled today has
  nothing pruned behind it, so the error cannot fire. evotech-core suggested
  minting an old cursor for it; that is a server-side exercise, and the client
  path is already pinned by `test/sync_cursor_too_old_test.dart`.
- **A third phone.** The allowance is 3 and only two phones are available. The
  "add a phone" button being disabled at the cap is covered by a widget test;
  what a real third seat does to the count is not.
- **A phone that is closed.** Sync is foreground-only by design. A till that is
  shut does not sync until it is opened. That is a stated limitation, not a
  defect — do not report it as one.
