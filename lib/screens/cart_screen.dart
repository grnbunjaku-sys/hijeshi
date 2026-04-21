import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/checkout_service.dart';
import '../utils/price_utils.dart';
import 'checkout_webview.dart';
import 'main_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double _sheetSize = 0.24;

  double get subtotal {
    return CartService.totalPrice;
  }

  double get appDiscount => subtotal * 0.10;

  double get totalAfterDiscount => subtotal - appDiscount;

  bool get _isExpanded => _sheetSize > 0.34;

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainScreen(),
      ),
          (route) => false,
    );
  }

  Future<void> _handleCheckout() async {
    try {
      if (CartService.cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shporta është bosh'),
          ),
        );
        return;
      }

      final checkoutUrl = await CheckoutService.createCheckoutUrl(
        CartService.cartItems,
      );

      if (!mounted) return;

      if (checkoutUrl == null || checkoutUrl.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gabim: Checkout URL nuk u krijua.'),
          ),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutWebView(url: checkoutUrl),
        ),
      );

      if (mounted) {
        setState(() {});
      }
    } on OutOfStockException catch (e) {
      for (int i = 0; i < e.productIds.length; i++) {
        final productId = e.productIds[i];
        final variantId = i < e.variantIds.length ? e.variantIds[i] : '';

        await CartService.removeFromCart(
          productId,
          variantId: variantId,
        );
      }

      if (!mounted) return;

      setState(() {});

      final names = e.productTitles.join(', ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            names.isNotEmpty
                ? 'U hoqën nga shporta sepse nuk kanë stok: $names'
                : 'Disa artikuj u hoqën nga shporta sepse nuk kanë stok.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      if (CartService.cartItems.isEmpty) {
        _goToHome();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gabim: $e'),
        ),
      );
    }
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF7F7F8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: Colors.black,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 40,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Shporta është bosh',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Shto produktet e preferuara dhe vazhdo me checkout.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _goToHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Kthehu te Home',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final image = item['image'];
    final title = item['title'] ?? '';
    final variantText = (item['selectedVariantText'] ?? '').toString().trim();
    final price = double.tryParse(item['price'].toString()) ?? 0;
    final quantity = item['quantity'] ?? 1;
    final productId = item['id'].toString();
    final variantId = (item['variantId'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F8),
              borderRadius: BorderRadius.circular(22),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: image != null && image.toString().isNotEmpty
                  ? Image.network(
                image.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                    ),
                  );
                },
              )
                  : Container(
                color: Colors.grey.shade300,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
                if (variantText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    variantText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '€${formatPrice(price)}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onTap: () async {
                          await CartService.decreaseQuantity(
                            productId,
                            variantId: variantId,
                          );
                        },
                      ),
                      SizedBox(
                        width: 42,
                        child: Center(
                          child: Text(
                            quantity.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onTap: () async {
                          await CartService.increaseQuantity(
                            productId,
                            variantId: variantId,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: const Color(0xFFFBEAEA),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                await CartService.removeFromCart(
                  productId,
                  variantId: variantId,
                );
              },
              child: const SizedBox(
                width: 52,
                height: 52,
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Column(
      children: [
        Container(
          width: 46,
          height: 5,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Row(
          children: [
            const Text(
              'Estimated Total',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '€${formatPrice(totalAfterDiscount)}',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildExpandedSummaryDetails() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEFFAF2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFCDEED6),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                color: Colors.green,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'App Discount 10% aplikohet automatikisht në checkout.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Subtotal',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '€${formatPrice(subtotal)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Text(
              'App Discount (10%)',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
            Spacer(),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Spacer(),
            Text(
              '-€${formatPrice(appDiscount)}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              'Delivery',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              'Calculated at checkout',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Divider(color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Promo code tjetër mund ta shtoni në checkout.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _handleCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: const Text(
          'Proceed to Checkout',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildSlidingSummary() {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        final newSize = notification.extent;
        if ((newSize - _sheetSize).abs() > 0.01 && mounted) {
          setState(() {
            _sheetSize = newSize;
          });
        }
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.24,
        minChildSize: 0.20,
        maxChildSize: 0.72,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryHeader(),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: _buildExpandedSummaryDetails(),
                        crossFadeState: _isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 220),
                      ),
                      _buildCheckoutButton(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CartService.cartCountNotifier,
      builder: (context, _, __) {
        final cartItems = List<Map<String, dynamic>>.from(CartService.cartItems);

        return ValueListenableBuilder<double>(
          valueListenable: CartService.cartTotalNotifier,
          builder: (context, __, ___) {
            return Scaffold(
              backgroundColor: const Color(0xFFF7F4F8),
              appBar: AppBar(
                backgroundColor: const Color(0xFFF7F4F8),
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed: _goToHome,
                ),
                title: const Text(
                  'My Cart',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              body: cartItems.isEmpty
                  ? _buildEmptyState()
                  : Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 240),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartItem(item);
                    },
                  ),
                  _buildSlidingSummary(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}