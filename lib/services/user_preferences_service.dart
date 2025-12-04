/// user_preferences_service.dart - User preferences persistence service
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_preferences.dart';
import '../utils/logger.dart';

class UserPreferencesService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserPreferences _preferences = UserPreferences.defaults();
  UserPreferences get preferences => _preferences;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Get the Firestore path for user settings
  /// Path: users/{userId}/settings
  String _getUserSettingsPath() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    return 'users/$userId/settings';
  }

  /// Load user preferences (one-time fetch)
  Future<void> loadPreferences() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Logger.warning('User not signed in, using defaults');
      _preferences = UserPreferences.defaults();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection(_getUserSettingsPath())
          .doc('preferences')
          .get();

      if (doc.exists) {
        _preferences = UserPreferences.fromMap(doc.data()!);
        Logger.success('Loaded user preferences');
      } else {
        // First time user - create default preferences
        _preferences = UserPreferences.defaults();
        await savePreferences(_preferences);
        Logger.success('Created default preferences');
      }
    } catch (e) {
      Logger.error('Error loading preferences', e);
      _preferences = UserPreferences.defaults();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get preferences as a real-time stream
  Stream<UserPreferences> getPreferencesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Logger.warning('User not signed in, returning defaults stream');
      return Stream.value(UserPreferences.defaults());
    }

    return _firestore
        .collection(_getUserSettingsPath())
        .doc('preferences')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return UserPreferences.fromMap(snapshot.data()!);
          } else {
            return UserPreferences.defaults();
          }
        });
  }

  /// Save preferences to Firestore
  Future<void> savePreferences(UserPreferences prefs) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Logger.error('Not authenticated, cannot save preferences', null);
      return;
    }

    try {
      await _firestore
          .collection(_getUserSettingsPath())
          .doc('preferences')
          .set(prefs.toMap());

      _preferences = prefs;
      notifyListeners();
      Logger.success('Preferences saved');
    } catch (e) {
      Logger.error('Error saving preferences', e);
    }
  }

  /// Update individual preference fields
  Future<void> updateCounty(String county) async {
    final updated = _preferences.copyWith(county: county);
    await savePreferences(updated);
  }

  Future<void> updateDarkMode(bool darkMode) async {
    final updated = _preferences.copyWith(darkMode: darkMode);
    await savePreferences(updated);
  }

  Future<void> updateRainAlerts(bool enabled) async {
    final updated = _preferences.copyWith(rainAlerts: enabled);
    await savePreferences(updated);
  }

  Future<void> updateHolidayAlerts(bool enabled) async {
    final updated = _preferences.copyWith(holidayAlerts: enabled);
    await savePreferences(updated);
  }

  Future<void> updateTargetDateAlerts(bool enabled) async {
    final updated = _preferences.copyWith(targetDateAlerts: enabled);
    await savePreferences(updated);
  }

  Future<void> updateIsGaeilge(bool enabled) async {
    final updated = _preferences.copyWith(isGaeilge: enabled);
    await savePreferences(updated);
  }
}
