import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'chat_screen.dart';

class SearchUserScreen extends StatefulWidget {
  static const String routeName = '/search-user';

  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _recentPartners = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _creatingChatForUid; // tracks which user's Chat button is loading

  final _avatarColors = [
    AppColors.primaryPurple,
    AppColors.softPink,
    AppColors.softBlue,
    AppColors.secondaryPurple,
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentPartners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentPartners() async {
    final currentUid = AuthService().currentUser!.uid;
    final partners = await DatabaseService().getRecentChatPartners(currentUid);
    if (mounted) {
      setState(() {
        _recentPartners = partners;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final currentUid = AuthService().currentUser!.uid;
      final queryLower = query.trim().toLowerCase();

      final nameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: queryLower)
          .get();

      final emailSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: queryLower)
          .get();

      final Map<String, Map<String, dynamic>> combined = {};

      for (var doc in [...nameSnapshot.docs, ...emailSnapshot.docs]) {
        if (doc.id != currentUid && !combined.containsKey(doc.id)) {
          combined[doc.id] = {
            'uid': doc.id,
            ...doc.data(),
          };
        }
      }

      setState(() {
        _results = combined.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openChat(Map<String, dynamic> user) async {
    if (_creatingChatForUid != null) return; // prevent double tap

    final otherUid = user['uid'];

    setState(() => _creatingChatForUid = otherUid);

    try {
      final currentUid = AuthService().currentUser!.uid;
      final chatRoomId = await DatabaseService()
          .getOrCreateChatRoom(currentUid, otherUid);

      if (mounted) {
        Navigator.pushNamed(
          context,
          ChatScreen.routeName,
          arguments: {
            'uid': otherUid,
            'name': user['name'],
            'chatRoomId': chatRoomId,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to open chat. Please try again.'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingChatForUid = null);
    }
  }

  Widget _buildUserTile(Map<String, dynamic> user, int index) {
    final color = _avatarColors[index % _avatarColors.length];
    final name = user['name'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final otherUid = user['uid'];
    final isCreating = _creatingChatForUid == otherUid;
    final anyCreating = _creatingChatForUid != null;

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
            backgroundColor: color,
            child: Text(
              name[0].toUpperCase(),
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
                  name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Chat button with loader
          GestureDetector(
            onTap: anyCreating ? null : () => _openChat(user),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: anyCreating && !isCreating
                      ? [AppColors.primaryPurple.withOpacity(0.4), AppColors.secondaryPurple.withOpacity(0.4)]
                      : [AppColors.primaryPurple, AppColors.secondaryPurple],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isCreating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
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
  }

  @override
  Widget build(BuildContext context) {
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
              'Enter full name or email to find a user',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: 18),

            Container(
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.white),
                onSubmitted: _searchUsers,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by full name or email',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.secondaryText,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.hintText, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _results = [];
                              _hasSearched = false;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              _hasSearched ? 'Search Results' : 'Recent Chats',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasSearched && _results.isEmpty
                      ? const Center(
                          child: Text(
                            'No users found.\nMake sure you enter the full name or email.',
                            style: AppTextStyles.small,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _hasSearched
                          ? ListView.separated(
                              itemCount: _results.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) =>
                                  _buildUserTile(_results[index], index),
                            )
                          : _recentPartners.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No recent chats yet.\nSearch for a user to start chatting!',
                                    style: AppTextStyles.small,
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _recentPartners.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) =>
                                      _buildUserTile(_recentPartners[index], index),
                                ),
            ),
          ],
        ),
      ),
    );
  }
}