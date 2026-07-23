import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/support_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/subscription_plan.dart';
import '../bloc/license_bloc.dart';
import '../licensing_error_text.dart';

/// Subscription plan catalogue. Picking a plan opens a contact sheet: the app
/// files a `pending` request server-side and hands the user to the operator
/// (WhatsApp/Telegram), who activates the device.
class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  @override
  void initState() {
    super.initState();
    context.read<LicenseBloc>().add(LoadPlansEvent());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plansTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: BlocConsumer<LicenseBloc, LicenseState>(
        listener: (context, state) {
          if (state.status == LicenseFlowStatus.requestSent) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.planRequestSent),
              backgroundColor: Colors.green,
            ));
            Navigator.of(context).maybePop();
          } else if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(licenseErrorText(state.error!, l10n)),
              backgroundColor: Colors.red,
            ));
          }
        },
        builder: (context, state) {
          if (state.plansLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.plans.isEmpty) {
            return _empty(context, l10n);
          }
          final expired = state.license.isExpired;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            // +1 leading slot for the expired notice, so a returning user is
            // told *why* they're looking at plans (and that their data is safe)
            // rather than seeing the same bare catalogue as a first subscriber.
            itemCount: state.plans.length + (expired ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (expired && i == 0) {
                return _expiredNotice(context, l10n, state.license.isTrial);
              }
              final plan = state.plans[expired ? i - 1 : i];
              return _planCard(context, l10n, plan);
            },
          );
        },
      ),
    );
  }

  /// Why-you're-here banner for a returning expired user (trial or paid — the
  /// wording differs, the flow doesn't). Explicitly reassures that shop data
  /// is untouched: fear of losing invoices/customers is the main reason a
  /// shopkeeper hesitates here.
  Widget _expiredNotice(
      BuildContext context, AppLocalizations l10n, bool wasTrial) {
    final color = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_clock_outlined, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              wasTrial
                  ? l10n.trialExpiredNotice
                  : l10n.subscriptionExpiredNotice,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(l10n.plansEmpty,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () =>
                context.read<LicenseBloc>().add(LoadPlansEvent()),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _planCard(
      BuildContext context, AppLocalizations l10n, SubscriptionPlan plan) {
    final symbol = plan.currencySymbol.isNotEmpty
        ? plan.currencySymbol
        : plan.currencyCode;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: plan.recommended
              ? AppTheme.primaryColor
              : Theme.of(context).dividerColor,
          width: plan.recommended ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(plan.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                if (plan.recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(l10n.planRecommended,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor)),
                  ),
              ],
            ),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(plan.description,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${plan.effectivePrice.toStringAsFixed(2)} $symbol',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
                if (plan.hasDiscount) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('${plan.price.toStringAsFixed(2)} $symbol',
                        style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough)),
                  ),
                ],
                const Spacer(),
                Text(l10n.planDurationMonths(plan.durationMonths),
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _openContactSheet(context, l10n, plan),
                style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor),
                child: Text(l10n.planSubscribe),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The message handed to the operator. It carries the **device id** — the only
  /// thing that lets support activate this install — plus the agent's name and
  /// phone, so the operator can act on the message alone without the user having
  /// to find and paste the id themselves.
  String _contactMessage(
      BuildContext context, AppLocalizations l10n, SubscriptionPlan plan) {
    final state = context.read<LicenseBloc>().state;
    String orDash(String value) =>
        value.trim().isEmpty ? '—' : value.trim();
    return l10n.contactMessage(
      plan.title,
      orDash(state.agentName),
      orDash(state.agentPhone),
      orDash(state.deviceId),
    );
  }

  void _openContactSheet(
      BuildContext context, AppLocalizations l10n, SubscriptionPlan plan) {
    // Built once, here: the preview below and the message actually sent must be
    // the same string, or the copy button lies.
    final message = _contactMessage(context, l10n, plan);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(l10n.contactMethodTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _messagePreview(sheetContext, l10n, message),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
                title: Text(l10n.contactWhatsApp),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _submit(context, l10n, plan, 'whatsapp', message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.send, color: Color(0xFF229ED9)),
                title: Text(l10n.contactTelegram),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _submit(context, l10n, plan, 'telegram', message);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.email_outlined, color: Colors.redAccent),
                title: Text(l10n.contactEmail),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _submit(context, l10n, plan, 'email', message);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the message before it's sent, with a copy button. The copy is the
  /// fallback for every case the pre-fill can't survive — notably **Telegram,
  /// which cannot pre-fill a message on a user/phone link at all** (`?text=` is
  /// only honoured on `share/url` and bot `start` links), so its chat opens
  /// empty by design and the user pastes.
  Widget _messagePreview(
      BuildContext sheetContext, AppLocalizations l10n, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.contactMessagePreview,
              style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(sheetContext).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Theme.of(sheetContext).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(sheetContext).dividerColor),
            ),
            child: Text(message,
                style: const TextStyle(fontSize: 13, height: 1.5)),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: Text(l10n.copy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: message));
                if (!sheetContext.mounted) return;
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.copied)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// File the pending request via the BLoC, then open the operator channel.
  Future<void> _submit(BuildContext context, AppLocalizations l10n,
      SubscriptionPlan plan, String method, String message) async {
    final state = context.read<LicenseBloc>().state;
    // Captured before the async gap: the page pops itself on `requestSent`, and
    // this resolves to the app-wide messenger, so the notice below still shows.
    final messenger = ScaffoldMessenger.of(context);
    context.read<LicenseBloc>().add(RequestPlanEvent(
          name: state.agentName,
          phone: state.agentPhone,
          plan: plan,
          contactMethod: method,
        ));
    final channel = switch (method) {
      'whatsapp' => SupportChannel.whatsapp,
      'telegram' => SupportChannel.telegram,
      _ => SupportChannel.email,
    };
    final launched = await SupportLauncher.launch(
      channel,
      message: message,
      emailSubject: l10n.contactEmailSubject,
    );
    // Never fail silently: the request is already filed server-side, so a user
    // who saw nothing happen would leave the operator waiting on a message that
    // was never sent. Point them at the copy they just saw.
    if (!launched) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.contactLaunchFailed),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 6),
      ));
    }
  }

}
