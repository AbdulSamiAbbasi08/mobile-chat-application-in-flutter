import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'chat_screen.dart';

class SearchUserScreen extends StatelessWidget {
  static const String routeName = '/search-user';

  const SearchUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = [
      {
        'name': 'Abdul Rafay',
        'email': 'rafay@example.com',
        'color': AppColors.primaryPurple,
      },
      {
        'name': 'Abdullah',
        'email': 'abdullah@example.com',
        'color': AppColors.softPink,
      },
      {
        'name': 'Bilal',
        'email': 'bilal@example.com',
        'color': AppColors.softBlue,
      },
      {
        'name': 'Abdul Sami',
        'email': 'sami@example.com',
        'color': AppColors.secondaryPurple,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find people to start a new conversation',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: 18),

            Container(
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const TextField(
                style: TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.secondaryText,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Suggested Users',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = users[index];

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: user['color'] as Color,
                          child: Text(
                            (user['name'] as String)[0],
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'] as String,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user['email'] as String,
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              ChatScreen.routeName,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryPurple,
                                  AppColors.secondaryPurple,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Chat',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}