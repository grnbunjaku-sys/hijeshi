import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isSendingReset = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(
      String message, {
        Color backgroundColor = Colors.red,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_isSubmitting) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    String? error;

    if (email.isEmpty) {
      error = 'Ju lutem shkruani email-in';
    } else if (!email.contains('@')) {
      error = 'Email jo valid';
    } else if (password.isEmpty) {
      error = 'Ju lutem shkruani password-in';
    } else if (password.length < 6) {
      error = 'Password duhet të ketë minimum 6 karaktere';
    }

    if (error != null) {
      _showSnackBar(error);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await AuthService.loginApi(
        email: email,
        password: password,
      );

      if (response['success'] != true) {
        if (!mounted) return;
        _showSnackBar(response['message'] ?? 'Login failed');
        return;
      }

      final user = response['user'] as Map<String, dynamic>?;
      final userName =
      (user?['name']?.toString().trim().isNotEmpty ?? false)
          ? user!['name'].toString().trim()
          : email.split('@')[0];

      try {
        await UserService.saveUser(
          name: userName,
          email: email,
          fcmToken: null,
        );
      } catch (e) {
        debugPrint('Firestore saveUser error: $e');
      }

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged in successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gabim gjatë login: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    await showDialog(
      context: context,
      barrierDismissible: !_isSendingReset,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            Future<void> handleReset() async {
              if (_isSendingReset) return;

              final email = resetEmailController.text.trim();

              if (email.isEmpty) {
                _showSnackBar('Ju lutem shkruani email-in');
                return;
              }

              if (!email.contains('@')) {
                _showSnackBar('Email jo valid');
                return;
              }

              if (mounted) {
                setState(() {
                  _isSendingReset = true;
                });
              }
              setDialogState(() {});

              try {
                final response = await AuthService.forgotPassword(email: email);

                if (!mounted) return;

                if (response['success'] == true) {
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }

                  _showSnackBar(
                    response['message'] ??
                        'Linku për resetimin e password-it u dërgua në email.',
                    backgroundColor: Colors.green,
                  );
                } else {
                  _showSnackBar(
                    response['message'] ?? 'Nuk u dërgua email-i për resetim.',
                  );
                }
              } catch (_) {
                if (!mounted) return;
                _showSnackBar('Ndodhi një gabim gjatë dërgimit të email-it.');
              } finally {
                if (mounted) {
                  setState(() {
                    _isSendingReset = false;
                  });
                }
                setDialogState(() {});
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text(
                'Forgot Password',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shkruaj email-in tënd dhe do të të dërgojmë linkun për resetimin e password-it.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      hintText: 'Enter your email',
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: _isSendingReset
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isSendingReset ? null : handleReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSendingReset
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                        : const Text(
                      'Send Link',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w500,
      ),
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
        borderSide: const BorderSide(
          color: Colors.black12,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      suffixIcon: suffixIcon,
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
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Log In',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5F7),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 30,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Log in to your account to continue shopping.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        hintText: 'Enter your email',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        hintText: 'Enter your password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          disabledForegroundColor: Colors.white70,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                            : const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}