# FCM live-unlock — enabling push

The app ships with **Firebase Cloud Messaging (FCM) live-unlock** wired in but
**dormant**. Its only job: when an operator activates a device's subscription
server-side, the backend pushes a data message and the app **re-checks its
license immediately** — the router gate flips from the activation screen to the
POS without the user restarting the app.

Until a Firebase project is configured, `Firebase.initializeApp()` fails
gracefully and push stays disabled — **the app builds and runs exactly as
before**; the user just re-checks manually (Settings → Subscription → Refresh)
or on next launch. Nothing below is required to ship without live-unlock.

## Enable it (one-time)

1. **Create a Firebase project** (or reuse the backend's) at
   <https://console.firebase.google.com>. Add an **Android app** with the
   package name **`com.mohamad.hasan.it.fawateer`**.
2. Download the generated **`google-services.json`** and drop it in
   **`android/app/google-services.json`** (git-ignore it — it's per-project).
3. Uncomment the two Google-Services Gradle lines:
   - `android/settings.gradle.kts` → the `com.google.gms.google-services` plugin
     in the top-level `plugins {}` block.
   - `android/app/build.gradle.kts` → the matching `id("com.google.gms.google-services")`
     in the app `plugins {}` block.
4. `flutter clean && flutter pub get && flutter run`. On launch the app prints
   an FCM token and registers it with the server (`create_device` /
   `update_my_data`, field `fcm_token`).

> `minSdk` must be **≥ 21** (Firebase Messaging 16.x). This project inherits
> Flutter's default, which already satisfies it.

## What the server must send

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
