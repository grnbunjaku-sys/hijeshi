import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/cart_service.dart';
import '../services/order_service.dart';
import 'main_screen.dart';

class CheckoutWebView extends StatefulWidget {
  final String url;

  const CheckoutWebView({super.key, required this.url});

  @override
  State<CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<CheckoutWebView> {
  late final WebViewController _controller;

  final String myShopifyDomain = "mtk0r1-1y.myshopify.com";
  final String storeDomain = "hijeshicosmetics.com";

  bool _orderCompleted = false;
  bool _alreadyHandledReturn = false;
  bool _isPageLoading = true;
  bool _orderSaved = false;
  int _loadingProgress = 0;

  bool _isStorefrontUrl(String url) {
    return url.contains(myShopifyDomain) || url.contains(storeDomain);
  }

  bool _isCheckoutUrl(String url) {
    return url.contains("/checkouts/") ||
        url.contains("/cart/c/") ||
        url.contains("checkout");
  }

  bool _isOrderCompletedUrl(String url) {
    return url.contains("thank_you") ||
        url.contains("thank-you") ||
        url.contains("/orders/") ||
        url.contains("orders/");
  }

  bool _shouldGoHome(String url) {
    final isStorefront = _isStorefrontUrl(url);
    final isCheckout = _isCheckoutUrl(url);

    if (!isStorefront) return false;
    if (isCheckout) return false;

    if (url.contains("/cart")) return true;
    if (url.contains("/collections")) return true;
    if (url.contains("/products")) return true;
    if (url == "https://$storeDomain") return true;
    if (url == "https://$storeDomain/") return true;
    if (url == "https://$myShopifyDomain") return true;
    if (url == "https://$myShopifyDomain/") return true;

    return false;
  }

  Future<void> _saveOrderIfNeeded() async {
    if (_orderSaved) return;

    _orderSaved = true;
    await OrderService.createOrderFromCurrentCart(
      status: 'Completed',
    );
  }

  Future<void> _goToHomeAndClearCart() async {
    if (!mounted || _alreadyHandledReturn) return;
    _alreadyHandledReturn = true;

    setState(() {
      _isPageLoading = true;
    });

    await CartService.clearCart();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainScreen(),
      ),
          (route) => false,
    );
  }

  void _handleUrl(String url) {
    if (_isOrderCompletedUrl(url)) {
      _orderCompleted = true;
      _saveOrderIfNeeded();
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _handleUrl(url);

            if (mounted) {
              setState(() {
                _isPageLoading = true;
                _loadingProgress = 0;
              });
            }
          },
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
              });
            }
          },
          onPageFinished: (url) {
            _handleUrl(url);

            if (mounted) {
              setState(() {
                _isPageLoading = false;
                _loadingProgress = 100;
              });
            }

            if (_shouldGoHome(url)) {
              _goToHomeAndClearCart();
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;

            _handleUrl(url);

            if (_shouldGoHome(url)) {
              _goToHomeAndClearCart();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.92),
      child: Center(
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _orderCompleted
                    ? 'Duke përfunduar porosinë...'
                    : 'Duke ngarkuar checkout...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _loadingProgress > 0 && _loadingProgress < 100
                    ? '$_loadingProgress%'
                    : 'Ju lutem prisni pak',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F4F8),
        elevation: 0,
        surfaceTintColor: const Color(0xFFF7F4F8),
        centerTitle: true,
        title: const Text(
          "Përfundimi i porosisë",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: AnimatedOpacity(
            opacity: _isPageLoading ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: LinearProgressIndicator(
              minHeight: 3,
              value: _loadingProgress > 0 && _loadingProgress < 100
                  ? _loadingProgress / 100
                  : null,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isPageLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }
}