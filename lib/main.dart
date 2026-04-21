import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/reset_password_screen.dart';
import 'services/cart_service.dart';
import 'services/favorite_service.dart';
import 'services/local_notification_service.dart';
import 'services/notification_service.dart';
import 'services/shopify_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String? _initialLocalNotificationPayload;

Future<void> _navigateFromData(Map<String, dynamic> data) async {
  debugPrint('DEBUG data: $data');

  final String type = (data['type'] ?? '').toString();
  final String collectionHandle = (data['collectionHandle'] ?? '').toString();
  final String collectionTitle =
  (data['title'] ?? data['collectionTitle'] ?? 'Collection').toString();
  final String productId = (data['productId'] ?? '').toString();

  debugPrint('DEBUG type: $type');
  debugPrint('DEBUG collectionHandle: $collectionHandle');
  debugPrint('DEBUG collectionTitle: $collectionTitle');
  debugPrint('DEBUG productId: $productId');

  if (type == 'collection' && collectionHandle.isNotEmpty) {
    debugPrint('OPEN COLLECTION: $collectionHandle');

    navigatorKey.currentState?.pushAndRemoveUntil(
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
    debugPrint('OPEN CART');

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainScreen(initialIndex: 3),
      ),
          (route) => false,
    );
    return;
  }

  if (type == 'home') {
    debugPrint('OPEN HOME');

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainScreen(initialIndex: 0),
      ),
          (route) => false,
    );
    return;
  }

  if (type == 'product' && productId.isNotEmpty) {
    debugPrint('OPEN PRODUCT: $productId');

    try {
      final shopify = ShopifyService();
      final product = await shopify.fetchProductById(productId);

      if (product == null) {
        debugPrint('Product not found');
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const MainScreen(initialIndex: 1),
          ),
              (route) => false,
        );
        return;
      }

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainScreen(initialIndex: 1),
        ),
            (route) => false,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: product),
        ),
      );
    } catch (e) {
      debugPrint('OPEN PRODUCT ERROR: $e');

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainScreen(initialIndex: 1),
        ),
            (route) => false,
      );
    }

    return;
  }

  debugPrint('OPEN DEFAULT MAIN SCREEN');

  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => const MainScreen(),
    ),
        (route) => false,
  );
}

Future<void> _handleLocalNotificationTap(String? payload) async {
  if (payload == null || payload.isEmpty) return;

  final Uri uri = Uri.parse(payload);

  final Map<String, dynamic> data = {
    'type': uri.queryParameters['type'] ?? '',
    'title': uri.queryParameters['title'] ?? '',
    'collectionHandle': uri.queryParameters['collectionHandle'] ?? '',
    'productId': uri.queryParameters['productId'] ?? '',
  };

  await _navigateFromData(data);
}

String _buildNotificationPayload(Map<String, dynamic> data) {
  return Uri(
    queryParameters: {
      'type': (data['type'] ?? '').toString(),
      'title': (data['title'] ?? '').toString(),
      'collectionHandle': (data['collectionHandle'] ?? '').toString(),
      'productId': (data['productId'] ?? '').toString(),
    },
  ).toString();
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final String title = message.notification?.title ?? 'Hijeshi';
  final String body = message.notification?.body ?? '';
  final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);

  debugPrint('Mesazh në background: $title');
  debugPrint('Background data: $data');

  if ((data['title'] ?? '').toString().isEmpty) {
    data['title'] = title;
  }

  await NotificationService.addNotification(
    title: title,
    body: body,
    data: data,
  );

  final String payload = _buildNotificationPayload(data);

  await LocalNotificationService.init();
  await LocalNotificationService.showNotification(
    title: title,
    body: body,
    payload: payload,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FavoriteService.loadFavorites();
  await CartService.loadCart();
  await NotificationService.loadNotifications();

  await LocalNotificationService.init(
    onTap: _handleLocalNotificationTap,
  );

  _initialLocalNotificationPayload =
  await LocalNotificationService.getLaunchPayload();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _messagingInitialized = false;
  bool _initialNavigationHandled = false;

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();

    _initDeepLinks();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_messagingInitialized) {
        _messagingInitialized = true;
        unawaited(setupFirebaseMessaging());
      }

      if (!_initialNavigationHandled) {
        _initialNavigationHandled = true;

        if (_initialLocalNotificationPayload != null &&
            _initialLocalNotificationPayload!.isNotEmpty) {
          final String payload = _initialLocalNotificationPayload!;
          _initialLocalNotificationPayload = null;
          await _handleLocalNotificationTap(payload);
        }
      }
    });
  }

  Future<void> _initDeepLinks() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleIncomingUri(initialUri);
      }

      _sub = _appLinks.uriLinkStream.listen((Uri uri) async {
        await _handleIncomingUri(uri);
      });
    } catch (e) {
      debugPrint('DEEP LINK INIT ERROR: $e');
    }
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    debugPrint('DEEP LINK URI: $uri');
    debugPrint('DEEP LINK SCHEME: ${uri.scheme}');
    debugPrint('DEEP LINK HOST: ${uri.host}');
    debugPrint('DEEP LINK PATH: ${uri.path}');

    final bool isHttpsReset =
        uri.scheme == 'https' &&
            uri.host == 'api.hijeshicosmetics.com' &&
            uri.path == '/app-reset-password';

    final bool isCustomSchemeReset =
        uri.scheme == 'hijeshi' &&
            uri.host == 'reset-password';

    if (isHttpsReset || isCustomSchemeReset) {
      final String token = uri.queryParameters['token'] ?? '';
      final String email = uri.queryParameters['email'] ?? '';

      debugPrint('RESET TOKEN: $token');
      debugPrint('RESET EMAIL: $email');

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            token: token,
            email: email,
          ),
        ),
      );

      return;
    }
  }

  Future<void> setupFirebaseMessaging() async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      final NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('Leje e dhënë: ${settings.authorizationStatus}');

      final String? token = await messaging.getToken();
      debugPrint('FCM Token: $token');

      unawaited(NotificationService.syncTokenForLoggedInUser());
      unawaited(messaging.subscribeToTopic('all'));

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final String title = message.notification?.title ?? 'Hijeshi';
        final String body = message.notification?.body ?? '';
        final Map<String, dynamic> data =
        Map<String, dynamic>.from(message.data);

        debugPrint('Foreground: $title - $body');
        debugPrint('Foreground data: $data');

        if ((data['title'] ?? '').toString().isEmpty) {
          data['title'] = title;
        }

        final String payload = _buildNotificationPayload(data);

        await NotificationService.addNotification(
          title: title,
          body: body,
          data: data,
        );

        await LocalNotificationService.showNotification(
          title: title,
          body: body,
          payload: payload,
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        debugPrint(
          'OpenedApp: ${message.notification?.title} - ${message.notification?.body}',
        );
        debugPrint('OpenedApp data: ${message.data}');

        final Map<String, dynamic> data =
        Map<String, dynamic>.from(message.data);

        if ((data['title'] ?? '').toString().isEmpty) {
          data['title'] = message.notification?.title ?? 'Hijeshi';
        }

        await NotificationService.addNotification(
          title: message.notification?.title ?? 'Hijeshi',
          body: message.notification?.body ?? '',
          data: data,
        );

        await _navigateFromData(data);
      });

      final RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          'Terminated->Opened: ${initialMessage.notification?.title} - ${initialMessage.notification?.body}',
        );
        debugPrint('Terminated data: ${initialMessage.data}');

        final Map<String, dynamic> data =
        Map<String, dynamic>.from(initialMessage.data);

        if ((data['title'] ?? '').toString().isEmpty) {
          data['title'] = initialMessage.notification?.title ?? 'Hijeshi';
        }

        await NotificationService.addNotification(
          title: initialMessage.notification?.title ?? 'Hijeshi',
          body: initialMessage.notification?.body ?? '',
          data: data,
        );

        await _navigateFromData(data);
      }
    } catch (e) {
      debugPrint('setupFirebaseMessaging ERROR: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF7F4F8);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Hijeshi',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ).copyWith(
          primary: Colors.black,
          surface: backgroundColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          surfaceTintColor: backgroundColor,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black,
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4F5F7),
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
            borderSide: const BorderSide(color: Colors.black12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.black,
        ),
      ),
      home: const MainScreen(),
    );
  }
}