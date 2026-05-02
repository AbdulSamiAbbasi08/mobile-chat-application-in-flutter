import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _loadingMessage = 'Creating your account...';
  String _usernameError = '';
  bool _isCheckingUsername = false;
  int _passwordStrength = 0; // 0=empty, 1=weak, 2=fair, 3=strong

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    final pass = _passwordController.text;
    setState(() {
      if (pass.isEmpty) {
        _passwordStrength = 0;
      } else if (pass.length < 6) {
        _passwordStrength = 1;
      } else if (pass.length < 8 ||
          !pass.contains(RegExp(r'[A-Z]')) ||
          !pass.contains(RegExp(r'[0-9]'))) {
        _passwordStrength = 2;
      } else {
        _passwordStrength = 3;
      }
    });
  }

  void _onUsernameChanged() {
    final username = _usernameController.text;

    // Validate format immediately
    if (username.contains(' ')) {
      setState(() => _usernameError = 'Username cannot contain spaces');
      return;
    }
    if (username.contains(RegExp(r'[A-Z]'))) {
      setState(() => _usernameError = 'Username must be lowercase');
      return;
    }
    if (username.isNotEmpty && !RegExp(r'^[a-z0-9._]+$').hasMatch(username)) {
      setState(() => _usernameError = 'Only letters, numbers, dots and underscores allowed');
      return;
    }

    setState(() => _usernameError = '');

    // Check availability after 800ms debounce
    if (username.length >= 3) {
      Future.delayed(const Duration(milliseconds: 800), () async {
        if (_usernameController.text == username && mounted) {
          setState(() => _isCheckingUsername = true);
          final available = await DatabaseService().isUsernameAvailable(username);
          if (mounted && _usernameController.text == username) {
            setState(() {
              _usernameError = available ? '' : 'Username already taken';
              _isCheckingUsername = false;
            });
          }
        }
      });
    }
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validations
    if (name.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }
    if (username.length < 3) {
      _showError('Username must be at least 3 characters');
      return;
    }
    if (_usernameError.isNotEmpty) {
      _showError(_usernameError);
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    // If email provided, validate format
    if (email.isNotEmpty && !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    // If no email, generate one from username
    final finalEmail = email.isNotEmpty ? email : '$username@swiftsync.app';

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Checking username availability...';
    });

    try {
      // Final username availability check
      final available = await DatabaseService().isUsernameAvailable(username);
      if (!available) {
        _showError('Username already taken. Please choose another.');
        return;
      }

      setState(() => _loadingMessage = 'Creating your account...');

      // Create Firebase Auth account
      final credential = await AuthService().register(finalEmail, password);

      setState(() => _loadingMessage = 'Saving your profile...');

      // Save profile to Firestore
      await DatabaseService().createUserProfile(
        uid: credential.user!.uid,
        name: name,
        username: username,
        email: finalEmail,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      }
    } catch (e) {
      String message = 'Registration failed. Please try again.';
      if (e.toString().contains('email-already-in-use')) {
        message = 'This email is already registered';
      } else if (e.toString().contains('invalid-email')) {
        message = 'Please enter a valid email address';
      } else if (e.toString().contains('weak-password')) {
        message = 'Password is too weak';
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

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.green;
      default: return Colors.transparent;
    }
  }

  String get _strengthLabel {
    switch (_passwordStrength) {
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Strong';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 36,
                ),
                child: IntrinsicHeight(
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
                          'Create Account',
                          style: AppTextStyles.screenTitle,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Center(
                        child: Text(
                          'Join SwiftSync and start chatting',
                          style: AppTextStyles.small,
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Full Name
                      CustomTextField(
                        hintText: 'Full name',
                        prefixIcon: Icons.person_outline,
                        controller: _nameController,
                      ),

                      const SizedBox(height: 16),

                      // Username field with availability indicator
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _usernameError.isNotEmpty
                                    ? Colors.red.shade400
                                    : _usernameController.text.isNotEmpty &&
                                            _usernameError.isEmpty &&
                                            !_isCheckingUsername
                                        ? Colors.green
                                        : AppColors.border,
                              ),
                            ),
                            child: TextField(
                              controller: _usernameController,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Username (e.g. abdulsami)',
                                hintStyle: const TextStyle(color: AppColors.hintText),
                                prefixIcon: const Icon(
                                  Icons.alternate_email,
                                  color: AppColors.secondaryText,
                                ),
                                suffixIcon: _isCheckingUsername
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primaryPurple,
                                          ),
                                        ),
                                      )
                                    : _usernameController.text.isNotEmpty
                                        ? Icon(
                                            _usernameError.isEmpty
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: _usernameError.isEmpty
                                                ? Colors.green
                                                : Colors.red.shade400,
                                            size: 20,
                                          )
                                        : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          if (_usernameError.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                _usernameError,
                                style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (_usernameController.text.isNotEmpty &&
                              _usernameError.isEmpty &&
                              !_isCheckingUsername &&
                              _usernameController.text.length >= 3)
                            const Padding(
                              padding: EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                'Username available ✓',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Email (optional)
                      CustomTextField(
                        hintText: 'Email address (optional)',
                        prefixIcon: Icons.email_outlined,
                        controller: _emailController,
                      ),

                      const SizedBox(height: 16),

                      // Password
                      CustomTextField(
                        hintText: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        controller: _passwordController,
                      ),

                      // Password strength indicator
                      if (_passwordStrength > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: List.generate(3, (i) {
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: i < _passwordStrength
                                            ? _strengthColor
                                            : AppColors.border,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _strengthLabel,
                              style: TextStyle(
                                color: _strengthColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _passwordStrength == 1
                              ? 'Use 8+ characters, uppercase and numbers'
                              : _passwordStrength == 2
                                  ? 'Add uppercase letters and numbers for stronger password'
                                  : 'Great password!',
                          style: TextStyle(
                            color: AppColors.hintText,
                            fontSize: 11,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Confirm Password
                      CustomTextField(
                        hintText: 'Confirm password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        controller: _confirmPasswordController,
                      ),

                      const SizedBox(height: 24),

                      PrimaryButton(
                        text: _isLoading ? _loadingMessage : 'Create Account',
                        icon: _isLoading ? null : Icons.arrow_forward_rounded,
                        onPressed: _isLoading ? null : _register,
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: AppTextStyles.small,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                context,
                                LoginScreen.routeName,
                              );
                            },
                            child: const Text(
                              'Login',
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
            ),
          ),

          // Full screen loader overlay
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