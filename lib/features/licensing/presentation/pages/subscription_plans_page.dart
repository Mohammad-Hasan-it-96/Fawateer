import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_config.dart';
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
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _planCard(context, l10n, state.plans[i]),
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(l10n.plansEmpty,
              style: TextStyle(color: Colors.grey[600])),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: plan.recommended
              ? AppTheme.primaryColor
              : Colors.grey.shade200,
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
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough)),
                  ),
                ],
                const Spacer(),
                Text(l10n.planDurationMonths(plan.durationMonths),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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

  void _openContactSheet(
      BuildContext context, AppLocalizations l10n, SubscriptionPlan plan) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(l10n.contactMethodTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
              title: Text(l10n.contactWhatsApp),
              onTap: () {
                Navigator.pop(sheetContext);
                _submit(context, l10n, plan, 'whatsapp');
              },
            ),
            ListTile(
              leading: const Icon(Icons.send, color: Color(0xFF229ED9)),
              title: Text(l10n.contactTelegram),
              onTap: () {
                Navigator.pop(sheetContext);
                _submit(context, l10n, plan, 'telegram');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// File the pending request via the BLoC, then open the operator channel.
  Future<void> _submit(BuildContext context, AppLocalizations l10n,
      SubscriptionPlan plan, String method) async {
    final state = context.read<LicenseBloc>().state;
    context.read<LicenseBloc>().add(RequestPlanEvent(
          name: state.agentName,
          phone: state.agentPhone,
          plan: plan,
          contactMethod: method,
        ));
    final uri = _contactUri(method, plan, l10n);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Uri? _contactUri(
      String method, SubscriptionPlan plan, AppLocalizations l10n) {
    final message = l10n.contactMessage(plan.title);
    if (method == 'whatsapp' && ApiConfig.supportWhatsApp.isNotEmpty) {
      return Uri.parse(
          'https://wa.me/${ApiConfig.supportWhatsApp}?text=${Uri.encodeComponent(message)}');
    }
    if (method == 'telegram' && ApiConfig.supportTelegram.isNotEmpty) {
      return Uri.parse('https://t.me/${ApiConfig.supportTelegram}');
    }
    return null;
  }
}
