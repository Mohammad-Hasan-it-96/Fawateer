import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app_settings/app_settings.dart';

import '../../../../core/utils/num_input.dart';

import '../../../billing/presentation/bloc/billing_bloc.dart';
import '../billing_error_text.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/domain/entities/product.dart';
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
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    returnImage: false,
  );

  bool _isCameraOn = true;
  bool _isFlashOn = false;
  bool _onCheckout = false;

  final Map<String, DateTime> _lastScanTimes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start/stop camera based on whether this branch is the visible tab
    final visible = TickerMode.of(context);
    if (visible && _isCameraOn) {
      _startScanner();
    } else if (!visible) {
      _scannerController.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isCameraOn && !_onCheckout && TickerMode.of(context)) {
        _startScanner();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _scannerController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  /// Start the camera, swallowing platform errors (permission denied, no
  /// camera). The [MobileScanner] errorBuilder renders the user-facing fallback,
  /// so an unhandled async throw never escapes here.
  void _startScanner() {
    _scannerController.start().catchError((_) {});
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
          // Restart camera when returning from checkout (cart cleared)
          BlocListener<BillingBloc, BillingState>(
            listenWhen: (prev, curr) =>
                _onCheckout &&
                prev.cartItems.isNotEmpty &&
                curr.cartItems.isEmpty,
            listener: (context, state) {
              if (_onCheckout) {
                setState(() => _onCheckout = false);
                if (_isCameraOn) _startScanner();
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
                    _scannerController.stop();
                    await context.push('/pos/checkout');
                    // Back from checkout: cart may be preserved (Back) or
                    // cleared (New Sale) — either way, resume scanning.
                    if (mounted) {
                      setState(() => _onCheckout = false);
                      if (_isCameraOn) _startScanner();
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
            controller: _scannerController,
            onDetect: _onDetect,
            // Shown when the camera can't start (permission denied, no camera).
            errorBuilder: (context, error, child) =>
                _buildCameraErrorState(l10n),
          ),
          if (!_isCameraOn) _buildCameraOffState(l10n),

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
                    if (_isCameraOn) {
                      _startScanner();
                    } else {
                      _scannerController.stop();
                    }
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
              _startScanner();
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.settings),
            label: Text(l10n.openSettings,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => AppSettings.openAppSettings(),
          ),
        ],
      ),
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
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, -5))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
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
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(l10n.totalPrice,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700])),
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
                color: Colors.grey[100], shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(Icons.shopping_basket, size: 40, color: Colors.grey[300]),
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
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
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
                      ? '${formatQty(item.quantity)} ${l10n.unitKg} × $currency${item.product.price.toStringAsFixed(2)}'
                      : '$currency${item.product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: measured ? 12 : 14,
                      color: Colors.grey[600]),
                ),
                if (measured) ...[
                  const SizedBox(height: 2),
                  Text('$currency${item.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.primaryColor)),
                ],
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
                color: Colors.grey[100],
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
        child: Icon(icon, size: 24, color: Colors.grey[800]),
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
    double existing = 0;
    for (final c in context.read<BillingBloc>().state.cartItems) {
      if (c.product.id == product.id) {
        existing = c.quantity;
        break;
      }
    }
    return showDialog<double>(
      context: context,
      builder: (_) => _MeasuredEntryDialog(
        product: product,
        currency: currency,
        initialWeight: existing,
      ),
    );
  }

  /// Opens a searchable product grid so the cashier can add items that have
  /// no barcode (or when scanning fails). Pauses the camera while open.
  void _showProductPicker(BuildContext context) {
    _scannerController.stop();
    final shopState = context.read<ShopBloc>().state;
    final currency =
        shopState is ShopLoaded ? shopState.shop.currencySymbol : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
    ).whenComplete(() {
      if (mounted && _isCameraOn && !_onCheckout) _startScanner();
    });
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
                  color: Colors.grey.withValues(alpha: 0.3),
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
                            style: const TextStyle(color: Colors.grey)))
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
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: highlighted
                      ? AppTheme.primaryColor
                      : Colors.grey.shade200,
                  width: highlighted ? 1.5 : 1,
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
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
                          '${widget.currency}${widget.product.price.toStringAsFixed(2)}',
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
  final double initialWeight;

  const _MeasuredEntryDialog({
    required this.product,
    required this.currency,
    this.initialWeight = 0,
  });

  @override
  State<_MeasuredEntryDialog> createState() => _MeasuredEntryDialogState();
}

class _MeasuredEntryDialogState extends State<_MeasuredEntryDialog> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _amountCtrl;
  double _weight = 0;

  double get _price => widget.product.price;

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
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
