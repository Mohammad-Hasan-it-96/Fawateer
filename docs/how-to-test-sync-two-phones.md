# How to test sync on two phones — step by step

This guide is for **doing** the test. It tells you what to install, what to tap,
and what you should see.

If you want the full list of checks to tick off, use
[`two-phone-field-test.md`](two-phone-field-test.md). This file is the "how";
that file is the "what to check".

In this guide:

- **Phone A** = the phone that already has your shop data. It becomes the **main
  phone** (`الهاتف الرئيسي`).
- **Phone B** = the second phone. It becomes a **linked phone** (`هاتف مرتبط`).

---

## The blocker is fixed (19 August 2026)

The old problem is gone. `POST /api/v1/sync/join-tokens/{code}/bootstrap` used
to answer "not found" for every code. The server team fixed it and put it live.

Two things were wrong, one on each side:

| Where | What was wrong | Fixed by |
|---|---|---|
| Server | The address looked up the code by an internal id we are never given, so no code could ever match | evotech-core PR #35, now live |
| App | We sent the hash in a field called `sha256`. The server wants `snapshot_sha256` | This app, 19 August |

The app fix matters even though you never saw it fail. The server's "not found"
came first, so our wrong field name was never reached. With their fix live, the
old build would have stopped one step later with a different error.

**What this means for you:** use a build made on **19 August or later**. An
older APK still sends the wrong field name and Phone B will not get the shop
data. Follow this guide from top to bottom.

The rest was already tested against the real server on 16 August and works:
sending sales, receiving sales, the phone list, renaming, removing.

Their full answer is filed at
`docs/backend-replies/2026-08-16-evotech-core-reply-bootstrap.txt`.

---

## 0 — What you need before you start

| Thing | Why |
|---|---|
| Two Android phones | The test needs two real devices |
| Internet on both | Sync is offline-first, but joining needs the network |
| A live subscription on **both** phones | Sync refuses a phone with no subscription. This is on purpose, not a bug |
| The **same** app build on both | An older build asks the server for old web addresses that no longer exist |
| Some real data on Phone A | A few products, one customer, one debt, a few sales |

**Why data on Phone A matters:** if the shop is empty, step 6 will look like it
worked when nothing was actually copied. Write down how many products A has. You
will compare that number on B.

---

## 1 — Build the app

Open a terminal in `D:\work\Flutter\Fawateer` and run:

```bash
flutter build apk --release --split-per-abi
```

The files appear in `build/app/outputs/flutter-apk/`. The copies already prepared
for this version are here:

```
build/release/1.2.0/fawateer-1.2.0-arm64-v8a.apk        (most modern phones)
build/release/1.2.0/fawateer-1.2.0-armeabi-v7a.apk      (older / cheaper phones)
```

If you do not know which one a phone needs, install `arm64-v8a` first. If Android
refuses it, use `armeabi-v7a`.

---

## 2 — Install on both phones

Connect the phone by USB and run:

```bash
adb devices                 # check the phone is listed
adb install -r build/release/1.2.0/fawateer-1.2.0-arm64-v8a.apk
```

Or just copy the APK file to the phone and open it there.

### If you see `INSTALL_FAILED_UPDATE_INCOMPATIBLE`

The phone has a **debug** build installed. Android will not replace a debug build
with a release build, because they are signed with different keys.

You have two choices:

- **Keep the shop data** — build and install a debug build instead:
  `flutter build apk --debug` then `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
- **Start clean** — `adb uninstall com.mohamad.hasan.it.fawateer`, then install
  the release APK. **This deletes everything on that phone.** Make a Google Drive
  backup first.

> Both phones should run the same *kind* of build (both release, or both debug).
> Mixing them is fine for sync itself, but makes the test less like the real
> thing.

---

## 3 — Check the build is new enough

Open the app → Settings → tap the version row at the bottom.

The build must be from **16 August 2026 or later**. Older builds ask the server
for four web addresses that do not exist, so every sync fails with the general
error `حدث خطأ. حاول مرة أخرى`.

---

## 4 — Turn on sync on Phone A

On Phone A: **Settings → الأجهزة والمزامنة**.

You will see two choices:

| Button | Use it when |
|---|---|
| `تفعيل للمحل` (enable for the shop) | This phone has your data → **press this on A** |
| `الانضمام إلى محل` (join a shop) | This phone is empty and will join → for B later |

Press **`تفعيل للمحل`**.

**You should see:**

- The title changes to `الهاتف الرئيسي` (main phone)
- A list appears: `الهواتف التي تستخدم هذا المحل`
- It says **`1 من 3 هواتف مستخدمة`** (1 of 3 phones used)
- One row, named after the phone model (for example `Infinix X6833B`), with
  `نشط الآن` under it

> If it says **1 of 1**, your plan did not give you extra phones. Stop and tell
> evotech-core. Everything after this would fail for the wrong reason.

---

## 5 — Make a join code on Phone A

Press **`إضافة هاتف`** (add a phone).

The app now does three things, and shows each one:

1. `جارٍ التحديث مع الهواتف الأخرى…` — sends and receives changes first
2. `جارٍ تجهيز نسخة من المحل…` — makes a copy of your whole shop
3. `جارٍ إرسال المحل إلى الهاتف الجديد…` — uploads that copy

This is **not instant**. It is uploading your whole shop file.

**You should see:** a QR code, and the same code written in letters below it, so
you can type it if the camera does not work.

> **Right now this step fails** with `حدث خطأ. حاول مرة أخرى` — see the "Known
> problem" section at the top. It is the upload in point 3 that fails.

---

## 6 — Join with Phone B

On Phone B: **Settings → الأجهزة والمزامنة → `الانضمام إلى محل`**.

Then either:

- press `مسح` and point the camera at the QR on Phone A, or
- type the code by hand and press `انضمام`

**You should see:**

- Phone B prepares, then shows `المحل الآن على هذا الهاتف`
- It asks you to close and open the app again — do that
- After restart, **Phone B shows the whole shop**: the same products, the same
  customer, the same debt, the same past sales

> **This is the step most likely to fail quietly.** If Phone B opens with an
> **empty shop** while Phone A still looks healthy, the shop copy did not arrive.
> Do not carry on. That is the bug worth reporting in full.

Now go back to Phone A and open the sync screen again:

- It should say **`2 من 3 هواتف مستخدمة`**
- Two rows, each with a name and a "last used" line
- Phone A's own row has the badge `هذا الهاتف` and **no remove button**

---

## 7 — The real test: does a sale move?

This is the whole point of the feature.

1. Keep **Phone B** open on the **Reports** tab (التقارير)
2. Sell something on **Phone A**
3. Watch Phone B

**You should see:**

- The sale appears on B within a few seconds
- **No notification banner pops up on B.** A sale must not ring like a message
- The product's stock went down on B too

Now do it the other way: sell on **B**, watch **A**.

> If it takes up to **5 minutes** instead of a few seconds, the sale still
> arrived. That is the backup timer working. It means the instant wake-up (we
> call it the "doorbell") did not reach the phone. Worth reporting, but no data
> was lost.

---

## 8 — Deleting must stay deleted

This is the worst bug this design can have, so test it properly.

1. Delete a product on **Phone A**
2. Check it is gone on **Phone B**
3. **Close both apps fully and open them again**
4. Check again on both

The product must stay gone on both phones. A deleted product coming back means
the shopkeeper cannot trust anything.

---

## 9 — Two phones selling the same item

Pick a product with small stock, for example 3 pieces.

1. Turn the internet **off on both phones**
2. Sell 2 on Phone A
3. Sell 2 on Phone B
4. Turn the internet back on for both

**You should see:**

- Both sales survive. The shop sold 4, and neither sale disappeared
- The Reports tab shows a **red card at the top** saying the count went below
  zero

> This is correct behaviour, not a failure. The app never refuses a customer
> because of a weak signal. Both sales were kept — which is exactly why the app
> can tell you the shelf count is now wrong. The fix is to count the shelf. There
> is no button to make the number disappear, on purpose: that would hide a real
> problem.

---

## 10 — Removing a phone

On Phone A, tap Phone B's row → `إزالة`.

**You should see:**

- The row disappears, the count goes back to `1 من 3`
- On Phone B, press `مزامنة الآن` → B says it was removed and offers the join
  screen again
- **Phone B still has all the shop data.** Removing a phone stops it sharing; it
  does not erase it

Then join B again with a new code, to be sure the way back in still works.

---

## When something fails

Every unknown failure shows the same Arabic message:
**`حدث خطأ. حاول مرة أخرى`**. That message cannot tell you if the problem is the
network, the server, the token, or the app.

**Long-press the sync row** — the row with the `مزامنة الآن` button. A dialog
opens with the real reason: the error name and the server's own message or HTTP
number. Press `نسخ` to copy it.

Copy that text and keep it. It is the difference between one fix and a day of
guessing.

### Common causes

| What you see | What it usually means |
|---|---|
| `اشتراكك لا يشمل أجهزة إضافية` | The subscription on that phone does not allow sync |
| `استخدمت كل الأجهزة المسموح بها` | All 3 seats are used. Remove one first |
| `الرمز غير صحيح أو مستخدم أو منتهي الصلاحية` | The code is single use and lasts a few minutes. Make a new one |
| `لا يوجد اتصال` | No internet. The app will retry by itself |
| `حدث خطأ. حاول مرة أخرى` + `NOT_FOUND` in the detail | A server address problem. Send the detail to evotech-core |
| Phone B joined but the shop is **empty** | The shop copy did not arrive. Report this in full |

---

## What this test cannot cover

- **A phone that is closed does not sync.** Sync only runs while the app is open.
  This is a deliberate choice — background work on Android is unreliable and
  phone makers kill it. A till that is shut catches up when it is opened. Do not
  report this as a bug.
- **A third phone.** The plan allows 3, but only two phones are available.
- **The 60-day limit.** The server deletes its change log after 60 days. A shop
  that started today has nothing old enough to trigger it.
