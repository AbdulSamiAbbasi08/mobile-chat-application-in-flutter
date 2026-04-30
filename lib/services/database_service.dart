import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create user profile on registration
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name.toLowerCase(),
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
        return doc.id;
      }
    }

    final newRoom = await _db.collection('chatRooms').add({
      'participants': [currentUid, otherUid],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
    });

    return newRoom.id;
  }

  // Get chat rooms stream for current user
  Stream<QuerySnapshot> getChatRooms(String uid) {
    return _db
        .collection('chatRooms')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
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
}