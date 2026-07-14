# Google Drive Backup — Getting Your API Credentials (Step by Step)

A no-skipping-steps guide to creating the **free** Google Cloud credentials the
Fawateer app needs to back up to a user's Google Drive.

> **Important — you are NOT creating an "API key".**
> Google Drive access on Android uses **OAuth 2.0**, not a plain API key.
> What you actually produce here is:
> 1. A **Google Cloud project** (free).
> 2. The **Drive API** turned on inside it.
> 3. An **OAuth consent screen**.
> 4. An **Android OAuth client** (identified by your app's package name + SHA-1 —
>    it has **no client secret**).
> 5. A **Web OAuth client** (only its *client ID* is used, as the app's
>    `serverClientId`).
>
> This needs the **free Google *Cloud* Console** — NOT the paid $25 Google *Play*
> Console.

---

## What you need before you start

- [ ] A Google account (any Gmail) to own the project.
- [ ] Your app's **Android package name** → it is **`com.mohamad.hasan.it.fawateer`**
      (the `applicationId` in `android/app/build.gradle.kts`; NOT `billing_app`,
      which is only the Dart/pubspec package name).
- [ ] The **SHA-1 fingerprint** of the keystore(s) that sign the app
      (debug for testing, release for the real APK) — Part 5 shows how to get it.
- [ ] ~15 minutes. No credit card required.

---

## Part 1 — Create a Google Cloud project

1. Go to **https://console.cloud.google.com**.
2. Sign in with the Google account that should own the project.
3. Top bar → click the **project dropdown** (next to the "Google Cloud" logo) →
   **New Project**.
4. **Project name:** `Fawateer` (or `Fawateer-Backup`). Leave *Organization* /
   *Location* as-is (usually "No organization").
5. Click **Create**. Wait a few seconds, then make sure the project dropdown now
   shows **Fawateer** (select it if it doesn't). Everything below must happen
   **inside this project.**

---

## Part 2 — Enable the Google Drive API

1. Left menu (☰) → **APIs & Services → Library**
   (or go to **https://console.cloud.google.com/apis/library**).
2. Search for **Google Drive API**.
3. Click it → click **Enable**.
4. Wait until it says the API is enabled.

---

## Part 3 — Configure the OAuth consent screen

This is the screen users see when they tap "Sign in with Google" to allow
backups.

1. Left menu → **APIs & Services → OAuth consent screen**
   (in the newer UI this may appear under **Google Auth Platform → Branding**).
2. **User type:** choose **External** → **Create**.
   (External = any Google account can use it. "Internal" only works if you have a
   Google Workspace organization.)
3. **App information:**
   - **App name:** `Fawateer`
   - **User support email:** your email.
   - **App logo:** optional (skip for now).
4. **Developer contact information:** your email → **Save and Continue**.
5. **Scopes** step → **Add or Remove Scopes** → in the filter, paste:
   ```
   https://www.googleapis.com/auth/drive.file
   ```
   Tick it → **Update** → **Save and Continue**.
   > Use **`drive.file`** — the app only sees files it created. It is a
   > **non-sensitive** scope, so Google does **not** require a security review or
   > charge a fee. Do NOT add the broad `drive` or `drive.readonly` scopes — those
   > are "restricted" and trigger the expensive verification.
6. **Test users** step → **Add Users** → add your own Gmail (and any tester
   phones' accounts) → **Save and Continue**.
7. **Summary** → **Back to Dashboard**.

> **Publishing status:** while in **Testing**, only the test users you listed can
> use it, capped at 100 users. When you're ready to ship to real shops, come back
> here and click **Publish App → Confirm**. For the non-sensitive `drive.file`
> scope this is a **self-service switch with no Google review**.

---

## Part 4 — Create the Web OAuth client (for `serverClientId`)

Flutter's `google_sign_in` on Android needs a **Web client ID** to request the
account properly (used as `serverClientId`). You only ever use its **client ID**
string — never its secret.

1. Left menu → **APIs & Services → Credentials**.
2. **+ Create Credentials → OAuth client ID**.
3. **Application type:** **Web application**.
4. **Name:** `Fawateer Web Client`.
5. Leave redirect URIs empty (not needed for this flow) → **Create**.
6. A dialog shows the **Client ID** (ends in `...apps.googleusercontent.com`).
   **Copy it and save it** — this string goes into the app as `serverClientId`.

---

## Part 5 — Create the Android OAuth client (package name + SHA-1)

This is what actually authorizes the installed app. It has **no client secret** —
Android clients are identified by your **package name + signing SHA-1**.

### 5a. Get your SHA-1 fingerprint (Windows / PowerShell)

**Debug key** (for development/testing builds) — run in PowerShell:

```powershell
keytool -list -v `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -alias androiddebugkey -storepass android -keypass android
```

**Release key** (for the real APK you hand to shops) — use YOUR keystore:

```powershell
keytool -list -v `
  -keystore "C:\path\to\your\release-keystore.jks" `
  -alias YOUR_KEY_ALIAS
```
(It will prompt for the keystore password.)

> `keytool` ships with the JDK. If "keytool is not recognized", it's usually at
> `C:\Program Files\Java\<jdk>\bin\keytool.exe`, or under Android Studio's bundled
> JBR: `"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"`.

From the output, copy the line that starts with **`SHA1:`** — a value like
`AA:BB:CC:DD:...:99`.

> You will likely register **two** Android clients (or two SHA-1s): one for the
> **debug** key and one for the **release** key. Do 5b for each.

### 5b. Register the Android client

1. **APIs & Services → Credentials → + Create Credentials → OAuth client ID**.
2. **Application type:** **Android**.
3. **Name:** `Fawateer Android (debug)` (or `(release)`).
4. **Package name:** `com.mohamad.hasan.it.fawateer`
   (must match `applicationId` in `android/app/build.gradle.kts` exactly).
5. **SHA-1 certificate fingerprint:** paste the `SHA1:` value from 5a.
6. **Create.**
7. Repeat for the **release** SHA-1 (name it `... (release)`) — **only once you
   create a dedicated release keystore.**

> **Current signing status (as of this setup):** `build.gradle.kts` signs the
> release build with the **debug** key
> (`signingConfig = signingConfigs.getByName("debug")`), and there is **no
> separate release keystore yet**. So for now **one** Android client with the
> **debug SHA-1** covers both debug and release builds. When you later add a real
> release keystore (recommended before public distribution), come back and
> register that SHA-1 too.

> Android OAuth clients show **no download / no secret** — that's expected. Once
> the package name + SHA-1 are registered in the same project where the Drive API
> is enabled, `google_sign_in` picks them up automatically at runtime. **No
> `google-services.json` is needed** for plain Google Sign-In (that file is only
> for Firebase).

---

## Part 6 — Write down what the app will use

After all steps you should have these saved somewhere safe:

| Value | Where it came from | Used in app as |
|---|---|---|
| **Web client ID** (`...apps.googleusercontent.com`) | Part 4 | `serverClientId` passed to `google_sign_in` |
| **Package name** = `com.mohamad.hasan.it.fawateer` | Part 5b | must match your Android build |
| **Debug SHA-1** = `BE:D0:B7:48:2D:8C:58:4C:B4:FD:63:BE:88:10:77:9F:2B:DE:54:EF` | Part 5a | registered in an Android OAuth client |
| **Release SHA-1** | Part 5a | only when a dedicated release keystore exists (none yet) |
| Scope = `drive.file` | Part 3 | requested at sign-in |

> The only string you paste into source code is the **Web client ID**. The Android
> client is matched silently by package name + SHA-1 — nothing to copy from it.

---

## Quick checklist

- [ ] Project **Fawateer** created and selected.
- [ ] **Google Drive API** enabled in that project.
- [ ] OAuth consent screen configured, **External**, scope `drive.file` only.
- [ ] Your Gmail added as a **test user** (until you publish).
- [ ] **Web** OAuth client created → Web **client ID** saved.
- [ ] **Android** OAuth client created with package `com.mohamad.hasan.it.fawateer` + debug SHA-1.
- [ ] All values recorded in the table above.

---

## Common gotchas

- **`Error 403: access_denied` / "app is being tested"** → the signed-in Google
  account isn't in your **Test users** list (Part 3, step 6), or the app isn't
  published yet.
- **`Error 10` (DEVELOPER_ERROR) on sign-in** → package name or SHA-1 mismatch.
  The SHA-1 of the build you're actually running (debug vs release) must be
  registered. Re-run Part 5a on the exact keystore and re-check.
- **`sign_in_failed` after switching to a release APK** → you registered only the
  debug SHA-1. Add the **release** SHA-1 too (Part 5b).
- **Wrong project** → the Drive API and the OAuth clients must all live in the
  **same** Cloud project. Check the project dropdown.
- **Play App Signing (only if you ever use Play Store)** → Google re-signs your
  app with a different key, so you'd also register **that** SHA-1 from Play
  Console. Not relevant now (no Play Console), noted for the future.

---

*This guide only covers obtaining the credentials. Wiring them into the Fawateer
backup feature is the implementation work described in
`docs/plans/001-backup-system.md` (Phase 1).*
