import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_settings/app_settings.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../licensing/presentation/bloc/license_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/printer_bloc.dart';
import '../bloc/printer_event.dart';
import '../bloc/printer_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

/// Map a [PrinterError] to a localized, user-facing message.
String _printerErrorText(PrinterError error, AppLocalizations l10n) {
  switch (error) {
    case PrinterError.permissionDenied:
      return l10n.printerPermissionDenied;
    case PrinterError.noPairedDevices:
      return l10n.printerNoPairedDevices;
    case PrinterError.connectFailed:
      return l10n.printerConnectFailed;
    case PrinterError.scanFailed:
      return l10n.printerScanFailed;
  }
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PrinterBloc>().add(InitPrinterEvent());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: BlocBuilder<ShopBloc, ShopState>(
                builder: (context, state) {
                  String shopName = '';
                  String initials = 'S';
                  if (state is ShopLoaded && state.shop.name.isNotEmpty) {
                    shopName = state.shop.name;
                    final parts = shopName.split(' ');
                    initials = parts
                        .take(2)
                        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
                        .join('');
                    if (initials.isEmpty) initials = 'S';
                  }

                  return Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.2),
                                blurRadius: 15,
                                spreadRadius: 5,
                              )
                            ]),
                        alignment: Alignment.center,
                        child: Text(initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      if (shopName.isNotEmpty)
                        Text(shopName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Account details — the agent's name/phone (editable) + device id.
            BlocConsumer<LicenseBloc, LicenseState>(
              listenWhen: (prev, curr) =>
                  prev.agentSaveOutcome != curr.agentSaveOutcome &&
                  curr.agentSaveOutcome != null,
              listener: (context, state) {
                final synced =
                    state.agentSaveOutcome == AgentSaveOutcome.synced;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      synced ? l10n.agentSavedSynced : l10n.agentSavedLocal),
                  backgroundColor: synced ? Colors.green : Colors.orange,
                ));
              },
              builder: (context, state) {
                return Column(
                  children: [
                    _buildSectionHeader(l10n.accountInfoSection),
                    _buildListGroup(
                      children: [
                        _buildListItem(
                          icon: Icons.badge_outlined,
                          title: l10n.activationNameLabel,
                          subtitle: state.agentName.isEmpty
                              ? l10n.notSet
                              : state.agentName,
                          trailingIcon: Icons.edit_outlined,
                          onTap: () =>
                              _showEditAccountSheet(context, l10n, state),
                        ),
                        _buildListItem(
                          icon: Icons.phone_outlined,
                          title: l10n.activationPhoneLabel,
                          subtitle: state.agentPhone.isEmpty
                              ? l10n.notSet
                              : state.agentPhone,
                          trailingIcon: Icons.edit_outlined,
                          onTap: () =>
                              _showEditAccountSheet(context, l10n, state),
                        ),
                        _buildListItem(
                          icon: Icons.fingerprint,
                          title: l10n.deviceIdLabel,
                          subtitle: state.deviceId,
                          trailingWidget: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            tooltip: l10n.copy,
                            color: AppTheme.primaryColor,
                            onPressed: state.deviceId.isEmpty
                                ? null
                                : () {
                                    Clipboard.setData(
                                        ClipboardData(text: state.deviceId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(l10n.copied)),
                                    );
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            _buildSectionHeader(l10n.managementSection),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: Icons.storefront,
                  title: l10n.shopDetailsItem,
                  subtitle: l10n.shopDetailsSubtitle,
                  onTap: () => context.push('/settings/shop'),
                ),
                _buildListItem(
                  icon: Icons.savings,
                  title: l10n.cashboxItem,
                  subtitle: l10n.cashboxSubtitle,
                  onTap: () => context.push('/settings/cashbox'),
                ),
                _buildListItem(
                  icon: Icons.cloud_upload_outlined,
                  title: l10n.backupItem,
                  subtitle: l10n.backupSubtitle,
                  onTap: () => context.push('/settings/backup'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSectionHeader(l10n.accountSection),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: Icons.workspace_premium_outlined,
                  title: l10n.subscriptionItem,
                  subtitle: l10n.subscriptionSubtitle,
                  onTap: () => context.push('/settings/subscription'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSectionHeader(l10n.hardwareSection),
            BlocConsumer<PrinterBloc, PrinterState>(
              listener: (context, state) {
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(_printerErrorText(state.error!, l10n)),
                      backgroundColor: Colors.red));
                } else if (state.status == PrinterStatus.connected) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.printerConnected),
                      backgroundColor: Colors.green));
                }
              },
              builder: (context, state) {
                return _buildListGroup(
                  children: [
                    _buildListItem(
                      icon: Icons.print,
                      title: l10n.printDeviceItem,
                      subtitleWidget: Row(
                        children: [
                          Text(
                            state.connectedMac != null
                                ? (state.connectedName ?? l10n.printerConnected)
                                : l10n.noPrinterConnected,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                          if (state.connectedMac != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.teal[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.teal[200]!)),
                              child: Text(
                                l10n.connectedBadge,
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[700]),
                              ),
                            ),
                          ]
                        ],
                      ),
                      trailingWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.status == PrinterStatus.scanning ||
                              state.status == PrinterStatus.connecting)
                            const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                          else
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () => context
                                  .read<PrinterBloc>()
                                  .add(RefreshPrinterEvent()),
                              color: AppTheme.primaryColor,
                            ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              AppSettings.openAppSettings(
                                  type: AppSettingsType.bluetooth);
                            },
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                l10n.bluetoothHint,
                style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500]),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet to edit the agent's name + phone. Saving dispatches
  /// [UpdateAgentEvent]; the outcome snackbar is shown by the section's
  /// [BlocConsumer] listener.
  void _showEditAccountSheet(
      BuildContext context, AppLocalizations l10n, LicenseState state) {
    final nameC = TextEditingController(text: state.agentName);
    final phoneC = TextEditingController(text: state.agentPhone);
    final formKey = GlobalKey<FormState>();
    final bloc = context.read<LicenseBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              Text(l10n.editAccountTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameC,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.activationNameLabel,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.fieldRequired
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phoneC,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.activationPhoneLabel,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.fieldRequired
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    bloc.add(UpdateAgentEvent(
                      name: nameC.text.trim(),
                      phone: phoneC.text.trim(),
                    ));
                    Navigator.pop(ctx);
                  },
                  child: Text(l10n.save,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      // Dispose after the sheet's close transition finishes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameC.dispose();
        phoneC.dispose();
      });
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildListGroup({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    Widget? trailingWidget,
    IconData? trailingIcon = Icons.chevron_right,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                  if (subtitleWidget != null) ...[
                    const SizedBox(height: 4),
                    subtitleWidget,
                  ]
                ],
              ),
            ),
            if (trailingWidget != null)
              trailingWidget
            else if (trailingIcon != null)
              Icon(trailingIcon, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
