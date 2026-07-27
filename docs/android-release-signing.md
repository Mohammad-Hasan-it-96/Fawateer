# Android release signing

How Fawateer's release APK is signed, and what to do on a new machine.

> **Why this exists.** Release used to be signed with the **debug** keystore
> (Flutter's template default). That is a trap for a commercial app:
>
> - The auto-generated debug keystore **expires after ~1 year**. Regenerating it
>   produces a **different key**.
> - Android **refuses to install an update signed with a different key**. The
>   only user-side recovery is **uninstall + reinstall**.
> - Fawateer is **offline-first**: uninstall wipes the local SQLite — *every
>   invoice, customer, and debt on that device*.
>
> So the release key must be one we own, control, and back up.

## The setup (one-time — already done on the owner's machine)

1. **Keystore lives OUTSIDE the repo**, e.g.
   `C:/Users/<you>/keystores/fawateer-release.jks`. Outside — not merely
   gitignored — so no future `.gitignore` edit or `git add -f` can leak it.
2. **`android/key.properties`** (gitignored) holds the alias, the two passwords,
   and the absolute path to the `.jks`. See `android/key.properties.example` for
   the shape.
3. **`android/app/build.gradle.kts`** reads that file and signs `release` with
   it. If `key.properties` is **missing and a release build is requested, the
   build fails loudly** — it will never silently fall back to the debug key.
   Debug/profile runs still work without it.

## Creating the keystore

Run this yourself so the passwords never land in a transcript or shell history —
`keytool` prompts interactively:

```bash
keytool -genkey -v \
  -keystore "$HOME/keystores/fawateer-release.jks" \
  -storetype JKS \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias fawateer
```

- `-validity 10000` ≈ 27 years. Do not shorten it: **an expired signing key
  means you can no longer ship updates to existing installs.**
- The "first and last name" (CN) prompt does not have to be a person — the shop
  or company name is fine. None of it is shown to users.
- Then `cp android/key.properties.example android/key.properties` and fill it in.

## Backups — done, and where they live

**The keystore is unrecoverable.** There is no reset, no support ticket, no
regeneration. Lose it and you can never update any installed copy of Fawateer —
every existing user is stranded on their current version, and moving them to a
new key costs them their data. That is why this section is not advice; it is a
record of the current state, to be kept accurate.

**As of 2026-07-27** (verified — see *Verify* below):

| What | Where |
|---|---|
| `fawateer-release.jks` | working copy on the dev laptop (`C:\Users\ASUS\keystores\`), Google Drive, external hard drive |
| `keyAlias` / `keyPassword` / `storePassword` | **Bitwarden** (item *"Fawateer keystore"*, synced to phone + laptop); also a plaintext `.txt` alongside the `.jks` on Drive and the external drive |
| SHA-1 | in this file (below), and in Google Cloud Console |

Three copies of the key across independently-failing systems, and the passwords
survive losing the laptop. **Never store fewer than two.**

### Two follow-ups this arrangement creates

1. **Don't let Bitwarden become a single point of failure.** The vault is
   zero-knowledge: forget the master password and there is no reset. Keep 2FA
   on, keep its **recovery code** offline, and keep the master password written
   down somewhere physical. Until that's true, the `.txt` copy on the external
   drive is the escape hatch — don't delete it.
2. **The Drive copy holds both halves.** The `.jks` and the plaintext password
   `.txt` sit in the same account, so one phished Google login yields complete
   control of the app's signing identity — enough to push a counterfeit
   "update" over a real shop's install. Once Bitwarden is hardened per (1),
   **delete the `.txt` from Drive** and leave the `.jks` there alone.

### Verifying a backup actually works

A backup you have never opened is not yet a backup. Two levels:

- `keytool -list -v -alias fawateer -keystore <path>` proves **which** keystore
  it is (compare the SHA-1). Note that if you press Enter at the password
  prompt it still lists — certificate data is public — and prints a
  `WARNING ... integrity has NOT been verified` block. Seeing that warning means
  the password was **not** checked.
- **`flutter build apk --release` is the real test.** It exercises
  `storePassword` *and* `keyPassword` (which may differ — `-list` only checks
  the store one) plus the `key.properties` wiring. If it signs, everything works.

Re-run the release build after any change to the keystore, `key.properties`, or
the backup copies.

## ⚠️ Google Drive backup: register the new SHA-1

Google Sign-In (used by the Drive backup, Plan 001) authorizes on **package name
+ signing SHA-1**. Changing the release key changes the SHA-1, so **the release
build's sign-in breaks until the new fingerprint is registered** — and it fails
as `ApiException: 10 (DEVELOPER_ERROR)`, which does not hint at the real cause.

The release SHA-1 is **`2B:95:86:BD:74:82:AA:AC:10:C1:F8:7A:FA:E8:2C:4E:1B:DB:59:91`**.
(Re-derive it any time with the `apksigner` command under **Verify** below, or from
the keystore with `keytool -list -v -alias fawateer -keystore <path>`.)

Then in **Google Cloud Console** → *APIs & Services → Credentials*:

- **Add a second Android OAuth client** for package
  `com.mohamad.hasan.it.fawateer` with the **release** SHA-1.
- **Keep the existing debug one.** An OAuth client holds a single fingerprint;
  you need both so debug and release each work. Do not overwrite the debug entry.

See `docs/google-drive-api-setup.md` for the console walkthrough.

> FCM does **not** need a SHA-1 — only Google Sign-In does. Enabling the release
> key does not affect push.

## Verify

```bash
flutter build apk --release
apksigner verify --print-certs -v build/app/outputs/flutter-apk/app-release.apk
```

`apksigner` lives in the Android SDK, e.g.
`%LOCALAPPDATA%\Android\Sdk\build-tools\36.1.0\apksigner.bat` on Windows.

Expect the signer DN to be **ours**, not the debug key's `CN=Android Debug`:

```
Verified using v2 scheme (APK Signature Scheme v2): true
Signer #1 certificate DN: CN=Mohamad Hasan, OU=EvoTech, O=EvoTech, L=Damascus, ST=Damascus, C=sy
Signer #1 certificate SHA-1 digest: 2b9586bd7482aaac10c1f87afae82c4e1bdb5991
```

> **Don't use `keytool -printcert -jarfile`** — it reads only the legacy **v1**
> (JAR) signature, which this APK doesn't carry, so it reports the misleading
> *"Not a signed jar file"* on a perfectly signed APK. `minSdk` is **24**, so
> Gradle signs with **v2 only** (v1 is only needed below API 24, and v2 was
> introduced there). That's correct, not a gap: every device that can install
> Fawateer can verify a v2 signature.

## On a new machine / fresh clone

`key.properties` and the `.jks` are both absent by design. Restore the keystore
from backup, copy `key.properties.example` → `key.properties`, fill it in.
Release builds fail with a pointing-at-this-doc error until you do; debug builds
work regardless.
