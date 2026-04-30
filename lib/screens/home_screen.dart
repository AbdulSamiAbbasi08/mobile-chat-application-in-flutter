import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'search_user_screen.dart';

class HomeScreen extends StatelessWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chats = [
      {
        'name': 'Abdul Sami',
        'message': 'Hey, are you free tonight?',
        'time': '10:24 PM',
        'color': AppColors.primaryPurple,
      },
      {
        'name': 'Abdullah',
        'message': 'Typing...',
        'time': '09:10 PM',
        'color': AppColors.softPink,
      },
      {
        'name': 'Bilal',
        'message': 'See you tomorrow',
        'time': 'Yesterday',
        'color': AppColors.softBlue,
      },
      {
        'name': 'Manan',
        'message': 'Send me the notes please',
        'time': 'Yesterday',
        'color': AppColors.secondaryPurple,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, ProfileScreen.routeName);
            },
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome Back 👋', style: AppTextStyles.small),
            const SizedBox(height: 6),
            const Text('Your Conversations', style: AppTextStyles.screenTitle),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, SearchUserScreen.routeName);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.secondaryText),
                    SizedBox(width: 12),
                    Text(
                      'Search users or start new chat',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            const Text('Recent Chats', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.separated(
                itemCount: chats.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final chat = chats[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, ChatScreen.routeName);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: chat['color'] as Color,
                            child: Text(
                              (chat['name'] as String)[0],
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
                                  chat['name'] as String,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  chat['message'] as String,
                                  style: TextStyle(
                                    color: (chat['message'] == 'Typing...')
                                        ? AppColors.softPink
                                        : AppColors.secondaryText,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            chat['time'] as String,
                            style: const TextStyle(
                              color: AppColors.hintText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryPurple,
        onPressed: () {
          Navigator.pushNamed(context, SearchUserScreen.routeName);
        },
        child: const Icon(Icons.chat_bubble_outline, color: AppColors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.navBarBackground,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: AppColors.hintText,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, SearchUserScreen.routeName);
          } else if (index == 2) {
            Navigator.pushNamed(context, ProfileScreen.routeName);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}