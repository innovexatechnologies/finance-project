import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('Error: .env file does not exist');
    return;
  }
  final lines = envFile.readAsLinesSync();
  String url = '';
  String anonKey = '';
  for (var line in lines) {
    if (line.startsWith('SUPABASE_URL=')) {
      url = line.substring('SUPABASE_URL='.length).trim();
    } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
      anonKey = line.substring('SUPABASE_ANON_KEY='.length).trim();
    }
  }
  print('Loaded URL: $url');
  print('Loaded Key: ${anonKey.substring(0, 10)}...');

  try {
    await Supabase.initialize(url: url, anonKey: anonKey);
    print('Supabase.initialize SUCCESS!');
    
    final client = Supabase.instance.client;
    print('Testing query to Supabase...');
    // Let's test a simple RPC, select or auth ping
    try {
      final data = await client.from('users').select().limit(1);
      print('Query succeeded: $data');
    } catch (queryErr) {
      print('Query result / error: $queryErr');
    }
  } catch (e, stack) {
    print('Supabase initialize error: $e\n$stack');
  }
  exit(0);
}
