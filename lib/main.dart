import 'package:flutter/material.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/auth/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Agar aapne baad mein Supabase integrate karna ho toh yahan initialization aayegi:
  // await Supabase.initialize(url: 'YOUR_URL', anonKey: 'YOUR_KEY');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAMPUSCONNECT — Student-Corporate Bridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accentTeal,
          surface: AppColors.cardSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.darkNavy,
          elevation: 0.5,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.darkNavy,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // App start hote hi Login screen show hogi
      home: const LoginScreen(),
    );
  }
}
