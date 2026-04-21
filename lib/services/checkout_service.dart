import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OutOfStockException implements Exception {
  final List<String> productIds;
  final List<String> variantIds;
  final List<String> productTitles;

  OutOfStockException({
    required this.productIds,
    required this.variantIds,
    required this.productTitles,
  });

  @override
  String toString() {
    if (productTitles.isEmpty) {
      return 'Disa artikuj nuk janë më në stok.';
    }

    return 'Jashtë stokut: ${productTitles.join(", ")}';
  }
}

class CheckoutService {
  static const String storeDomain = 'mtk0r1-1y.myshopify.com';
  static const String storefrontAccessToken =
      '156e2297b6cb9cc8448d83d284e331a0';
  static const String apiVersion = '2026-01';

  static const String appDiscountCode = 'APP10';
  static const Duration _timeoutDuration = Duration(seconds: 20);

  static Uri get _graphqlUrl =>
      Uri.parse('https://$storeDomain/api/$apiVersion/graphql.json');

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-Shopify-Storefront-Access-Token': storefrontAccessToken,
  };

  static int _getQuantity(Map<String, dynamic> item) {
    final quantity = item['quantity'];

    if (quantity is int) return quantity;
    if (quantity is double) return quantity.toInt();
    if (quantity is String) return int.tryParse(quantity) ?? 1;

    return 1;
  }

  static Future<Map<String, dynamic>> _postGraphQL({
    required String query,
    Map<String, dynamic>? variables,
  }) async {
    final response = await http
        .post(
      _graphqlUrl,
      headers: _headers,
      body: jsonEncode({
        'query': query,
        'variables': variables ?? {},
      }),
    )
        .timeout(_timeoutDuration);

    final decoded = jsonDecode(response.body);

    print('SHOPIFY STATUS: ${response.statusCode}');
    print('SHOPIFY RESPONSE: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Përgjigje jo valide nga Shopify');
    }

    if (decoded['errors'] != null) {
      throw Exception(decoded['errors'].toString());
    }

    return decoded;
  }

  static Future<void> _validateStock(
      List<Map<String, dynamic>> cartItems,
      ) async {
    final outOfStockIds = <String>[];
    final outOfStockVariantIds = <String>[];
    final outOfStockTitles = <String>[];

    const query = r'''
      query VariantAvailability($id: ID!) {
        node(id: $id) {
          ... on ProductVariant {
            id
            title
            availableForSale
            quantityAvailable
            product {
              title
            }
          }
        }
      }
    ''';

    for (final item in cartItems) {
      final variantId = item['variantId']?.toString() ?? '';
      final productId = item['id']?.toString() ?? '';
      final productTitle = item['title']?.toString() ?? 'Produkt pa emër';
      final quantity = _getQuantity(item);

      if (variantId.isEmpty) {
        outOfStockIds.add(productId);
        outOfStockVariantIds.add('');
        outOfStockTitles.add(productTitle);
        continue;
      }

      final decoded = await _postGraphQL(
        query: query,
        variables: {'id': variantId},
      );

      final node = decoded['data']?['node'];

      if (node == null) {
        outOfStockIds.add(productId);
        outOfStockVariantIds.add(variantId);
        outOfStockTitles.add(productTitle);
        continue;
      }

      final availableForSale = node['availableForSale'] == true;
      final quantityAvailable = node['quantityAvailable'];

      bool enoughStock = availableForSale;

      if (quantityAvailable is int) {
        enoughStock = availableForSale && quantityAvailable >= quantity;
      }

      if (!enoughStock) {
        outOfStockIds.add(productId);
        outOfStockVariantIds.add(variantId);
        outOfStockTitles.add(
          node['product']?['title']?.toString() ?? productTitle,
        );
      }
    }

    if (outOfStockIds.isNotEmpty) {
      throw OutOfStockException(
        productIds: outOfStockIds,
        variantIds: outOfStockVariantIds,
        productTitles: outOfStockTitles,
      );
    }
  }

  static Future<String?> createCheckoutUrl(
      List<Map<String, dynamic>> cartItems,
      ) async {
    if (cartItems.isEmpty) {
      throw Exception('Cart është bosh');
    }

    await _validateStock(cartItems);

    final List<Map<String, dynamic>> lines = [];

    for (final item in cartItems) {
      final variantId = item['variantId']?.toString() ?? '';
      final quantity = _getQuantity(item);

      if (variantId.isEmpty) {
        throw Exception('Variant ID mungon për produktin: ${item['title']}');
      }

      lines.add({
        'merchandiseId': variantId,
        'quantity': quantity,
      });
    }

    if (lines.isEmpty) {
      throw Exception('Cart është bosh');
    }

    const mutation = r'''
      mutation cartCreate($input: CartInput) {
        cartCreate(input: $input) {
          cart {
            id
            checkoutUrl
            discountCodes {
              code
              applicable
            }
          }
          userErrors {
            field
            message
          }
          warnings {
            code
            message
          }
        }
      }
    ''';

    final decoded = await _postGraphQL(
      query: mutation,
      variables: {
        'input': {
          'lines': lines,
          'discountCodes': [appDiscountCode],
        },
      },
    );

    final data = decoded['data'];
    if (data == null) {
      throw Exception('Nuk u kthye data nga Shopify');
    }

    final cartCreate = data['cartCreate'];
    if (cartCreate == null) {
      throw Exception('cartCreate mungon në përgjigje');
    }

    final userErrors = cartCreate['userErrors'] as List<dynamic>? ?? [];
    if (userErrors.isNotEmpty) {
      throw Exception(userErrors.first['message'].toString());
    }

    final warnings = cartCreate['warnings'] as List<dynamic>? ?? [];
    if (warnings.isNotEmpty) {
      print('SHOPIFY WARNINGS: $warnings');
    }

    final cart = cartCreate['cart'];
    if (cart == null) {
      throw Exception('Cart nuk u krijua');
    }

    final discountCodes = cart['discountCodes'] as List<dynamic>? ?? [];
    print('APPLIED DISCOUNT CODES: $discountCodes');

    final checkoutUrl = cart['checkoutUrl']?.toString() ?? '';

    if (checkoutUrl.isEmpty) {
      throw Exception('Checkout URL mungon');
    }

    return checkoutUrl;
  }
}