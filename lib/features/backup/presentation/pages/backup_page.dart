import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/backup_info.dart';
import '../bloc/backup_bloc.dart';

/// Map a [Failure] to a localized, user-facing message (no English in the BLoC).
String _errorText(Failure f, AppLocalizations l10n) {
  if (f is NetworkFailure) return l10n.backupErrorNetwork;
  if (f is ServerFailure) return l10n.backupErrorServer;
  if (f is PermissionFailure) return l10n.backupErrorSignIn;
  if (f is IncompatibleFailure) {
    // 'schema_too_new' → update the app; anything else here → corrupt file.
    return f.message == 'schema_too_new'
        ? l10n.backupErrorIncompatibleNew
        : l10n.backupErrorCorrupt;
  }
  return l10n.backupErrorUnknown;
}

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  @override
  void initState() {
    super.initState();
    context.read<BackupBloc>().add(const BackupStatusRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: BlocConsumer<BackupBloc, BackupState>(
        listenWhen: (p, c) =>
            p.error != c.error ||
            p.success != c.success ||
            p.exportedFile != c.exportedFile,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.error != null) {
            messenger.showSnackBar(SnackBar(
              content: Text(_errorText(state.error!, l10n)),
              backgroundColor: Colors.red,
            ));
          }
          switch (state.success) {
            case BackupSuccess.backedUp:
              messenger.showSnackBar(SnackBar(
                content: Text(l10n.backupSuccessBackedUp),
                backgroundColor: Colors.green,
              ));
            case BackupSuccess.exported:
              messenger.showSnackBar(SnackBar(
                content: Text(l10n.backupSuccessExported),
                backgroundColor: Colors.green,
              ));
              final f = state.exportedFile;
              if (f != null) {
                Share.shareXFiles([XFile(f.path)], subject: l10n.backupTitle);
              }
            case BackupSuccess.restored:
              _showRestartDialog(context, l10n);
            case null:
              break;
          }
        },
        builder: (context, state) {
          return AbsorbPointer(
            absorbing: state.isBusy,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.isBusy) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                ],
                if (!state.signedIn)
                  _signInCard(context, l10n, state)
                else
                  _signedInSection(context, l10n, state),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Signed-out ─────────────────────────────────────────────────────────
  Widget _signInCard(
      BuildContext context, AppLocalizations l10n, BackupState state) {
    final bloc = context.read<BackupBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          child: Column(
            children: [
              const Icon(Icons.cloud_upload_outlined,
                  size: 56, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(l10n.backupSignInPrompt,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor),
                  icon: const Icon(Icons.login),
                  label: Text(l10n.backupSignInButton),
                  onPressed: () => bloc.add(const BackupSignInRequested()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          icon: const Icon(Icons.ios_share),
          label: Text(l10n.backupExportButton),
          onPressed: () => bloc.add(const BackupExportRequested()),
        ),
      ],
    );
  }

  // ── Signed-in ──────────────────────────────────────────────────────────
  Widget _signedInSection(
      BuildContext context, AppLocalizations l10n, BackupState state) {
    final bloc = context.read<BackupBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Account + last-backup status.
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.backupAccountLabel,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                        Text(state.email ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => bloc.add(const BackupSignOutRequested()),
                    child: Text(l10n.backupSignOut),
                  ),
                ],
              ),
              const Divider(height: 24),
              _lastBackupLine(l10n, state.lastBackupAt),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            style:
                FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            icon: const Icon(Icons.backup),
            label: Text(state.busy == BackupBusy.backingUp
                ? l10n.backupBusyBackingUp
                : l10n.backupNowButton),
            onPressed: () => bloc.add(const BackupNowRequested()),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.ios_share),
          label: Text(l10n.backupExportButton),
          onPressed: () => bloc.add(const BackupExportRequested()),
        ),
        const SizedBox(height: 16),
        Text(l10n.backupListTitle,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        if (state.loadingList)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator()))
        else if (state.backups.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.backupListEmpty,
                style: TextStyle(color: Colors.grey[500])),
          )
        else
          ...state.backups.map((b) => _backupTile(context, l10n, b)),
      ],
    );
  }

  Widget _lastBackupLine(AppLocalizations l10n, DateTime? at) {
    if (at == null) {
      return Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.backupNever,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      );
    }
    final days = DateTime.now().difference(at).inDays;
    final color = days == 0
        ? Colors.green
        : (days <= 2 ? Colors.orange : Colors.red);
    return Row(
      children: [
        Icon(Icons.check_circle, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${l10n.backupLastLabel}: ${_fmt(at)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _backupTile(
      BuildContext context, AppLocalizations l10n, BackupInfo b) {
    return _card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_fmt(b.createdAt),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    if (b.fromThisDevice) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(l10n.backupThisDevice,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${b.summary}  ·  ${_size(b.sizeBytes)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _confirmRestore(context, l10n, b),
            child: Text(l10n.backupRestore),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────
  Future<void> _confirmRestore(
      BuildContext context, AppLocalizations l10n, BackupInfo b) async {
    final bloc = context.read<BackupBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.backupRestoreConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_fmt(b.createdAt)}\n${b.summary}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(l10n.backupRestoreConfirmBody,
                style: const TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.backupRestore),
          ),
        ],
      ),
    );
    if (ok == true) bloc.add(BackupRestoreRequested(b));
  }

  Future<void> _showRestartDialog(
      BuildContext context, AppLocalizations l10n) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.backupRestartTitle),
        content: Text(l10n.backupRestartBody),
        actions: [
          FilledButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text(l10n.backupRestartAction),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Widget _card({required Widget child, EdgeInsets? margin}) => Container(
        margin: margin,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: child,
      );

  String _fmt(DateTime d) => DateFormat('yyyy/MM/dd  HH:mm').format(d);

  String _size(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
