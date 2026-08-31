import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sync/device_label.dart';
import '../../../../core/utils/app_snack.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/bootstrap_service.dart';
import '../../domain/entities/join_invite.dart';
import '../../domain/entities/sync_device.dart';
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
        listenWhen: (a, b) =>
            a.error != b.error ||
            a.message != b.message ||
            a.restartRequired != b.restartRequired,
        listener: (context, state) {
          if (state.restartRequired) {
            _showRestartDialog(context, l10n);
            return;
          }
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
                // Preparing an invite is a sync, a vacuum and a multi-megabyte
                // upload. On a shop's 3G that is long enough that a bare
                // spinner reads as a hang, so it says which part is running.
                if (state.step != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _stepText(l10n, state.step!),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
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
              // What the role means, not the seat count — the count lives on
              // the registry card, next to the list it describes, and stating
              // it twice a few dp apart reads as two different figures.
              //
              // The allowance itself is only ever sent to the owner, so a
              // member's cached copy is 0; this used to render as "Devices
              // allowed: 0" on every linked phone.
              subtitle: Text(session.isOwner
                  ? l10n.syncStatusOwnerHint
                  : l10n.syncStatusMemberHint),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.sync),
              // A long press is deliberately the only way in. The detail is
              // untranslated server text — worthless to a shopkeeper, and the
              // one thing that saves a support round trip when the localized
              // message is the "something went wrong" catch-all. Hiding it
              // costs nothing; not having it cost a field test.
              onLongPress: () => _showErrorDetail(context, l10n, state),
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
        _registry(context, l10n, state),
        const SizedBox(height: 16),
        if (state.invite != null)
          _JoinCodeCard(invite: state.invite!)
        else ...[
          FilledButton.icon(
            icon: const Icon(Icons.add_to_home_screen),
            label: Text(l10n.syncAddDeviceAction),
            // Kept visible and disabled, not hidden. Elsewhere on this screen an
            // action the server would refuse is hidden — but "add a phone"
            // vanishing is exactly what an owner at their cap would read as the
            // feature being broken, and the reason is something they can act on.
            onPressed: state.isAtCap
                ? null
                : () =>
                    context.read<SyncBloc>().add(const MintJoinTokenRequested()),
          ),
          // Only ever shown on a registry we actually read (`isAtCap` is false
          // on an unknown allowance). The server still refuses at mint — this
          // spares the owner a doomed round trip and a red error for something
          // predictable, it does not replace the enforcement.
          if (state.isAtCap)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.syncAtCapHint(state.allowance!),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error)),
            ),
        ],
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

  // ── device registry (owner only) ───────────────────────────────────────────

  /// The seats in this business, and the owner's one destructive action.
  ///
  /// Rendered inline **above** "add a phone" rather than on a screen of its own:
  /// the question "can I add another?" is answered by the list, so putting the
  /// list behind a tap means the owner mints a code, is refused for the
  /// allowance, and only then goes looking for what is using it.
  ///
  /// A failed fetch degrades to a retry line instead of an empty list. Empty and
  /// unreachable look identical otherwise, and "no phones are using this shop"
  /// is a lie an offline owner would act on.
  Widget _registry(
      BuildContext context, AppLocalizations l10n, SyncState state) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.syncDevicesTitle,
                          style: theme.textTheme.titleMedium),
                      // "2 of 3 used" is the answer to "can I add another?".
                      // It degrades rather than disappearing: with no registry
                      // yet it states the limit alone, never a used-count of
                      // zero read off a list that simply has not loaded.
                      Text(_allowanceLine(l10n, state),
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (state.devicesLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          if (state.devicesError != null && state.devices.isEmpty)
            ListTile(
              subtitle: Text(l10n.syncDevicesUnavailable,
                  style: theme.textTheme.bodySmall),
              trailing: TextButton(
                onPressed: () =>
                    context.read<SyncBloc>().add(const LoadDevicesRequested()),
                child: Text(l10n.syncDevicesRetry),
              ),
            )
          else
            for (final device in state.devices)
              _deviceTile(context, l10n, state, device),
        ],
      ),
    );
  }

  Widget _deviceTile(BuildContext context, AppLocalizations l10n,
      SyncState state, SyncDevice device) {
    final theme = Theme.of(context);
    final busy = state.revoking == device.uuid;
    final renaming = state.renaming == device.uuid;
    final named = device.label != null;
    return ListTile(
      leading: Icon(device.role.isOwner ? Icons.smartphone : Icons.phonelink),
      // The whole row opens the rename sheet. Every row in this list belongs to
      // a business whose registry only the owner can read, so if you can see a
      // row you may rename it — no second permission check is needed, and the
      // owner's own phone is renameable too (it is a till like any other).
      onTap: state.renaming != null
          ? null
          : () => _openRename(context, l10n, device),
      title: Row(
        children: [
          Flexible(
            child: Text(
              device.label ??
                  (device.role.isOwner
                      ? l10n.syncStatusOwner
                      : l10n.syncStatusMember),
              overflow: TextOverflow.ellipsis,
              // An unnamed row is shown in the role's words but styled as the
              // placeholder it is, so "الجهاز الرئيسي" cannot be mistaken for a
              // name somebody chose.
              style: named
                  ? null
                  : TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
          ),
          const SizedBox(width: 6),
          if (renaming)
            const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            Icon(Icons.edit_outlined,
                size: 14, color: theme.textTheme.bodySmall?.color),
        ],
      ),
      // A name says WHICH phone this is; last-seen says whether it is still
      // working. Both are needed, so this line stays even on a named row.
      subtitle: Text(_seenText(l10n, device.lastSeenAt),
          style: theme.textTheme.bodySmall),
      trailing: busy
          ? const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : device.isCurrent
              // A badge, not a disabled button: the owner is looking for which
              // row is safe to remove, and greyed-out text still reads as an
              // action that failed.
              ? Chip(
                  label: Text(l10n.syncDeviceThis),
                  visualDensity: VisualDensity.compact)
              : device.isRevocable
                  ? TextButton(
                      onPressed: state.revoking != null
                          ? null
                          : () => _confirmRevoke(context, l10n, device),
                      child: Text(l10n.syncRevokeAction,
                          style: TextStyle(color: theme.colorScheme.error)),
                    )
                  // The owner seat on another device — refused server-side
                  // (2026-07-29 R1), so it is never offered here either.
                  : Text(l10n.syncDeviceOwnerNote,
                      style: theme.textTheme.bodySmall),
    );
  }

  Future<void> _openRename(BuildContext context, AppLocalizations l10n,
      SyncDevice device) async {
    final bloc = context.read<SyncBloc>();
    final name = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RenameSheet(device: device, l10n: l10n),
    );
    // null = dismissed. An empty string is a real answer — it clears the name —
    // so the two cannot be collapsed into one falsy check.
    if (name == null) return;
    bloc.add(RenameDeviceRequested(device.uuid, name));
  }

  Future<void> _confirmRevoke(BuildContext context, AppLocalizations l10n,
      SyncDevice device) async {
    final bloc = context.read<SyncBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.syncRevokeTitle),
        // States what revoking does *and* what it does not: the other phone
        // keeps its copy of the books, and nothing here can erase it
        // (2026-07-29 R2). An owner who believes this wipes a stolen tablet
        // will not take the other steps that actually protect them.
        content: Text(l10n.syncRevokeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.syncRevokeConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) bloc.add(RevokeDeviceRequested(device.uuid));
  }

  /// "2 of 3 phones used", degrading honestly as information runs out.
  ///
  /// Three cases, and conflating any two of them states something false:
  ///  - both known → the count that answers "can I add another?";
  ///  - a limit but no registry (offline, or the fetch has not landed) → the
  ///    limit alone. Filling in a used-count of 0 would tell an owner with three
  ///    linked phones that they have none;
  ///  - a registry but no stated limit → the count alone, and nothing is gated.
  static String _allowanceLine(AppLocalizations l10n, SyncState state) {
    final limit = state.allowance;
    final registry = state.registry;
    if (registry == null) {
      return limit == null ? '' : l10n.syncDevicesAllowed(limit);
    }
    if (limit == null) return l10n.syncDevicesCount(registry.used);
    return l10n.syncDevicesUsed(registry.used, limit);
  }

  /// Coarse buckets, deliberately. The owner is asking "is this the one that
  /// left the shop?", which minutes-vs-days answers and a timestamp does not.
  static String _seenText(AppLocalizations l10n, DateTime? at) {
    if (at == null) return l10n.syncDeviceSeenNever;
    final ago = DateTime.now().difference(at);
    if (ago.inMinutes < 2) return l10n.syncDeviceSeenJustNow;
    if (ago.inHours < 1) return l10n.syncDeviceSeenMinutes(ago.inMinutes);
    if (ago.inHours < 24) return l10n.syncDeviceSeenHours(ago.inHours);
    return l10n.syncDeviceSeenDays(ago.inDays);
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
        // Stated, not actioned. There is no resolution screen behind this yet
        // (`GET /sync/conflicts` is in the contract but its response shape is
        // unpinned), and a count the owner can see is what keeps that a known
        // gap rather than an invisible one. The rows themselves landed — the
        // last write is what both phones will show.
        if (outcome.conflicts > 0)
          Text(l10n.syncConflicts(outcome.conflicts)),
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

  /// The joining device has just had its database replaced, so SQLite is closed
  /// and every screen behind this dialog would throw on its first query.
  ///
  /// Non-dismissible with a single action, exactly like `BackupPage`'s restore —
  /// and for the same reason: letting the shopkeeper tap past it drops them into
  /// a POS whose every query fails, which from behind the counter looks precisely
  /// like the app destroyed their shop.
  Future<void> _showRestartDialog(
      BuildContext context, AppLocalizations l10n) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(l10n.syncRestartTitle),
          content: Text(l10n.syncRestartBody),
          actions: [
            FilledButton(
              onPressed: () => SystemNavigator.pop(),
              child: Text(l10n.syncRestartConfirm),
            ),
          ],
        ),
      ),
    );
  }

  // ── typed → localized ──────────────────────────────────────────────────────

  static String _stepText(AppLocalizations l10n, BootstrapStep step) =>
      switch (step) {
        BootstrapStep.syncing => l10n.syncStepSyncing,
        BootstrapStep.snapshotting => l10n.syncStepSnapshotting,
        BootstrapStep.uploading => l10n.syncStepUploading,
      };

  /// The last technical failure, verbatim and copyable.
  ///
  /// Shows the typed error's own name beside the server's text: the two answer
  /// different questions — which branch the app took, and what the server
  /// actually said — and a report carrying only one of them is usually the
  /// wrong one.
  static Future<void> _showErrorDetail(
      BuildContext context, AppLocalizations l10n, SyncState state) async {
    // Read from `errorDetail` alone. It already carries its own typed error
    // name (`SyncBloc._detailOf`), and pairing it with the live `state.error`
    // here is what used to force the detail to be thrown away with the
    // snackbar — which left this dialog permanently empty.
    final body = state.errorDetail ?? l10n.syncErrorDetailNone;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.syncErrorDetailTitle),
        content: SelectableText(
          body,
          // Forced LTR: this is ASCII diagnostic text (URLs, HTTP codes), and
          // the Arabic layout reorders it into something that cannot be read
          // back or retyped — the same reason the join code is forced LTR.
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: body));
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(SnackBar(
                  content: Text(l10n.copied),
                  behavior: SnackBarBehavior.floating,
                ));
            },
            child: Text(l10n.copy),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  String? _feedbackText(AppLocalizations l10n, SyncState state) {
    final error = state.error;
    if (error != null) return syncErrorText(l10n, error);
    return switch (state.message) {
      SyncMessage.enabled => l10n.syncEnabledMessage,
      SyncMessage.joined => l10n.syncJoinedMessage,
      SyncMessage.left => l10n.syncLeftMessage,
      SyncMessage.deviceRevoked => l10n.syncRevokedMessage,
      SyncMessage.deviceRenamed => l10n.syncRenamedMessage,
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
      SyncError.deviceRevoked => l10n.syncErrorRevoked,
      SyncError.ownerOnly => l10n.syncErrorOwnerOnly,
      SyncError.cursorTooOld => l10n.syncErrorTooFarBehind,
      SyncError.offline => l10n.syncErrorOffline,
      SyncError.server => l10n.syncErrorServer,
    };

/// The invitation, as a QR to scan and as text to type.
///
/// Both, always. A shop phone with a cracked lens or a screen too scratched to
/// scan still has to be able to join — Plan 002 Q2 keeps a typed fallback for
/// exactly that, and a QR-only screen would strand those shops.
class _JoinCodeCard extends StatelessWidget {
  const _JoinCodeCard({required this.invite});

  final JoinInvite invite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final token = invite.token;
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
                  // The QR carries the snapshot's hash alongside the token; the
                  // typed code below cannot, and says so.
                  painter: _QrPainter(invite.encode()),
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
            // Scanning carries the snapshot's fingerprint; a typed code cannot
            // (nobody keys in 64 hex characters), so the joining device has to
            // trust the server's word on the file instead of the owner's. Worth
            // one line of nudge, not a warning — the typed path is legitimate
            // and exists because a cracked lens is common in this trade.
            if (invite.hasSnapshot)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(l10n.syncJoinCodePreferScan,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
              ),
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

/// Name one phone in the shop's device list.
///
/// A sheet rather than an `AlertDialog` because the keyboard is up the whole
/// time it is open, and a dialog with a raised keyboard leaves the field behind
/// the keys on a short screen.
///
/// **Returns `''` to clear the name and `null` when dismissed.** Those are
/// different answers: one is a decision the owner made, the other is them
/// changing their mind, and collapsing them would make Cancel silently erase a
/// name.
class _RenameSheet extends StatefulWidget {
  const _RenameSheet({required this.device, required this.l10n});

  final SyncDevice device;
  final AppLocalizations l10n;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.device.label ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    return Padding(
      // Lift the sheet above the keyboard; without this the Save button sits
      // under it and the owner has to dismiss the keyboard to find it.
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.syncRenameTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.syncRenameHelp, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            // Capped where the owner can see it stop, not silently on save —
            // the server enforces the same 40 and would otherwise hand back a
            // shortened name with no explanation of what shortened it.
            maxLength: kDeviceNameMaxLength,
            decoration: InputDecoration(
              labelText: l10n.syncRenameLabel,
              hintText: l10n.syncRenameHint,
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_controller.text),
                child: Text(l10n.syncRenameSave),
              ),
            ],
          ),
        ],
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
