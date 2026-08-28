import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://afggmxyqarbgqedzoxkh.supabase.co',
    anonKey: 'sb_publishable_lmO5FpN7j9Jfz5oANPWRXg_3auGDfMR',
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

        scaffoldBackgroundColor: const Color(0xFFF8F8F8),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BB62),
          primary: const Color(0xFF38BB62),
          secondary: const Color(0xFF2E9F52),
          surface: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF333632),
          elevation: 0,
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF38BB62),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF38BB62),
            side: const BorderSide(
              color: Color(0xFF38BB62),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          labelStyle: const TextStyle(
            color: Color(0xFF555555),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF38BB62),
              width: 1.2,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF38BB62),
              width: 2,
            ),
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF38BB62),
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.2,
            ),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
        ),
      ),

      home: const WelcomeScreen(),
    );
  }
}

class SupabaseTestPage extends StatefulWidget {
  const SupabaseTestPage({super.key});

  @override
  State<SupabaseTestPage> createState() => _SupabaseTestPageState();
}

class _SupabaseTestPageState extends State<SupabaseTestPage> {
  String status = 'Connecting to Supabase...';

  @override
  void initState() {
    super.initState();
    testSupabase();
  }

  Future<void> testSupabase() async {
    try {
      final data = await Supabase.instance.client
          .from('pricecatcher_full')
          .select()
          .limit(20);

      debugPrint(data.toString());

      if (!mounted) return;

      setState(() {
        status = 'Connected! ${data.length} records received.';
      });
    } catch (error) {
      debugPrint('Supabase error: $error');

      if (!mounted) return;

      setState(() {
        status = 'Error: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartJimat'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}