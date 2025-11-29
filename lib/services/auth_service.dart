import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  User? _user;
  User? get user => _user;

  AuthService() {
    // Initialize user from current session
    try {
      _user = Supabase.instance.client.auth.currentUser;
    } catch (e) {
      // Supabase might not be initialized yet
    }

    // Listen for auth changes
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        _user = data.session?.user;
        notifyListeners();
      });
    } catch (e) {
      // Supabase might not be initialized yet
    }
  }

  Future<void> signInAnonymously() async {
    try {
      print('🔐 DEBUG: Attempting anonymous sign in...');
      final response = await Supabase.instance.client.auth.signInAnonymously();
      print('🔐 DEBUG: Sign in response: ${response.user?.id}');

      if (kDebugMode) {
        print("✅ Sign in successful: ${response.user?.id}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error signing in: $e");
        print("❌ Error details: ${e.toString()}");
      }
    }
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }
}
