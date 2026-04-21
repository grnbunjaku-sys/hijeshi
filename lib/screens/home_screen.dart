import 'dart:async';

import 'package:flutter/material.dart';

import '../services/shopify_service.dart';
import '../services/cart_service.dart';
import '../services/favorite_service.dart';
import '../utils/price_utils.dart';
import 'main_screen.dart';
import 'product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? collectionHandle;
  final String? title;

  const HomeScreen({
    super.key,
    this.collectionHandle,
    this.title,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShopifyService _shopifyService = ShopifyService();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  List<dynamic> allProducts = [];
  List<dynamic> filteredProducts = [];
  List<Map<String, String>> collections = const [
    {'title': 'All', 'handle': '', 'image': ''},
  ];

  bool isLoading = true;
  bool isLoadingCollections = true;
  String selectedSort = 'default';

  final List<String> sortOptions = [
    'default',
    'price_low_high',
    'price_high_low',
    'name_az',
    'name_za',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadFavorites());
      unawaited(_loadCollections());
      unawaited(_loadProducts());
    });

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) {
        _debounce!.cancel();
      }

      _debounce = Timer(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        _applyFilters();
      });

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    try {
      final loadedCollections = await _shopifyService.fetchCollections();

      if (!mounted) return;

      setState(() {
        collections = loadedCollections;
        isLoadingCollections = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingCollections = false;
      });

      debugPrint('Error loading collections: $e');
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final products = await _shopifyService.fetchProducts(
        collectionHandle: widget.collectionHandle,
      );

      if (!mounted) return;

      setState(() {
        allProducts = products;
        isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      debugPrint('Error loading products: $e');
    }
  }

  Future<void> _loadFavorites() async {
    await FavoriteService.loadFavorites();

    if (!mounted) return;

    setState(() {});
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

  String _getProductImage(Map<String, dynamic> product) {
    final imageEdges = product['images']?['edges'] as List? ?? [];

    if (imageEdges.isEmpty) return '';

    return imageEdges[0]['node']['url']?.toString() ?? '';
  }

  String _getProductPriceString(Map<String, dynamic> product) {
    final variantEdges = product['variants']?['edges'] as List? ?? [];

    if (variantEdges.isEmpty) return '0.00';

    return variantEdges[0]['node']['price']?['amount']?.toString() ?? '0.00';
  }

  double _getProductPrice(Map<String, dynamic> product) {
    return double.tryParse(_getProductPriceString(product)) ?? 0.0;
  }

  String _getProductVendor(Map<String, dynamic> product) {
    return (product['vendor'] ?? '').toString().trim();
  }

  void _applyFilters() {
    List<dynamic> products = List.from(allProducts);
    final query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      products = products.where((edge) {
        final product = edge['node'] as Map<String, dynamic>;
        final title = (product['title'] ?? '').toString().toLowerCase();
        final vendor = (product['vendor'] ?? '').toString().toLowerCase();
        final productType =
        (product['productType'] ?? '').toString().toLowerCase();
        final tags = (product['tags'] ?? []).toString().toLowerCase();

        return title.contains(query) ||
            vendor.contains(query) ||
            productType.contains(query) ||
            tags.contains(query);
      }).toList();
    }

    switch (selectedSort) {
      case 'price_low_high':
        products.sort((a, b) {
          final productA = a['node'] as Map<String, dynamic>;
          final productB = b['node'] as Map<String, dynamic>;
          return _getProductPrice(productA)
              .compareTo(_getProductPrice(productB));
        });
        break;

      case 'price_high_low':
        products.sort((a, b) {
          final productA = a['node'] as Map<String, dynamic>;
          final productB = b['node'] as Map<String, dynamic>;
          return _getProductPrice(productB)
              .compareTo(_getProductPrice(productA));
        });
        break;

      case 'name_az':
        products.sort((a, b) {
          final productA = a['node'] as Map<String, dynamic>;
          final productB = b['node'] as Map<String, dynamic>;
          return (productA['title'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo((productB['title'] ?? '').toString().toLowerCase());
        });
        break;

      case 'name_za':
        products.sort((a, b) {
          final productA = a['node'] as Map<String, dynamic>;
          final productB = b['node'] as Map<String, dynamic>;
          return (productB['title'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo((productA['title'] ?? '').toString().toLowerCase());
        });
        break;

      case 'default':
      default:
        break;
    }

    if (!mounted) return;

    setState(() {
      filteredProducts = products;
    });
  }

  String _sortLabel(String value) {
    switch (value) {
      case 'price_low_high':
        return 'Price: Low to High';
      case 'price_high_low':
        return 'Price: High to Low';
      case 'name_az':
        return 'Name: A-Z';
      case 'name_za':
        return 'Name: Z-A';
      default:
        return 'Default';
    }
  }

  String _currentHandle() {
    return widget.collectionHandle ?? '';
  }

  void _openCollection(Map<String, String> collection) {
    final handle = collection['handle'] ?? '';
    final title = collection['title'] ?? 'Shop';

    if (_currentHandle() == handle) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          initialIndex: 1,
          shopTitle: title,
          shopCollectionHandle: handle.isEmpty ? null : handle,
        ),
      ),
          (route) => false,
    );
  }

  Widget _buildCollectionChip({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.10 : 0.04),
              blurRadius: isSelected ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndSortCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products, brands...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _applyFilters();
                },
                icon: const Icon(Icons.close),
              )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF4F5F7),
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Colors.black12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSort,
                isExpanded: true,
                borderRadius: BorderRadius.circular(18),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: sortOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      _sortLabel(option),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedSort = value;
                  });
                  _applyFilters();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final image = _getProductImage(product);
    final price = _getProductPriceString(product);
    final productId = product['id']?.toString() ?? '';
    final title = product['title']?.toString() ?? '';
    final vendor = _getProductVendor(product);
    final isFavorite = FavoriteService.isFavorite(productId);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );

        await _loadFavorites();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey,
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
                              color: Colors.grey,
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
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    right: 18,
                    child: Column(
                      children: [
                        Material(
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
                        const SizedBox(height: 8),
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () async {
                              await _quickAddToCart(product);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(9),
                              child: Icon(
                                Icons.add_shopping_cart_outlined,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                        letterSpacing: 0.5,
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
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '€${formatPrice(price)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Save 10% in app',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w700,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 34,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try another keyword or change the selected filters.',
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

  @override
  Widget build(BuildContext context) {
    final currentHandle = _currentHandle();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F4F8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ?? 'Shop',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${filteredProducts.length} products available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _buildSearchAndSortCard(),
            SizedBox(
              height: 64,
              child: isLoadingCollections
                  ? const Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: collections.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  final handle = collection['handle'] ?? '';
                  final title = collection['title'] ?? '';
                  final isSelected = currentHandle == handle;

                  return _buildCollectionChip(
                    title: title,
                    isSelected: isSelected,
                    onTap: () => _openCollection(collection),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: () async {
                  await _loadCollections();
                  await _loadProducts();
                },
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filteredProducts.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.61,
                  ),
                  itemBuilder: (context, index) {
                    final edge =
                    filteredProducts[index] as Map<String, dynamic>;
                    final product = edge['node'] as Map<String, dynamic>;

                    return _buildProductCard(product);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}