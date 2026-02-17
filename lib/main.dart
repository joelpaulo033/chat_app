import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Hakikisha hizi imports zinaendana na jina la project yako
import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/services/auth/auth_gate.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/services/chat/firebase_api.dart';
import 'package:chat_app/theme/light_mode.dart';

void main() async {
  // 1. Muhimu: Hakikisha Flutter engine imekuwa initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Anzisha Firebase kwa kutumia options za platform husika
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Anzisha Notifications (kama simu sio Web)
  if (!kIsWeb) {
    try {
      await FirebaseApi().initNotifications();
    } catch (e) {
      debugPrint("Notification Error: $e");
    }
  }

  // 4. Run App ukiwa na Provider kwa ajili ya usimamizi wa Auth
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Inaficha lile neno "Debug" kule juu kulia
      debugShowCheckedModeBanner: false,

      title: 'Modern Chat App',

      // --- MFUMO WA RANGI (THEME) ---
      // Inachukua rangi za kisasa tulizoweka kwenye AppTheme
      theme: AppTheme.lightTheme,       // Rangi za mchana (Electric Blue)
      darkTheme: AppTheme.darkTheme,     // Rangi za usiku (Deep Slate/Black)

      // Hii line inafanya app ibadilike rangi yenyewe simu ikibadilika settings
      themeMode: ThemeMode.system,

      // --- UKURASA WA KWANZA ---
      // AuthGate itaamua kama uende Login au Chat moja kwa moja
      home: const AuthGate(),
    );
  }
}