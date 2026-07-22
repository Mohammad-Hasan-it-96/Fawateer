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

## ⚠️ Back up the keystore + passwords NOW

**The keystore is unrecoverable.** There is no reset, no support ticket, no
regeneration. Lose it and you can never update any installed copy of Fawateer —
every existing user is stranded on their current version, and moving them to a
new key costs them their data.

Store in **two separate places** (e.g. a password manager entry with the `.jks`
attached, plus an offline copy):

- the `.jks` file itself
- `keyAlias`, `keyPassword`, `storePassword`
- the SHA-1 (below)

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
