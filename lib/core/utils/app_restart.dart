import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Relaunches the app after its database has been replaced.
///
/// **Why the app has to restart at all.** A restore — a Drive backup, or the
/// bootstrap snapshot a joining phone receives — closes the SQLite connection
/// and swaps the file underneath it. Nothing in Dart can recover from that:
/// `AppDatabase` is a GetIt singleton and every app-wide BLoC is already holding
/// a stream from the dead connection, so the process genuinely has to start
/// over. Plan 001 said as much and left it there.
///
/// What it left there was a POS that closes itself and drops the shopkeeper on
/// the launcher, seconds after telling them the operation succeeded. That reads
/// as a crash, which is the worst possible ending for the one operation where
/// the owner most needs to believe their data is safe.
///
/// So the dialog now relaunches instead of only exiting. The restart is native
/// ([MainActivity.restart]) because Flutter cannot relaunch its own process:
/// `SystemNavigator.pop()` finishes the activity, and the engine and the Drift
/// isolate are cached, so anything short of killing the process would reattach
/// to the file that is no longer there.
///
/// **It always ends the app, one way or the other.** If the channel is missing
/// (an older build, or a platform with no implementation) it falls back to the
/// previous behaviour rather than leaving the user in an app whose database is
/// gone — a manual reopen is a worse experience, never a wrong one.
class AppRestart {
  const AppRestart._();

  static const MethodChannel _channel = MethodChannel('fawateer/app_restart');

  /// Kill this process and start the app again. Never returns on success.
  static Future<void> now() async {
    try {
      await _channel.invokeMethod<void>('restart');
    } catch (e) {
      if (kDebugMode) debugPrint('[restart] native restart unavailable: $e');
      await SystemNavigator.pop();
    }
  }
}
