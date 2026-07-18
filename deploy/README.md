# deploy/

Source of truth for files that are **hosted**, not shipped in the APK.

## `fawateer.json` → `https://evotech-sys.com/config/fawateer.json`

The app's remote config. On startup `RemoteConfigService` fetches this URL and
applies it over the baked-in `ApiConfig` defaults, so the API base URL and
support contacts can move **without a store release**. It is hosted on the
**web** host, not the API host, on purpose: it is the file that says where the
API is, so an API outage must not be able to take it down too.

**This file in the repo is the source of truth. The URL is a copy of it.**
To change what the app sees:

1. Edit `deploy/fawateer.json` here and commit.
2. Publish the identical bytes to `https://evotech-sys.com/config/fawateer.json`.
3. Confirm: `curl -s https://evotech-sys.com/config/fawateer.json`.

### Schema — derived from `lib/core/config/remote_config.dart` (`RemoteConfig.fromJson`)

The parser is defensive: any missing or malformed field degrades to a safe
default rather than throwing, and a fetch failure leaves the baked-in
`ApiConfig` defaults in place. **This means a wrong key fails silently** — the
app looks fine while using the fallback URL. Keep the keys exact.

| Key | Type | Notes |
|---|---|---|
| `latest_version` | string | Compared against the installed `versionName` to drive the update prompt. Track `pubspec.yaml`'s `version:`, e.g. `1.0.0`. |
| `api.base_url` | string | **Nested under `api`** — NOT a top-level `baseUrl`. The API URL, including the `/api/fawateer` namespace. |
| `downloads` | object | Per-ABI APK URLs, keyed by exact Android ABI (`arm64-v8a`, `armeabi-v7a`, `x86_64`). Empty `{}` = no in-app download offered. |
| `update_notes` | string[] | Arabic release notes shown in the update dialog. |
| `support.email` | string | |
| `support.whatsapp` | string | International format, digits only. |
| `support.telegram` | string | Full `https://t.me/...` link or bare username. |

`support.*` mirror the `ApiConfig` baked-in defaults; the hosted file overrides
them at runtime. When the per-ABI APKs are published (`--split-per-abi`, see
`docs/android-release-distribution.md`), fill `downloads` and bump
`latest_version` to enable the in-app update prompt.
