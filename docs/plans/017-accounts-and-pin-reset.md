# Plan 017 — Email Accounts, and How to Reset a Forgotten PIN

> **Status:** 🔬 **STUDY — recommendation: do NOT build accounts for this.**
> Source: the owner's question while reviewing Plan 016 — *"I think about using
> email for register and login, and in this case using it for reset PIN. What do
> you think about this feature?"*
>
> **Short answer:** the PIN-reset problem is real and needs solving, but email
> accounts are a very large, risky way to solve it — and they would break
> something that currently works. There is a much cheaper answer that reuses a
> channel the app already has. Accounts may still be worth building **later, for
> their own reasons**, and those are listed honestly at the end.

---

## 1. What the app does today (and why)

**Fawateer has no user accounts, on purpose.** A shop is identified by its
**device id** — `SHA-256(ANDROID_ID + salt)` — and everything hangs off that:

- **Licensing** — `create_device` / `check_device` are keyed on `(app_name,
  device_id)`. There is no login, no password, nothing to forget.
- **Activation** — the user copies their device id from the screen and sends it
  to support on WhatsApp/Telegram. A human activates it. The app unlocks live
  over FCM.
- **The backend agreed this explicitly.** From `docs/backend-replies/`:
  *"Companies presumes a human login. A Fawateer shop has none."* The whole
  `device_businesses` design was built around that fact.

So there is already a working, human-in-the-loop channel between a shop and the
operator. **That channel is the answer to the PIN problem.**

---

## 2. The strongest argument against email accounts: the free trial

This is concrete, not theoretical.

`docs/plans/006-free-trial.md` decided that **trial abuse is prevented
server-side, keyed on the device id** — which survives an app reinstall and only
changes on a factory reset. The plan explicitly **rejected** anything the user
can reset themselves.

**An email account is something the user can reset in ten seconds.** New email →
new account → new trial, forever, from the same phone. Unless the trial stays
keyed on the device id anyway — in which case the account has not helped, and you
now maintain *two* identity systems that must agree.

That is the trap: accounts do not replace device identity here, they sit **on top
of it**, and every rule has to be re-decided for the pair.

---

## 3. What email accounts would actually cost

Not "a login screen". The full list:

| Piece | Notes |
|---|---|
| Register + verify email | verification mails land in spam; shops will call support about it |
| Login + session + token refresh | the app currently has no session concept at all |
| Forgot **password** | you have replaced "forgot PIN" with "forgot password" — the same problem, one level up |
| Password rules, rate limiting, lockout | or the account is not real security |
| Backend: users table, auth, mail sending | new infrastructure on `evotech-core` |
| Migration for existing shops | every installed device must be attached to some account |
| Offline behaviour | **the app must work with no internet — so login cannot gate the POS.** That means the session must be cached and long-lived, which weakens the account anyway |

And the sharpest one:

> **Many small shopkeepers in Syria do not use email.** They use WhatsApp. The
> app already talks to them on WhatsApp — that is why `url_launcher` and the
> operator contacts exist. Asking for an email address to unlock a till is asking
> for the one thing they may not have.

---

## 4. Recommended answer for PIN reset

### Option R1 — operator reset, through the existing channel ⭐ **recommended**

Exactly how activation already works:

1. The "forgot PIN" screen shows the **device id** (already displayed and
   copy-to-clipboard in several places via `DeviceIdCard`).
2. The shop sends it on WhatsApp — one tap, the contact is already in the app.
3. Support gives back a **one-time reset code**.
4. Entering it clears the PIN.

- ✅ **No backend work, no accounts, no email.**
- ✅ Uses a channel the shop already knows and already trusts.
- ✅ A human check is *appropriate* here — "let me into the manager functions of a
  till" should involve a person.
- ❌ Needs support to be reachable. (They already are, for activation.)

**How the code is produced matters.** It must work **offline**, because a shop
with a locked PIN and no internet is exactly when this happens. So it should be
derived, not fetched:

```
reset_code = first 6 digits of SHA-256(device_id + secret + YYYY-MM-DD)
```

Support computes the same value with a small internal tool. It changes daily, so
a code shared once does not become a permanent master key, and the app can verify
it with no network. **The secret must not sit in the APK in plain text** — treat
it like the device-id salt (`ApiConfig.deviceIdSalt`), and accept that an APK can
be reverse-engineered. That is acceptable: this is a speed bump on an owner's own
till, not a bank vault.

### Option R2 — the subscription phone number

The shop already gave a name and phone at activation (`update_my_data`). Send the
reset code as a WhatsApp message to that stored number.

- ✅ No email; uses a number the shop definitely has.
- ✅ More automatic than R1.
- ❌ Needs backend work (send + verify a code).
- ❌ Needs internet at the moment of reset.
- Reasonable **later**, as an upgrade to R1 — not instead of it.

### Option R3 — email accounts

- ❌ Everything in §2 and §3.
- Not for this problem.

---

## 5. So is email/accounts ever worth it?

**Maybe — but for its own reasons, not for the PIN.** The honest case *for*
accounts, if it is ever revisited:

- **Restore on a new phone without support.** Today a lost phone means contacting
  the operator to move the licence. An account makes that self-service. This is
  the single strongest argument.
- **Self-service subscription renewal**, instead of an operator activating each
  device by hand.
- **Multi-device without a QR** — a second phone signs in instead of scanning.
  (Note the QR flow is already built and works, and was designed for staff phones
  that should *not* have the owner's credentials.)
- **One owner, several shops** — a real business need the device model cannot
  express at all.

The case *against*, restated:

- It does not replace device identity, so trial abuse still has to be device-keyed
  and you now run two systems.
- The POS must work offline, so the login cannot really gate anything.
- It is a large backend project, and the current device model **is working**.

**Recommendation:** revisit only when a *business* reason appears from that list —
most likely "the shop replaced their phone and I am tired of doing it by hand", or
"one owner, three shops". A forgotten PIN is not that reason.

---

## 6. Decision for now

- **PIN reset → Option R1** (device id + operator + offline daily code).
- **Accounts → not now.** Keep this document as the record of why, and as the
  starting point if a real business reason turns up.
- **PIN storage** (from Plan 016) stays: hashed with a per-install salt, never
  plain text — it travels inside every Drive backup and every sync snapshot.
