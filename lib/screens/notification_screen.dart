import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/shopify_service.dart';
import 'main_screen.dart';
import 'product_details_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Future<void> _clearNotifications() async {
    await NotificationService.clear();
  }

  @override
  void initState() {
    super.initState();
    NotificationService.loadNotifications();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.markAllAsRead();
    });
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
                Icons.notifications_none_rounded,
                size: 42,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nuk ka njoftime ende',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Kur të vijnë njoftime të reja, do të shfaqen këtu.',
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

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final String title = item['title']?.toString() ?? '';
    final String body = item['body']?.toString() ?? '';
    final bool isRead = item['isRead'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
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
          color: isRead
              ? Colors.black.withValues(alpha: 0.04)
              : const Color(0xFFD88FA3).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isRead
                  ? const Color(0xFFF4F5F7)
                  : const Color(0xFFD88FA3).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: isRead ? Colors.black : const Color(0xFFD88FA3),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isRead ? FontWeight.w700 : FontWeight.w800,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
                if (body.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTap(Map<String, dynamic> item, int index) async {
    await NotificationService.markAsReadAt(index);

    final Map<String, dynamic> data =
    Map<String, dynamic>.from(item['data'] ?? {});

    final String type = (data['type'] ?? '').toString();
    final String collectionHandle =
    (data['collectionHandle'] ?? '').toString();
    final String collectionTitle = (data['title'] ?? 'Collection').toString();
    final String productId = (data['productId'] ?? '').toString();

    final navigator = Navigator.of(context);

    if (type == 'collection' && collectionHandle.isNotEmpty) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainScreen(
            initialIndex: 1,
            shopTitle: collectionTitle,
            shopCollectionHandle: collectionHandle,
          ),
        ),
            (route) => false,
      );
      return;
    }

    if (type == 'cart') {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainScreen(initialIndex: 3),
        ),
            (route) => false,
      );
      return;
    }

    if (type == 'home') {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainScreen(initialIndex: 0),
        ),
            (route) => false,
      );
      return;
    }

    if (type == 'product' && productId.isNotEmpty) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainScreen(initialIndex: 1),
        ),
            (route) => false,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      try {
        final shopify = ShopifyService();
        final product = await shopify.fetchProductById(productId);

        if (product != null) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error opening product: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.notifier,
      builder: (context, _, __) {
        final List<Map<String, dynamic>> notifications =
        List<Map<String, dynamic>>.from(NotificationService.notifications);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F4F8),
          appBar: AppBar(
            title: const Text(
              'Njoftimet',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFFF7F4F8),
            actions: [
              if (notifications.isNotEmpty)
                TextButton(
                  onPressed: _clearNotifications,
                  child: const Text(
                    'Pastro',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          body: notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final Map<String, dynamic> item = notifications[index];

              return GestureDetector(
                onTap: () => _handleTap(item, index),
                child: _buildNotificationCard(item),
              );
            },
          ),
        );
      },
    );
  }
}