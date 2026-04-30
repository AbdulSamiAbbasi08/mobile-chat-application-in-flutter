import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  static const String routeName = '/register';

  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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

                  const CustomTextField(
                    hintText: 'Full name',
                    prefixIcon: Icons.person_outline,
                  ),

                  const SizedBox(height: 16),

                  const CustomTextField(
                    hintText: 'Email address',
                    prefixIcon: Icons.email_outlined,
                  ),

                  const SizedBox(height: 16),

                  const CustomTextField(
                    hintText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                  ),

                  const SizedBox(height: 16),

                  const CustomTextField(
                    hintText: 'Confirm password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                  ),

                  const SizedBox(height: 24),

                  PrimaryButton(
                    text: 'Create Account',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        HomeScreen.routeName,
                      );
                    },
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
    );
  }
}