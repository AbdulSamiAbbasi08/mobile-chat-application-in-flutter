import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/search_user_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SwiftSyncApp());
}

class SwiftSyncApp extends StatelessWidget {
  const SwiftSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SwiftSync',
      theme: AppTheme.darkTheme,
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        ChatScreen.routeName: (context) => const ChatScreen(),
        SearchUserScreen.routeName: (context) => const SearchUserScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
      },
    );
  }
}