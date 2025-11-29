import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'config/supabase_config.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'services/portfolio_service.dart';
import 'services/price_pulse_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    print('🚀 Initializing Supabase...');
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    print('✅ Supabase initialized successfully!');
    print('🔐 Attempting anonymous sign-in...');

    // Sign in immediately
    try {
      final response = await Supabase.instance.client.auth.signInAnonymously();
      print('✅ Anonymous sign-in successful! User ID: ${response.user?.id}');
    } catch (authError) {
      print('❌ Anonymous sign-in FAILED: $authError');
      print('⚠️  Make sure Anonymous Auth is enabled in Supabase Dashboard!');
      print(
        '⚠️  Go to: Authentication → Providers → Anonymous Sign-ins → Toggle ON',
      );
    }
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthService()..signInAnonymously(),
        ),
        Provider(create: (_) => PortfolioService()),
        Provider(create: (_) => PricePulseService()),
      ],
      child: MaterialApp(
        title: 'AgriPulse',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
