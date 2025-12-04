/// auth_service.dart - Firebase authentication service
///
/// Supports anonymous auth, email/password, and account linking
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? false;
  String? _lastError;
  String? get lastError => _lastError;

  AuthService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  /// Sign in anonymously (default for new users)
  Future<void> signInAnonymously() async {
    try {
      _lastError = null;
      Logger.debug('Attempting anonymous sign in...');

      final userCredential = await RetryHelper.retryFirebaseOperation(
        operation: () => _auth.signInAnonymously(),
        operationName: 'Anonymous sign-in',
      );

      _user = userCredential.user;
      Logger.debug('Sign in response: ${_user?.uid}');

      // Create user document if it doesn't exist
      if (_user != null) {
        await _createUserDocument(_user!.uid);
      }

      Logger.success("Anonymous sign in successful: ${_user?.uid}");
    } catch (e) {
      _lastError = ErrorHandler.getAuthErrorMessage(e);
      Logger.error("Error signing in", e);
      notifyListeners();
      rethrow; // Re-throw so callers can handle it
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      _lastError = null;
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;

      Logger.success("Email sign in successful: ${_user?.uid}");

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _lastError = "Auth Error: ${e.code}";
      Logger.error("Firebase Auth Exception: ${e.code}", e);
      notifyListeners();
      return null;
    }
  }

  /// Register with email and password
  Future<UserCredential?> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      _lastError = null;
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;

      // Create user document
      if (_user != null) {
        await _createUserDocument(_user!.uid);
      }

      Logger.success("Email registration successful: ${_user?.uid}");

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _lastError = "Auth Error: ${e.code}";
      Logger.error("Firebase Auth Exception: ${e.code}", e);
      notifyListeners();
      return null;
    }
  }

  /// Link anonymous account to email/password credentials
  /// This preserves all user data (portfolios, preferences) when upgrading
  Future<bool> linkAnonymousToEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (_user == null || !_user!.isAnonymous) {
        _lastError = "No anonymous user to link";
        return false;
      }

      _lastError = null;
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await _user!.linkWithCredential(credential);

      // Update user document to mark as non-anonymous
      await _firestore.collection('users').doc(_user!.uid).update({
        'is_anonymous': false,
        'email': email,
        'linked_at': FieldValue.serverTimestamp(),
      });

      Logger.success("Anonymous account linked to email: ${_user?.uid}");

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _lastError = "Link Error: ${e.code} - ${e.message}";
      Logger.error("Error linking account: ${e.code}", e);
      notifyListeners();
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _lastError = null;
      await _auth.sendPasswordResetEmail(email: email);

      Logger.success("Password reset email sent to: $email");

      return true;
    } on FirebaseAuthException catch (e) {
      _lastError = "Password Reset Error: ${e.code}";
      Logger.error("Error sending password reset: ${e.code}", e);
      notifyListeners();
      return false;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Logger.success("User signed out");
    } catch (e) {
      Logger.error("Error signing out", e);
    }
  }

  /// Delete user account and all associated data
  /// GDPR compliance - user can request data deletion
  /// This permanently deletes:
  /// - All portfolios (cattle groups)
  /// - All preferences
  /// - User document
  /// - Firebase Auth account
  Future<bool> deleteUserAccount() async {
    try {
      if (_user == null) {
        _lastError = "No user to delete";
        return false;
      }

      final userId = _user!.uid;

      Logger.debug("Starting account deletion for user: $userId");

      // Step 1: Delete all portfolios subcollection
      Logger.debug("Deleting portfolios...");
      final portfoliosSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('portfolios')
          .get();

      for (var doc in portfoliosSnapshot.docs) {
        await doc.reference.delete();
        Logger.debug("Deleted portfolio: ${doc.id}");
      }
      Logger.success("Deleted ${portfoliosSnapshot.docs.length} portfolios");

      // Step 2: Delete all preferences subcollection
      Logger.debug("Deleting preferences...");
      final preferencesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .get();

      for (var doc in preferencesSnapshot.docs) {
        await doc.reference.delete();
        Logger.debug("Deleted preference: ${doc.id}");
      }
      Logger.success("Deleted ${preferencesSnapshot.docs.length} preferences");

      // Step 3: Delete user document
      Logger.debug("Deleting user document...");
      await _firestore.collection('users').doc(userId).delete();
      Logger.success("User document deleted");

      // Step 4: Delete Firebase Auth user
      Logger.debug("Deleting Firebase Auth user...");
      await _user!.delete();
      Logger.success("Firebase Auth user deleted");

      Logger.success("User account fully deleted: $userId");

      return true;
    } on FirebaseAuthException catch (e) {
      _lastError = "Delete Error: ${e.code}";
      Logger.error("Error deleting account: ${e.code}", e);
      notifyListeners();
      return false;
    } catch (e) {
      _lastError = "Delete Error: $e";
      Logger.error("Error deleting account", e);
      notifyListeners();
      return false;
    }
  }

  /// Export all user data (GDPR Article 20 - Right to Data Portability)
  /// Returns a Map containing all user data in JSON-serializable format
  Future<Map<String, dynamic>> exportUserData() async {
    try {
      if (_user == null) {
        throw Exception('No user to export data for');
      }

      final userId = _user!.uid;

      Logger.debug("Starting data export for user: $userId");

      // Export user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.exists ? userDoc.data() : {};

      // Export all portfolios
      final portfoliosSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('portfolios')
          .get();

      final portfolios = portfoliosSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      // Export all preferences
      final preferencesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .get();

      final preferences = preferencesSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      final exportData = {
        'user_id': userId,
        'email': _user!.email,
        'is_anonymous': _user!.isAnonymous,
        'created_at': _user!.metadata.creationTime?.toIso8601String(),
        'last_sign_in': _user!.metadata.lastSignInTime?.toIso8601String(),
        'export_date': DateTime.now().toIso8601String(),
        'user_data': userData,
        'portfolios': portfolios,
        'preferences': preferences,
        'total_portfolios': portfolios.length,
        'total_preferences': preferences.length,
      };

      Logger.success("Data export completed: ${portfolios.length} portfolios, ${preferences.length} preferences");

      return exportData;
    } catch (e) {
      Logger.error("Error exporting user data", e);
      rethrow;
    }
  }

  /// Create user document in Firestore
  /// Called on first sign in or registration
  Future<void> _createUserDocument(String userId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'created_at': FieldValue.serverTimestamp(),
          'subscription_status': 'free',
          'is_anonymous': _user?.isAnonymous ?? false,
          'settings': {
            'dark_mode': false,
            'notifications': true,
            'default_county': 'Cork',
          },
        });

        Logger.success("User document created: $userId");
      }
    } catch (e) {
      Logger.error("Error creating user document", e);
    }
  }
}
