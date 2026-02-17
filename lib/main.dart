import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/services/auth/auth_gate.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/services/chat/chat_service.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/services/notifications/firebase_api.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // only initialize notifications on non-web platforms
  if (!kIsWeb) {
    await FirebaseApi().initNotifications();
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => ChatService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      theme: AppTheme.lightTheme,
    );
  }
}
