/// main.dart - Application entry point and provider setup
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Crashlytics temporarily disabled due to version conflicts
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'config/theme.dart';
import 'config/firebase_config.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'services/portfolio_service.dart';
import 'services/price_pulse_service.dart';
import 'services/user_preferences_service.dart';
import 'services/analytics_service.dart';
import 'services/validation_tracker_service.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    print('🚀 Initializing Firebase...');
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: FirebaseConfig.apiKey,
        authDomain: FirebaseConfig.authDomain,
        projectId: FirebaseConfig.projectId,
        storageBucket: FirebaseConfig.storageBucket,
        messagingSenderId: FirebaseConfig.messagingSenderId,
        appId: FirebaseConfig.appId,
      ),
    );
    print('✅ Firebase initialized successfully!');

    // Initialize Crashlytics (catches Flutter errors)
    // Temporarily disabled due to version conflicts with Firebase Core 4.x
    // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Attempt sign-in immediately
    print('🔐 Attempting anonymous sign-in...');
    try {
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.signInAnonymously();
      print(
        '✅ Anonymous sign-in successful! User ID: ${userCredential.user?.uid}',
      );
    } on FirebaseAuthException catch (e) {
      print('❌ Anonymous sign-in FAILED with code: ${e.code}');
      print('❌ Message: ${e.message}');
      print(
        '⚠️ Make sure "Anonymous" is enabled in Firebase Console -> Authentication -> Sign-in method',
      );
    } catch (e) {
      print('❌ Anonymous sign-in FAILED: $e');
      print(
        '⚠️ Make sure "Anonymous" is enabled in Firebase Console -> Authentication -> Sign-in method',
      );
    }
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
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
        ChangeNotifierProvider(create: (_) => UserPreferencesService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => AnalyticsService()),
        Provider(create: (_) => ValidationTrackerService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'AgriPulse',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const MainScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
