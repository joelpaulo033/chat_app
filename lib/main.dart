import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/services/auth/auth_gate.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/services/chat/firebase_api.dart';
import 'package:chat_app/theme/light_mode.dart'; // Hakikisha path hii ni sahihi
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  // 1. Inahakikisha Flutter engine imekuwa initialized kabla ya Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Anzisha Firebase (Lazima iwe 'await')
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Anzisha Push Notifications (Kama sio browser/web)
  if (!kIsWeb) {
    try {
      await FirebaseApi().initNotifications();
    } catch (e) {
      debugPrint("Notification Error: $e");
    }
  }

  // 4. Run App ukiwa na Provider kwa ajili ya usimamizi wa Login/Logout
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
      // Inaficha lile neno "Debug" kule juu kulia mwa screen
      debugShowCheckedModeBanner: false,

      title: 'Modern Chat App',

      // --- MFUMO WA RANGI (THEME) ---
      // Hapa tunatumia zile rangi za kisasa (Trending Blue) tulizotengeneza
      theme: AppTheme.lightTheme,       // Inatumika mchana (Light Mode)
      darkTheme: AppTheme.darkTheme,     // Inatumika usiku (Dark Mode)

      // 'system' inafanya app ibadilike rangi yenyewe kulingana na settings za simu
      themeMode: ThemeMode.system,

      // --- UKURASA WA KWANZA (ENTRY POINT) ---
      // AuthGate inakagua kama mtumiaji ameshalogin au la
      home: const AuthGate(),
    );
  }
}