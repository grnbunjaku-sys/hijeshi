import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';
import 'policy_webview_screen.dart';
import 'register_screen.dart';
import 'my_orders_screen.dart';
import 'notifications_center_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';

  static const String _privacyPolicyUrl =
      'https://www.hijeshicosmetics.com/policies/privacy-policy';
  static const String _termsUrl =
      'https://www.hijeshicosmetics.com/policies/terms-of-service';
  static const String _shippingUrl =
      'https://www.hijeshicosmetics.com/policies/shipping-policy';
  static const String _helpContactUrl =
      'https://www.hijeshicosmetics.com/pages/help-contact';
  static const String _aboutHijeshiUrl =
      'https://www.hijeshicosmetics.com/pages/about-hijeshi';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    final userName = await AuthService.getUserName() ?? '';
    final userEmail = await AuthService.getUserEmail() ?? '';

    if (!mounted) return;

    setState(() {
      _isLoggedIn = isLoggedIn;
      _userName = userName;
      _userEmail = userEmail;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();

    if (!mounted) return;

    setState(() {
      _isLoggedIn = false;
      _userName = '';
      _userEmail = '';
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _openLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );

    await _loadUser();
  }

  Future<void> _openRegister() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );

    await _loadUser();
  }

  Future<void> _openPolicyPage({
    required String title,
    required String url,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PolicyWebViewScreen(
          title: title,
          url: url,
        ),
      ),
    );
  }

  Future<void> _openFavorites() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoritesScreen(),
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsCenterScreen(),
      ),
    );
  }

  Future<void> _openOrders() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyOrdersScreen(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildProfileAvatar({required bool loggedIn}) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        loggedIn ? Icons.account_circle : Icons.person_outline,
        size: 54,
        color: Colors.black,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: Colors.black87,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDanger ? Colors.redAccent : Colors.black87,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDanger ? Colors.redAccent : Colors.black,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Discover'),
        _buildMenuTile(
          icon: Icons.favorite_border,
          title: 'Favorites',
          subtitle: 'Save your beauty picks for later',
          onTap: _openFavorites,
        ),
        _buildMenuTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Stay updated with new drops and offers',
          onTap: _openNotifications,
        ),
        _buildSectionTitle('Legal & Support'),
        _buildMenuTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'Read how we manage your data',
          onTap: () => _openPolicyPage(
            title: 'Privacy Policy',
            url: _privacyPolicyUrl,
          ),
        ),
        _buildMenuTile(
          icon: Icons.description_outlined,
          title: 'Terms & Conditions',
          subtitle: 'Review store terms and conditions',
          onTap: () => _openPolicyPage(
            title: 'Terms & Conditions',
            url: _termsUrl,
          ),
        ),
        _buildMenuTile(
          icon: Icons.local_shipping_outlined,
          title: 'Shipping & Returns',
          subtitle: 'Delivery, returns and refund details',
          onTap: () => _openPolicyPage(
            title: 'Shipping & Returns',
            url: _shippingUrl,
          ),
        ),
        _buildMenuTile(
          icon: Icons.support_agent_outlined,
          title: 'Help & Contact',
          subtitle: 'Need support? Reach out to us',
          onTap: () => _openPolicyPage(
            title: 'Help & Contact',
            url: _helpContactUrl,
          ),
        ),
        _buildMenuTile(
          icon: Icons.info_outline_rounded,
          title: 'About Hijeshi',
          subtitle: 'Learn more about our brand and app',
          onTap: () => _openPolicyPage(
            title: 'About Hijeshi',
            url: _aboutHijeshiUrl,
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedInMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('My Account'),
        _buildMenuTile(
          icon: Icons.shopping_bag_outlined,
          title: 'Porositë',
          subtitle: 'Shiko statusin e porosive tuaja',
          onTap: _openOrders,
        ),
        _buildMenuTile(
          icon: Icons.favorite_border,
          title: 'Favorites',
          subtitle: 'Produktet që i ke ruajtur',
          onTap: _openFavorites,
        ),
        _buildMenuTile(
          icon: Icons.notifications_none_rounded,
          title: 'Njoftimet',
          subtitle: 'Ofertat, launch-et dhe përditësimet',
          onTap: _openNotifications,
        ),
        _buildSectionTitle('Legal'),
        _buildMenuTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Politika e Privatësisë',
          subtitle: 'E lidhur me policy page nga Shopify',
          onTap: () => _openPolicyPage(
            title: 'Politika e Privatësisë',
            url: _privacyPolicyUrl,
          ),
        ),
        _buildMenuTile(
          icon: Icons.description_outlined,
          title: 'Terms & Conditions',
          subtitle: 'Kushtet e përdorimit të dyqanit',
          onTap: () => _openPolicyPage(
            title: 'Terms & Conditions',
            url: _termsUrl,
          ),
        ),
        _buildMenuTile(
          icon: Icons.local_shipping_outlined,
          title: 'Shipping & Returns',
          subtitle: 'Dorëzimi, kthimet dhe rimbursimet',
          onTap: () => _openPolicyPage(
            title: 'Shipping & Returns',
            url: _shippingUrl,
          ),
        ),
        _buildSectionTitle('Support'),
        _buildMenuTile(
          icon: Icons.support_agent_outlined,
          title: 'Help & Contact',
          subtitle: 'Kontakto ekipin e Hijeshi',
          onTap: () => _openPolicyPage(
            title: 'Help & Contact',
            url: _helpContactUrl,
          ),
        ),
        _buildMenuTile(
          icon: Icons.info_outline_rounded,
          title: 'About Hijeshi',
          subtitle: 'Informacion rreth aplikacionit',
          onTap: () => _openPolicyPage(
            title: 'About Hijeshi',
            url: _aboutHijeshiUrl,
          ),
        ),
        _buildMenuTile(
          icon: Icons.logout_rounded,
          title: 'Log Out',
          subtitle: 'Dil nga llogaria jote',
          isDanger: true,
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _buildLoggedInView() {
    final displayName = _userName.isNotEmpty ? _userName : 'User';
    final displayEmail =
    _userEmail.isNotEmpty ? _userEmail : 'No email available';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProfileAvatar(loggedIn: true),
        const SizedBox(height: 18),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome back to your beauty profile.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoTile(
          icon: Icons.person_outline,
          title: 'Full Name',
          value: displayName,
        ),
        const SizedBox(height: 12),
        _buildInfoTile(
          icon: Icons.mail_outline,
          title: 'Email Address',
          value: displayEmail,
        ),
        const SizedBox(height: 28),
        _buildLoggedInMenu(),
      ],
    );
  }

  Widget _buildLoggedOutView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProfileAvatar(loggedIn: false),
        const SizedBox(height: 18),
        const Text(
          'My Account',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Log in or create an account to manage your orders, wishlist and shopping experience.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _openLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              'Log In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: _openRegister,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: BorderSide(
                color: Colors.black.withValues(alpha: 0.10),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _buildGuestMenu(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage your account and preferences',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: _isLoading
                        ? _buildLoadingState()
                        : _isLoggedIn
                        ? _buildLoggedInView()
                        : _buildLoggedOutView(),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'Hijeshi v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}