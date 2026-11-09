import 'package:flutter/material.dart';
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