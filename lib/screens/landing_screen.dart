import 'dart:async';

import 'package:flutter/material.dart';

import '../services/shopify_service.dart';
import '../services/favorite_service.dart';
import '../services/cart_service.dart';
import '../utils/price_utils.dart';
import 'main_screen.dart';
import 'product_details_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ShopifyService _shopifyService = ShopifyService();
  final PageController _pageController = PageController(viewportFraction: 0.92);

  Timer? _sliderTimer;
  bool isLoading = true;

  List<Map<String, String>> brandCollections = [];
  List<Map<String, String>> categoryCollections = [];
  Map<String, dynamic>? bestSellerCollection;
  Map<String, dynamic>? justDroppedCollection;
  Map<String, dynamic>? parfumesCollection;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await FavoriteService.loadFavorites();

      final data = await _shopifyService.fetchHomeData();

      if (!mounted) return;

      setState(() {
        brandCollections = List<Map<String, String>>.from(
          data["brands"] ?? <Map<String, String>>[],
        );
        categoryCollections = List<Map<String, String>>.from(
          data["categories"] ?? <Map<String, String>>[],
        );
        bestSellerCollection = data["bestSeller"] as Map<String, dynamic>?;
        justDroppedCollection = data["justDropped"] as Map<String, dynamic>?;
        parfumesCollection = data["parfumes"] as Map<String, dynamic>?;
        isLoading = false;
      });

      _startSlider();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      debugPrint('Error loading landing data: $e');
    }
  }

  void _startSlider() {
    _sliderTimer?.cancel();

    if (brandCollections.length <= 1) return;

    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients || brandCollections.isEmpty) {
        return;
      }

      final nextPage = (_currentPage + 1) % brandCollections.length;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  void _openShopCollection({
    required String title,
    required String handle,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          initialIndex: 1,
          shopTitle: title,
          shopCollectionHandle: handle.isEmpty ? null : handle,
        ),
      ),
    );
  }

  String _getProductImage(Map<String, dynamic> product) {
    final imageEdges = product['images']?['edges'] as List? ?? [];

    if (imageEdges.isEmpty) return '';

    return imageEdges[0]['node']?['url']?.toString() ?? '';
  }

  String _getProductPriceString(Map<String, dynamic> product) {
    final variantEdges = product['variants']?['edges'] as List? ?? [];

    if (variantEdges.isEmpty) return '0.00';

    return variantEdges[0]['node']?['price']?['amount']?.toString() ?? '0.00';
  }

  Future<void> _toggleFavorite(Map<String, dynamic> product) async {
    final imageEdges = product['images']?['edges'] as List? ?? [];
    final variantEdges = product['variants']?['edges'] as List? ?? [];

    final image = imageEdges.isNotEmpty
        ? imageEdges[0]['node']['url']?.toString() ?? ''
        : '';

    final variantId = variantEdges.isNotEmpty
        ? variantEdges[0]['node']['id']?.toString() ?? ''
        : '';

    final price = variantEdges.isNotEmpty
        ? (variantEdges[0]['node']['price']?['amount']?.toString() ?? '0.00')
        : '0.00';

    final favoriteProduct = {
      'id': product['id']?.toString() ?? '',
      'variantId': variantId,
      'title': product['title']?.toString() ?? 'Produkt',
      'price': price,
      'image': image,
      'description': product['description']?.toString() ?? '',
    };

    if ((favoriteProduct['id'] as String).isEmpty) return;

    await FavoriteService.toggleFavorite(favoriteProduct);

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _quickAddToCart(Map<String, dynamic> product) async {
    final imageEdges = product['images']?['edges'] as List? ?? [];
    final variantEdges = product['variants']?['edges'] as List? ?? [];

    if (variantEdges.isEmpty) return;

    final image = imageEdges.isNotEmpty
        ? imageEdges[0]['node']['url']?.toString() ?? ''
        : '';

    final firstVariant = variantEdges[0]['node'];
    final variantId = firstVariant['id']?.toString() ?? '';
    final price = firstVariant['price']?['amount']?.toString() ?? '0.00';

    if (variantId.isEmpty) return;

    await CartService.addToCart({
      'id': variantId,
      'variantId': variantId,
      'title': product['title']?.toString() ?? 'Produkt',
      'price': price,
      'image': image,
      'quantity': 1,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['title'] ?? 'Produkti'} u shtua në shportë'),
        duration: const Duration(seconds: 1),
      ),
    );

    setState(() {});
  }

  bool _isFavorite(String productId) {
    return FavoriteService.isFavorite(productId);
  }

  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: Colors.black,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Text(
                      'Shop all',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F8),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildHeader(),
                const SizedBox(height: 18),
                _buildSearchRow(),
                const SizedBox(height: 24),
                if (brandCollections.isNotEmpty) ...[
                  _buildSectionHeader(
                    title: 'Brendet më të njohura',
                    subtitle: 'Zgjedhjet më të preferuara nga dyqani',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 470,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: brandCollections.length,
                      onPageChanged: (index) {
                        if (!mounted) return;
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final brand = brandCollections[index];
                        return _buildBrandSlide(brand);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDotsIndicator(),
                ],
                const SizedBox(height: 30),
                if (categoryCollections.isNotEmpty) ...[
                  _buildSectionHeader(
                    title: 'Collections',
                    subtitle: 'Eksploro kategoritë kryesore',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 240,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryCollections.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final collection = categoryCollections[index];
                        return _buildCollectionCard(collection);
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _buildProductSection(bestSellerCollection),
                const SizedBox(height: 32),
                _buildProductSection(justDroppedCollection),
                const SizedBox(height: 32),
                _buildProductSection(parfumesCollection),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              height: 52,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return const Text(
                  'HIJESHI COSMETICS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.black,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Original beauty picks, premium experience',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                _openShopCollection(
                  title: 'Të gjitha produktet',
                  handle: '',
                );
              },
              child: Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade600),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search products, brands...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildActionIcon(
            icon: Icons.favorite_border,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainScreen(initialIndex: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<int>(
            valueListenable: CartService.cartCountNotifier,
            builder: (context, cartCount, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildActionIcon(
                    icon: Icons.shopping_bag_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const MainScreen(initialIndex: 3),
                        ),
                      );
                    },
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
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
                          cartCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(icon, size: 26, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildDotsIndicator() {
    final visibleDots =
    brandCollections.length > 6 ? 6 : brandCollections.length;
    final activeIndex =
        _currentPage % (brandCollections.isEmpty ? 1 : brandCollections.length);

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          visibleDots,
              (index) {
            final isActive = index == (activeIndex % visibleDots);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? const Color(0xFFE8B8C7)
                    : Colors.grey.shade300,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrandSlide(Map<String, String> brand) {
    final title = brand['title'] ?? '';
    final handle = brand['handle'] ?? '';
    final image = brand['image'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 8),
      child: GestureDetector(
        onTap: () => _openShopCollection(title: title, handle: handle),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: image.isNotEmpty
                        ? SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Image.network(
                          image,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              width: 220,
                              height: 220,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                        : Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3DDE6),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Shop now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        color: Colors.black,
                      ),
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

  Widget _buildCollectionCard(Map<String, String> collection) {
    final title = collection['title'] ?? '';
    final handle = collection['handle'] ?? '';
    final image = collection['image'] ?? '';

    return GestureDetector(
      onTap: () => _openShopCollection(title: title, handle: handle),
      child: SizedBox(
        width: 180,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: image.isNotEmpty
                      ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.image_not_supported_outlined),
                        ),
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(6),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.70),
                      ],
                    ),
                  ),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSection(Map<String, dynamic>? section) {
    if (section == null) return const SizedBox.shrink();

    final title = section['title']?.toString() ?? '';
    final handle = section['handle']?.toString() ?? '';
    final products = section['products'] as List<dynamic>? ?? [];

    if (title.isEmpty || products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: title,
          subtitle: 'Shiko produktet më të veçuara',
          onTap: () => _openShopCollection(title: title, handle: handle),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 392,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final edge = products[index] as Map<String, dynamic>;
              final product = edge['node'] as Map<String, dynamic>;
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final image = _getProductImage(product);
    final price = _getProductPriceString(product);
    final productId = product['id']?.toString() ?? '';
    final isFavorite = _isFavorite(productId);
    final vendor = (product['vendor'] ?? '').toString().trim();
    final title = product['title']?.toString() ?? '';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );

        await FavoriteService.loadFavorites();

        if (!mounted) return;
        setState(() {});
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.black.withOpacity(0.03),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: image.isNotEmpty
                            ? Image.network(
                          image,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                ),
                              ),
                            );
                          },
                        )
                            : Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    left: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.20),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        '10% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    right: 18,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () async {
                          await _toggleFavorite(product);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: isFavorite ? Colors.red : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vendor.isNotEmpty) ...[
                    Text(
                      vendor.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '€${formatPrice(price)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async => _quickAddToCart(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Add to cart',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}