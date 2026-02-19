import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  static final _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // name
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  Future<void> initNotifications() async {
    // 1. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/sms'); // Ensure this icon exists
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Create the channel on the device (required for Android 8+)
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 2. Request permission from user
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');
    } else {
      debugPrint('❌ User declined or has not accepted permission');
    }

    // 3. Get the FCM Token
    final fCMToken = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $fCMToken');

    // 4. Save token if user is logged in
    if (fCMToken != null) {
      await _saveTokenToFirestore(fCMToken);
    }

    // 5. Token Refresh handling
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      await _saveTokenToFirestore(newToken);
    });

    // 6. Autostart: Listen to Auth Changes to save token on login & start Global Listener
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
        }
        // Initialize Global Firestore Listener for Local Popups
        _listenToIncomingMessages(user.uid);
      }
    });

    // 7. Handle Foreground Messages (FCM)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null && !kIsWeb) {
        showLocalNotification(
          title: notification.title ?? 'New Message',
          body: notification.body ?? '',
          payload: message.data.toString(),
        );
      }
    });
  }

  // --- GLOBAL FIRESTORE LISTENER FOR LOCAL POPUPS --- //
  final Map<String, Timestamp> _lastSeenTimestamps = {};

  void _listenToIncomingMessages(String currentUserId) {
    if (kIsWeb) return; // Do not use local notifications on web for now

    FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;

        final lastSenderId = data['lastSenderId'];
        final lastMessage = data['lastMessage'] ?? '';
        final timestamp = data['lastMessageTimestamp'] as Timestamp?;
        final isGroup = data['isGroup'] ?? false;

        // Skip if there's no timestamp, or if we sent the message ourselves
        if (timestamp == null ||
            lastSenderId == null ||
            lastSenderId == currentUserId) {
          _lastSeenTimestamps[change.doc.id] = timestamp ?? Timestamp.now();
          continue;
        }

        // Check if this is a NEW message (not just fetching initial data)
        bool shouldNotify = false;
        if (_lastSeenTimestamps.containsKey(change.doc.id)) {
          final oldTime = _lastSeenTimestamps[change.doc.id]!;
          if (timestamp.compareTo(oldTime) > 0) {
            shouldNotify = true;
          }
        } else {
          // If we haven't seen this chat room in memory, only notify if the message is VERY recent (within 5 seconds).
          // This prevents a flood of old messages popping up when the app first launches.
          final now = Timestamp.now();
          if (now.seconds - timestamp.seconds < 5) {
            shouldNotify = true;
          }
        }

        // Update the tracked timestamp
        _lastSeenTimestamps[change.doc.id] = timestamp;

        if (shouldNotify) {
          // Fetch the sender's name for the notification title
          String title = 'New Message';
          try {
            if (isGroup) {
              final groupName = data['groupName'] ?? 'Group Chat';
              final senderDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(lastSenderId)
                  .get();
              final senderName = senderDoc.data()?['displayName'] ??
                  senderDoc.data()?['email'] ??
                  'Someone';
              title = '$groupName ($senderName)';
            } else {
              final senderDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(lastSenderId)
                  .get();
              title = senderDoc.data()?['displayName'] ??
                  senderDoc.data()?['email'] ??
                  'New Message';
            }
          } catch (e) {
            debugPrint('Error fetching sender for notification: $e');
          }

          showLocalNotification(
            title: title,
            body: lastMessage,
          );
        }
      }
    });
  }

  // Helper method to trigger the drop-down banner popup
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return; // Local notifications are mainly for mobile

    _localNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000), // Random ID
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/sms',
        ),
      ),
      payload: payload,
    );
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final authService = AuthService();
    final user = authService.getCurrentUser();
    if (user != null) {
      try {
        await authService.updateFcmToken(user.uid, token);
        debugPrint('✅ FCM Token saved to Firestore');
      } catch (e) {
        debugPrint('❌ Failed to save FCM Token: $e');
      }
    }
  }
}
