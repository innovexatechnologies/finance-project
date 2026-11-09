import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'feature/splash/presentation/screens/splash_screen.dart';

void main() async {
  // Flutter engine ready karna lazmi hai async initialization se pehle
  WidgetsFlutterBinding.ensureInitialized();

  // .env file load karein
  await dotenv.load(fileName: ".env");

  // Supabase client initialize karein
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ??
        dotenv.env['SUPABASE_PUBLISHABLE_KEY'],
  );

  runApp(const MyApp());
}

// Global client reference taake direct queries call ho sakein
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusConnect - Student Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
