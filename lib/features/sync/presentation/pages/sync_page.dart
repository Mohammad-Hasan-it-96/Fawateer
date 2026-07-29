import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_snack.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/join_token.dart';
import '../../domain/entities/sync_outcome.dart';
import '../../domain/sync_error.dart';
import '../bloc/sync_bloc.dart';

/// Settings → Devices & sync (Plan 002).
///
/// **The wording avoids the word "sync" wherever it can.** The shopkeeper's
/// model is "my two phones show the same shop", not replication, cursors or
/// conflict resolution — so the copy talks about phones and the shop, and the
/// owner/member split is presented as "main phone" / "linked phone" rather than
/// as roles. There is no permission system behind it to explain (Plan 002 Q4
/// was reduced to ownership of the subscription, not a permission matrix).
class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  @override
  void initState() {
    super.initState();
    // Dispatched here rather than in the route's `create:` — same as
    // `BackupPage`. Reading app_routes.dart alone makes it look like nothing
    // loads; this comment is the pointer.
    context.read<SyncBloc>().add(const LoadSyncStatus());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncTitle)),
      body: BlocConsumer<SyncBloc, SyncState>(
        listenWhen: (a, b) => a.error != b.error || a.message != b.message,
        listener: (context, state) {
          final text = _feedbackText(l10n, state);
          if (text == null) return;
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(
              content: Text(text),
              behavior: SnackBarBehavior.floating,
              backgroundColor:
                  state.error != null ? Theme.of(context).colorScheme.error : null,
              duration: AppSnackDuration.normal,
            ));
          context.read<SyncBloc>().add(const ClearSyncFeedback());
        },
        builder: (context, state) {
          if (!state.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return AbsorbPointer(
            absorbing: state.busy,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.busy) const LinearProgressIndicator(),
                if (state.isEnrolled)
                  ..._enrolled(context, l10n, state)
                else
                  ..._notEnrolled(context, l10n),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── not enrolled ───────────────────────────────────────────────────────────

  List<Widget> _notEnrolled(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.syncPitchTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(l10n.syncPitchBody, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      // Which phone is which is the one thing a shopkeeper can get wrong here,
      // and getting it wrong on the phone that holds the data is the expensive
      // direction. So each action carries its own "choose this on the … phone".
      FilledButton.icon(
        icon: const Icon(Icons.phonelink_setup),
        label: Text(l10n.syncEnableAction),
        onPressed: () =>
            context.read<SyncBloc>().add(const EnableSyncAsOwner()),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 20),
        child: Text(l10n.syncEnableHint, style: theme.textTheme.bodySmall),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(l10n.syncJoinAction),
        onPressed: () => _promptForCode(context, l10n),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(l10n.syncJoinHint, style: theme.textTheme.bodySmall),
      ),
    ];
  }

  // ── enrolled ───────────────────────────────────────────────────────────────

  List<Widget> _enrolled(
      BuildContext context, AppLocalizations l10n, SyncState state) {
    final theme = Theme.of(context);
    final session = state.session!;
    return [
      Card(
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                session.isOwner ? Icons.smartphone : Icons.phonelink,
                color: theme.colorScheme.primary,
              ),
              title: Text(session.isOwner
                  ? l10n.syncStatusOwner
                  : l10n.syncStatusMember),
              subtitle: Text(l10n.syncDevicesUsed(session.deviceAllowance)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.sync),
              title: Text(state.lastSyncAt == null
                  ? l10n.syncNever
                  : l10n.syncLastAt(_formatWhen(l10n, state.lastSyncAt!))),
              subtitle: _outcomeLine(l10n, state.outcome),
              trailing: TextButton(
                onPressed: state.busy
                    ? null
                    : () =>
                        context.read<SyncBloc>().add(const SyncNowRequested()),
                child: Text(l10n.syncNowAction),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      // Only the main phone can invite another. A linked phone showing this
      // button would be offering something the server will refuse.
      if (session.isOwner) ...[
        if (state.joinToken != null)
          _JoinCodeCard(token: state.joinToken!)
        else
          FilledButton.icon(
            icon: const Icon(Icons.add_to_home_screen),
            label: Text(l10n.syncAddDeviceAction),
            onPressed: () =>
                context.read<SyncBloc>().add(const MintJoinTokenRequested()),
          ),
        const SizedBox(height: 24),
      ],
      TextButton.icon(
        icon: Icon(Icons.link_off, color: theme.colorScheme.error),
        label: Text(l10n.syncLeaveAction,
            style: TextStyle(color: theme.colorScheme.error)),
        onPressed: () => _confirmLeave(context, l10n),
      ),
    ];
  }

  Widget? _outcomeLine(AppLocalizations l10n, SyncOutcome? outcome) {
    if (outcome == null) return null;
    // "Nothing moved" is a success, not silence — a button that appears to do
    // nothing is the fastest way to make a working feature look broken.
    if (!outcome.didWork && outcome.isSuccess) return Text(l10n.syncUpToDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.syncMovedCounts(outcome.pushed, outcome.pulled)),
        if (outcome.rejected > 0)
          Text(l10n.syncPendingRejected(outcome.rejected)),
      ],
    );
  }

  // ── actions ────────────────────────────────────────────────────────────────

  Future<void> _promptForCode(
      BuildContext context, AppLocalizations l10n) async {
    final bloc = context.read<SyncBloc>();
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.syncEnterCodeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.syncEnterCodeLabel),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            // Reuses the existing top-level scanner route, the same one the
            // product pages push for a barcode.
            TextButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l10n.syncEnterCodeScan),
              onPressed: () async {
                final scanned =
                    await dialogContext.push<String>('/scanner');
                if (scanned != null && scanned.isNotEmpty) {
                  controller.text = scanned;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.syncEnterCodeConfirm),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code != null && code.isNotEmpty) bloc.add(JoinWithToken(code));
  }

  Future<void> _confirmLeave(
      BuildContext context, AppLocalizations l10n) async {
    final bloc = context.read<SyncBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.syncLeaveTitle),
        // Says plainly that nothing is deleted. Unlinking looks destructive and
        // is not; a shopkeeper who assumes it wipes the till will never use it,
        // and one who assumes it wipes the *other* till might.
        content: Text(l10n.syncLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.syncLeaveConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) bloc.add(const LeaveSyncRequested());
  }

  // ── typed → localized ──────────────────────────────────────────────────────

  String? _feedbackText(AppLocalizations l10n, SyncState state) {
    final error = state.error;
    if (error != null) return syncErrorText(l10n, error);
    return switch (state.message) {
      SyncMessage.enabled => l10n.syncEnabledMessage,
      SyncMessage.joined => l10n.syncJoinedMessage,
      SyncMessage.left => l10n.syncLeftMessage,
      SyncMessage.synced => null, // the status line already says what happened
      null => null,
    };
  }

  /// Time of day only. The last sync is minutes-to-hours old in every case
  /// that matters, and a full date would push the line onto two lines in Arabic
  /// for information nobody reads.
  static String _formatWhen(AppLocalizations l10n, DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(at.hour)}:${two(at.minute)}';
  }
}

/// Maps the typed [SyncError] to ARB. Lives beside the page, following the
/// app's rule that no BLoC ever holds user-facing English.
String syncErrorText(AppLocalizations l10n, SyncError error) =>
    switch (error) {
      SyncError.subscriptionRequired => l10n.syncErrorSubscription,
      SyncError.allowanceExceeded => l10n.syncErrorAllowance,
      SyncError.invalidJoinToken => l10n.syncErrorJoinToken,
      SyncError.fallbackDeviceRejected => l10n.syncErrorFallbackDevice,
      SyncError.offline => l10n.syncErrorOffline,
      SyncError.server => l10n.syncErrorServer,
    };

/// The invitation, as a QR to scan and as text to type.
///
/// Both, always. A shop phone with a cracked lens or a screen too scratched to
/// scan still has to be able to join — Plan 002 Q2 keeps a typed fallback for
/// exactly that, and a QR-only screen would strand those shops.
class _JoinCodeCard extends StatelessWidget {
  const _JoinCodeCard({required this.token});

  final JoinToken token;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final remaining = token.remainingAt(DateTime.now());
    final expired = remaining == Duration.zero;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(l10n.syncJoinCodeTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            if (!expired)
              // White plate behind the QR regardless of theme: a dark-mode QR
              // drawn on a dark surface is unreadable to every scanner.
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: CustomPaint(
                  size: const Size(180, 180),
                  painter: _QrPainter(token.token),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              expired
                  ? l10n.syncJoinCodeExpired
                  : l10n.syncJoinCodeExpires(remaining.inMinutes + 1),
              style: theme.textTheme.bodySmall?.copyWith(
                color: expired ? theme.colorScheme.error : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.syncJoinCodeManual, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            SelectableText(
              token.token,
              // Forced LTR: the code is opaque ASCII and would otherwise be
              // reordered by the Arabic layout and typed back in wrongly.
              textDirection: TextDirection.ltr,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontFamily: 'monospace', letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(l10n.syncCopyCode),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: token.token));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(SnackBar(
                        content: Text(l10n.syncJoinCodeCopied),
                        behavior: SnackBarBehavior.floating,
                        duration: AppSnackDuration.brief,
                      ));
                  },
                ),
                TextButton(
                  onPressed: () =>
                      context.read<SyncBloc>().add(const DismissJoinToken()),
                  child: Text(l10n.syncJoinCodeDone),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a QR with the pure-Dart `barcode` package — the same library
/// `LabelImage` rasterizes for thermal labels, so the app carries no second QR
/// dependency and no platform channel.
class _QrPainter extends CustomPainter {
  const _QrPainter(this.data);

  final String data;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    for (final element in Barcode.qrCode()
        .make(data, width: size.width, height: size.height, drawText: false)) {
      if (element is BarcodeBar && element.black) {
        canvas.drawRect(
          Rect.fromLTWH(element.left, element.top, element.width, element.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) => oldDelegate.data != data;
}
