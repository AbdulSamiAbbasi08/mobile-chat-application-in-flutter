import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

// ── Background message handler — must be top-level function ──────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM shows notification automatically when app is closed
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? navigatorKey;

  String? _cachedToken;
  DateTime? _tokenExpiry;

  // ── Initialize ────────────────────────────────────────────────────────────
  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;
    await _requestPermission();
    await _initLocalNotifications();
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ── Request permission ────────────────────────────────────────────────────
  Future<void> _requestPermission() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ── Get device FCM token ──────────────────────────────────────────────────
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      print('==== GET TOKEN ERROR: $e ====');
      return null;
    }
  }

  // ── Init local notifications ──────────────────────────────────────────────
  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final data = jsonDecode(details.payload!) as Map<String, dynamic>;
          _navigateToChat(data);
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'swiftsync_messages',
      'SwiftSync Messages',
      description: 'Notifications for new messages',
      importance: Importance.high,
      playSound: true,
    );

    await (_localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>())?.createNotificationChannel(channel);
  }

  // ── Handle foreground message ─────────────────────────────────────────────
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'swiftsync_messages',
          'SwiftSync Messages',
          channelDescription: 'Notifications for new messages',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF7C3AED),
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── Handle notification tap (background) ──────────────────────────────────
  void _handleNotificationTap(RemoteMessage message) {
    _navigateToChat(message.data);
  }

  // ── Navigate to chat ──────────────────────────────────────────────────────
  void _navigateToChat(Map<String, dynamic> data) {
    final chatRoomId = data['chatRoomId'] as String?;
    final otherUid   = data['senderUid'] as String?;
    final senderName = data['senderName'] as String?;

    if (chatRoomId == null || otherUid == null) return;

    navigatorKey?.currentState?.pushNamed(
      '/chat',
      arguments: {
        'chatRoomId': chatRoomId,
        'uid': otherUid,
        'name': senderName ?? 'Unknown',
      },
    );
  }

  // ── Handle initial message (app opened from closed state) ─────────────────
  Future<void> handleInitialMessage() async {
    final message = await _fcm.getInitialMessage();
    if (message != null) {
      await Future.delayed(const Duration(seconds: 1));
      _navigateToChat(message.data);
    }
  }

  // ── Get OAuth access token using JWT + service account ────────────────────
  Future<String?> _getAccessToken() async {
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      print('==== USING CACHED ACCESS TOKEN ====');
      return _cachedToken;
    }

    try {
      print('==== LOADING SERVICE ACCOUNT JSON ====');
      final jsonStr =
          await rootBundle.loadString('assets/service_account.json');
      final serviceAccount = jsonDecode(jsonStr) as Map<String, dynamic>;

      final clientEmail = serviceAccount['client_email'] as String;
      final privateKeyPem = serviceAccount['private_key'] as String;
      print('==== CLIENT EMAIL: $clientEmail ====');

      final now = DateTime.now();

      final jwt = JWT({
        'iss': clientEmail,
        'scope': 'https://www.googleapis.com/auth/firebase.messaging',
        'aud': 'https://oauth2.googleapis.com/token',
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': (now.millisecondsSinceEpoch ~/ 1000) + 3600,
      });

      print('==== SIGNING JWT ====');
      final signedJwt = jwt.sign(
        RSAPrivateKey(privateKeyPem),
        algorithm: JWTAlgorithm.RS256,
        noIssueAt: true,
      );
      print('==== JWT SIGNED SUCCESSFULLY ====');

      print('==== EXCHANGING JWT FOR ACCESS TOKEN ====');
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': signedJwt,
        },
      );

      print('==== TOKEN RESPONSE STATUS: ${response.statusCode} ====');
      print('==== TOKEN RESPONSE BODY: ${response.body} ====');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedToken = data['access_token'] as String?;
        _tokenExpiry = now.add(const Duration(minutes: 55));
        print('==== ACCESS TOKEN OBTAINED SUCCESSFULLY ====');
        return _cachedToken;
      }

      print('==== FAILED TO GET ACCESS TOKEN ====');
      return null;
    } catch (e) {
      print('==== GET ACCESS TOKEN ERROR: $e ====');
      return null;
    }
  }

  // ── Send push notification ────────────────────────────────────────────────
  Future<void> sendNotification({
    required String receiverToken,
    required String senderName,
    required String message,
    required String chatRoomId,
    required String senderUid,
  }) async {
    try {
      print('==== SENDING NOTIFICATION TO: $receiverToken ====');

      final accessToken = await _getAccessToken();
      print('==== ACCESS TOKEN RESULT: $accessToken ====');

      if (accessToken == null) {
        print('==== ACCESS TOKEN IS NULL — ABORTING NOTIFICATION ====');
        return;
      }

      final url =
          'https://fcm.googleapis.com/v1/projects/${ApiKeys.fcmProjectId}/messages:send';

      final body = jsonEncode({
        'message': {
          'token': receiverToken,
          'notification': {
            'title': senderName,
            'body': message.length > 100
                ? '${message.substring(0, 100)}...'
                : message,
          },
          'data': {
            'chatRoomId': chatRoomId,
            'senderUid': senderUid,
            'senderName': senderName,
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'swiftsync_messages',
              'color': '#7C3AED',
            },
          },
        }
      });

      print('==== CALLING FCM API ====');
      final fcmResponse = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('==== FCM RESPONSE STATUS: ${fcmResponse.statusCode} ====');
      print('==== FCM RESPONSE BODY: ${fcmResponse.body} ====');
    } catch (e) {
      print('==== SEND NOTIFICATION ERROR: $e ====');
    }
  }
}