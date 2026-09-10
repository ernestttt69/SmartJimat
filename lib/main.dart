import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:
    'https://afggmxyqarbgqedzoxkh.supabase.co',
    anonKey:
    'sb_publishable_lmO5FpN7j9Jfz5oANPWRXg_3auGDfMR',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartJimat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
        ColorScheme.fromSeed(
          seedColor:
          const Color(0xFF38BB62),
        ),
        scaffoldBackgroundColor:
        const Color(0xFFF6F7F8),
      ),
      home:
      const MainNavigationScreen(),
    );
  }
}