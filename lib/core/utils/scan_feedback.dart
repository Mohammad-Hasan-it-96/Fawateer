import 'package:audioplayers/audioplayers.dart';

/// The audible confirmation that a barcode was read.
///
/// A cashier scanning a queue of items is looking at the goods, not the screen —
/// the beep is the only signal that a scan landed, which is why every hardware
/// scanner has one. Pairs with the existing haptic in `home_page`.
///
/// Deliberately **fire-and-forget and failure-silent**: a device with no audio
/// route, a muted stream, or an OS that refuses the player must never interrupt
/// a sale. The scan itself is the thing that matters; the beep is feedback.
class ScanFeedback {
  ScanFeedback._();

  static final AudioPlayer _player = AudioPlayer(playerId: 'scan_beep')
    // Reuses one player instance: constructing one per scan leaks native
    // resources when scanning fast, which is the normal case at a counter.
    ..setReleaseMode(ReleaseMode.stop);

  static bool _configured = false;

  /// Plays the beep. Safe to call on every detection, including rapid repeats.
  static Future<void> beep() async {
    try {
      if (!_configured) {
        // `AudioContextConfig(route: AudioRoute.system)` keeps this on the
        // notification/system stream rather than media, so it doesn't duck or
        // pause whatever the user is playing.
        await _player.setAudioContext(
          AudioContextConfig(
            focus: AudioContextConfigFocus.mixWithOthers,
          ).build(),
        );
        _configured = true;
      }
      // stop() first so a second scan retriggers from the start instead of
      // being ignored while the first is still playing.
      await _player.stop();
      await _player.play(AssetSource('sounds/beep.wav'), volume: 1.0);
    } catch (_) {
      // Intentionally swallowed — see the class doc.
    }
  }
}
