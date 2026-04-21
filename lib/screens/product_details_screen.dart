import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';
import '../services/favorite_service.dart';
import '../utils/price_utils.dart';

class ProductDetailsScreen extends StatefulWidget {
  final dynamic product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String? selectedFirstOptionValue;
  String? selectedSecondOptionValue;
  dynamic selectedVariant;

  @override
  void initState() {
    super.initState();
    _initializeVariantSelection();
  }

  List<dynamic> get _variantEdges {
    try {
      return widget.product['variants']?['edges'] as List<dynamic>? ?? [];
    } catch (_) {
      return [];
    }
  }

  List<dynamic> get _variantNodes {
    return _variantEdges
        .map((edge) => edge['node'])
        .where((node) => node != null)
        .toList();
  }

  List<dynamic> get _productOptions {
    try {
      return widget.product['options'] as List<dynamic>? ?? [];
    } catch (_) {
      return [];
    }
  }

  String _normalizeOptionName(String value) {
    return value.toString().trim().toLowerCase();
  }

  bool _isColorOption(String name) {
    final normalized = _normalizeOptionName(name);
    return normalized == 'color' ||
        normalized == 'colour' ||
        normalized == 'shade' ||
        normalized == 'ngjyra';
  }

  bool _isSizeOption(String name) {
    final normalized = _normalizeOptionName(name);
    return normalized == 'size' ||
        normalized == 'madhesia' ||
        normalized == 'madhësia' ||
        normalized == 'volume' ||
        normalized == 'ml';
  }

  String _getOptionDisplayTitle(String rawName) {
    if (_isColorOption(rawName)) return 'Colours';
    if (_isSizeOption(rawName)) return 'Size';
    return rawName;
  }

  String? get _firstOptionName {
    if (_productOptions.isEmpty) return null;
    final name = _productOptions.first['name']?.toString();
    if (name == null || name.trim().isEmpty) return null;
    return name;
  }

  String? get _secondOptionName {
    if (_productOptions.length < 2) return null;
    final name = _productOptions[1]['name']?.toString();
    if (name == null || name.trim().isEmpty) return null;
    return name;
  }

  String? _getOptionValueByName(dynamic variant, String optionName) {
    try {
      final options = variant['selectedOptions'] as List<dynamic>? ?? [];
      for (final opt in options) {
        final name = opt['name']?.toString() ?? '';
        if (_normalizeOptionName(name) == _normalizeOptionName(optionName)) {
          final value = opt['value']?.toString();
          if (value != null && value.trim().isNotEmpty) {
            return value;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  List<String> _getAllValuesForOption(String optionName) {
    final values = <String>{};

    for (final variant in _variantNodes) {
      final value = _getOptionValueByName(variant, optionName);
      if (value != null && value.isNotEmpty) {
        values.add(value);
      }
    }

    return values.toList();
  }

  List<String> _getFilteredSecondOptionValues() {
    final secondName = _secondOptionName;
    final firstName = _firstOptionName;

    if (secondName == null || secondName.isEmpty) return [];
    if (firstName == null || firstName.isEmpty) {
      return _getAllValuesForOption(secondName);
    }

    final values = <String>{};

    for (final variant in _variantNodes) {
      final firstValue = _getOptionValueByName(variant, firstName);
      final secondValue = _getOptionValueByName(variant, secondName);

      if (secondValue == null || secondValue.isEmpty) continue;

      if (selectedFirstOptionValue == null ||
          selectedFirstOptionValue!.isEmpty ||
          firstValue == selectedFirstOptionValue) {
        values.add(secondValue);
      }
    }

    return values.toList();
  }

  void _initializeVariantSelection() {
    final variants = _variantNodes;
    if (variants.isEmpty) return;

    selectedVariant = variants.first;

    final firstName = _firstOptionName;
    final secondName = _secondOptionName;

    if (firstName != null) {
      selectedFirstOptionValue =
          _getOptionValueByName(selectedVariant, firstName);
    }

    if (secondName != null) {
      selectedSecondOptionValue =
          _getOptionValueByName(selectedVariant, secondName);
    }

    _updateSelectedVariant();
  }

  void _updateSelectedVariant() {
    final variants = _variantNodes;
    final firstName = _firstOptionName;
    final secondName = _secondOptionName;

    if (variants.isEmpty) {
      selectedVariant = null;
      return;
    }

    for (final variant in variants) {
      final firstValue =
      firstName != null ? _getOptionValueByName(variant, firstName) : null;
      final secondValue =
      secondName != null ? _getOptionValueByName(variant, secondName) : null;

      final firstMatches = firstName == null ||
          selectedFirstOptionValue == null ||
          selectedFirstOptionValue!.isEmpty ||
          firstValue == selectedFirstOptionValue;

      final secondMatches = secondName == null ||
          selectedSecondOptionValue == null ||
          selectedSecondOptionValue!.isEmpty ||
          secondValue == selectedSecondOptionValue;

      if (firstMatches && secondMatches) {
        selectedVariant = variant;

        if (firstName != null) {
          selectedFirstOptionValue = _getOptionValueByName(variant, firstName);
        }

        if (secondName != null) {
          selectedSecondOptionValue =
              _getOptionValueByName(variant, secondName);
        }

        return;
      }
    }

    if (firstName != null && selectedFirstOptionValue != null) {
      for (final variant in variants) {
        final firstValue = _getOptionValueByName(variant, firstName);

        if (firstValue == selectedFirstOptionValue) {
          selectedVariant = variant;

          if (secondName != null) {
            selectedSecondOptionValue =
                _getOptionValueByName(variant, secondName);
          }

          return;
        }
      }
    }

    selectedVariant = variants.first;

    if (firstName != null) {
      selectedFirstOptionValue =
          _getOptionValueByName(selectedVariant, firstName);
    }

    if (secondName != null) {
      selectedSecondOptionValue =
          _getOptionValueByName(selectedVariant, secondName);
    }
  }

  void _onFirstOptionSelected(String value) {
    setState(() {
      selectedFirstOptionValue = value;

      final availableSecondValues = _getFilteredSecondOptionValues();

      if (selectedSecondOptionValue != null &&
          !availableSecondValues.contains(selectedSecondOptionValue)) {
        selectedSecondOptionValue =
        availableSecondValues.isNotEmpty ? availableSecondValues.first : null;
      }

      _updateSelectedVariant();
    });
  }

  void _onSecondOptionSelected(String value) {
    setState(() {
      selectedSecondOptionValue = value;
      _updateSelectedVariant();
    });
  }

  String? _getImage(dynamic product) {
    try {
      if (product['image'] != null) {
        return product['image'].toString();
      }

      if (product['images'] != null &&
          product['images']['edges'] != null &&
          product['images']['edges'].isNotEmpty &&
          product['images']['edges'][0]['node'] != null &&
          product['images']['edges'][0]['node']['url'] != null) {
        return product['images']['edges'][0]['node']['url'].toString();
      }
    } catch (_) {}

    return null;
  }

  List<String> _getAllImages(dynamic product) {
    final images = <String>[];

    try {
      if (product['image'] != null &&
          product['image'].toString().trim().isNotEmpty) {
        images.add(product['image'].toString());
      }
    } catch (_) {}

    try {
      final imageEdges = product['images']?['edges'] as List<dynamic>? ?? [];
      for (final edge in imageEdges) {
        final url = edge['node']?['url']?.toString();
        if (url != null && url.isNotEmpty && !images.contains(url)) {
          images.add(url);
        }
      }
    } catch (_) {}

    return images;
  }

  String _getPrice(dynamic product) {
    try {
      if (selectedVariant != null &&
          selectedVariant['price'] != null &&
          selectedVariant['price']['amount'] != null) {
        return selectedVariant['price']['amount'].toString();
      }
    } catch (_) {}

    try {
      if (product['price'] != null) {
        return product['price'].toString();
      }

      if (product['variants'] != null &&
          product['variants']['edges'] != null &&
          product['variants']['edges'].isNotEmpty &&
          product['variants']['edges'][0]['node'] != null &&
          product['variants']['edges'][0]['node']['price'] != null &&
          product['variants']['edges'][0]['node']['price']['amount'] != null) {
        return product['variants']['edges'][0]['node']['price']['amount']
            .toString();
      }
    } catch (_) {}

    return "0";
  }

  String? _getVariantId(dynamic product) {
    try {
      if (selectedVariant != null && selectedVariant['id'] != null) {
        return selectedVariant['id'].toString();
      }
    } catch (_) {}

    try {
      if (product['variantId'] != null &&
          product['variantId'].toString().isNotEmpty) {
        return product['variantId'].toString();
      }
    } catch (_) {}

    try {
      if (product['variants'] != null &&
          product['variants']['edges'] != null &&
          product['variants']['edges'].isNotEmpty &&
          product['variants']['edges'][0]['node'] != null &&
          product['variants']['edges'][0]['node']['id'] != null) {
        return product['variants']['edges'][0]['node']['id'].toString();
      }
    } catch (_) {}

    try {
      if (product['variants'] != null &&
          product['variants']['nodes'] != null &&
          product['variants']['nodes'].isNotEmpty &&
          product['variants']['nodes'][0]['id'] != null) {
        return product['variants']['nodes'][0]['id'].toString();
      }
    } catch (_) {}

    try {
      if (product['variant'] != null && product['variant']['id'] != null) {
        return product['variant']['id'].toString();
      }
    } catch (_) {}

    return null;
  }

  bool _isAvailableForSale() {
    try {
      if (selectedVariant != null &&
          selectedVariant['availableForSale'] != null) {
        return selectedVariant['availableForSale'] == true;
      }
    } catch (_) {}
    return true;
  }

  String _getSelectedVariantSubtitle() {
    final parts = <String>[];

    if (selectedFirstOptionValue != null &&
        selectedFirstOptionValue!.trim().isNotEmpty) {
      parts.add(selectedFirstOptionValue!.trim());
    }

    if (selectedSecondOptionValue != null &&
        selectedSecondOptionValue!.trim().isNotEmpty) {
      parts.add(selectedSecondOptionValue!.trim());
    }

    return parts.join(' • ');
  }

  Color? _getColorFromLabel(String label) {
    final normalized = _normalizeOptionName(label);

    const colorMap = <String, Color>{
      'white': Color(0xFFFFFFFF),
      'black': Color(0xFF111111),
      'red': Color(0xFFEF4444),
      'blue': Color(0xFF3B82F6),
      'green': Color(0xFF22C55E),
      'yellow': Color(0xFFFACC15),
      'pink': Color(0xFFF9A8D4),
      'rose': Color(0xFFF43F5E),
      'purple': Color(0xFFA855F7),
      'violet': Color(0xFF8B5CF6),
      'orange': Color(0xFFFB923C),
      'brown': Color(0xFF8B5E3C),
      'beige': Color(0xFFD6BC9A),
      'nude': Color(0xFFD4A373),
      'ivory': Color(0xFFFFF8E7),
      'cream': Color(0xFFFFF5E1),
      'grey': Color(0xFF9CA3AF),
      'gray': Color(0xFF9CA3AF),
      'gold': Color(0xFFD4AF37),
      'silver': Color(0xFFC0C0C0),
    };

    return colorMap[normalized];
  }

  bool _shouldUseColorSwatches(String? optionName, List<String> values) {
    if (values.isEmpty) return false;

    if (optionName != null && _isSizeOption(optionName)) {
      return false;
    }

    int recognizedColors = 0;
    for (final value in values) {
      if (_getColorFromLabel(value) != null) {
        recognizedColors++;
      }
    }

    if (optionName != null && _isColorOption(optionName)) {
      return recognizedColors == values.length;
    }

    return recognizedColors == values.length && values.length <= 12;
  }

  Widget _buildColorSwatch({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    final swatchColor = _getColorFromLabel(label) ?? const Color(0xFFFDF2F8);
    final isLightColor = swatchColor.computeLuminance() > 0.82;
    const selectedBorder = Color(0xFFEC4899);
    const normalBorder = Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: swatchColor,
          border: Border.all(
            color: disabled
                ? Colors.grey.shade300
                : selected
                ? selectedBorder
                : isLightColor
                ? const Color(0xFFD1D5DB)
                : normalBorder,
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.10 : 0.05),
              blurRadius: selected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: selected
            ? Center(
          child: Icon(
            Icons.check,
            color: isLightColor ? Colors.black87 : Colors.white,
            size: 22,
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    const pinkBg = Color(0xFFFDF2F8);
    const pinkBorder = Color(0xFFFBCFE8);
    const pinkText = Color(0xFFBE185D);
    const selectedPink = Color(0xFFF9A8D4);
    const selectedPinkBorder = Color(0xFFF472B6);

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.shade100
              : selected
              ? selectedPink
              : pinkBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: disabled
                ? Colors.grey.shade300
                : selected
                ? selectedPinkBorder
                : pinkBorder,
            width: selected ? 1.2 : 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: selectedPinkBorder.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: disabled
                ? Colors.grey
                : selected
                ? Colors.white
                : pinkText,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTopActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor ?? Colors.black),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildOptionSection({
    required String title,
    required List<String> values,
    required String? selectedValue,
    required ValueChanged<String> onSelected,
    required bool useColorSwatches,
  }) {
    if (useColorSwatches) {
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: values.map((value) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColorSwatch(
                label: value,
                selected: selectedValue == value,
                onTap: () => onSelected(value),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 70,
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selectedValue == value
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: selectedValue == value
                        ? const Color(0xFFBE185D)
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.map((value) {
        return _buildOptionChip(
          label: value,
          selected: selectedValue == value,
          onTap: () => onSelected(value),
        );
      }).toList(),
    );
  }

  void _openGalleryImage({
    required int initialIndex,
    required List<String> images,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GalleryViewerScreen(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final image = _getImage(product);
    final galleryImages = _getAllImages(product);
    final price = _getPrice(product);
    final formattedPrice = formatPrice(price);
    final variantId = _getVariantId(product);
    final description = (product['description'] ?? '').toString();
    final title = (product['title'] ?? 'Product Details').toString();
    final productId = (product['id'] ?? '').toString();
    final isFavorite = FavoriteService.isFavorite(productId);

    final firstOptionName = _firstOptionName;
    final secondOptionName = _secondOptionName;

    final firstOptionValues = firstOptionName != null
        ? _getAllValuesForOption(firstOptionName)
        : <String>[];

    final secondOptionValues = secondOptionName != null
        ? _getFilteredSecondOptionValues()
        : <String>[];

    final useFirstOptionSwatches =
    _shouldUseColorSwatches(firstOptionName, firstOptionValues);
    final useSecondOptionSwatches =
    _shouldUseColorSwatches(secondOptionName, secondOptionValues);

    final selectedVariantText = _getSelectedVariantSubtitle();
    final isAvailable = _isAvailableForSale();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F8),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 470,
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                automaticallyImplyLeading: false,
                leading: _buildTopActionButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                actions: [
                  _buildTopActionButton(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    iconColor: isFavorite ? Colors.red : Colors.black,
                    onTap: () async {
                      final favoriteProduct = {
                        'id': productId,
                        'variantId': variantId ?? '',
                        'title': title,
                        'price': price,
                        'image': image,
                        'description': description,
                      };

                      await FavoriteService.toggleFavorite(favoriteProduct);

                      if (mounted) {
                        setState(() {});
                      }

                      final nowFavorite = FavoriteService.isFavorite(productId);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            nowFavorite
                                ? 'Produkti u shtua në Favorites'
                                : 'Produkti u largua nga Favorites',
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildTopActionButton(
                          icon: Icons.shopping_bag_outlined,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CartScreen(),
                              ),
                            );

                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                        if (CartService.itemCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
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
                                CartService.itemCount.toString(),
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
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFDF2F8),
                          Color(0xFFFFFFFF),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: image != null
                        ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(
                            top: 88,
                            left: 20,
                            right: 20,
                            bottom: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: GestureDetector(
                              onTap: () {
                                if (galleryImages.isNotEmpty) {
                                  _openGalleryImage(
                                    initialIndex: 0,
                                    images: galleryImages,
                                  );
                                }
                              },
                              child: Image.network(
                                image,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 70,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        if (!isAvailable)
                          Positioned(
                            left: 34,
                            right: 34,
                            bottom: 36,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                'Out of stock',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                        : Container(
                      margin: const EdgeInsets.only(
                        top: 88,
                        left: 20,
                        right: 20,
                        bottom: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 70,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F4F8),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -18, 0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (selectedVariantText.isNotEmpty)
                          Text(
                            selectedVariantText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFF1F7),
                                Color(0xFFFCE7F3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFFBCFE8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF472B6)
                                    .withValues(alpha: 0.14),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Price',
                                      style: TextStyle(
                                        color: Color(0xFFBE185D),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '€$formattedPrice',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        color: Color(0xFF9D174D),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                isAvailable ? 'In Stock' : 'Unavailable',
                                style: TextStyle(
                                  color: isAvailable
                                      ? const Color(0xFFBE185D)
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (galleryImages.length > 1) ...[
                          const SizedBox(height: 18),
                          _buildInfoCard(
                            title: 'Gallery',
                            child: SizedBox(
                              height: 82,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: galleryImages.length,
                                separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final galleryImage = galleryImages[index];
                                  return GestureDetector(
                                    onTap: () {
                                      _openGalleryImage(
                                        initialIndex: index,
                                        images: galleryImages,
                                      );
                                    },
                                    child: Container(
                                      width: 82,
                                      height: 82,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Image.network(
                                          galleryImage,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) {
                                            return const Icon(
                                              Icons.image_not_supported_outlined,
                                              color: Colors.grey,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                        if (firstOptionName != null &&
                            firstOptionValues.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _buildInfoCard(
                            title: _getOptionDisplayTitle(firstOptionName),
                            child: _buildOptionSection(
                              title: _getOptionDisplayTitle(firstOptionName),
                              values: firstOptionValues,
                              selectedValue: selectedFirstOptionValue,
                              onSelected: _onFirstOptionSelected,
                              useColorSwatches: useFirstOptionSwatches,
                            ),
                          ),
                        ],
                        if (secondOptionName != null &&
                            secondOptionValues.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _buildInfoCard(
                            title: _getOptionDisplayTitle(secondOptionName),
                            child: _buildOptionSection(
                              title: _getOptionDisplayTitle(secondOptionName),
                              values: secondOptionValues,
                              selectedValue: selectedSecondOptionValue,
                              onSelected: _onSecondOptionSelected,
                              useColorSwatches: useSecondOptionSwatches,
                            ),
                          ),
                        ],
                        if (!isAvailable) ...[
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              "Ky variant aktualisht nuk është në stok.",
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _buildInfoCard(
                          title: 'Description',
                          child: Text(
                            description.trim().isNotEmpty
                                ? description
                                : "Nuk ka përshkrim për këtë produkt.",
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.7,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF472B6).withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFFCE7F3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 58,
                        child: ElevatedButton.icon(
                          onPressed: !isAvailable
                              ? null
                              : () async {
                            final cartProduct = {
                              'id': product['id'] ?? '',
                              'variantId': variantId ?? '',
                              'title': title,
                              'price': price,
                              'image': image,
                              'quantity': 1,
                              'selectedVariantText': selectedVariantText,
                            };

                            await CartService.addToCart(cartProduct);

                            if (mounted) {
                              setState(() {});
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  variantId == null || variantId.isEmpty
                                      ? "Produkti u shtua në shportë, por pa variant ID."
                                      : "Produkti u shtua në shportë",
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag_outlined),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFCE7F3),
                            foregroundColor: const Color(0xFF9D174D),
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade600,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(
                                color: Color(0xFFFBCFE8),
                              ),
                            ),
                          ),
                          label: Text(
                            isAvailable ? "Add to Cart" : "Out of Stock",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryViewerScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _GalleryViewerScreen({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_GalleryViewerScreen> createState() => _GalleryViewerScreenState();
}

class _GalleryViewerScreenState extends State<_GalleryViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final imageUrl = widget.images[index];

          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white54,
                    size: 60,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}