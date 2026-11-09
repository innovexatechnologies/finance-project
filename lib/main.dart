import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/feature/auth/presentation/widgets/screens/login_screen.dart';

void main() async {
  // Flutter engine ready karna lazmi hai async initialization se pehle
  WidgetsFlutterBinding.ensureInitialized();

  // .env file load karein
  await dotenv.load(fileName: ".env");

  // Supabase client initialize karein
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

// Global client reference taake login_screen ya kisi bhi repo se direct queries call ho sakein
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinkVibe - Professional Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      // App start hote hi Login screen show hogi
      home: const LoginScreen(),
    );
  }
}
