import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // Initialize notifications
    await NotificationService().initialize(
      NotificationService.navigatorKey!,
    );

    final user = AuthService().currentUser;

    // If logged in, save/refresh FCM token
    if (user != null) {
      final token = await NotificationService().getToken();
      if (token != null) {
        await DatabaseService().saveUserFcmToken(user.uid, token);
      }

      // Handle notification tap if app was opened from closed state
      await NotificationService().handleInitialMessage();
    }

    // Wait at least 4 seconds for splash to show
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    final destination =
        user != null ? const HomeScreen() : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: 0.0, end: 1.0);
          final fadeAnimation = animation.drive(tween);
          return FadeTransition(opacity: fadeAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryPurple,
              AppColors.secondaryPurple,
              AppColors.pinkAccent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/app_logo.png',
                  width: 120,
                ),
                const SizedBox(height: 20),
                const Text(
                  "SwiftSync",
                  style: AppTextStyles.appTitle,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Lets Chat...",
                  style: AppTextStyles.small,
                ),
              ],
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Text(
                'Developed by Abdul Sami Abbasi®',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}