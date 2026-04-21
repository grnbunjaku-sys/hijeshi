import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PolicyWebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const PolicyWebViewScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<PolicyWebViewScreen> createState() => _PolicyWebViewScreenState();
}

class _PolicyWebViewScreenState extends State<PolicyWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  late final Uri _baseUri;

  @override
  void initState() {
    super.initState();
    _baseUri = Uri.parse(widget.url);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (_) async {
            await _injectCleanPolicyMode();

            Future.delayed(
              const Duration(milliseconds: 10),
              _injectCleanPolicyMode,
            );
            Future.delayed(
              const Duration(milliseconds: 50),
              _injectCleanPolicyMode,
            );
            Future.delayed(
              const Duration(milliseconds: 120),
              _injectCleanPolicyMode,
            );
            Future.delayed(
              const Duration(milliseconds: 250),
              _injectCleanPolicyMode,
            );
            Future.delayed(
              const Duration(milliseconds: 500),
              _injectCleanPolicyMode,
            );

            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
          onNavigationRequest: (request) {
            final requestedUri = Uri.tryParse(request.url);

            if (requestedUri == null) {
              return NavigationDecision.prevent;
            }

            final baseHost = _baseUri.host.toLowerCase().replaceFirst('www.', '');
            final requestedHost = requestedUri.host
                .toLowerCase()
                .replaceFirst('www.', '');

            final requestedUrl = request.url.toLowerCase();

            if (requestedHost.contains('admin.shopify.com')) {
              return NavigationDecision.prevent;
            }

            if (requestedUrl.contains('/admin')) {
              return NavigationDecision.prevent;
            }

            final sameHost = requestedHost == baseHost;
            final samePath = requestedUri.path == _baseUri.path;
            final sameQuery = requestedUri.query == _baseUri.query;
            final isHttpOrHttps =
                requestedUri.scheme == 'http' || requestedUri.scheme == 'https';

            final isSamePage = sameHost && samePath;
            final isAnchorOnly = sameHost && samePath && sameQuery;
            final isBasePageWithFragment =
                sameHost &&
                    samePath &&
                    (requestedUri.query == _baseUri.query ||
                        requestedUri.query.isEmpty ||
                        _baseUri.query.isEmpty);

            if (!isHttpOrHttps) {
              return NavigationDecision.prevent;
            }

            if (isSamePage || isAnchorOnly || isBasePageWithFragment) {
              return NavigationDecision.navigate;
            }

            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(_baseUri);
  }

  Future<void> _injectCleanPolicyMode() async {
    const script = '''
      (function() {
        try {
          document.documentElement.style.opacity = '0';

          function hideElement(selector) {
            document.querySelectorAll(selector).forEach(function(el) {
              el.style.display = 'none';
              el.style.visibility = 'hidden';
              el.style.opacity = '0';
              el.style.height = '0';
              el.style.minHeight = '0';
              el.style.maxHeight = '0';
              el.style.width = '0';
              el.style.maxWidth = '0';
              el.style.overflow = 'hidden';
              el.style.margin = '0';
              el.style.padding = '0';
              el.style.border = '0';
              el.removeAttribute('sticky');
            });
          }

          function applyStyles() {
            hideElement('header');
            hideElement('footer');
            hideElement('#shopify-section-header');
            hideElement('#shopify-section-footer');
            hideElement('[id*="shopify-section-header"]');
            hideElement('[id*="shopify-section-footer"]');
            hideElement('.announcement-bar');
            hideElement('.shopify-section-group-header-group');
            hideElement('.shopify-section-group-footer-group');
            hideElement('.header-wrapper');
            hideElement('.footer');
            hideElement('.newsletter');
            hideElement('.site-footer');
            hideElement('.sticky-atc');
            hideElement('.floating-cart');
            hideElement('.needsclick');
            hideElement('iframe');
            hideElement('chat-widget');
            hideElement('form[action*="/cart"]');
            hideElement('[class*="header"]');
            hideElement('[class*="Header"]');
            hideElement('[class*="footer"]');
            hideElement('[class*="Footer"]');
            hideElement('[id*="announcement"]');
            hideElement('[class*="announcement"]');
            hideElement('[class*="sticky"]');
            hideElement('[class*="drawer"]');
            hideElement('[class*="popup"]');
            hideElement('[class*="modal"]');
            hideElement('[aria-label*="chat"]');
            hideElement('[aria-label*="Chat"]');
            hideElement('[class*="intercom"]');
            hideElement('[id*="intercom"]');
            hideElement('[class*="cookie"]');
            hideElement('[id*="cookie"]');

            document.body.style.background = '#ffffff';
            document.body.style.margin = '0';
            document.body.style.padding = '0';
            document.body.style.overflowX = 'hidden';

            document.documentElement.style.background = '#ffffff';
            document.documentElement.style.margin = '0';
            document.documentElement.style.padding = '0';
            document.documentElement.style.overflowX = 'hidden';

            var main =
              document.querySelector('.shopify-policy__container') ||
              document.querySelector('main') ||
              document.querySelector('.main-page-wrapper') ||
              document.querySelector('.page-width') ||
              document.querySelector('.rte') ||
              document.querySelector('.shopify-section') ||
              document.body;

            if (main) {
              main.style.maxWidth = '900px';
              main.style.margin = '0 auto';
              main.style.padding = '24px 18px 40px 18px';
              main.style.boxSizing = 'border-box';
            }

            setTimeout(function() {
              document.documentElement.style.opacity = '1';
            }, 50);
          }

          applyStyles();
          setTimeout(applyStyles, 1);
          setTimeout(applyStyles, 20);
          setTimeout(applyStyles, 80);
          setTimeout(applyStyles, 180);
          setTimeout(applyStyles, 400);
          setTimeout(applyStyles, 800);
          setTimeout(applyStyles, 1500);
        } catch (e) {
          document.documentElement.style.opacity = '1';
        }
      })();
    ''';

    try {
      await _controller.runJavaScript(script);
    } catch (_) {}
  }

  Future<void> _reloadPage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await _controller.loadRequest(_baseUri);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F4F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Stack(
          children: [
            if (!_hasError) WebViewWidget(controller: _controller),
            if (_hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 48,
                        color: Colors.black54,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Page failed to load',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _reloadPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Try Again',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isLoading && !_hasError)
              Container(
                color: Colors.white,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}