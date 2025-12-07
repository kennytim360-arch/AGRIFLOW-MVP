/// price_log_service.dart - Service for managing personal price logs
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/price_log.dart';
import '../models/cattle_group.dart';
import '../utils/logger.dart';

/// Service for managing personal price tracking
///
/// This service allows farmers to:
/// - Log prices they were offered or received
/// - Compare their prices against market data
/// - Track sales over time
/// - Get weekly reminders to log prices
class PriceLogService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache
  List<PriceLog> _cachedLogs = [];
  DateTime? _lastCacheTime;
  static const _cacheValidityDuration = Duration(minutes: 5);

  // SharedPreferences keys
  static const _keyWeeklyReminderEnabled = 'weekly_reminder_enabled';
  static const _keyReminderDay = 'reminder_day'; // 1 = Monday, 7 = Sunday
  static const _keyReminderHour = 'reminder_hour';
  static const _keyReminderMinute = 'reminder_minute';
  static const _keyLastReminderDate = 'last_reminder_date';

  /// Gets the Firestore collection path for current user's price logs
  String _getUserPath() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return 'users/$userId/price_logs';
  }

  /// Adds a new price log entry
  Future<String> addLog(PriceLog log) async {
    try {
      Logger.info('Adding price log: ${log.type.displayName} - ${log.breed.displayName}');

      final docRef = await _firestore.collection(_getUserPath()).add(log.toMap());

      Logger.success('Price log added with ID: ${docRef.id}');
      _clearCache();

      return docRef.id;
    } catch (e, stackTrace) {
      Logger.error('Failed to add price log', e, stackTrace);
      rethrow;
    }
  }

  /// Updates an existing price log
  Future<void> updateLog(PriceLog log) async {
    try {
      if (log.id == null) {
        throw Exception('Cannot update log without ID');
      }

      Logger.info('Updating price log: ${log.id}');

      await _firestore.collection(_getUserPath()).doc(log.id).update(log.toMap());

      Logger.success('Price log updated');
      _clearCache();
    } catch (e, stackTrace) {
      Logger.error('Failed to update price log', e, stackTrace);
      rethrow;
    }
  }

  /// Deletes a price log
  Future<void> deleteLog(String logId) async {
    try {
      Logger.info('Deleting price log: $logId');

      await _firestore.collection(_getUserPath()).doc(logId).delete();

      Logger.success('Price log deleted');
      _clearCache();
    } catch (e, stackTrace) {
      Logger.error('Failed to delete price log', e, stackTrace);
      rethrow;
    }
  }

  /// Loads all price logs for the current user
  Future<List<PriceLog>> loadLogs() async {
    try {
      // Return cached data if valid
      if (_cachedLogs.isNotEmpty &&
          _lastCacheTime != null &&
          DateTime.now().difference(_lastCacheTime!) < _cacheValidityDuration) {
        Logger.debug('Returning cached price logs');
        return _cachedLogs;
      }

      Logger.info('Loading price logs from Firestore');

      final snapshot = await _firestore
          .collection(_getUserPath())
          .orderBy('date', descending: true)
          .get();

      final logs = snapshot.docs
          .map((doc) => PriceLog.fromMap(doc.data(), doc.id))
          .toList();

      // Cache results
      _cachedLogs = logs;
      _lastCacheTime = DateTime.now();

      Logger.success('Loaded ${logs.length} price logs');
      return logs;
    } catch (e, stackTrace) {
      Logger.error('Failed to load price logs', e, stackTrace);
      return [];
    }
  }

  /// Loads logs for a specific breed and weight bucket
  Future<List<PriceLog>> loadLogsFiltered({
    Breed? breed,
    WeightBucket? weightBucket,
    String? county,
    PriceLogType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Logger.info('Loading filtered price logs');

      Query query = _firestore.collection(_getUserPath());

      // Apply filters
      if (breed != null) {
        query = query.where('breed', isEqualTo: breed.name);
      }
      if (weightBucket != null) {
        query = query.where('weight_bucket', isEqualTo: weightBucket.name);
      }
      if (county != null) {
        query = query.where('county', isEqualTo: county);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('date', descending: true);

      final snapshot = await query.get();
      final logs = snapshot.docs
          .map((doc) => PriceLog.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      Logger.success('Loaded ${logs.length} filtered price logs');
      return logs;
    } catch (e, stackTrace) {
      Logger.error('Failed to load filtered price logs', e, stackTrace);
      return [];
    }
  }

  /// Gets statistics for all price logs
  Future<PriceLogStats> getStats() async {
    try {
      final logs = await loadLogs();
      return PriceLogStats.fromLogs(logs);
    } catch (e, stackTrace) {
      Logger.error('Failed to calculate price log stats', e, stackTrace);
      return PriceLogStats.empty();
    }
  }

  /// Gets logs from the current week
  Future<List<PriceLog>> getThisWeekLogs() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartMidnight = DateTime(weekStart.year, weekStart.month, weekStart.day);

      return await loadLogsFiltered(startDate: weekStartMidnight);
    } catch (e, stackTrace) {
      Logger.error('Failed to load this week logs', e, stackTrace);
      return [];
    }
  }

  /// Clears the cache
  void _clearCache() {
    _cachedLogs = [];
    _lastCacheTime = null;
    notifyListeners();
  }

  // ============================================================================
  // WEEKLY REMINDER SETTINGS
  // ============================================================================

  /// Gets weekly reminder settings
  Future<WeeklyReminderSettings> getReminderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return WeeklyReminderSettings(
        enabled: prefs.getBool(_keyWeeklyReminderEnabled) ?? true,
        dayOfWeek: prefs.getInt(_keyReminderDay) ?? 5, // Default: Friday
        hour: prefs.getInt(_keyReminderHour) ?? 18, // Default: 6 PM
        minute: prefs.getInt(_keyReminderMinute) ?? 0,
        lastReminderDate: prefs.getString(_keyLastReminderDate) != null
            ? DateTime.parse(prefs.getString(_keyLastReminderDate)!)
            : null,
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to get reminder settings', e, stackTrace);
      return WeeklyReminderSettings.defaults();
    }
  }

  /// Saves weekly reminder settings
  Future<void> saveReminderSettings(WeeklyReminderSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_keyWeeklyReminderEnabled, settings.enabled);
      await prefs.setInt(_keyReminderDay, settings.dayOfWeek);
      await prefs.setInt(_keyReminderHour, settings.hour);
      await prefs.setInt(_keyReminderMinute, settings.minute);

      if (settings.lastReminderDate != null) {
        await prefs.setString(
          _keyLastReminderDate,
          settings.lastReminderDate!.toIso8601String(),
        );
      }

      Logger.success('Reminder settings saved');
      notifyListeners();

      // Schedule the next reminder
      if (settings.enabled) {
        await _scheduleNextReminder(settings);
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to save reminder settings', e, stackTrace);
    }
  }

  /// Schedules the next reminder (to be implemented with local notifications)
  Future<void> _scheduleNextReminder(WeeklyReminderSettings settings) async {
    try {
      Logger.info(
        'Scheduling reminder for ${_getDayName(settings.dayOfWeek)} at ${settings.hour}:${settings.minute.toString().padLeft(2, '0')}',
      );

      // TODO: Implement with flutter_local_notifications
      // This will be implemented when the package is added
      // For now, just log the intent

      Logger.success('Reminder scheduled');
    } catch (e, stackTrace) {
      Logger.error('Failed to schedule reminder', e, stackTrace);
    }
  }

  /// Helper to get day name
  String _getDayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[day - 1];
  }

  /// Checks if user should see a reminder (called on app startup)
  Future<bool> shouldShowReminder() async {
    try {
      final settings = await getReminderSettings();
      if (!settings.enabled) return false;

      final now = DateTime.now();

      // Check if it's the right day of week
      if (now.weekday != settings.dayOfWeek) return false;

      // Check if we already showed reminder today
      if (settings.lastReminderDate != null) {
        final lastReminder = settings.lastReminderDate!;
        final today = DateTime(now.year, now.month, now.day);
        final lastReminderDay = DateTime(
          lastReminder.year,
          lastReminder.month,
          lastReminder.day,
        );

        if (today == lastReminderDay) {
          return false; // Already showed today
        }
      }

      // Check if it's past the reminder time
      final reminderTime = DateTime(
        now.year,
        now.month,
        now.day,
        settings.hour,
        settings.minute,
      );

      if (now.isAfter(reminderTime)) {
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      Logger.error('Failed to check reminder status', e, stackTrace);
      return false;
    }
  }

  /// Marks reminder as shown for today
  Future<void> markReminderShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastReminderDate, DateTime.now().toIso8601String());
      Logger.info('Reminder marked as shown');
    } catch (e, stackTrace) {
      Logger.error('Failed to mark reminder as shown', e, stackTrace);
    }
  }
}

/// Weekly reminder settings
class WeeklyReminderSettings {
  final bool enabled;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final int hour; // 0-23
  final int minute; // 0-59
  final DateTime? lastReminderDate;

  const WeeklyReminderSettings({
    required this.enabled,
    required this.dayOfWeek,
    required this.hour,
    required this.minute,
    this.lastReminderDate,
  });

  factory WeeklyReminderSettings.defaults() {
    return const WeeklyReminderSettings(
      enabled: true,
      dayOfWeek: 5, // Friday
      hour: 18, // 6 PM
      minute: 0,
    );
  }

  WeeklyReminderSettings copyWith({
    bool? enabled,
    int? dayOfWeek,
    int? hour,
    int? minute,
    DateTime? lastReminderDate,
  }) {
    return WeeklyReminderSettings(
      enabled: enabled ?? this.enabled,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      lastReminderDate: lastReminderDate ?? this.lastReminderDate,
    );
  }

  String get dayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dayOfWeek - 1];
  }

  String get timeString {
    final hourStr = hour.toString().padLeft(2, '0');
    final minStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minStr';
  }
}
