import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/app_data_service.dart';
import 'core/theme/app_theme.dart';
import 'feature/splash/presentation/screens/splash_screen.dart';

void main() async {
  // Flutter engine ready karna lazmi hai async initialization se pehle
  WidgetsFlutterBinding.ensureInitialized();

  // .env file load karein (gracefully handle if asset is not yet ready or empty)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Notice: .env asset load fallback ($e).');
  }

  // Supabase client initialize karein agar credentials mojood hon
  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  final supabaseKey = (dotenv.env['SUPABASE_ANON_KEY'] ??
          dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
          '')
      .trim();

  if (supabaseUrl.isNotEmpty &&
      supabaseKey.isNotEmpty &&
      supabaseUrl.startsWith('http') &&
      !supabaseUrl.contains('your-project-id')) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseKey,
      );
      debugPrint('Supabase initialized successfully.');
    } catch (e) {
      debugPrint('Notice: Supabase initialization error: $e');
    }
  } else {
    debugPrint(
      'Notice: Supabase credentials not configured in .env. Running with local storage fallback.',
    );
  }

  // Persistent storage service initialize karein
  await AppDataService.instance.init();

  runApp(const MyApp());
}

// Global client reference taake direct queries call ho sakein
SupabaseClient get supabase => Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAMPUSCONNECT — Student-Corporate Bridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
