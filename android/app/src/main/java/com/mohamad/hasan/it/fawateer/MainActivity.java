package com.mohamad.hasan.it.fawateer;

import io.flutter.embedding.android.FlutterFragmentActivity;

/**
 * FlutterFragmentActivity, not FlutterActivity: the `local_auth` plugin shows
 * the system biometric prompt as an AndroidX fragment, so on a plain
 * FlutterActivity every fingerprint attempt fails at runtime with
 * "no_fragment_activity". Nothing else in the app depends on the difference.
 */
public class MainActivity extends FlutterFragmentActivity {
}
