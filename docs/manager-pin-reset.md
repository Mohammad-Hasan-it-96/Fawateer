# Manager PIN — how support resets a forgotten one

The manager lock (Plan 016 B) asks for a 4–6 digit PIN before a sale is deleted
or its payment type is changed. **The PIN is never stored**, only a salted
SHA-256 hash of it, so nobody — including you — can read a shop's PIN back out
of their phone or their Google Drive backup.

That means a shop that forgets its PIN cannot be helped by looking it up. They
are unlocked with a **daily reset code** instead, computed from their device id.
This is Plan 017 option R1, chosen over email accounts.

## Why it is computed and not sent

A shop locked out of its own till very often has no internet either — that is
frequently *why* they are calling. So the code must be checkable offline, which
means the app derives it rather than fetching it. You derive the same value.

## The flow

1. The shop taps **نسيت الرمز؟ / Forgot the PIN?** in the PIN prompt.
2. That screen shows their **device number** (the same id used for activation)
   with a copy button, and buttons to reach you on WhatsApp or Telegram.
3. They send you the device id.
4. You compute the code for **today** and read it back to them.
5. They type it in. The PIN is removed, and they set a new one from Settings.

The code is six digits, changes every day, and is different for every device —
so a code you give out once does not become a permanent key to that till, and
never opens a different shop's phone.

## Computing the code

```
day  = the shop's local date, as YYYY-MM-DD
data = "<device_id>|fawateer_manager_pin_v1|<day>"
h    = SHA-256(data)                       # raw bytes, not hex
n    = (h[0] << 16 | h[1] << 8 | h[2]) % 1000000
code = n, left-padded with zeros to 6 digits
```

The secret is `ApiConfig.pinResetSecret` in the app source. **If it ever
changes, every unreleased build stops matching your tool** — bump it only with a
release, and update this document in the same commit.

Python, for an internal tool:

```python
import hashlib
from datetime import date

def reset_code(device_id: str, day: date = None) -> str:
    day = day or date.today()
    data = f"{device_id}|fawateer_manager_pin_v1|{day.isoformat()}"
    h = hashlib.sha256(data.encode()).digest()
    n = (h[0] << 16 | h[1] << 8 | h[2]) % 1_000_000
    return f"{n:06d}"
```

The app accepts **yesterday, today and tomorrow**, so you and the shop being on
opposite sides of midnight — or in different time zones — does not produce a
code that stops working while you are reading it out.

## What this does and does not protect

Say this plainly to shops who ask, because they will otherwise assume more:

- It stops a helper deleting a sale while the owner is out. That is the job.
- It is **not a login**. There is no session, no user list, and no audit of who
  did what.
- Someone holding the unlocked phone with unlimited time will get past four
  digits. The app slows guessing down (a 30-second wait after 5 wrong tries)
  but that counter lives in memory and resets when the app restarts.
- **You can always reset it.** If the shop trusts you with activation, they are
  already trusting you with this.

## Related

- `docs/plans/016-manager-lock-and-invoice-edit.md` — why the lock exists and
  what it guards.
- `docs/plans/017-accounts-and-pin-reset.md` — why this is not solved with email
  accounts.
