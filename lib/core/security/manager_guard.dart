import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/licensing/data/services/device_identity_service.dart';
import '../../features/licensing/presentation/widgets/device_id_card.dart';
import '../../l10n/app_localizations.dart';
import '../service_locator.dart' as di;
import '../utils/support_launcher.dart';
import 'manager_pin.dart';
import 'manager_pin_service.dart';

/// Ask for the manager PIN before a destructive action (Plan 016 B).
///
/// Returns true when the action may proceed. **No PIN set means true** — the
/// lock is opt-in, and a shop that never turns it on must see exactly today's
/// behaviour.
///
/// This is the single place the question is asked, so protecting one more
/// action later is one `if (!await requireManager(context)) return;`. It is
/// also where the multi-device rule will land when `feat/multi-device-sync`
/// merges: "main device only" becomes one extra check inside this function
/// rather than a change at every call site.
Future<bool> requireManager(BuildContext context) async {
  final service = di.sl<ManagerPinService>();
  if (!await service.isPinSet()) return true;
  if (!context.mounted) return false;

  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PinPromptDialog(),
  );
  return ok ?? false;
}

/// "Enter the manager PIN" — used by [requireManager] and, in confirm mode, by
/// the settings screen before changing or removing the PIN.
class _PinPromptDialog extends StatefulWidget {
  const _PinPromptDialog();

  @override
  State<_PinPromptDialog> createState() => _PinPromptDialogState();
}

class _PinPromptDialogState extends State<_PinPromptDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final service = di.sl<ManagerPinService>();

    final waiting = service.cooldownRemaining;
    if (waiting != null) {
      setState(() => _error = l10n.managerPinLocked(waiting.inSeconds + 1));
      return;
    }

    setState(() => _checking = true);
    final ok = await service.verify(_controller.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }
    final cooling = service.cooldownRemaining;
    setState(() {
      _checking = false;
      _error = cooling != null
          ? l10n.managerPinLocked(cooling.inSeconds + 1)
          : l10n.managerPinWrong;
      _controller.clear();
    });
  }

  Future<void> _forgot() async {
    final cleared = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ForgotPinSheet(),
    );
    // The PIN is gone, so there is nothing left to ask: let the action through
    // rather than making the shop repeat it.
    if (cleared == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.managerPinEnter),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PinField(
            controller: _controller,
            label: l10n.managerPinTitle,
            autofocus: true,
            onSubmitted: _checking ? null : (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 12.5)),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: _forgot,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact),
              child: Text(l10n.managerPinForgot,
                  style: const TextStyle(fontSize: 12.5)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _checking ? null : _submit,
          child: Text(l10n.managerPinUnlock),
        ),
      ],
    );
  }
}

/// Forgot the PIN (Plan 017 R1): show the device id, hand the shop to support,
/// and accept the daily code support reads back.
///
/// **No account, no email, no server call.** The code is derived from the
/// device id and today's date, so this works with the phone in flight mode —
/// which is exactly the situation a locked-out shop is often in.
class _ForgotPinSheet extends StatefulWidget {
  const _ForgotPinSheet();

  @override
  State<_ForgotPinSheet> createState() => _ForgotPinSheetState();
}

class _ForgotPinSheetState extends State<_ForgotPinSheet> {
  final _code = TextEditingController();
  String _deviceId = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final id = await di.sl<DeviceIdentityService>().getDeviceId();
    if (mounted) setState(() => _deviceId = id);
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _contact(SupportChannel channel, AppLocalizations l10n) async {
    final message = l10n.managerPinResetMessage(_deviceId);
    final ok = await SupportLauncher.launch(channel,
        message: message, emailSubject: l10n.managerPinResetTitle);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.supportLaunchFailed)));
  }

  Future<void> _apply(AppLocalizations l10n) async {
    if (!isValidPinResetCode(_code.text, _deviceId, DateTime.now())) {
      setState(() => _error = l10n.managerPinResetWrong);
      return;
    }
    await di.sl<ManagerPinService>().clear();
    if (!mounted) return;
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.managerPinResetDone),
        backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(l10n.managerPinResetTitle,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(l10n.managerPinResetIntro,
                style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            DeviceIdCard(deviceId: _deviceId, l10n: l10n),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contact(SupportChannel.whatsapp, l10n),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: Text(l10n.supportWhatsApp,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contact(SupportChannel.telegram, l10n),
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: Text(l10n.supportTelegram,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                labelText: l10n.managerPinResetCodeLabel,
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => _apply(l10n),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(l10n.managerPinRemove),
            ),
          ],
        ),
      ),
    );
  }
}

/// Set or change the manager PIN. Pops true when something was saved.
///
/// Changing or removing an existing PIN goes through [requireManager] first —
/// otherwise the lock protects the sales but not the lock itself, which is the
/// obvious way around it.
Future<bool> showManagerPinSetup(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _SetPinSheet(),
  );
  return result ?? false;
}

class _SetPinSheet extends StatefulWidget {
  const _SetPinSheet();

  @override
  State<_SetPinSheet> createState() => _SetPinSheetState();
}

class _SetPinSheetState extends State<_SetPinSheet> {
  final _pin = TextEditingController();
  final _repeat = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!isValidPin(_pin.text)) {
      setState(() => _error = l10n.managerPinInvalid);
      return;
    }
    if (_pin.text != _repeat.text) {
      setState(() => _error = l10n.managerPinMismatch);
      return;
    }
    final ok = await di.sl<ManagerPinService>().setPin(_pin.text);
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = l10n.managerPinInvalid);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(l10n.managerPinSet,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(l10n.managerPinNote,
                style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            _PinField(
                controller: _pin, label: l10n.managerPinNew, autofocus: true),
            const SizedBox(height: 12),
            _PinField(controller: _repeat, label: l10n.managerPinConfirm),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12.5)),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => _save(l10n),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// An obscured, digits-only PIN field. Shared so the setup and the prompt can't
/// disagree about what a PIN may contain.
class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  const _PinField({
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        autofocus: autofocus,
        obscureText: true,
        keyboardType: TextInputType.number,
        // Digits only, capped at 6 — the field can't produce a PIN the format
        // rule would then reject.
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline),
          border: const OutlineInputBorder(),
        ),
      );
}
