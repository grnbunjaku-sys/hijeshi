import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/order_service.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bool isLoggedIn = await AuthService.isLoggedIn();
    final String userName = await AuthService.getUserName() ?? '';
    final String userEmail = await AuthService.getUserEmail() ?? '';

    await OrderService.loadOrders();

    if (!mounted) return;

    setState(() {
      _isLoggedIn = isLoggedIn;
      _userName = userName;
      _userEmail = userEmail;
      _isLoading = false;
    });
  }

  Future<void> _refreshOrders() async {
    await OrderService.loadOrders();

    if (!mounted) return;

    setState(() {});
  }

  String _formatPrice(dynamic value) {
    final double parsed = double.tryParse(value.toString()) ?? 0;
    return parsed.toStringAsFixed(2);
  }

  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year • $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildGuestState() {
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
                size: 42,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Duhet të kyçesh për të parë porositë',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Hyr në llogarinë tënde që të shohësh historinë dhe statusin e porosive.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrdersState() {
    final String displayName = _userName.isNotEmpty ? _userName : 'User';
    final String displayEmail =
    _userEmail.isNotEmpty ? _userEmail : 'No email available';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
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
                  Icons.receipt_long_outlined,
                  size: 42,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ende nuk ke porosi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pasi të bësh porosinë e parë, ajo do të shfaqet këtu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
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
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      label: 'Emri',
                      value: displayName,
                    ),
                    const SizedBox(height: 14),
                    _buildInfoRow(
                      icon: Icons.mail_outline,
                      label: 'Email',
                      value: displayEmail,
                    ),
                    const SizedBox(height: 14),
                    _buildInfoRow(
                      icon: Icons.info_outline,
                      label: 'Status',
                      value: 'No orders yet',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: Colors.black87,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final String orderNumber = (order['orderNumber'] ?? '').toString();
    final String status = (order['status'] ?? 'Completed').toString();
    final String createdAt = (order['createdAt'] ?? '').toString();
    final String currency = (order['currency'] ?? 'EUR').toString();
    final double total = double.tryParse(order['total'].toString()) ?? 0;
    final int totalItems = int.tryParse(order['totalItems'].toString()) ?? 0;

    final List<dynamic> items = (order['items'] as List<dynamic>? ?? []);

    String currencySymbol = '€';
    if (currency.toUpperCase() == 'USD') {
      currencySymbol = '\$';
    } else if (currency.toUpperCase() == 'GBP') {
      currencySymbol = '£';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  orderNumber,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFD88FA3).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD88FA3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(createdAt),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.shopping_bag_outlined,
            label: 'Artikuj',
            value: '$totalItems',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.payments_outlined,
            label: 'Totali',
            value: '${_formatPrice(total)} $currencySymbol',
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Produktet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            ...items.take(4).map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              final title = (map['title'] ?? 'Product').toString();
              final quantity = int.tryParse(map['quantity'].toString()) ?? 1;
              final variantText =
              (map['selectedVariantText'] ?? '').toString();

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        variantText.isNotEmpty
                            ? '$title ×$quantity • $variantText'
                            : '$title ×$quantity',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: OrderService.notifier,
      builder: (context, _, __) {
        final orders = OrderService.orders;

        Widget body;
        if (_isLoading) {
          body = _buildLoadingState();
        } else if (!_isLoggedIn) {
          body = _buildGuestState();
        } else if (orders.isEmpty) {
          body = _buildEmptyOrdersState();
        } else {
          body = RefreshIndicator(
            onRefresh: _refreshOrders,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = Map<String, dynamic>.from(orders[index]);
                return _buildOrderCard(order);
              },
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7F4F8),
          appBar: AppBar(
            title: const Text(
              'Porositë',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFFF7F4F8),
            elevation: 0,
          ),
          body: body,
        );
      },
    );
  }
}