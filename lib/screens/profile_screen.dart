import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  static const String routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget profileOption({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      Color iconColor = AppColors.primaryPurple,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.hintText,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            const SizedBox(height: 8),

            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple,
                    AppColors.secondaryPurple,
                    AppColors.pinkAccent,
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Abdul Sami',
              style: AppTextStyles.screenTitle,
            ),

            const SizedBox(height: 6),

            const Text(
              'sami@example.com',
              style: AppTextStyles.small,
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Available for chatting',
                style: TextStyle(
                  color: AppColors.softPink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 28),

            profileOption(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: 'Update your personal information',
              onTap: () {},
            ),

            const SizedBox(height: 12),

            profileOption(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Manage push and in-app alerts',
              onTap: () {},
              iconColor: AppColors.softBlue,
            ),

            const SizedBox(height: 12),

            profileOption(
              icon: Icons.lock_outline_rounded,
              title: 'Privacy & Security',
              subtitle: 'Control password and account privacy',
              onTap: () {},
              iconColor: AppColors.softPink,
            ),

            const SizedBox(height: 12),

            profileOption(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: 'Dark theme enabled',
              onTap: () {},
              iconColor: AppColors.secondaryPurple,
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    LoginScreen.routeName,
                    (route) => false,
                  );
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.softPink,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.softPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.softPink),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}