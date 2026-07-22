import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app_settings/app_settings.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../settings/presentation/widgets/exchange_rate_sheet.dart';
import '../widgets/discount_dialog.dart';

import '../../../../core/utils/num_input.dart';
import '../../../../core/utils/scan_feedback.dart';

import '../../../billing/presentation/bloc/billing_bloc.dart';
import '../billing_error_text.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/domain/entities/price_currency.dart';
import '../../../../core/currency/exchange_rate_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/cart_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  /// Not `final`: a controller that has latched an error can only be replaced,
  /// never revived — see [_recoverCamera].
  MobileScannerController _scannerController = _newController();

  static MobileScannerController _newController() => MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        returnImage: false,
      );

  /// Serializes every camera start/stop.
  ///
  /// The native scanner rejects a `start()` issued while the camera is already
  /// running (`AlreadyStarted`), and mobile_scanner latches that rejection into
  /// `controller.value.error` — which `MobileScanner` renders through
  /// [errorBuilder] forever, because `stop()` returns early while `isRunning`
  /// is false and so can never clear it. Two callers each firing a start was
  /// therefore enough to strand the preview on "camera unavailable" until the
  /// app was killed. Queuing the calls removes the overlap that causes it.
  Future<void> _cameraOp = Future<void>.value();

  /// Bumped on every controller swap so `MobileScanner` rebuilds its state
  /// against the new instance instead of holding the disposed one.
  int _cameraGeneration = 0;

  /// Bounds [_recoverCamera] so a genuinely broken camera can't loop; reset
  /// whenever a start succeeds.
  int _recoveryAttempts = 0;
  static const int _maxRecoveryAttempts = 2;

  // ── camera desired-state inputs ────────────────────────────────────────────
  // Each of these is set by exactly one concern, and every change funnels
  // through [_syncCamera]. Driving the camera imperatively instead — a `stop()`
  // at each callsite paired with a `start()` on the way back — is what stranded
  // the preview on black: any path that stopped without a matching start (an
  // overlay dismissed while the app was backgrounded, a tab change during
  // checkout) left the camera off with nothing left to turn it on.

  /// The user's camera toggle.
  bool _isCameraOn = true;

  /// This tab is the visible branch of the shell.
  bool _tabVisible = false;

  /// The app is in the foreground.
  bool _appResumed = true;

  /// The checkout route is pushed over this page.
  bool _onCheckout = false;

  /// A sheet or dialog is covering the scanner (picker, measured entry, unknown
  /// barcode) — it owns the screen, and a live camera behind it would keep
  /// decoding and re-fire the prompt on top of itself.
  int _overlayDepth = 0;

  bool _isFlashOn = false;

  /// The camera should run only when nothing else wants the screen.
  bool get _shouldScan =>
      _isCameraOn &&
      _tabVisible &&
      _appResumed &&
      !_onCheckout &&
      _overlayDepth == 0;

  final Map<String, DateTime> _lastScanTimes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController.addListener(_onScannerState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fires for any inherited change (keyboard, theme, locale), not just the
    // tab — [_syncCamera] is idempotent, so re-running it is free.
    _tabVisible = TickerMode.of(context);
    _syncCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `inactive` also covers a transient interruption (notification shade, a
    // permission prompt), where holding the camera open is what makes the
    // preview come back black once Android has torn the surface down.
    _appResumed = state == AppLifecycleState.resumed;
    _syncCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.removeListener(_onScannerState);
    _scannerController.dispose();
    super.dispose();
  }

  /// Queue [action] behind whatever camera work is already in flight, so two
  /// starts can never overlap. Platform errors are swallowed: the
  /// [MobileScanner] errorBuilder is the user-facing channel.
  Future<void> _enqueue(Future<void> Function() action) {
    final next = _cameraOp.then((_) => action()).catchError((_) {});
    _cameraOp = next;
    return next;
  }

  /// Drive the camera to whatever [_shouldScan] currently says.
  ///
  /// Every camera decision goes through here, and it re-reads [_shouldScan]
  /// *inside* the queue rather than capturing it at call time — so when several
  /// events land together (tab change plus a resume, say) the last one wins
  /// instead of a stale start re-opening a camera the newer state wants closed.
  Future<void> _syncCamera() => _enqueue(() async {
        if (!mounted) return;
        if (_shouldScan) {
          await _scannerController.start();
        } else {
          await _scannerController.stop();
        }
      });

  /// Run [body] with the scanner treated as covered, restoring it afterwards
  /// even if [body] throws — a sheet that closed on an error used to leave the
  /// camera stopped for good.
  Future<T> _withOverlay<T>(Future<T> Function() body) async {
    _overlayDepth++;
    _syncCamera();
    try {
      return await body();
    } finally {
      _overlayDepth--;
      _syncCamera();
    }
  }

  /// Auto-recovers a stuck camera, so the cashier doesn't have to notice a
  /// retry button to get back to scanning.
  void _onScannerState() {
    final error = _scannerController.value.error;
    if (error == null) {
      _recoveryAttempts = 0;
      return;
    }
    // A denied permission is the user's to resolve, and the error state already
    // offers Settings; recreating the controller would only re-fail. Anything
    // else is a native camera we still hold but can no longer drive.
    if (error.errorCode == MobileScannerErrorCode.permissionDenied) return;
    if (!mounted || !_isCameraOn) return;
    if (_recoveryAttempts >= _maxRecoveryAttempts) return;
    _recoveryAttempts++;
    _recoverCamera();
  }

  /// Replace a controller that has latched an error and start the fresh one.
  ///
  /// Disposing the old controller is what releases the native camera it is
  /// still holding — without that, the new controller's start would be
  /// rejected as `AlreadyStarted` exactly like the one that stranded it.
  Future<void> _recoverCamera() {
    return _enqueue(() async {
      final old = _scannerController;
      old.removeListener(_onScannerState);
      if (!mounted) {
        await old.dispose();
        return;
      }
      final fresh = _newController();
      setState(() {
        _scannerController = fresh;
        _cameraGeneration++;
      });
      fresh.addListener(_onScannerState);
      await old.dispose();
      if (mounted && _shouldScan) await fresh.start();
    });
  }

  /// Offers to create a product from a barcode the catalogue doesn't know.
  ///
  /// Routes to the products tab's add page with the barcode already filled, so
  /// the cashier never has to read the digits off this dialog and retype them.
  Future<void> _promptAddUnknownBarcode(
      BuildContext context, AppLocalizations l10n, String barcode) {
    // The camera stays suspended across both the dialog and the add page it
    // leads to: left running it keeps decoding the same barcode and re-fires
    // this dialog on top of the add form.
    return _withOverlay(() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.unknownBarcodeTitle),
          content: Text(l10n.unknownBarcodeMessage(barcode)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.unknownBarcodeAdd),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await context.push('/products/add', extra: barcode);
    });
  }

  void _onDetect(BarcodeCapture capture) async {
    final now = DateTime.now();
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        final rawValue = barcode.rawValue!;
        final lastScan = _lastScanTimes[rawValue];
        if (lastScan != null && now.difference(lastScan).inSeconds < 2) {
          continue;
        }
        _lastScanTimes[rawValue] = now;

        // Beep first, then buzz: the sound is the primary confirmation for a
        // cashier whose eyes are on the goods, and awaiting `canVibrate` first
        // would delay it noticeably on some devices.
        ScanFeedback.beep();

        final canVibrate = await Vibrate.canVibrate;
        if (canVibrate) Vibrate.feedback(FeedbackType.success);

        if (mounted) {
          context.read<BillingBloc>().add(ScanBarcodeEvent(rawValue));
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<BillingBloc, BillingState>(
            listenWhen: (prev, curr) =>
                prev.error != curr.error && curr.error != null,
            listener: (context, state) {
              // An unknown barcode isn't really an error — it's an unstocked
              // item, and the useful next step is creating it. Offer that
              // instead of a snackbar the cashier can only dismiss.
              if (state.error == BillingError.productNotFound &&
                  (state.errorBarcode ?? '').isNotEmpty) {
                _promptAddUnknownBarcode(context, l10n, state.errorBarcode!);
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    billingErrorText(state.error!, state.errorBarcode, l10n)),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
          // A measured product (e.g. weight) was scanned: prompt for the
          // weight/amount, then add it (or clear the prompt on cancel).
          BlocListener<BillingBloc, BillingState>(
            listenWhen: (prev, curr) =>
                prev.measuredPrompt != curr.measuredPrompt &&
                curr.measuredPrompt != null,
            listener: (context, state) async {
              final bloc = context.read<BillingBloc>();
              final product = state.measuredPrompt!;
              final weight = await _promptMeasuredEntry(context, product);
              if (!mounted) return;
              if (weight != null) {
                bloc.add(AddProductToCartEvent(product, quantity: weight));
              } else {
                bloc.add(const ClearMeasuredPromptEvent());
              }
            },
          ),
        ],
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.4,
              child: _buildScannerSection(l10n),
            ),
            Positioned(
              top: (MediaQuery.of(context).size.height * 0.4) - 24,
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomPanel(l10n),
            ),
          ],
        ),
      ),
      bottomSheet: BlocBuilder<BillingBloc, BillingState>(
        builder: (context, state) {
          return PrimaryButton(
            onPressed: state.cartItems.isEmpty
                ? null
                : () async {
                    setState(() => _onCheckout = true);
                    _syncCamera();
                    try {
                      await context.push('/pos/checkout');
                    } finally {
                      // Back from checkout, by any route (Back, New Sale, or a
                      // navigation error): the camera resumes because the flag
                      // clears, not because this callsite restarted it.
                      if (mounted) {
                        setState(() => _onCheckout = false);
                        _syncCamera();
                      }
                    }
                  },
            icon: Icons.payment,
            label: l10n.reviewOrder,
          );
        },
      ),
    );
  }

  Widget _buildScannerSection(AppLocalizations l10n) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            // Rebuilds against a replaced controller (see [_recoverCamera]).
            key: ValueKey(_cameraGeneration),
            controller: _scannerController,
            onDetect: _onDetect,
            // Shown when the camera can't start (permission denied, no camera).
            errorBuilder: (context, error, child) =>
                _buildCameraErrorState(l10n),
          ),
          if (!_isCameraOn) _buildCameraOffState(l10n),

          // Quick currency-rate chip (top-start): tap to set/update the USD→SP
          // exchange rate without leaving the POS.
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: _buildRateChip(l10n),
          ),

          // Two overlay buttons (flash + camera toggle) — top-right horizontal row
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: Row(
              children: [
                if (_isCameraOn) _buildOverlayButton(
                  icon: _isFlashOn ? Icons.flashlight_off : Icons.flashlight_on,
                  label: l10n.flash,
                  onPressed: () {
                    setState(() => _isFlashOn = !_isFlashOn);
                    _scannerController.toggleTorch();
                  },
                ),
                if (_isCameraOn) const SizedBox(width: 8),
                _buildOverlayButton(
                  icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                  label: l10n.camera,
                  onPressed: () {
                    setState(() => _isCameraOn = !_isCameraOn);
                    _syncCamera();
                  },
                ),
              ],
            ),
          ),

          // Scan target corners
          if (_isCameraOn)
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(children: [
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraOffState(AppLocalizations l10n) {
    return Container(
      color: const Color(0xFF1E293B),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
                color: Color(0xFF334155), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.videocam_off, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(l10n.cameraOff,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(l10n.cameraOffHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.videocam),
            label: Text(l10n.turnOnCamera,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              setState(() => _isCameraOn = true);
              _syncCamera();
            },
          ),
        ],
      ),
    );
  }

  /// Shown when the camera can't start (permission permanently denied, or no
  /// usable camera). Keeps the cashier unblocked: they can open settings to
  /// grant access, or add items manually via the picker below.
  Widget _buildCameraErrorState(AppLocalizations l10n) {
    return Container(
      color: const Color(0xFF1E293B),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
                color: Color(0xFF334155), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.no_photography,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(l10n.cameraUnavailable,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(l10n.cameraPermissionHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Manual escape hatch for the case auto-recovery gave up on
              // (see [_maxRecoveryAttempts]) — cheaper for the cashier than
              // restarting the app.
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  _recoveryAttempts = 0;
                  _recoverCamera();
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.settings),
                label: Text(l10n.openSettings,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                // asAnotherTask: launches Settings with FLAG_ACTIVITY_NEW_TASK
                // — without it Android silently drops the launch on many
                // devices ("nothing happens"). Opens App Info → Permissions →
                // Camera.
                onPressed: () =>
                    AppSettings.openAppSettings(asAnotherTask: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Compact tappable pill showing the current USD→SP rate (or a prompt to set
  /// it). Opens the rate modal — a fast in-place edit from the POS.
  Widget _buildRateChip(AppLocalizations l10n) {
    return BlocBuilder<BillingBloc, BillingState>(
      buildWhen: (p, c) => p.exchangeRate != c.exchangeRate,
      builder: (context, state) {
        final rate = state.exchangeRate;
        final shopState = context.read<ShopBloc>().state;
        final sym =
            shopState is ShopLoaded ? shopState.shop.currencySymbol : '';
        final label = rate == null
            ? l10n.setExchangeRateShort
            : '\$1 = ${NumberFormat('#,###').format(rate)} $sym';
        return GestureDetector(
          onTap: () => showExchangeRateSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.currency_exchange,
                    color: Colors.white, size: 16),
                const SizedBox(width: 6),
                // Force LTR so "$1 = 13,000 ل.س" keeps a stable, readable order
                // in the Arabic (RTL) layout instead of the number/symbol
                // reshuffling into a confusing mix.
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlayButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: (alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight)
                ? const BorderSide(color: Colors.greenAccent, width: 3)
                : BorderSide.none,
            bottom: (alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight)
                ? const BorderSide(color: Colors.greenAccent, width: 3)
                : BorderSide.none,
            left: (alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft)
                ? const BorderSide(color: Colors.greenAccent, width: 3)
                : BorderSide.none,
            right: (alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight)
                ? const BorderSide(color: Colors.greenAccent, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          BlocBuilder<BillingBloc, BillingState>(
            builder: (context, state) {
              final totalItems =
                  state.cartItems.fold<double>(0, (s, i) => s + i.quantity);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.scannedItems,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        Text(l10n.itemsCount(formatQty(totalItems)),
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(l10n.totalPrice,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        BlocBuilder<ShopBloc, ShopState>(
                          builder: (context, shopState) {
                            final currency = shopState is ShopLoaded
                                ? shopState.shop.currencySymbol
                                : '';
                            return Text(
                              '$currency${state.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).primaryColor),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 4),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showProductPicker(context),
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                label: Text(l10n.addItem),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<BillingBloc, BillingState>(
              builder: (context, state) {
                if (state.cartItems.isEmpty) {
                  return _buildEmptyCart(l10n);
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(
                      left: 15, right: 15, top: 16, bottom: 100),
                  itemCount: state.cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildCartItemCard(context, state.cartItems[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(Icons.shopping_basket,
                size: 40,
                color: Theme.of(context).colorScheme.outlineVariant),
          ),
          const SizedBox(height: 16),
          Text(l10n.cartEmpty,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(l10n.cartEmptyHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item) {
    final l10n = AppLocalizations.of(context)!;
    final measured = item.product.saleType.isMeasured;
    final shopState = context.watch<ShopBloc>().state;
    final currency =
        shopState is ShopLoaded ? shopState.shop.currencySymbol : '';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  measured
                      // e.g. "0.333 كغ × 15000.00" then the line total below.
                      ? '${formatQty(item.quantity)} ${l10n.unitKg} × $currency${item.unitPriceSp.toStringAsFixed(2)}'
                      : '$currency${item.unitPriceSp.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: measured ? 12 : 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                if (item.isForeign) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.sellCurrency.label(item.product.price, ''),
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
                if (measured) ...[
                  const SizedBox(height: 2),
                  Text('$currency${item.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.primaryColor)),
                ],
                const SizedBox(height: 6),
                _buildLineDiscount(context, item, currency, l10n),
              ],
            ),
          ),
          if (measured)
            // A weight line isn't stepped by 1 — tap to re-enter weight/amount.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _editMeasured(context, item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${formatQty(item.quantity)} ${l10n.unitKg}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit,
                            size: 16, color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                ),
                _qtyButton(
                  icon: Icons.delete_outline,
                  onPressed: () => context
                      .read<BillingBloc>()
                      .add(RemoveProductFromCartEvent(item.product.id)),
                ),
              ],
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _qtyButton(
                    icon: Icons.remove,
                    onPressed: () {
                      if (item.quantity > 1) {
                        context.read<BillingBloc>().add(UpdateQuantityEvent(
                            item.product.id, item.quantity - 1));
                      } else {
                        context.read<BillingBloc>().add(
                            RemoveProductFromCartEvent(item.product.id));
                      }
                    },
                  ),
                  InkWell(
                    onTap: () => _editQuantity(context, item),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 44),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Text(formatQty(item.quantity),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  _qtyButton(
                    icon: Icons.add,
                    onPressed: () => context.read<BillingBloc>().add(
                        UpdateQuantityEvent(item.product.id, item.quantity + 1)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(icon,
            size: 24, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  /// Tap-to-edit quantity: opens a numeric keypad so the cashier sets an exact
  /// amount in one entry — including decimals for weight items (0.5 kg) —
  /// instead of tapping +/- repeatedly. Submitting 0 removes the line; an
  /// empty/invalid entry leaves the quantity unchanged.
  Future<void> _editQuantity(BuildContext context, CartItem item) async {
    final bloc = context.read<BillingBloc>();
    final newQty = await showDialog<double>(
      context: context,
      builder: (_) => _QuantityDialog(item: item),
    );
    if (newQty != null) {
      bloc.add(UpdateQuantityEvent(item.product.id, newQty));
    }
  }

  /// Compact per-line discount affordance: a tappable chip showing the current
  /// markdown ("−500 • net 4500"), or a subtle "Discount" button when none is
  /// set. Opens the % / fixed discount dialog.
  Widget _buildLineDiscount(BuildContext context, CartItem item, String currency,
      AppLocalizations l10n) {
    final has = item.effectiveDiscount > 0;
    // Grouped, no decimals — SP amounts here are large; ".00" just wastes space
    // and pushed the row into a right-overflow.
    final fmt = NumberFormat('#,###');
    final color = has ? Colors.red : AppTheme.primaryColor;
    return InkWell(
      onTap: () => _editLineDiscount(context, item, currency),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(has ? Icons.local_offer : Icons.local_offer_outlined,
                size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                has ? '- $currency${fmt.format(item.effectiveDiscount)}'
                    : l10n.addDiscountAction,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editLineDiscount(
      BuildContext context, CartItem item, String currency) async {
    final bloc = context.read<BillingBloc>();
    final result = await showDiscountDialog(
      context: context,
      base: item.gross,
      currency: currency,
      initialDiscount: item.discount,
    );
    if (result != null) {
      bloc.add(SetLineDiscountEvent(item.product.id, result));
    }
  }

  /// Re-enter the weight/amount for a measured cart line (add-or-replace: the
  /// line is set to the new weight, not incremented).
  Future<void> _editMeasured(BuildContext context, CartItem item) async {
    final bloc = context.read<BillingBloc>();
    final weight = await _promptMeasuredEntry(context, item.product);
    if (weight != null) {
      bloc.add(AddProductToCartEvent(item.product, quantity: weight));
    }
  }

  /// Opens the dual-field weight/amount dialog for a measured product,
  /// pre-filled with the product's current cart weight (0 if not yet in cart).
  /// Returns the chosen weight in kg, or null if cancelled.
  Future<double?> _promptMeasuredEntry(
      BuildContext context, Product product) {
    final shopState = context.read<ShopBloc>().state;
    final currency =
        shopState is ShopLoaded ? shopState.shop.currencySymbol : '';
    final billingState = context.read<BillingBloc>().state;
    // Work the weight↔amount linkage in SP: a USD-priced weighed item is
    // resolved to its SP per-kg price at the current rate so the dialog's money
    // field is in SP (matching the cart total). 0 if no rate yet → amount field
    // disabled and the checkout guard blocks the sale.
    final spPerUnit = product.priceCurrency == PriceCurrency.usd
        ? (usdToSp(product.price, billingState.exchangeRate) ?? 0)
        : product.price;
    double existing = 0;
    for (final c in billingState.cartItems) {
      if (c.product.id == product.id) {
        existing = c.quantity;
        break;
      }
    }
    // Suspended while the dialog is up: a live camera behind it would keep
    // decoding and re-raise the measured prompt on top of itself. Nesting
    // inside the picker's overlay is fine — [_overlayDepth] counts.
    return _withOverlay(() => showDialog<double>(
          context: context,
          builder: (_) => _MeasuredEntryDialog(
            product: product,
            currency: currency,
            pricePerUnit: spPerUnit,
            initialWeight: existing,
          ),
        ));
  }

  /// Opens a searchable product grid so the cashier can add items that have
  /// no barcode (or when scanning fails). Pauses the camera while open.
  Future<void> _showProductPicker(BuildContext context) {
    final shopState = context.read<ShopBloc>().state;
    final currency =
        shopState is ShopLoaded ? shopState.shop.currencySymbol : '';

    return _withOverlay(() => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => _ProductPickerSheet(
            currency: currency,
            onAdd: (product) async {
              final bloc = context.read<BillingBloc>();
              if (product.saleType.isMeasured) {
                // Ask for weight/amount before adding a measured product.
                final weight = await _promptMeasuredEntry(context, product);
                if (weight == null) return;
                bloc.add(AddProductToCartEvent(product, quantity: weight));
              } else {
                bloc.add(AddProductToCartEvent(product));
              }
              final canVibrate = await Vibrate.canVibrate;
              if (canVibrate) Vibrate.feedback(FeedbackType.success);
            },
          ),
        ));
  }
}

/// Bottom-sheet product picker: search field + tap-to-add grid. Stays open for
/// multiple adds; the cart total updates live on the screen behind it. Reads the
/// product list live from [ProductBloc] (rather than a snapshot taken at open
/// time) so it isn't empty when the sheet is opened before the first stream
/// emission, and reflects any product added/edited while it's open.
class _ProductPickerSheet extends StatefulWidget {
  final String currency;
  final void Function(Product) onAdd;

  const _ProductPickerSheet({
    required this.currency,
    required this.onAdd,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productState = context.watch<ProductBloc>().state;
    final products = productState.products;
    // Still awaiting the first stream emission — show a spinner instead of a
    // misleading "no products" so an empty first open can't look like search
    // returning nothing.
    final loading =
        products.isEmpty && productState.status == ProductStatus.loading;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? products
        : products
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.barcode.toLowerCase().contains(q))
            .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                child: Row(
                  children: [
                    Text(l10n.addItem,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                    ? Center(
                        child: Text(l10n.noProductsFound,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)))
                    : GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.6,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _ProductTile(
                          product: filtered[i],
                          currency: widget.currency,
                          onAdd: () => widget.onAdd(filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

}

/// A single tappable product tile with add feedback. On tap it fires [onAdd]
/// and plays a brief scale "pop" + green check flash, and it shows a live badge
/// with how many of this product are already in the cart — so the cashier can
/// see, unambiguously, that the tap landed and the item is on the order.
class _ProductTile extends StatefulWidget {
  final Product product;
  final String currency;
  final VoidCallback onAdd;

  const _ProductTile({
    required this.product,
    required this.currency,
    required this.onAdd,
  });

  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile> {
  /// True for a short window right after a tap, driving the pop + check flash.
  bool _justAdded = false;

  Future<void> _handleTap() async {
    widget.onAdd();
    if (!mounted) return;
    setState(() => _justAdded = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) setState(() => _justAdded = false);
  }

  @override
  Widget build(BuildContext context) {
    // Live quantity of this product already in the cart.
    double inCart = 0;
    for (final c in context.watch<BillingBloc>().state.cartItems) {
      if (c.product.id == widget.product.id) {
        inCart = c.quantity;
        break;
      }
    }
    final highlighted = _justAdded || inCart > 0;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _justAdded ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: highlighted
                    ? AppTheme.primaryColor.withValues(alpha: 0.06)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: highlighted
                      ? AppTheme.primaryColor
                      : Theme.of(context).dividerColor,
                  width: highlighted ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          widget.product.priceCurrency
                              .label(widget.product.price, widget.currency),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor),
                        ),
                      ),
                      const Icon(Icons.add_circle,
                          color: AppTheme.primaryColor, size: 24),
                    ],
                  ),
                ],
              ),
            ),

            // Live "already in cart" quantity badge (top-start corner).
            if (inCart > 0)
              PositionedDirectional(
                top: 6,
                start: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(formatQty(inCart),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ),

            // Brief green check flash centered on the tile right after a tap.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _justAdded ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numeric-keypad dialog for setting an exact cart quantity. Owns its own
/// [TextEditingController] so it's disposed in [dispose] — after the element is
/// fully unmounted — rather than in the caller's async gap, which would tear
/// the field down mid-transition.
class _QuantityDialog extends StatefulWidget {
  final CartItem item;
  const _QuantityDialog({required this.item});

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: formatQty(widget.item.quantity));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Parse tolerantly (Arabic digits/separators) and reject non-finite values;
  /// null leaves the quantity unchanged.
  void _submit() =>
      Navigator.of(context).pop(NumInput.parseFlexibleNumber(_controller.text));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.item.product.name,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: NumInput.decimalFormatters,
        decoration: InputDecoration(labelText: l10n.quantityDialogTitle),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Dual-field entry for a measured product (priced per kg). Weight and amount
/// are shown together and stay in sync: typing in one recomputes the other
/// (weight → amount = weight × price; amount → weight = amount / price). The
/// field being edited is the source of truth — the callback only writes the
/// *other* controller, so there's no feedback loop. Returns the chosen weight
/// (kg) at full precision, so `price × weight` reconstructs the exact money
/// amount the cashier entered.
class _MeasuredEntryDialog extends StatefulWidget {
  final Product product;
  final String currency;

  /// The per-unit (per-kg) price **in SP** — already resolved from the product's
  /// currency at the current rate, so weight↔amount linkage and the shown total
  /// are all in SP.
  final double pricePerUnit;
  final double initialWeight;

  const _MeasuredEntryDialog({
    required this.product,
    required this.currency,
    required this.pricePerUnit,
    this.initialWeight = 0,
  });

  @override
  State<_MeasuredEntryDialog> createState() => _MeasuredEntryDialogState();
}

class _MeasuredEntryDialogState extends State<_MeasuredEntryDialog> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _amountCtrl;
  double _weight = 0;

  double get _price => widget.pricePerUnit;

  @override
  void initState() {
    super.initState();
    _weight = widget.initialWeight;
    _weightCtrl = TextEditingController(
        text: _weight > 0 ? formatQty(_weight) : '');
    _amountCtrl = TextEditingController(
        text: _weight > 0 ? (_weight * _price).toStringAsFixed(2) : '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // Setting `controller.text` does not fire the other field's onChanged, so
  // these two handlers can't recurse into each other.
  void _onWeightChanged(String v) {
    final w = NumInput.parseFlexibleNumber(v) ?? 0;
    _weight = w;
    _amountCtrl.text = w > 0 ? (w * _price).toStringAsFixed(2) : '';
    setState(() {});
  }

  void _onAmountChanged(String v) {
    final a = NumInput.parseFlexibleNumber(v) ?? 0;
    final w = _price > 0 ? a / _price : 0.0;
    _weight = w;
    _weightCtrl.text = w > 0 ? formatQty(w) : '';
    setState(() {});
  }

  void _confirm() =>
      Navigator.of(context).pop(_weight > 0 ? _weight : null);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canAmount = _price > 0;
    return AlertDialog(
      title: Text(widget.product.name,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.priceLabel}: ${widget.currency}${_price.toStringAsFixed(2)} / ${l10n.unitKg}',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: NumInput.decimalFormatters,
            decoration: InputDecoration(
              labelText: l10n.weightFieldLabel,
              suffixText: l10n.unitKg,
            ),
            onChanged: _onWeightChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            enabled: canAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: NumInput.decimalFormatters,
            decoration: InputDecoration(
              labelText: l10n.amountFieldLabel,
              suffixText: widget.currency,
            ),
            onChanged: _onAmountChanged,
          ),
          const SizedBox(height: 16),
          Text(
            '${l10n.colTotal}: ${widget.currency}${(_weight * _price).toStringAsFixed(2)}',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.primaryColor),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _weight > 0 ? _confirm : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
