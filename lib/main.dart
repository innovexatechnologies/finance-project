import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/app_data_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/supabase_helper.dart';
import 'core/theme/app_theme.dart';
import 'feature/company/services/company_profile_service.dart';
import 'feature/splash/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load .env asset bundled with the application
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Notice: .env asset load fallback ($e).');
  }

  // 2. Production fallback credentials if .env was not bundled or read
  const defaultUrl = 'https://nosnzigmrxrdotiikjab.supabase.co';
  const defaultAnonKey = 'sb_publishable_yX1bnVB7y-n-fZhelfJhjw_otuDqRlJ';

  final envUrl = (dotenv.env['SUPABASE_URL'] ??
          const String.fromEnvironment('SUPABASE_URL', defaultValue: ''))
      .trim()
      .replaceAll(RegExp(r'/+$'), '');
  final envKey = (dotenv.env['SUPABASE_ANON_KEY'] ??
          dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
          const String.fromEnvironment('SUPABASE_ANON_KEY',
              defaultValue: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY',
                  defaultValue: '')))
      .trim();

  final supabaseUrl = envUrl.isNotEmpty ? envUrl : defaultUrl;
  final supabaseKey = envKey.isNotEmpty ? envKey : defaultAnonKey;

  if (supabaseUrl.isNotEmpty &&
      supabaseKey.isNotEmpty &&
      supabaseUrl.startsWith('http') &&
      !supabaseUrl.contains('your-project-id')) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
      debugPrint('Supabase initialized successfully: $supabaseUrl');
    } catch (e) {
      debugPrint('Notice: Supabase initialization error: $e');
    }
  } else {
    debugPrint(
      'Notice: Supabase credentials not configured. Running with local storage fallback.',
    );
  }

  await AppDataService.instance.init();
  if (AppDataService.instance.isLoggedIn &&
      AppDataService.instance.userRole.toLowerCase() == 'company') {
    CompanyProfileService.hydrateFromLocalCache();
  }

  await DeepLinkService.instance.init(navigatorKey: MyApp.navigatorKey);

  runApp(const MyApp());
}

SupabaseClient? get supabaseOrNull => SupabaseHelper.clientOrNull;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    DeepLinkService.instance.attachNavigatorKey(navigatorKey);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SkillBridge — Student-Corporate Bridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
