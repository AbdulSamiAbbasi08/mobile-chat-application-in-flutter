import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _loadingMessage = 'Logging in...';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Looking up your account...';
    });

    try {
      final email = await DatabaseService().getEmailByUsername(username);

      if (email == null) {
        _showError('No account found with this username');
        return;
      }

      setState(() => _loadingMessage = 'Logging in...');

      await AuthService().login(email, password);

      if (mounted) {
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      }
    } catch (e) {
      String message = 'Login failed. Please try again.';
      if (e.toString().contains('wrong-password') ||
          e.toString().contains('invalid-credential')) {
        message = 'Incorrect password';
      } else if (e.toString().contains('too-many-requests')) {
        message = 'Too many attempts. Please try again later.';
      }
      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final forgotUsernameController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Password',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your username and we\'ll send a password reset link to your registered email address.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: forgotUsernameController,
              autofocus: true,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Username',
                hintStyle: const TextStyle(color: AppColors.hintText),
                prefixIcon: const Icon(Icons.alternate_email, color: AppColors.hintText, size: 20),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryPurple),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.hintText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Send Reset Link',
              style: TextStyle(color: AppColors.softPink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final username = forgotUsernameController.text.trim().toLowerCase();
    forgotUsernameController.dispose();

    if (username.isEmpty) {
      _showError('Please enter your username');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Sending reset link...';
    });

    try {
      final email = await DatabaseService().getEmailByUsername(username);

      if (email == null) {
        _showError('No account found with this username');
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset link sent to $email'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      String message = 'Failed to send reset link. Try again.';
      if (e.toString().contains('too-many-requests')) {
        message = 'Too many attempts. Please try again later.';
      }
      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),

                  Center(
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 90,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Center(
                    child: Text(
                      'Welcome Back',
                      style: AppTextStyles.screenTitle,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Center(
                    child: Text(
                      'Login to continue chatting with friends',
                      style: AppTextStyles.small,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 36),

                  CustomTextField(
                    hintText: 'Username',
                    prefixIcon: Icons.alternate_email,
                    controller: _usernameController,
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    hintText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    controller: _passwordController,
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _forgotPassword, // ← wired up
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.softPink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  PrimaryButton(
                    text: _isLoading ? _loadingMessage : 'Login',
                    icon: _isLoading ? null : Icons.arrow_forward_rounded,
                    onPressed: _isLoading ? null : _login,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: AppTextStyles.small,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RegisterScreen.routeName,
                          );
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: AppColors.softPink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _loadingMessage,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
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