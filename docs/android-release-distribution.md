# Android release artifacts & distribution

What to build for a release, and how it reaches shops. Signing itself is in
`docs/android-release-signing.md`.

## Build

```bash
flutter build apk --release --split-per-abi
```

Produces three APKs in `build/app/outputs/flutter-apk/`, each carrying **one**
native ABI:

| Artifact | ABI | versionCode | ~size |
|---|---|---|---|
| `app-armeabi-v7a-release.apk` | `armeabi-v7a` | base + 1000 | 24 MB |
| `app-arm64-v8a-release.apk` | `arm64-v8a` | base + 2000 | 27 MB |
| `app-x86_64-release.apk` | `x86_64` | base + 4000 | 30 MB |

A **universal** APK (`flutter build apk --release`, no split) is ~76 MB — it
bundles all three ABIs and ships two useless ones to every device. We don't
distribute it, because the in-app updater already picks per-ABI (below).

## ⚠️ Never mix universal and split builds

Flutter offsets the versionCode **per ABI** (`+1000`/`+2000`/`+4000`), so at
pubspec `1.0.0+1` the splits are `1001`/`2001`/`4001` while the universal APK is
plain **`1`**. Android **refuses to install a lower versionCode over a higher
one**, and the error blames the package, not the version.

So a device that has `app-arm64-v8a-release.apk` (2001) installed **cannot**
install the universal APK (1) — the install just fails. Pick one model and stay
on it. We're on **split**, from 1.0.0 onward. Nothing has shipped universal, so
there's no legacy to carry.

For the same reason the ABI offsets are **not a fallback ladder**: you can't hand
an arm64 user (2001) the `armeabi-v7a` build (1001) as a "safe" substitute — it's
a downgrade and will be blocked. On a **fresh** install any matching APK is fine
(no prior code to compare against); it's only updates that are ordered.

Bumping `version:` in `pubspec.yaml` bumps all three together
(`1.0.1+2` → `1002`/`2002`/`4002`), which stays monotonic per ABI. That's the
only thing that has to hold.

## Which one to send a shop manually

- **Modern phone (essentially all since ~2017):** `arm64-v8a`.
- **Old/cheap 32-bit device:** `armeabi-v7a`. This also *runs* on arm64 phones
  (they list `armeabi-v7a` in `supportedAbis`), so it's the safest blind send —
  but only for a **first** install, per the downgrade rule above.
- **`x86_64`:** emulators and a few rare Intel tablets. Build it, host it, don't
  think about it.

## Hosting: the `downloads` block in `fawateer_version.json`

`RemoteConfigService._pickDownload` walks the device's `supportedAbis` **in
order** and takes the first key that matches, so the JSON keys must be exact
Android ABI strings:

```json
{
  "latest_version": "1.0.0",
  "downloads": {
    "arm64-v8a":   "https://…/app-arm64-v8a-release.apk",
    "armeabi-v7a": "https://…/app-armeabi-v7a-release.apk",
    "x86_64":      "https://…/app-x86_64-release.apk"
  }
}
```

Keep **`arm64-v8a` first**. If no ABI matches, `_pickDownload` falls back to the
first non-empty URL in insertion order — so the most-likely-correct build should
sit at the top.

The update prompt compares **`latest_version` against the installed
`versionName`** (`_isNewer`, a dotted numeric compare) — versionCode plays no
part in it. So `latest_version` must track `pubspec`'s `version:` string
(`1.0.0`), not the `+1` build number and not the offset codes.
