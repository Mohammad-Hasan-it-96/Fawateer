# FCM live-unlock — push

**Status: ✅ ENABLED on the client** (2026-07-16, Firebase project
**`fawateer-4c9bc`**). Debug APK builds clean with Firebase linked.
**⚠️ The server side is still owed — see "What the server must send" below.
Until the backend sends the push, live-unlock does nothing.**

FCM live-unlock's only job: when an operator activates a device's subscription
server-side, the backend pushes a data message and the app **re-checks its
license immediately** — the router gate flips from the activation screen to the
POS without the user restarting the app.

Push remains **self-disabling**: if `google-services.json` is absent (e.g. a
fresh clone — it's gitignored), `Firebase.initializeApp()` throws, we swallow it,
and the app runs exactly as before. The user just re-checks manually
(Settings → Subscription → Refresh) or on next launch. Live-unlock is a
convenience, never a dependency.

## Client setup (already done — recorded for a fresh clone / new machine)

1. Firebase project **`fawateer-4c9bc`** at <https://console.firebase.google.com>,
   with an **Android app** registered under package
   **`com.mohamad.hasan.it.fawateer`** — the Android `applicationId`, **not**
   `billing_app` (that's only the Dart/pubspec name). A mismatch builds fine and
   silently never delivers.
2. **`google-services.json`** lives at **`android/app/google-services.json`**.
   It is **gitignored** — a fresh clone must re-download it from the Firebase
   console (Project Settings → Your apps → Android → google-services.json), or
   the build fails with *"File google-services.json is missing."*
3. The two Google-Services Gradle lines are **active** (no longer commented):
   - `android/settings.gradle.kts` → `id("com.google.gms.google-services") version "4.4.2" apply false`
   - `android/app/build.gradle.kts` → `id("com.google.gms.google-services")`
4. `flutter clean && flutter pub get && flutter run`. On launch the app requests
   a token and registers it with the server (`create_device` / `update_my_data`,
   field `fcm_token`).

> No `flutterfire configure` / `firebase_options.dart` is used. This is an
> Android-only build, so plain `Firebase.initializeApp()` reads
> `google-services.json` via the Gradle plugin. If iOS is ever added, it needs
> `GoogleService-Info.plist` + its own Firebase app.

> `minSdk` must be **≥ 21** (Firebase Messaging 16.x). This project inherits
> Flutter's default, which already satisfies it.

## What the server must send  ⬅️ STILL OWED

> **Use the FCM HTTP v1 API.** The legacy endpoint
> (`https://fcm.googleapis.com/fcm/send` + a static "server key") was **shut down
> in 2024** — do not go looking for a server key to paste into Laravel; there
> isn't one any more. v1 authenticates with **OAuth2 from a service account**:
> Firebase console → **Project Settings → Service Accounts → Generate new private
> key** → hand that JSON to the backend. Endpoint is
> `https://fcm.googleapis.com/v1/projects/fawateer-4c9bc/messages:send`.
> The payload below is already v1-shaped.

To trigger the live re-check, push a **data message** to the device's stored
`fcm_token` with a `data.type` of one of:

- `new_plan_activated`
- `subscription_activated`
- `license_updated`

Example payload:

```json
{
  "message": {
    "token": "<device fcm_token>",
    "data": { "type": "new_plan_activated" },
    "notification": {
      "title": "تم تفعيل اشتراكك",
      "body": "تم تفعيل اشتراكك بنجاح."
    }
  }
}
```

The optional `notification` block shows a system tray banner (needs
`POST_NOTIFICATIONS`, already in the manifest). The `data.type` is what the app
keys off — a message without a recognized `type` is ignored.

## How it's wired (code map)

- `lib/features/licensing/data/services/push_notification_service.dart` — inits
  Firebase, requests permission, syncs the token, and on a license-typed message
  invokes the `onLicenseChanged` callback. Self-disables if Firebase is absent.
- `lib/main.dart` — starts the service after `runApp`, wiring `onLicenseChanged`
  to `LicenseBloc.add(CheckLicenseEvent())` (the shared singleton the gate reads).
- `LicenseRepository.registerPushToken` → `update_my_data`; `activate()` also
  attaches the cached token to `create_device`.
