import 'package:flutter/material.dart';
import 'landing_screen.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import '../services/cart_service.dart';
import '../services/notification_service.dart';
import 'notification_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  final String? shopTitle;
  final String? shopCollectionHandle;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
    this.shopTitle,
    this.shopCollectionHandle,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const Color _activePink = Color(0xFFD88FA3);

  late int _selectedIndex;
  late String? _shopTitle;
  late String? _shopCollectionHandle;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _shopTitle = widget.shopTitle;
    _shopCollectionHandle = widget.shopCollectionHandle;
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialIndex != widget.initialIndex ||
        oldWidget.shopTitle != widget.shopTitle ||
        oldWidget.shopCollectionHandle != widget.shopCollectionHandle) {
      setState(() {
        _selectedIndex = widget.initialIndex;
        _shopTitle = widget.shopTitle;
        _shopCollectionHandle = widget.shopCollectionHandle;
      });
    }
  }

  List<Widget> get _screens => [
    const LandingScreen(),
    HomeScreen(
      key: ValueKey('${_shopCollectionHandle ?? 'all'}_${_shopTitle ?? ''}'),
      title: _shopTitle ?? 'Të gjitha produktet',
      collectionHandle: _shopCollectionHandle,
    ),
    const FavoritesScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavIcon({
    required IconData icon,
    required bool isSelected,
    Widget? badge,
  }) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Icon(
              icon,
              size: 24,
              color: isSelected ? _activePink : Colors.grey.shade500,
            ),
          ),
          if (badge != null) badge,
        ],
      ),
    );
  }

  Widget _buildCartBadge(int count) {
    if (count <= 0) return const SizedBox.shrink();

    return Positioned(
      right: -4,
      top: -4,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(
          minWidth: 18,
          minHeight: 18,
        ),
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.unreadCountNotifier,
      builder: (context, count, _) {
        return Positioned(
          top: 48,
          right: 18,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationScreen(),
                ),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_none,
                    color: Colors.black,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CartService.cartCountNotifier,
      builder: (context, cartCount, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F4F8),
          body: Stack(
            children: [
              _screens[_selectedIndex],
              _buildNotificationBell(),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: _activePink,
                unselectedItemColor: Colors.grey,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                items: [
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(
                      icon: Icons.home_outlined,
                      isSelected: _selectedIndex == 0,
                    ),
                    activeIcon: _buildNavIcon(
                      icon: Icons.home_rounded,
                      isSelected: true,
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(
                      icon: Icons.storefront_outlined,
                      isSelected: _selectedIndex == 1,
                    ),
                    activeIcon: _buildNavIcon(
                      icon: Icons.storefront_rounded,
                      isSelected: true,
                    ),
                    label: 'Shop',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(
                      icon: Icons.favorite_border,
                      isSelected: _selectedIndex == 2,
                    ),
                    activeIcon: _buildNavIcon(
                      icon: Icons.favorite,
                      isSelected: true,
                    ),
                    label: 'Favorites',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(
                      icon: Icons.shopping_bag_outlined,
                      isSelected: _selectedIndex == 3,
                      badge: _buildCartBadge(cartCount),
                    ),
                    activeIcon: _buildNavIcon(
                      icon: Icons.shopping_bag,
                      isSelected: true,
                      badge: _buildCartBadge(cartCount),
                    ),
                    label: 'Shporta',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(
                      icon: Icons.person_outline,
                      isSelected: _selectedIndex == 4,
                    ),
                    activeIcon: _buildNavIcon(
                      icon: Icons.person,
                      isSelected: true,
                    ),
                    label: 'Profili',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}