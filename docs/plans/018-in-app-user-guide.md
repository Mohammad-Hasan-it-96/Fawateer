# Plan 018 — In-App User Guide

> **Status:** 📋 **AGREED, POSTPONED.** Raised by the owner after using the app
> for months: *"we built an easy app, but the features increase day after day, so
> I think we need notes."* The diagnosis is right. Deferred because the app has
> exactly **one user, who can phone the developer** — the guide's value starts on
> the day there is a second shop that cannot.
>
> Nothing here is blocked. Pick it up when a second customer is close.

---

## The real problem is discovery, not explanation

Features a new shop cannot find on their own, counted on the current build:

custom product fields · categories · sell-by-weight · USD pricing · line and
cart discounts · the cashbox · credit sales · Drive backup · printing product
labels · **multi-select by long-press** · duplicate a product · delete a sale ·
change a sale's payment type · the manager lock · low-stock alerts · the
inverted-barcode toggle · strict inventory.

**Sixteen.** And the shape of the problem matters: nobody asks *"how do I
duplicate a product?"* — they do not know it is possible. Once they know it
exists, the button is obvious.

So a page that answers **"how"** helps only people who already know **"what"**.
The guide has to sell the existence of features, not just their steps.

Multi-select is the sharpest example: long-press is invisible to anyone who has
never tried it, which is why an app-bar button was added beside it during
Plan 013. That instinct — *do not rely on the user discovering a gesture* — is
the whole plan in miniature.

## Two failure modes to design against

**1. Nobody opens Help.** A shopkeeper at a counter does not browse a manual. A
long page nobody reads costs a week and teaches no one.

**2. It goes stale, silently.** Features ship weekly. A guide describing last
month's flow is **worse than nothing** — it teaches wrong steps and generates
the support calls it was written to prevent.

This project has already produced failure mode 2 once: `deploy/fawateer.json`
sat at `latest_version: 1.0.0` while the app was `1.0.1`, so the in-app update
prompt could never fire, and **nothing reported it**. Any second place holding
the truth drifts. The mitigations below are the price of having one.

## Proposed shape — three layers, in value order

**1. `دليل الاستخدام` in Settings, organised by job, not by feature.**
Not *"Categories"* but *"كيف أبيع بالدين"*, *"كيف أعرف نواقصي"*, *"كيف أحمي
فواتيري"*. A shopkeeper thinks in jobs; the feature names are ours, not theirs.
Each entry short, and naming the path (`الإعدادات ← حقول المنتجات`).

**2. A `؟` button on the four screens that hide the most** — product fields, the
serialized-units toggle, the cashbox, the manager lock — opening *that* section.
**This is the layer that actually gets read.** Help at the moment of confusion
beats a manual by a wide margin.

**3. `ما الجديد` — reuse `update_notes`.** The release notes already exist in the
remote config and already render in the update dialog. Showing them in Settings
answers "what can this app do that it couldn't last month?" with **no second
source of truth to go stale**.

## Rules that keep it honest

- **The guide entry ships in the same commit as the feature.** Write it into
  `CLAUDE.md` so it is a rule, not an intention.
- **Describe where things live, not click-by-click steps.** Paths survive a
  redesign; step lists do not.
- **In the app, in ARB — not a web page.** This is an offline-first POS; a shop
  with no signal must still be able to read it. ARB is also where translation
  already lives.

## Known cost

Every line is written **twice**, Arabic and English. This is the first content in
the app where the English is pure cost — nobody runs this app in English, and
the locale is pinned to `ar` in `main.dart`. Write both anyway; the rule exists
so a future language switch is not a rewrite.

## Not decided

- Whether the guide should be searchable. Probably not at ~14 entries.
- Whether a first-run tour is worth it on top. Leaning **no**: tours are skipped,
  and the shop's first session is spent entering products, not learning.
