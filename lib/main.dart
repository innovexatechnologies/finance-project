import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/app_data_service.dart';
import 'core/services/supabase_helper.dart';
import 'core/theme/app_theme.dart';
import 'feature/splash/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ??
        dotenv.env['SUPABASE_PUBLISHABLE_KEY'],
  );

  await AppDataService.instance.init();
  if (SupabaseHelper.currentUser != null) {
    await AppDataService.instance.syncFromSupabase();
  }

  runApp(const MyApp());
}

SupabaseClient? get supabaseOrNull => SupabaseHelper.clientOrNull;

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
