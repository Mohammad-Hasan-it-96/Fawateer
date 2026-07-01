import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
      _scannerController.start();
    } else if (!visible) {
      _scannerController.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isCameraOn && !_onCheckout && TickerMode.of(context)) {
        _scannerController.start();
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
          // Restart camera when returning from checkout (cart cleared)
          BlocListener<BillingBloc, BillingState>(
            listenWhen: (prev, curr) =>
                _onCheckout &&
                prev.cartItems.isNotEmpty &&
                curr.cartItems.isEmpty,
            listener: (context, state) {
              if (_onCheckout) {
                setState(() => _onCheckout = false);
                if (_isCameraOn) _scannerController.start();
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
                      if (_isCameraOn) _scannerController.start();
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
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
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
                      _scannerController.start();
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
              _scannerController.start();
            },
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
                Builder(builder: (context) {
                  final shopState = context.watch<ShopBloc>().state;
                  final currency = shopState is ShopLoaded
                      ? shopState.shop.currencySymbol
                      : '';
                  return Text(
                    '$currency${item.product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[600]),
                  );
                }),
              ],
            ),
          ),
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
                      context.read<BillingBloc>().add(
                          UpdateQuantityEvent(item.product.id, item.quantity - 1));
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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

  /// Opens a searchable product grid so the cashier can add items that have
  /// no barcode (or when scanning fails). Pauses the camera while open.
  void _showProductPicker(BuildContext context) {
    _scannerController.stop();
    final products = context.read<ProductBloc>().state.products;
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
        products: products,
        currency: currency,
        onAdd: (product) async {
          context.read<BillingBloc>().add(AddProductToCartEvent(product));
          final canVibrate = await Vibrate.canVibrate;
          if (canVibrate) Vibrate.feedback(FeedbackType.success);
        },
      ),
    ).whenComplete(() {
      if (mounted && _isCameraOn && !_onCheckout) _scannerController.start();
    });
  }
}

/// Bottom-sheet product picker: search field + tap-to-add grid. Stays open for
/// multiple adds; the cart total updates live on the screen behind it.
class _ProductPickerSheet extends StatefulWidget {
  final List<Product> products;
  final String currency;
  final void Function(Product) onAdd;

  const _ProductPickerSheet({
    required this.products,
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
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.products
        : widget.products
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
                child: filtered.isEmpty
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
                        itemBuilder: (context, i) =>
                            _buildTile(context, filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTile(BuildContext context, Product p) {
    return InkWell(
      onTap: () => widget.onAdd(p),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(p.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${widget.currency}${p.price.toStringAsFixed(2)}',
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

  void _submit() =>
      Navigator.of(context).pop(double.tryParse(_controller.text));

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
