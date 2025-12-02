/// validation_tracker_service.dart - Device-local tracking of user validations
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
/// Tracks which price pulses a user has validated/flagged using SharedPreferences
/// Maintains strict anonymity - no server-side tracking
library;

import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ValidationTrackerService {
  static const String _validatedKey = 'validated_pulses';
  static const String _flaggedKey = 'flagged_pulses';
  static const String _lastValidationTimeKey = 'last_validation_time';

  /// Check if user has validated a pulse
  Future<bool> hasValidated(String pulseId) async {
    final prefs = await SharedPreferences.getInstance();
    final validatedList = prefs.getStringList(_validatedKey) ?? [];
    return validatedList.contains(pulseId);
  }

  /// Check if user has flagged a pulse
  Future<bool> hasFlagged(String pulseId) async {
    final prefs = await SharedPreferences.getInstance();
    final flaggedList = prefs.getStringList(_flaggedKey) ?? [];
    return flaggedList.contains(pulseId);
  }

  /// Mark a pulse as validated
  Future<void> markValidated(String pulseId) async {
    final prefs = await SharedPreferences.getInstance();
    final validatedList = prefs.getStringList(_validatedKey) ?? [];

    if (!validatedList.contains(pulseId)) {
      validatedList.add(pulseId);
      await prefs.setStringList(_validatedKey, validatedList);
      await _recordValidationTime();
    }

    // Remove from flagged if it was previously flagged
    final flaggedList = prefs.getStringList(_flaggedKey) ?? [];
    if (flaggedList.contains(pulseId)) {
      flaggedList.remove(pulseId);
      await prefs.setStringList(_flaggedKey, flaggedList);
    }
  }

  /// Mark a pulse as flagged
  Future<void> markFlagged(String pulseId) async {
    final prefs = await SharedPreferences.getInstance();
    final flaggedList = prefs.getStringList(_flaggedKey) ?? [];

    if (!flaggedList.contains(pulseId)) {
      flaggedList.add(pulseId);
      await prefs.setStringList(_flaggedKey, flaggedList);
      await _recordValidationTime();
    }

    // Remove from validated if it was previously validated
    final validatedList = prefs.getStringList(_validatedKey) ?? [];
    if (validatedList.contains(pulseId)) {
      validatedList.remove(pulseId);
      await prefs.setStringList(_validatedKey, validatedList);
    }
  }

  /// Remove validation/flag (allow user to change their mind)
  Future<void> removeValidation(String pulseId) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove from validated
    final validatedList = prefs.getStringList(_validatedKey) ?? [];
    if (validatedList.contains(pulseId)) {
      validatedList.remove(pulseId);
      await prefs.setStringList(_validatedKey, validatedList);
    }

    // Remove from flagged
    final flaggedList = prefs.getStringList(_flaggedKey) ?? [];
    if (flaggedList.contains(pulseId)) {
      flaggedList.remove(pulseId);
      await prefs.setStringList(_flaggedKey, flaggedList);
    }
  }

  /// Get total validation count (for analytics/gamification)
  Future<int> getTotalValidationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final validatedList = prefs.getStringList(_validatedKey) ?? [];
    return validatedList.length;
  }

  /// Get total flag count (for analytics/abuse detection)
  Future<int> getTotalFlagCount() async {
    final prefs = await SharedPreferences.getInstance();
    final flaggedList = prefs.getStringList(_flaggedKey) ?? [];
    return flaggedList.length;
  }

  /// Check rate limiting (prevent spam)
  /// Returns true if user can validate/flag, false if rate limited
  Future<bool> canValidate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTime = prefs.getInt(_lastValidationTimeKey);

    if (lastTime == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch;
    final timeDiff = now - lastTime;

    return timeDiff >= validationMinIntervalMs;
  }

  /// Record validation time (for rate limiting)
  Future<void> _recordValidationTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastValidationTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Clear all validation history (for testing/debugging)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_validatedKey);
    await prefs.remove(_flaggedKey);
    await prefs.remove(_lastValidationTimeKey);
  }

  /// Get validation status for a pulse
  /// Returns: 'validated', 'flagged', or 'none'
  Future<String> getValidationStatus(String pulseId) async {
    if (await hasValidated(pulseId)) return 'validated';
    if (await hasFlagged(pulseId)) return 'flagged';
    return 'none';
  }
}
