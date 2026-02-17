import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Background message handler
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Payload: ${message.data}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request permission from the user
    await _firebaseMessaging.requestPermission();

    // Fetch the FCM token for this device
    final fCMToken = await _firebaseMessaging.getToken();
    debugPrint('Token: $fCMToken');

    // Initialize platform-specific settings for notifications
    initPushNotifications();
  }

  // Handle incoming messages
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    // Navigate to a specific screen if needed when notification is tapped
  }

  // Initialize push notification settings
  Future<void> initPushNotifications() async {
    // Handle notification when the app is opened from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    // Add listener for when the app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    // Add listener for foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      // You could show a local notification here if needed
      debugPrint(
          'Foreground Notification: ${notification.title} - ${notification.body}');
    });
  }
}
