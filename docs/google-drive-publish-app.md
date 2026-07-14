# Publishing the OAuth App to Production (fixing `Error 403: access_denied`)

This removes the **"Access blocked: … has not completed the Google verification
process"** screen. Because Fawateer uses only the **non-sensitive `drive.file`**
scope, publishing is a **self-service toggle with NO Google review, NO fee, and
NO Play Console** — you just flip the app from *Testing* to *Production*.

> **Why this error happens:** while the OAuth consent screen is in **Testing**,
> only Google accounts you added as *test users* can sign in; everyone else gets
> `403: access_denied`. Publishing to **Production** lifts that restriction.

---

## Before you start

- [ ] You can sign in to **https://console.cloud.google.com** with the Google
      account that **owns** the `Fawateer` project (the one you created the
      project with — not necessarily the phone's test account).
- [ ] The **Fawateer** project is selected in the top project dropdown.
- [ ] Drive API is enabled and the consent screen already has the `drive.file`
      scope (from the earlier setup). Publishing does not change those.

---

## Step 1 — Open the OAuth consent screen / Audience page

Go directly to:

```
https://console.cloud.google.com/apis/credentials/consent
```

- Confirm the **project name at the top** says **Fawateer**. If not, click the
  project dropdown and switch to it.
- In the newer console layout this page is titled **"Google Auth Platform"** and
  the publishing control lives under the **"Audience"** tab. In the older layout
  it's the **"OAuth consent screen"** page. Either way you're looking for the
  **Publishing status** section.

---

## Step 2 — Check the current status

You should see:

```
Publishing status:  Testing
User type:          External
```

If it already says **In production**, you're done — skip to Step 5 and just retry
sign-in. (The block only happens in *Testing*.)

---

## Step 3 — Click "Publish app"

1. In the **Publishing status** section, click the **PUBLISH APP** button.
2. A dialog appears: **"Push to production?"** listing your scopes.
3. Confirm the only scope shown is the non-sensitive one:
   ```
   .../auth/drive.file   (See, edit, create, and delete only the specific
                           Google Drive files you use with this app)
   ```
   If you see broader scopes like `.../auth/drive` or `.../auth/drive.readonly`,
   **stop** — those are *restricted* and WOULD require verification. Remove them
   and keep only `drive.file`. (Fawateer only needs `drive.file`.)
4. Click **CONFIRM**.

---

## Step 4 — Confirm the new status

The page should now show:

```
Publishing status:  In production
```

That's it. There is:
- **No "Prepare for verification" requirement** for `drive.file` (non-sensitive).
- **No OAuth verification form** to submit.
- **No brand/security review**, no fee, no Play Console.

> You may still see a note like *"Verification not required"* or a general
> reminder that sensitive/restricted scopes would need review — that's
> informational. As long as your only scope is `drive.file`, you're free to use it
> in production immediately.

---

## Step 5 — Retry sign-in in the app

1. On the phone, open **Fawateer → Settings → Backup & Restore → Sign in with
   Google**.
2. Pick the account (e.g. `johnmclaren1985@gmail.com`).
3. You'll now see the normal Google consent screen ("Fawateer wants access to …
   Google Drive files it creates") **instead of** the *Access blocked* page.
4. Tap **Allow**. Sign-in completes and you can **Back up now**.

---

## What "Production" does and doesn't mean

- ✅ **Any** Google account can now sign in (no test-user list, no 100-user cap).
- ✅ Users still see a **normal consent prompt** — publishing doesn't remove the
  consent step, it removes the *block*.
- ✅ You can add/remove scopes later; adding a *restricted* scope in the future
  is what would trigger verification — `drive.file` never does.
- ⚠️ Users each grant access to **their own** Drive. You (the developer) get no
  access to their data — exactly the privacy posture we designed for.

---

## Troubleshooting after publishing

| Symptom | Cause | Fix |
|---|---|---|
| Still see *Access blocked / access_denied* | Wrong project selected, or you published a *different* project | Re-open the consent page, confirm the title says **Fawateer**, re-check status = In production |
| `Error 10` (DEVELOPER_ERROR) on sign-in | Package name / SHA-1 mismatch — unrelated to publishing | Confirm the Android OAuth client uses package `com.mohamad.hasan.it.fawateer` + the debug SHA-1 `BE:D0:B7:48:2D:8C:58:4C:B4:FD:63:BE:88:10:77:9F:2B:DE:54:EF` |
| Sign-in works but backup fails | Drive API not enabled, or `drive.file` scope missing from consent screen | Enable **Google Drive API**; add the `drive.file` scope |
| Consent shows a broad "See and manage all your Drive files" prompt | A restricted scope crept in | Remove everything except `drive.file` |

---

*Alternative if you'd rather stay in Testing:* just add each tester's Google
account under **Test users** on the same page — no publishing needed, but capped
at 100 accounts and each must be added manually. Publishing (this guide) is the
better choice once you distribute to real shops.
