package com.mohamad.hasan.it.fawateer;

import android.content.Intent;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

/**
 * FlutterFragmentActivity, not FlutterActivity: the `local_auth` plugin shows
 * the system biometric prompt as an AndroidX fragment, so on a plain
 * FlutterActivity every fingerprint attempt fails at runtime with
 * "no_fragment_activity". Nothing else in the app depends on the difference.
 */
public class MainActivity extends FlutterFragmentActivity {

    /** See {@link com.mohamad.hasan.it.fawateer.MainActivity#restart()}. */
    private static final String CHANNEL = "fawateer/app_restart";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if ("restart".equals(call.method)) {
                        result.success(null);
                        restart();
                    } else {
                        result.notImplemented();
                    }
                });
    }

    /**
     * Relaunch the app, replacing the current process.
     *
     * Restoring a database (a Drive restore, or the bootstrap snapshot a joining
     * phone receives) closes the SQLite connection and swaps the file underneath
     * it. Nothing in Dart can reopen it: {@code AppDatabase} is a GetIt singleton
     * and every app-wide BLoC is already holding a stream from the dead
     * connection. So the app genuinely has to start over — the only question is
     * whether the shopkeeper has to do it by hand.
     *
     * They did, and it read as a crash: a POS that closes itself and sits on the
     * launcher after an operation the owner was told had succeeded.
     *
     * {@code makeRestartActivityTask} builds the same intent the launcher icon
     * sends, on a fresh task with the old one cleared, so the relaunched app
     * cannot come back to a screen holding the closed database.
     * {@code Runtime.exit(0)} rather than {@code finish()} because the process
     * must actually die: Flutter caches the engine and the Drift isolate, and a
     * warm restart would reattach both to the file that is no longer there.
     */
    private void restart() {
        Intent launch = getPackageManager().getLaunchIntentForPackage(getPackageName());
        if (launch == null || launch.getComponent() == null) {
            // No launcher entry to return to. Falling back to a plain exit is
            // exactly the old behaviour, which is a worse experience but never
            // a wrong one — the user reopens the app themselves.
            Runtime.getRuntime().exit(0);
            return;
        }
        startActivity(Intent.makeRestartActivityTask(launch.getComponent()));
        Runtime.getRuntime().exit(0);
    }
}
