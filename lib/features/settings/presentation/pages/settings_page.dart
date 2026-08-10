import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_settings/app_settings.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/remote_config_service.dart';
import '../../../../core/config/update_dialog.dart';
import '../../../../core/security/manager_guard.dart';
import '../../../../core/security/manager_pin_service.dart';
import '../../../../core/service_locator.dart' as di;
import '../../../../core/settings/inventory_settings_service.dart';
import '../../../../core/settings/print_settings_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/font_scale_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../billing/presentation/bloc/billing_bloc.dart';
import '../../../licensing/domain/repositories/license_repository.dart';
import '../../../licensing/presentation/bloc/license_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/printer_bloc.dart';
import '../bloc/printer_event.dart';
import '../bloc/printer_state.dart';
import '../widgets/exchange_rate_sheet.dart';
import '../widgets/powered_by_footer.dart';
import '../widgets/rate_app_sheet.dart';
import '../widgets/support_sheet.dart';

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
  /// Installed version, shown read-only. Empty until [_loadAbout] resolves.
  String _version = '';

  /// Hides the rating prompt once this device has reviewed.
  bool _reviewed = false;

  /// Strict-inventory toggle state ("don't sell below zero"). Off by default.
  bool _blockOversell = false;

  /// Show-print-button / auto-print toggle (Plan 011 #6). On by default.
  bool _showPrintButton = true;

  /// True while a manual "check for updates" (tap on the version row) runs.
  bool _checkingUpdate = false;

  /// Whether a manager PIN is set (Plan 016 B). Off by default.
  bool _pinSet = false;

  @override
  void initState() {
    super.initState();
    context.read<PrinterBloc>().add(InitPrinterEvent());
    _loadAbout();
    _loadInventory();
    _loadPrintSetting();
    _loadPinState();
  }

  /// Best-effort read of whether the manager lock is on; leaves it off on error.
  Future<void> _loadPinState() async {
    var set = false;
    try {
      set = await di.sl<ManagerPinService>().isPinSet();
    } catch (_) {/* leave off */}
    if (!mounted) return;
    setState(() => _pinSet = set);
  }

  /// Set a first PIN, or change an existing one.
  ///
  /// Changing an existing PIN asks for the current one first. Without that the
  /// lock would protect the sales but not itself — anyone could simply set a
  /// new PIN and walk in through the front door.
  Future<void> _openPinSetup() async {
    if (_pinSet) {
      if (!await requireManager(context) || !mounted) return;
    }
    if (!mounted) return;
    final saved = await showManagerPinSetup(context);
    if (!mounted) return;
    await _loadPinState();
    if (!saved || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.managerPinSaved),
        backgroundColor: Colors.green));
  }

  /// Turn the lock off. Also gated by the current PIN, for the same reason.
  Future<void> _removePin() async {
    if (!await requireManager(context) || !mounted) return;
    await di.sl<ManagerPinService>().clear();
    if (!mounted) return;
    await _loadPinState();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.managerPinRemoved),
        backgroundColor: Colors.green));
  }

  /// Best-effort read of the strict-inventory flag; leaves it off on error.
  Future<void> _loadInventory() async {
    var blocked = false;
    try {
      blocked =
          await di.sl<InventorySettingsService>().isBlockOversellEnabled();
    } catch (_) {/* leave off */}
    if (!mounted) return;
    setState(() => _blockOversell = blocked);
  }

  /// Persist the strict-inventory flag and push it into the app-wide
  /// [BillingBloc] so checkout reflects it immediately, no restart.
  Future<void> _setBlockOversell(bool value) async {
    setState(() => _blockOversell = value);
    await di.sl<InventorySettingsService>().setBlockOversell(value);
    if (!mounted) return;
    context.read<BillingBloc>().add(const LoadInventorySettingsEvent());
  }

  /// Best-effort read of the print-button flag; leaves it on (default) on error.
  Future<void> _loadPrintSetting() async {
    var enabled = true;
    try {
      enabled = await di.sl<PrintSettingsService>().isPrintButtonEnabled();
    } catch (_) {/* leave on */}
    if (!mounted) return;
    setState(() => _showPrintButton = enabled);
  }

  /// Persist the print-button flag and push it into the app-wide [BillingBloc]
  /// so checkout hides the button and skips auto-print immediately, no restart.
  Future<void> _setShowPrintButton(bool value) async {
    setState(() => _showPrintButton = value);
    await di.sl<PrintSettingsService>().setPrintButtonEnabled(value);
    if (!mounted) return;
    context.read<BillingBloc>().add(const LoadPrintSettingsEvent());
  }

  /// Both reads are best-effort: settings must render even if package info or
  /// prefs fail, so a failure leaves the version blank rather than erroring.
  Future<void> _loadAbout() async {
    String version = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version} (${info.buildNumber})';
    } catch (_) {/* leave blank */}
    var reviewed = false;
    try {
      reviewed = await di.sl<LicenseRepository>().hasReviewed();
    } catch (_) {/* offer the prompt rather than hide it on error */}
    if (!mounted) return;
    setState(() {
      _version = version;
      _reviewed = reviewed;
    });
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
              color: Theme.of(context).colorScheme.surface,
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
                      const SizedBox(height: 14),
                      // Subscription at a glance. Previously the header showed
                      // only a name, so the one thing that can stop the shop
                      // trading was two taps away with no warning.
                      _subscriptionSummary(context, l10n),
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
                  icon: Icons.currency_exchange,
                  title: l10n.currencySettingsItem,
                  subtitle: l10n.currencySettingsSubtitle,
                  onTap: () => showExchangeRateSheet(context),
                ),
                _buildListItem(
                  icon: Icons.tune,
                  title: l10n.productFieldsItem,
                  subtitle: l10n.productFieldsSubtitle,
                  onTap: () => context.push('/settings/product-fields'),
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

            _buildSectionHeader(l10n.inventorySection),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: Icons.inventory_2_outlined,
                  title: l10n.inventoryStrictTitle,
                  subtitle: l10n.inventoryStrictSubtitle,
                  trailingWidget: Switch(
                    value: _blockOversell,
                    onChanged: _setBlockOversell,
                  ),
                  onTap: () => _setBlockOversell(!_blockOversell),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSectionHeader(l10n.managerLockSection),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: _pinSet ? Icons.lock_outline : Icons.lock_open_outlined,
                  title: l10n.managerPinTitle,
                  subtitle: _pinSet
                      ? l10n.managerPinOnSubtitle
                      : l10n.managerPinOffSubtitle,
                  onTap: _openPinSetup,
                ),
                if (_pinSet)
                  _buildListItem(
                    icon: Icons.lock_reset_outlined,
                    title: l10n.managerPinRemove,
                    subtitle: l10n.managerPinOffSubtitle,
                    onTap: _removePin,
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

            _buildSectionHeader(l10n.appearanceSection),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: Icons.brightness_6_outlined,
                  title: l10n.themeModeTitle,
                  subtitle: _themeModeLabel(
                      di.sl<ThemeController>().mode, l10n),
                  onTap: () => _showThemeSheet(context, l10n),
                ),
                _buildListItem(
                  icon: Icons.format_size,
                  title: l10n.fontSizeTitle,
                  subtitle: _fontScaleLabel(
                      di.sl<FontScaleController>().scale, l10n),
                  onTap: () => _showFontSizeSheet(context, l10n),
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
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
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
                                  type: AppSettingsType.bluetooth,
                                  asAnotherTask: true);
                            },
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    _buildListItem(
                      icon: Icons.print_disabled_outlined,
                      title: l10n.showPrintButtonTitle,
                      subtitle: l10n.showPrintButtonSubtitle,
                      trailingWidget: Switch(
                        value: _showPrintButton,
                        onChanged: _setShowPrintButton,
                      ),
                      onTap: () => _setShowPrintButton(!_showPrintButton),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),

            const SizedBox(height: 12),

            _buildSectionHeader(l10n.supportSection),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: Icons.support_agent,
                  title: l10n.contactSupportItem,
                  subtitle: l10n.contactSupportSubtitle,
                  onTap: () => showSupportSheet(context),
                ),
                _buildListItem(
                  icon: Icons.star_outline_rounded,
                  title: l10n.rateAppItem,
                  subtitle: _reviewed
                      ? l10n.rateAppThanksSubtitle
                      : l10n.rateAppSubtitle,
                  // Already reviewed → inert row, kept visible so the section
                  // doesn't reflow between launches.
                  trailingIcon: _reviewed ? null : Icons.chevron_right,
                  trailingWidget: _reviewed
                      ? Icon(Icons.check_circle,
                          size: 20, color: Colors.green.shade600)
                      : null,
                  onTap: _reviewed ? null : () => _rate(context, l10n),
                ),
                _buildListItem(
                  icon: Icons.share_outlined,
                  title: l10n.shareAppItem,
                  subtitle: l10n.shareAppSubtitle,
                  onTap: () => _shareApp(context, l10n),
                ),
                _buildListItem(
                  icon: Icons.info_outline,
                  title: l10n.appVersionItem,
                  // Blank until PackageInfo resolves; never shows an error.
                  subtitle: _version.isEmpty
                      ? l10n.checkForUpdatesHint
                      : '$_version — ${l10n.checkForUpdatesHint}',
                  trailingWidget: _checkingUpdate
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.system_update_alt,
                          size: 20, color: AppTheme.primaryColor),
                  onTap: _checkingUpdate
                      ? null
                      : () => _checkForUpdates(context, l10n),
                ),
              ],
            ),

            const PoweredByFooter(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _rate(BuildContext context, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    final sent = await showRateAppSheet(context);
    if (!sent || !mounted) return;
    setState(() => _reviewed = true);
    messenger.showSnackBar(SnackBar(
      content: Text(l10n.rateThanks),
      backgroundColor: Colors.green,
    ));
  }

  /// Manual "check for updates" — tapping the app-version row.
  ///
  /// Exists because the automatic prompt only runs once per process at cold
  /// start: Android keeps the app alive in the background for days, so a shop
  /// that never swipe-kills it may not see a new release for a long time. This
  /// re-fetches the hosted config on demand and either shows the same update
  /// dialog as startup, confirms "you're up to date", or reports the check
  /// failed (offline with nothing cached).
  Future<void> _checkForUpdates(
      BuildContext context, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _checkingUpdate = true);
    final service = di.sl<RemoteConfigService>();
    final resolved = await service.refresh();
    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    if (service.updateAvailable) {
      await showUpdateDialog(this.context, service);
    } else {
      messenger.showSnackBar(SnackBar(
        content:
            Text(resolved ? l10n.updateUpToDate : l10n.updateCheckFailed),
        backgroundColor: resolved ? Colors.green : Colors.red,
      ));
    }
  }

  Future<void> _shareApp(BuildContext context, AppLocalizations l10n) async {
    // Text only, no download link: the APK is distributed per-ABI outside a
    // store, so there is no single URL that is correct for every device.
    await Share.share(
      '${l10n.shareAppMessage}\n${PoweredByFooter.websiteUrl}',
    );
  }

  /// Status / plan / expiry strip under the shop name, tappable through to the
  /// subscription page. Reads the shared [LicenseBloc], so it follows a live
  /// re-check or an FCM unlock with no manual refresh.
  Widget _subscriptionSummary(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<LicenseBloc, LicenseState>(
      builder: (context, state) {
        final status = state.license;
        final active = status.isActive;
        final days = status.daysRemaining;
        // Match the trial banner's threshold so the two never disagree.
        final urgent = active && days != null && days <= 3;
        final accent = !active
            ? Theme.of(context).colorScheme.error
            : urgent
                ? Colors.orange.shade800
                : Colors.green.shade600;

        return InkWell(
          onTap: () => context.push('/settings/subscription'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(active ? Icons.verified_rounded : Icons.error_outline,
                    size: 18, color: accent),
                const SizedBox(width: 8),
                Text(
                  active
                      ? (status.isTrial
                          ? l10n.trialChip
                          : l10n.subscriptionActiveChip)
                      : l10n.subscriptionInactiveChip,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: accent),
                ),
                if (active && days != null) ...[
                  const SizedBox(width: 8),
                  Container(
                      width: 1,
                      height: 14,
                      color: accent.withValues(alpha: 0.35)),
                  const SizedBox(width: 8),
                  Text(
                    // Clamped at zero: a same-day expiry floors to 0 rather
                    // than showing a negative count.
                    '${l10n.expiresOnLabel}: ${days < 0 ? 0 : days}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                    color: Theme.of(context).colorScheme.outlineVariant,
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

  String _themeModeLabel(ThemeMode mode, AppLocalizations l10n) =>
      switch (mode) {
        ThemeMode.light => l10n.themeLight,
        ThemeMode.dark => l10n.themeDark,
        ThemeMode.system => l10n.themeSystem,
      };

  String _fontScaleLabel(AppFontScale scale, AppLocalizations l10n) =>
      switch (scale) {
        AppFontScale.tiny => l10n.fontSizeTiny,
        AppFontScale.small => l10n.fontSizeSmall,
        AppFontScale.normal => l10n.fontSizeNormal,
        AppFontScale.large => l10n.fontSizeLarge,
        AppFontScale.extraLarge => l10n.fontSizeExtraLarge,
      };

  void _showFontSizeSheet(BuildContext context, AppLocalizations l10n) {
    final controller = di.sl<FontScaleController>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(l10n.fontSizeTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final scale in AppFontScale.values)
              ListTile(
                // Preview each option at its own size so the choice is legible.
                title: Text(
                  _fontScaleLabel(scale, l10n),
                  textScaler: TextScaler.linear(scale.factor),
                ),
                trailing: controller.scale == scale
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await controller.setScale(scale);
                  // The controller drives MaterialApp; repaint this page's own
                  // subtitle too.
                  if (mounted) setState(() {});
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showThemeSheet(BuildContext context, AppLocalizations l10n) {
    final controller = di.sl<ThemeController>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(l10n.themeModeTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final mode in ThemeMode.values)
              ListTile(
                leading: Icon(switch (mode) {
                  ThemeMode.light => Icons.light_mode_outlined,
                  ThemeMode.dark => Icons.dark_mode_outlined,
                  ThemeMode.system => Icons.brightness_auto_outlined,
                }),
                title: Text(_themeModeLabel(mode, l10n)),
                trailing: controller.mode == mode
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await controller.setMode(mode);
                  // The controller drives MaterialApp, but this page's own
                  // subtitle is plain state — repaint it too.
                  if (mounted) setState(() {});
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildListGroup({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
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
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
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
              Icon(trailingIcon,
                  color: Theme.of(context).colorScheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}
