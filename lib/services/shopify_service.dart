import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ShopifyService {
  final String storeDomain = "mtk0r1-1y.myshopify.com";
  final String storefrontAccessToken = "156e2297b6cb9cc8448d83d284e331a0";

  static const int _productsPageSize = 40;
  static const int _homeProductsLimit = 12;
  static const int _imagesLimit = 10;
  static const int _variantsLimit = 50;
  static const int _collectionsPageSize = 100;
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
          id
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
          image {
            id
            url
          }
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

  Future<Map<String, dynamic>> _postGraphQL(
      String query, {
        Map<String, dynamic>? variables,
      }) async {
    final response = await http
        .post(
      _graphqlUrl,
      headers: _headers,
      body: jsonEncode({
        "query": query,
        if (variables != null) "variables": variables,
      }),
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

  Future<Map<String, dynamic>> fetchProductsPage({
    String? collectionHandle,
    String? cursor,
    int first = _productsPageSize,
  }) async {
    final bool hasCollection =
        collectionHandle != null && collectionHandle.isNotEmpty;

    final String query = hasCollection
        ? '''
    query FetchCollectionProductsPage(\$handle: String!, \$first: Int!, \$after: String) {
      collection(handle: \$handle) {
        products(first: \$first, after: \$after) {
          edges {
            cursor
            node {
              $_productFields
            }
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
    '''
        : '''
    query FetchProductsPage(\$first: Int!, \$after: String) {
      products(first: \$first, after: \$after) {
        edges {
          cursor
          node {
            $_productFields
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
    ''';

    final json = await _postGraphQL(
      query,
      variables: {
        "first": first,
        "after": cursor,
        if (hasCollection) "handle": collectionHandle,
      },
    );

    final Map<String, dynamic>? connection = hasCollection
        ? (json["data"]?["collection"]?["products"] as Map<String, dynamic>?)
        : (json["data"]?["products"] as Map<String, dynamic>?);

    return {
      "edges": (connection?["edges"] as List<dynamic>?) ?? <dynamic>[],
      "pageInfo": connection?["pageInfo"] ?? <String, dynamic>{},
    };
  }

  Future<List<dynamic>> fetchProducts({String? collectionHandle}) async {
    final List<dynamic> allEdges = [];
    String? cursor;
    bool hasNextPage = true;

    while (hasNextPage) {
      final page = await fetchProductsPage(
        collectionHandle: collectionHandle,
        cursor: cursor,
        first: 250,
      );

      final edges = (page["edges"] as List<dynamic>?) ?? <dynamic>[];
      allEdges.addAll(edges);

      final pageInfo = page["pageInfo"] as Map<String, dynamic>?;

      hasNextPage = pageInfo?["hasNextPage"] == true;
      cursor = pageInfo?["endCursor"]?.toString();

      if (cursor == null || cursor.isEmpty) {
        hasNextPage = false;
      }
    }

    return allEdges;
  }

  Future<List<Map<String, String>>> fetchCollections() async {
    final List<dynamic> allEdges = [];
    String? cursor;
    bool hasNextPage = true;

    while (hasNextPage) {
      final query = '''
      query FetchCollections(\$first: Int!, \$after: String) {
        collections(first: \$first, after: \$after) {
          edges {
            cursor
            node {
              title
              handle
              image {
                url
              }
            }
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
      ''';

      final json = await _postGraphQL(
        query,
        variables: {
          "first": _collectionsPageSize,
          "after": cursor,
        },
      );

      final connection = json["data"]?["collections"] as Map<String, dynamic>?;
      if (connection == null) break;

      final edges = (connection["edges"] as List<dynamic>?) ?? <dynamic>[];
      allEdges.addAll(edges);

      final pageInfo = connection["pageInfo"] as Map<String, dynamic>?;

      hasNextPage = pageInfo?["hasNextPage"] == true;
      cursor = pageInfo?["endCursor"]?.toString();

      if (cursor == null || cursor.isEmpty) {
        hasNextPage = false;
      }
    }

    final collections = allEdges
        .map((edge) => _mapSimpleCollection(edge["node"]))
        .whereType<Map<String, String>>()
        .toList();

    return [
      {"title": "All", "handle": "", "image": ""},
      ...collections,
    ];
  }

  Future<Map<String, dynamic>?> fetchCollectionByHandle(String handle) async {
    final query = '''
    query FetchCollectionByHandle(\$handle: String!) {
      collection(handle: \$handle) {
        title
        handle
        image {
          url
        }
      }
    }
    ''';

    final json = await _postGraphQL(
      query,
      variables: {"handle": handle},
    );

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

    final allCollectionsWithAllItem = await fetchCollections();
    final allCollections = allCollectionsWithAllItem
        .where((collection) => (collection["handle"] ?? "").isNotEmpty)
        .toList();

    final query = '''
    {
      bestSellerA: collection(handle: "best-seller") {
        title
        handle
        image {
          url
        }
        products(first: 1) {
          edges {
            node {
              id
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
        products(first: 1) {
          edges {
            node {
              id
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
        products(first: 1) {
          edges {
            node {
              id
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
        products(first: 1) {
          edges {
            node {
              id
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
      }

      parfumes: collection(handle: "$parfumesHandle") {
        title
        handle
        image {
          url
        }
      }
    }
    ''';

    final json = await _postGraphQL(query);
    final data = json["data"] as Map<String, dynamic>? ?? {};

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

    Map<String, dynamic>? bestSellerCollection =
    _firstValidCollectionWithProducts([
      data["bestSellerA"],
      data["bestSellerB"],
      data["bestSellerC"],
      data["bestSellerD"],
    ]);

    if (bestSellerCollection != null) {
      bestSellerCollection =
      await _attachLimitedProductsToCollection(bestSellerCollection);
    }

    final bestSellerHandle =
    (bestSellerCollection?["handle"] ?? "").toString().toLowerCase();

    final justDroppedCollection = await _attachLimitedProductsToCollection(
      _mapCollectionNode(data["justDropped"]),
    );

    final parfumesCollection = await _attachLimitedProductsToCollection(
      _mapCollectionNode(data["parfumes"]),
    );

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

  Future<Map<String, dynamic>?> _attachLimitedProductsToCollection(
      Map<String, dynamic>? collection,
      ) async {
    if (collection == null) return null;

    final handle = collection["handle"]?.toString() ?? "";
    if (handle.isEmpty) return collection;

    final productsPage = await fetchProductsPage(
      collectionHandle: handle,
      first: _homeProductsLimit,
    );

    return {
      ...collection,
      "products": productsPage["edges"] ?? <dynamic>[],
    };
  }

  Future<Map<String, dynamic>?> _attachAllProductsToCollection(
      Map<String, dynamic>? collection,
      ) async {
    if (collection == null) return null;

    final handle = collection["handle"]?.toString() ?? "";
    if (handle.isEmpty) return collection;

    final products = await fetchProducts(collectionHandle: handle);

    return {
      ...collection,
      "products": products,
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
    final query = '''
    query FetchProductById(\$id: ID!) {
      node(id: \$id) {
        ... on Product {
          $_productFields
        }
      }
    }
    ''';

    final json = await _postGraphQL(
      query,
      variables: {"id": productId},
    );

    final product = json["data"]?["node"];

    if (product == null) {
      return null;
    }

    return product as Map<String, dynamic>;
  }
}