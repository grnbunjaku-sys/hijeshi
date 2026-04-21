import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ShopifyService {
  final String storeDomain = "mtk0r1-1y.myshopify.com";
  final String storefrontAccessToken = "156e2297b6cb9cc8448d83d284e331a0";

  static const int _productsLimit = 12;
  static const int _imagesLimit = 10;
  static const int _variantsLimit = 50;
  static const int _collectionsLimit = 80;
  static const Duration _timeoutDuration = Duration(seconds: 20);

  Uri get _graphqlUrl =>
      Uri.parse("https://$storeDomain/api/2026-01/graphql.json");

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "X-Shopify-Storefront-Access-Token": storefrontAccessToken,
  };

  String get _productFields => '''
    id
    title
    description
    vendor
    productType
    tags
    options {
      name
      values
    }
    images(first: $_imagesLimit) {
      edges {
        node {
          url
        }
      }
    }
    variants(first: $_variantsLimit) {
      edges {
        node {
          id
          title
          availableForSale
          price {
            amount
          }
          selectedOptions {
            name
            value
          }
        }
      }
    }
  ''';

  Future<Map<String, dynamic>> _postGraphQL(String query) async {
    final response = await http
        .post(
      _graphqlUrl,
      headers: _headers,
      body: jsonEncode({"query": query}),
    )
        .timeout(_timeoutDuration);

    if (response.statusCode != 200) {
      throw Exception("HTTP ${response.statusCode}: ${response.body}");
    }

    final Map<String, dynamic> json =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (json["errors"] != null) {
      throw Exception(json["errors"].toString());
    }

    return json;
  }

  Future<List<dynamic>> fetchProducts({String? collectionHandle}) async {
    final String query;

    if (collectionHandle != null && collectionHandle.isNotEmpty) {
      final safeHandle = collectionHandle.replaceAll('"', '\\"');

      query = '''
      {
        collection(handle: "$safeHandle") {
          title
          handle
          products(first: $_productsLimit) {
            edges {
              node {
                $_productFields
              }
            }
          }
        }
      }
      ''';
    } else {
      query = '''
      {
        products(first: $_productsLimit) {
          edges {
            node {
              $_productFields
            }
          }
        }
      }
      ''';
    }

    final json = await _postGraphQL(query);

    if (collectionHandle != null && collectionHandle.isNotEmpty) {
      final collection = json["data"]?["collection"] as Map<String, dynamic>?;

      if (collection == null) {
        return [];
      }

      return (collection["products"]?["edges"] as List<dynamic>?) ?? [];
    }

    return (json["data"]?["products"]?["edges"] as List<dynamic>?) ?? [];
  }

  Future<List<Map<String, String>>> fetchCollections() async {
    final query = '''
    {
      collections(first: $_collectionsLimit) {
        edges {
          node {
            title
            handle
            image {
              url
            }
          }
        }
      }
    }
    ''';

    final json = await _postGraphQL(query);

    final List<dynamic> edges =
        (json["data"]?["collections"]?["edges"] as List<dynamic>?) ?? [];

    final collections = edges
        .map((edge) => _mapSimpleCollection(edge["node"]))
        .whereType<Map<String, String>>()
        .toList();

    return [
      {"title": "All", "handle": "", "image": ""},
      ...collections,
    ];
  }

  Future<Map<String, dynamic>?> fetchCollectionByHandle(String handle) async {
    final safeHandle = handle.replaceAll('"', '\\"');

    final query = '''
    {
      collection(handle: "$safeHandle") {
        title
        handle
        image {
          url
        }
      }
    }
    ''';

    final json = await _postGraphQL(query);

    final collection = json["data"]?["collection"];
    if (collection == null) return null;

    return {
      "title": collection["title"]?.toString() ?? "",
      "handle": collection["handle"]?.toString() ?? "",
      "image": collection["image"]?["url"]?.toString() ?? "",
    };
  }

  Future<Map<String, dynamic>> fetchHomeData() async {
    const makeupHandle = 'makeup';
    const skincareHandle = 'skin-care';
    const haircareHandle = 'hair-care';
    const bodycareHandle = 'body-care';
    const nailsHandle = 'nails';
    const parfumesHandle = 'parfumes';
    const justDroppedHandle = 'just-dropped';

    final query = '''
    {
      collections(first: $_collectionsLimit) {
        edges {
          node {
            title
            handle
            image {
              url
            }
          }
        }
      }

      bestSellerA: collection(handle: "best-seller") {
        title
        handle
        image {
          url
        }
        products(first: $_productsLimit) {
          edges {
            node {
              $_productFields
            }
          }
        }
      }

      bestSellerB: collection(handle: "bestselling") {
        title
        handle
        image {
          url
        }
        products(first: $_productsLimit) {
          edges {
            node {
              $_productFields
            }
          }
        }
      }

      bestSellerC: collection(handle: "best-selling") {
        title
        handle
        image {
          url
        }
        products(first: $_productsLimit) {
          edges {
            node {
              $_productFields
            }
          }
        }
      }

      bestSellerD: collection(handle: "bestsellers") {
        title
        handle
        image {
          url
        }
        products(first: $_productsLimit) {
          edges {
            node {
              $_productFields
            }
          }
        }
      }

      justDropped: collection(handle: "$justDroppedHandle") {
        title
        handle
        image {
          url
        }
        products(first: $_productsLimit) {
          edges {
            node {
              $_productFields
            }
          }
        }
      }

      parfumes: collection(handle: "$parfumesHandle") {
        title
        handle
        image {
          url
        }
        products(first: $_productsLimit) {
          edges {
            node {
              $_productFields
            }
          }
        }
      }
    }
    ''';

    final json = await _postGraphQL(query);
    final data = json["data"] as Map<String, dynamic>? ?? {};

    final List<dynamic> allCollectionEdges =
        (data["collections"]?["edges"] as List<dynamic>?) ?? [];

    final allCollections = allCollectionEdges
        .map((edge) => _mapSimpleCollection(edge["node"]))
        .whereType<Map<String, String>>()
        .toList();

    const desiredCategoryOrder = [
      makeupHandle,
      skincareHandle,
      haircareHandle,
      bodycareHandle,
      parfumesHandle,
      nailsHandle,
    ];

    final Map<String, Map<String, String>> collectionByHandle = {
      for (final collection in allCollections)
        (collection['handle'] ?? '').toLowerCase(): collection,
    };

    final categoryCollections = desiredCategoryOrder
        .map((handle) => collectionByHandle[handle])
        .whereType<Map<String, String>>()
        .toList();

    final categoryHandles = categoryCollections
        .map((collection) => (collection['handle'] ?? '').toLowerCase())
        .toSet();

    final bestSellerCollection = _firstValidCollectionWithProducts([
      data["bestSellerA"],
      data["bestSellerB"],
      data["bestSellerC"],
      data["bestSellerD"],
    ]);

    final bestSellerHandle =
    (bestSellerCollection?["handle"] ?? "").toString().toLowerCase();

    final justDroppedCollection =
    _mapCollectionNode(data["justDropped"], includeProducts: true);

    final parfumesCollection =
    _mapCollectionNode(data["parfumes"], includeProducts: true);

    final excludedHandles = <String>{
      ...categoryHandles,
      if (bestSellerHandle.isNotEmpty) bestSellerHandle,
      justDroppedHandle,
      'home-page',
      'homepage',
      'home',
      'nails',
      'sale',
      'offers',
      'offer',
      'gift',
      'gifts',
      'mini',
      'minis',
      'new',
      'new-arrivals',
      'just-arrived',
      'best-seller',
      'bestselling',
      'best-selling',
      'bestseller',
      'bestsellers',
      'fragrance',
      'fragrances',
      'perfume',
      'perfumes',
      'parfume',
      'parfumes',
    };

    final brandCollections = allCollections.where((collection) {
      final handle = (collection['handle'] ?? '').toLowerCase();
      final title = (collection['title'] ?? '').toLowerCase();

      if (excludedHandles.contains(handle)) return false;

      final looksLikeCategory = title.contains('home page') ||
          title == 'home' ||
          title.contains('makeup') ||
          title.contains('skin') ||
          title.contains('hair') ||
          title.contains('body') ||
          title.contains('parfume') ||
          title.contains('parfumes') ||
          title.contains('perfume') ||
          title.contains('perfumes') ||
          title.contains('fragrance') ||
          title.contains('nail') ||
          title.contains('mini') ||
          title.contains('gift') ||
          title.contains('sale') ||
          title.contains('best seller') ||
          title.contains('bestselling') ||
          title.contains('just dropped') ||
          title.contains('new arrival');

      return !looksLikeCategory;
    }).toList();

    return {
      "brands": brandCollections,
      "categories": categoryCollections,
      "bestSeller": bestSellerCollection,
      "justDropped": justDroppedCollection,
      "parfumes": parfumesCollection,
    };
  }

  Map<String, String>? _mapSimpleCollection(dynamic rawNode) {
    if (rawNode == null || rawNode is! Map<String, dynamic>) return null;

    final title = rawNode["title"]?.toString() ?? "";
    final handle = rawNode["handle"]?.toString() ?? "";
    final image = rawNode["image"]?["url"]?.toString() ?? "";

    if (title.isEmpty || handle.isEmpty) return null;

    return {
      "title": title,
      "handle": handle,
      "image": image,
    };
  }

  Map<String, dynamic>? _mapCollectionNode(
      dynamic rawNode, {
        bool includeProducts = false,
      }) {
    if (rawNode == null || rawNode is! Map<String, dynamic>) return null;

    final title = rawNode["title"]?.toString() ?? "";
    final handle = rawNode["handle"]?.toString() ?? "";
    final image = rawNode["image"]?["url"]?.toString() ?? "";

    if (title.isEmpty || handle.isEmpty) return null;

    final map = <String, dynamic>{
      "title": title,
      "handle": handle,
      "image": image,
    };

    if (includeProducts) {
      map["products"] =
          (rawNode["products"]?["edges"] as List<dynamic>?) ?? <dynamic>[];
    }

    return map;
  }

  Map<String, dynamic>? _firstValidCollectionWithProducts(List<dynamic> rawList) {
    for (final raw in rawList) {
      final mapped = _mapCollectionNode(raw, includeProducts: true);
      if (mapped == null) continue;

      final products = mapped["products"] as List<dynamic>? ?? [];
      if (products.isNotEmpty) {
        return mapped;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchProductById(String productId) async {
    final safeProductId = productId.replaceAll('"', '\\"');

    final query = '''
    {
      node(id: "$safeProductId") {
        ... on Product {
          $_productFields
        }
      }
    }
    ''';

    final json = await _postGraphQL(query);

    final product = json["data"]?["node"];

    if (product == null) {
      return null;
    }

    return product as Map<String, dynamic>;
  }
}