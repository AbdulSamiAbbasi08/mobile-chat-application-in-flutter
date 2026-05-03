import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class ChatScreen extends StatefulWidget {
  static const String routeName = '/chat';

  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  late String _chatRoomId;
  late String _otherName;
  late String _otherUid;
  late String _currentUid;
  bool _didInit = false;

  Map<String, dynamic>? _replyTo;

  @override
  void initState() {
    super.initState();
    _currentUid = AuthService().currentUser!.uid;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _chatRoomId = args['chatRoomId'];
    _otherName  = args['name'] ?? 'Unknown';
    _otherUid   = args['uid'] ?? '';

    if (!_didInit) {
      _didInit = true;
      DatabaseService().markMessagesAsSeen(_chatRoomId, _currentUid);
      DatabaseService().markChatAsRead(_chatRoomId, _currentUid);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final reply = _replyTo;
    setState(() => _replyTo = null);

    final db = FirebaseFirestore.instance;

    await db
        .collection('chatRooms')
        .doc(_chatRoomId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': _currentUid,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      if (reply != null) 'replyToText': reply['text'],
      if (reply != null) 'replyToSender': reply['senderName'],
    });

    await db.collection('chatRooms').doc(_chatRoomId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': _currentUid,
    });
  }

  void _setReply(Map<String, dynamic> msg) {
    final isMe = msg['senderId'] == _currentUid;
    setState(() {
      _replyTo = {
        'text': msg['text'] ?? '',
        'senderName': isMe ? 'You' : _otherName,
      };
    });
    _focusNode.requestFocus();
    HapticFeedback.lightImpact();
  }

  void _cancelReply() => setState(() => _replyTo = null);

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Widget _buildTicks(String status) {
    switch (status) {
      case 'seen':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done, size: 13, color: AppColors.pinkAccent),
            Transform.translate(
              offset: const Offset(-6, 0),
              child: Icon(Icons.done, size: 13, color: AppColors.pinkAccent),
            ),
          ],
        );
      case 'delivered':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done, size: 13, color: AppColors.white.withOpacity(0.6)),
            Transform.translate(
              offset: const Offset(-6, 0),
              child: Icon(Icons.done, size: 13, color: AppColors.white.withOpacity(0.6)),
            ),
          ],
        );
      default:
        return Icon(Icons.done, size: 13, color: AppColors.white.withOpacity(0.6));
    }
  }

  Widget _buildSwipeableMessage(Map<String, dynamic> msg, Widget child) {
    double dragOffset = 0;
    bool triggered = false;

    return StatefulBuilder(
      builder: (context, setLocal) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 0) {
              setLocal(() {
                dragOffset = (dragOffset + details.delta.dx).clamp(0.0, 72.0);
              });
              if (dragOffset >= 60 && !triggered) {
                triggered = true;
                _setReply(msg);
              }
            }
          },
          onHorizontalDragEnd: (_) {
            setLocal(() {
              dragOffset = 0;
              triggered = false;
            });
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 100),
                      opacity: (dragOffset / 60).clamp(0.0, 1.0),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.reply_rounded,
                          color: AppColors.primaryPurple,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(dragOffset, 0),
                child: child,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReplyQuote(String senderName, String text, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isMe ? AppColors.pinkAccent : AppColors.primaryPurple,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            style: TextStyle(
              color: isMe ? AppColors.pinkAccent : AppColors.primaryPurple,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showUserProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FutureBuilder<DocumentSnapshot>(
          future: DatabaseService().getUserProfile(_otherUid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final data     = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final name     = data['name'] ?? _otherName;
            final username = data['username'] ?? '';
            final status   = data['status'] ?? '';
            final initial  = name.isNotEmpty ? name[0].toUpperCase() : '?';

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.hintText,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 80, height: 80,
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
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('@$username',
                    style: const TextStyle(color: AppColors.hintText, fontSize: 14),
                  ),
                  if (status.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(status,
                        style: const TextStyle(
                          color: AppColors.softPink,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryPurple),
                      label: const Text('Back to Chat',
                        style: TextStyle(color: AppColors.primaryPurple),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryPurple),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _showUserProfile,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryPurple,
                child: Text(
                  _otherName[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_otherName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text('Tap to view profile',
                    style: TextStyle(color: AppColors.hintText, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Messages list ─────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(_chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSay hello! 👋',
                      style: TextStyle(color: AppColors.hintText),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                  DatabaseService().markMessagesAsSeen(_chatRoomId, _currentUid);
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg       = messages[index].data() as Map<String, dynamic>;
                    final bool isMe = msg['senderId'] == _currentUid;
                    final time      = _formatTime(msg['timestamp'] as Timestamp?);
                    final status    = msg['status'] as String? ?? 'sent';
                    final replyText   = msg['replyToText'] as String?;
                    final replySender = msg['replyToSender'] as String?;
                    final hasReply    = replyText != null && replyText.isNotEmpty && replySender != null;

                    final bubble = Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                          bottom: 6,
                          left: isMe ? 48 : 0,
                          right: isMe ? 0 : 48,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isMe
                              ? const LinearGradient(
                                  colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isMe ? null : const Color(0xFF2A2A3D),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                          border: isMe
                              ? null
                              : Border.all(
                                  color: AppColors.primaryPurple.withOpacity(0.25),
                                  width: 1,
                                ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Reply quote — only when message has a reply
                            if (hasReply)
                              _buildReplyQuote(replySender!, replyText!, isMe),

                            // Message text
                            Text(
                              msg['text'] ?? '',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Time + ticks — pushed to right
                            Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    time,
                                    style: TextStyle(
                                      color: isMe
                                          ? AppColors.white.withOpacity(0.7)
                                          : AppColors.hintText,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    _buildTicks(status),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    return _buildSwipeableMessage(msg, bubble);
                  },
                );
              },
            ),
          ),

          // ── Reply preview bar ─────────────────────────────────────────
          if (_replyTo != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to ${_replyTo!['senderName']}',
                          style: const TextStyle(
                            color: AppColors.primaryPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _replyTo!['text'],
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _cancelReply,
                    icon: const Icon(Icons.close, color: AppColors.hintText, size: 20),
                  ),
                ],
              ),
            ),

          // ── Input bar ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            decoration: const BoxDecoration(color: AppColors.background),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter &&
                            !HardwareKeyboard.instance.isShiftPressed) {
                          _sendMessage();
                        }
                      },
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        style: const TextStyle(color: AppColors.white),
                        maxLines: null,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: AppColors.hintText),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 52, height: 52,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryPurple, AppColors.secondaryPurple, AppColors.pinkAccent],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded, color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}