import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_restart.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/sync_bloc.dart';
import 'sync_page.dart' show syncErrorText;

/// First-run "link this phone to a shop that already exists".
///
/// The same join the Settings screen performs, asked at the one moment the
/// shopkeeper is actually holding both phones. It is a separate page rather
/// than a dialog because this is the whole task on this screen — and because
/// what follows is a database restore and a restart, which is not a thing to
/// run out of a bottom sheet the user may have opened by accident.
///
/// **It deliberately does not register the device first.** A joining phone has
/// no name and no number of its own to give, and the shop it is joining is
/// already registered by its owner; inventing values to satisfy
/// `create_device` would put fabricated contact details on a real support
/// record. The seat carries the licence instead: the owner's subscription
/// covers it (ADR 0011 Decision 2 — one subscription, N devices), and enrolling
/// links the device to the business server-side, creating its
/// `device_subscriptions` row with name and phone **null** and no trial of its
/// own. Confirmed and implemented by evotech-core on 2026-09-01
/// (`docs/backend-replies/2026-09-01-evotech-core-reply-seat-licence-coverage.txt`).
///
/// The client half of that is **not on this page** — it is
/// `LicenseBloc.isLinkedMember`. A phone that comes through here has no cached
/// agent name, and the licence check used to read that as "brand-new install,
/// skip the server poll entirely". So it would never have asked, and the whole
/// backend change would have looked like it did nothing.
class JoinShopPage extends StatefulWidget {
  const JoinShopPage({super.key});

  @override
  State<JoinShopPage> createState() => _JoinShopPageState();
}

class _JoinShopPageState extends State<JoinShopPage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<SyncBloc>().add(JoinWithToken(code));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocConsumer<SyncBloc, SyncState>(
      listenWhen: (a, b) =>
          a.error != b.error || a.restartRequired != b.restartRequired,
      listener: (context, state) {
        // The snapshot has replaced the database and SQLite is closed. Nothing
        // on this screen works from here — only a restart does.
        if (state.restartRequired) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => PopScope(
              canPop: false,
              child: AlertDialog(
                title: Text(l10n.syncRestartTitle),
                content: Text(l10n.syncRestartBody),
                actions: [
                  FilledButton(
                    onPressed: AppRestart.now,
                    child: Text(l10n.syncRestartConfirm),
                  ),
                ],
              ),
            ),
          );
          return;
        }
        final error = state.error;
        if (error == null) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(syncErrorText(l10n, error)),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ));
        context.read<SyncBloc>().add(const ClearSyncFeedback());
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.welcomeJoinTitle)),
          body: AbsorbPointer(
            absorbing: state.busy,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (state.busy) const LinearProgressIndicator(),
                const SizedBox(height: 8),
                // Says where the code comes from. Without it the shopkeeper is
                // looking at a text field for a thing they have never seen and
                // do not know exists.
                Text(l10n.joinShopHowTo,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(l10n.syncEnterCodeScan),
                    onPressed: () async {
                      final scanned = await context.push<String>('/scanner');
                      if (!context.mounted ||
                          scanned == null ||
                          scanned.isEmpty) {
                        return;
                      }
                      _code.text = scanned;
                      if (context.mounted) _submit(context);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(l10n.joinShopOrType,
                        style: theme.textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 20),
                TextField(
                  controller: _code,
                  decoration: InputDecoration(
                    labelText: l10n.syncEnterCodeLabel,
                    border: const OutlineInputBorder(),
                  ),
                  // An opaque ASCII code reordered by the Arabic layout gets
                  // typed back in wrongly — same rule as the owner's QR text.
                  textDirection: TextDirection.ltr,
                  onSubmitted: (_) => _submit(context),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: state.busy ? null : () => _submit(context),
                  child: Text(l10n.syncEnterCodeConfirm),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
