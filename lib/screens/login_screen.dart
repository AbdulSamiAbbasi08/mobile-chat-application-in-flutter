import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
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
                text: 'Login',
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
    );
  }
}