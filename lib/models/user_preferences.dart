/// user_preferences.dart - User settings and preferences data model
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class UserPreferences {
  final String county;
  final bool darkMode;
  final bool rainAlerts;
  final bool holidayAlerts;
  final bool targetDateAlerts;
  final bool isGaeilge;
  final DateTime updatedAt;

  UserPreferences({
    required this.county,
    required this.darkMode,
    required this.rainAlerts,
    required this.holidayAlerts,
    required this.targetDateAlerts,
    required this.isGaeilge,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Default preferences for new users
  factory UserPreferences.defaults() {
    return UserPreferences(
      county: 'Cork',
      darkMode: false,
      rainAlerts: true,
      holidayAlerts: true,
      targetDateAlerts: true,
      isGaeilge: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'county': county,
      'dark_mode': darkMode,
      'rain_alerts': rainAlerts,
      'holiday_alerts': holidayAlerts,
      'target_date_alerts': targetDateAlerts,
      'is_gaeilge': isGaeilge,
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        return DateTime.now();
      }
    }

    return UserPreferences(
      county: map['county'] ?? 'Cork',
      darkMode: map['dark_mode'] ?? false,
      rainAlerts: map['rain_alerts'] ?? true,
      holidayAlerts: map['holiday_alerts'] ?? true,
      targetDateAlerts: map['target_date_alerts'] ?? true,
      isGaeilge: map['is_gaeilge'] ?? false,
      updatedAt: parseDate(map['updated_at']),
    );
  }

  UserPreferences copyWith({
    String? county,
    bool? darkMode,
    bool? rainAlerts,
    bool? holidayAlerts,
    bool? targetDateAlerts,
    bool? isGaeilge,
  }) {
    return UserPreferences(
      county: county ?? this.county,
      darkMode: darkMode ?? this.darkMode,
      rainAlerts: rainAlerts ?? this.rainAlerts,
      holidayAlerts: holidayAlerts ?? this.holidayAlerts,
      targetDateAlerts: targetDateAlerts ?? this.targetDateAlerts,
      isGaeilge: isGaeilge ?? this.isGaeilge,
      updatedAt: DateTime.now(),
    );
  }
}
