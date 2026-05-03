import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'search_user_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOffline = false;
  String _userName = '';
  late StreamSubscription _connectivitySub;

  final _avatarColors = const [
    AppColors.primaryPurple,
    AppColors.softPink,
    AppColors.softBlue,
    AppColors.secondaryPurple,
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOffline = result.contains(ConnectivityResult.none);
      });
    });
  }

  Future<void> _loadUserName() async {
    final user = AuthService().currentUser;
    if (user != null) {
      final doc = await DatabaseService().getUserProfile(user.uid);
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() => _userName = data['name'] ?? '');
      }
    }
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      final hour = date.hour > 12
          ? date.hour - 12
          : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Returns true if this chat has unread messages for currentUid
  bool _isUnread(Map<String, dynamic> room, String currentUid) {
    final lastMessageTime = room['lastMessageTime'] as Timestamp?;
    final lastMessageSenderId = room['lastMessageSenderId'] as String?;

    // No message yet, or current user sent the last message — never unread
    if (lastMessageTime == null) return false;
    if (lastMessageSenderId == currentUid) return false;

    final lastReadMap = room['lastRead'] as Map<String, dynamic>?;
    final lastRead = lastReadMap?[currentUid] as Timestamp?;

    // Never opened = unread; or last message is newer than last read
    if (lastRead == null) return true;
    return lastMessageTime.compareTo(lastRead) > 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, ProfileScreen.routeName),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.orange.shade700,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'You are offline — messages will sync when connected',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName.isNotEmpty
                        ? 'Welcome Back, ${_userName[0].toUpperCase()}${_userName.substring(1)} 👋'
                        : 'Welcome Back 👋',
                    style: AppTextStyles.small,
                  ),
                  const SizedBox(height: 6),
                  const Text('Your Conversations', style: AppTextStyles.screenTitle),
                  const SizedBox(height: 20),
                  const Text('Recent Chats', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 4),
                  const Text(
                    'Swipe left to delete a chat',
                    style: TextStyle(color: AppColors.hintText, fontSize: 11),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: DatabaseService().getChatRooms(currentUid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No conversations yet.\nTap Search to start chatting!',
                              style: AppTextStyles.small,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        final chatRooms = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final deletedFor = List<String>.from(data['deletedFor'] ?? []);
                          return !deletedFor.contains(currentUid);
                        }).toList();

                        if (chatRooms.isEmpty) {
                          return const Center(
                            child: Text(
                              'No conversations yet.\nTap Search to start chatting!',
                              style: AppTextStyles.small,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: chatRooms.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final room = chatRooms[index].data() as Map<String, dynamic>;
                            final participants = List<String>.from(room['participants']);
                            final otherUid = participants.firstWhere((id) => id != currentUid);
                            final color = _avatarColors[index % _avatarColors.length];
                            final chatRoomId = chatRooms[index].id;
                            final unread = _isUnread(room, currentUid); // ← unread check

                            return FutureBuilder<DocumentSnapshot>(
                              future: DatabaseService().getUserProfile(otherUid),
                              builder: (context, userSnap) {
                                final name = userSnap.data?.exists == true
                                    ? (userSnap.data!.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
                                    : 'Loading...';
                                final lastMessage = room['lastMessage'] ?? '';
                                final time = _formatTime(room['lastMessageTime'] as Timestamp?);

                                return Dismissible(
                                  key: Key(chatRoomId),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: AppColors.cardBackground,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        title: const Text(
                                          'Delete Chat',
                                          style: TextStyle(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        content: Text(
                                          'Delete your conversation with $name? This will only remove it from your view.',
                                          style: const TextStyle(
                                            color: AppColors.secondaryText,
                                            fontSize: 14,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel',
                                                style: TextStyle(color: AppColors.hintText)),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.redAccent,
                                                    fontWeight: FontWeight.w600)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      await DatabaseService().deleteChatForUser(chatRoomId, currentUid);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Chat with $name deleted'),
                                            backgroundColor: AppColors.cardBackground,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    }
                                    return false;
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade700,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.delete_outline, color: Colors.white, size: 26),
                                        SizedBox(height: 4),
                                        Text('Delete',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: () async {
                                      // Mark as read before opening
                                      await DatabaseService().markChatAsRead(chatRoomId, currentUid);
                                      if (context.mounted) {
                                        Navigator.pushNamed(
                                          context,
                                          ChatScreen.routeName,
                                          arguments: {
                                            'uid': otherUid,
                                            'name': name,
                                            'chatRoomId': chatRoomId,
                                          },
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        // Subtle highlight for unread chats
                                        color: unread
                                            ? AppColors.primaryPurple.withOpacity(0.08)
                                            : AppColors.cardBackground,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: unread
                                              ? AppColors.primaryPurple.withOpacity(0.4)
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Avatar with unread dot
                                          Stack(
                                            children: [
                                              CircleAvatar(
                                                radius: 26,
                                                backgroundColor: color,
                                                child: Text(
                                                  name[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    color: AppColors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (unread)
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: Container(
                                                    width: 13,
                                                    height: 13,
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primaryPurple,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: AppColors.background,
                                                        width: 2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Bold name if unread
                                                Text(
                                                  name,
                                                  style: TextStyle(
                                                    color: AppColors.white,
                                                    fontSize: 16,
                                                    fontWeight: unread
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                // Bold white preview if unread
                                                Text(
                                                  lastMessage.isEmpty
                                                      ? 'Tap to start chatting'
                                                      : lastMessage,
                                                  style: TextStyle(
                                                    color: unread
                                                        ? AppColors.white
                                                        : (lastMessage.isEmpty
                                                            ? AppColors.hintText
                                                            : AppColors.secondaryText),
                                                    fontSize: 14,
                                                    fontWeight: unread
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Time + unread dot indicator
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                time,
                                                style: TextStyle(
                                                  color: unread
                                                      ? AppColors.primaryPurple
                                                      : AppColors.hintText,
                                                  fontSize: 12,
                                                  fontWeight: unread
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              'Developed by Abdul Sami Abbasi®',
              style: TextStyle(color: AppColors.hintText, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryPurple,
        onPressed: () => Navigator.pushNamed(context, SearchUserScreen.routeName),
        child: const Icon(Icons.chat_bubble_outline, color: AppColors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.navBarBackground,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: AppColors.hintText,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, SearchUserScreen.routeName);
          else if (index == 2) Navigator.pushNamed(context, ProfileScreen.routeName);
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