/// auth_service.dart - Firebase authentication service
///
/// Supports anonymous auth, email/password, and account linking
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

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
      final userCredential = await _auth.signInAnonymously();
      _user = userCredential.user;
      Logger.debug('Sign in response: ${_user?.uid}');

      // Create user document if it doesn't exist
      if (_user != null) {
        await _createUserDocument(_user!.uid);
      }

      Logger.success("Anonymous sign in successful: ${_user?.uid}");
    } on FirebaseAuthException catch (e) {
      _lastError = "Auth Error: ${e.code}";
      Logger.error("Firebase Auth Exception: ${e.code}", e);
      Logger.error("Error message: ${e.message}");
      notifyListeners();
    } catch (e) {
      _lastError = "Error: $e";
      Logger.error("Error signing in", e);
      notifyListeners();
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
  Future<bool> deleteUserAccount() async {
    try {
      if (_user == null) {
        _lastError = "No user to delete";
        return false;
      }

      final userId = _user!.uid;

      // Delete user document (triggers Cloud Function to delete subcollections)
      await _firestore.collection('users').doc(userId).delete();

      // Delete Firebase Auth user
      await _user!.delete();

      Logger.success("User account deleted: $userId");

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
