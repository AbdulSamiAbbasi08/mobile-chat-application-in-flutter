import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create user profile on registration
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String username,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'username': username.toLowerCase(),
      'email': email.toLowerCase(),
      'status': 'Available for chatting',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user profile by uid
  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  // Update user name
  Future<void> updateUserName(String uid, String newName) async {
    await _db.collection('users').doc(uid).update({
      'name': newName.toLowerCase(),
    });
  }

  // Update user status
  Future<void> updateUserStatus(String uid, String newStatus) async {
    await _db.collection('users').doc(uid).update({
      'status': newStatus,
    });
  }

  // Search users by name or email
  Future<QuerySnapshot> searchUsers(String query) async {
    return await _db
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
  }

  // Get or create a chat room between two users
  Future<String> getOrCreateChatRoom(String currentUid, String otherUid) async {
    final existing = await _db
        .collection('chatRooms')
        .where('participants', arrayContains: currentUid)
        .get();

    for (var doc in existing.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(otherUid)) {
        await _db.collection('chatRooms').doc(doc.id).update({
          'deletedFor': [],
        });
        return doc.id;
      }
    }

    final newRoom = await _db.collection('chatRooms').add({
      'participants': [currentUid, otherUid],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
      'deletedFor': [],
    });

    return newRoom.id;
  }

  // Get chat rooms stream for current user
  Stream<QuerySnapshot> getChatRooms(String uid) {
    return _db
        .collection('chatRooms')
        .where('participants', arrayContains: uid)
        .snapshots();
  }

  // Get recent chat partners for suggestions
  Future<List<Map<String, dynamic>>> getRecentChatPartners(String uid) async {
    final rooms = await _db
        .collection('chatRooms')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .limit(5)
        .get();

    final List<Map<String, dynamic>> partners = [];
    for (var room in rooms.docs) {
      final data = room.data();
      final deletedFor = List<String>.from(data['deletedFor'] ?? []);
      if (deletedFor.contains(uid)) continue;

      final participants = List<String>.from(room['participants']);
      final otherUid = participants.firstWhere((id) => id != uid);
      final userDoc = await getUserProfile(otherUid);
      if (userDoc.exists) {
        partners.add({
          'uid': otherUid,
          ...userDoc.data() as Map<String, dynamic>,
        });
      }
    }
    return partners;
  }

  // Check if username already exists
  Future<bool> isUsernameAvailable(String username) async {
    final snapshot = await _db
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .get();
    return snapshot.docs.isEmpty;
  }

  // Get email by username for login
  Future<String?> getEmailByUsername(String username) async {
    final snapshot = await _db
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first['email'] as String?;
  }

  // Delete chat for one user only (hide it from their view)
  Future<void> deleteChatForUser(String chatRoomId, String uid) async {
    await _db.collection('chatRooms').doc(chatRoomId).update({
      'deletedFor': FieldValue.arrayUnion([uid]),
    });
  }

  // Update full profile (name + status)
  Future<void> updateUserProfile(String uid, {
    required String name,
    required String status,
  }) async {
    await _db.collection('users').doc(uid).update({
      'name': name.toLowerCase(),
      'status': status,
    });
  }

  // Mark chat as read by updating lastReadTime for current user
  Future<void> markChatAsRead(String chatRoomId, String uid) async {
    await _db.collection('chatRooms').doc(chatRoomId).update({
      'lastRead.$uid': FieldValue.serverTimestamp(),
    });
  }

  // Mark all messages in a chat as seen by the receiver
  Future<void> markMessagesAsSeen(String chatRoomId, String currentUid) async {
    final messages = await _db
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUid)
        .get();

    final docsToUpdate = messages.docs.where((doc) {
      final status = doc.data()['status'] as String? ?? 'sent';
      return status != 'seen';
    }).toList();

    if (docsToUpdate.isEmpty) return;

    final batch = _db.batch();
    for (final doc in docsToUpdate) {
      batch.update(doc.reference, {'status': 'seen'});
    }
    await batch.commit();
  }

  // ── AI Chat Methods ───────────────────────────────────────────────────────

  Stream<QuerySnapshot> getAiMessages(String uid) {
    return _db
        .collection('aiChats')
        .doc(uid)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getAiMessagesList(String uid) async {
    final snapshot = await _db
        .collection('aiChats')
        .doc(uid)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> saveAiMessage(String uid, String role, String text) async {
    final batch = _db.batch();
    final msgRef = _db
        .collection('aiChats')
        .doc(uid)
        .collection('messages')
        .doc();
    batch.set(msgRef, {
      'role': role,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    final parentRef = _db.collection('aiChats').doc(uid);
    batch.set(parentRef, {
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<bool> shouldResetAiChat(String uid) async {
    final doc = await _db.collection('aiChats').doc(uid).get();
    if (!doc.exists) return false;
    final lastMessageTime = doc.data()?['lastMessageTime'] as Timestamp?;
    if (lastMessageTime == null) return false;
    final diff = DateTime.now().difference(lastMessageTime.toDate());
    return diff.inHours >= 1;
  }

  Future<void> clearAiChat(String uid) async {
    final messages = await _db
        .collection('aiChats')
        .doc(uid)
        .collection('messages')
        .get();
    final batch = _db.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.set(
      _db.collection('aiChats').doc(uid),
      {'lastMessageTime': null},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  // ── FCM Token Methods ─────────────────────────────────────────────────────

  // Save FCM token to user's Firestore document
  Future<void> saveUserFcmToken(String uid, String token) async {
  await _db.collection('users').doc(uid).set({
    'fcmToken': token,
  }, SetOptions(merge: true));
}

  // Get FCM token of another user (to send them a notification)
  Future<String?> getUserFcmToken(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['fcmToken'] as String?;
  }
}