/// analytics_service.dart - Firebase Analytics tracking service
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Get observer for navigation tracking
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Log custom event: Price Pulse submitted
  Future<void> logPricePulseSubmitted({
    required String breed,
    required String weightBucket,
    required double price,
    required String county,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'price_pulse_submitted',
        parameters: {
          'breed': breed,
          'weight_bucket': weightBucket,
          'price': price,
          'county': county,
        },
      );

      if (kDebugMode) {
        print('📊 Analytics: Price pulse submitted ($breed, $weightBucket)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log custom event: Portfolio group added
  Future<void> logPortfolioGroupAdded({
    required String breed,
    required int quantity,
    required String weightBucket,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'portfolio_group_added',
        parameters: {
          'breed': breed,
          'quantity': quantity,
          'weight_bucket': weightBucket,
        },
      );

      if (kDebugMode) {
        print('📊 Analytics: Portfolio group added');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log custom event: Portfolio group deleted
  Future<void> logPortfolioGroupDeleted() async {
    try {
      await _analytics.logEvent(name: 'portfolio_group_deleted');

      if (kDebugMode) {
        print('📊 Analytics: Portfolio group deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log custom event: Portfolio updated
  Future<void> logPortfolioUpdated({required int groupCount}) async {
    try {
      await _analytics.logEvent(
        name: 'portfolio_updated',
        parameters: {'group_count': groupCount},
      );

      if (kDebugMode) {
        print('📊 Analytics: Portfolio updated ($groupCount groups)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log custom event: Calculator used
  Future<void> logCalculatorUsed({
    required String calculationType,
    required String breed,
    required double currentWeight,
    required double targetWeight,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'calculator_used',
        parameters: {
          'type': calculationType,
          'breed': breed,
          'current_weight': currentWeight,
          'target_weight': targetWeight,
        },
      );

      if (kDebugMode) {
        print('📊 Analytics: Calculator used ($calculationType)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log custom event: PDF exported
  Future<void> logPdfExported({required int groupCount}) async {
    try {
      await _analytics.logEvent(
        name: 'pdf_exported',
        parameters: {'group_count': groupCount},
      );

      if (kDebugMode) {
        print('📊 Analytics: PDF exported');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log custom event: Data exported
  Future<void> logDataExported() async {
    try {
      await _analytics.logEvent(name: 'data_exported');

      if (kDebugMode) {
        print('📊 Analytics: Data exported');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log custom event: Data deleted
  Future<void> logDataDeleted() async {
    try {
      await _analytics.logEvent(name: 'data_deleted');

      if (kDebugMode) {
        print('📊 Analytics: Data deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log custom event: Account linked (anonymous to email)
  Future<void> logAccountLinked() async {
    try {
      await _analytics.logEvent(name: 'account_linked');

      if (kDebugMode) {
        print('📊 Analytics: Account linked');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log custom event: Theme changed
  Future<void> logThemeChanged({required bool isDarkMode}) async {
    try {
      await _analytics.logEvent(
        name: 'theme_changed',
        parameters: {'dark_mode': isDarkMode},
      );

      if (kDebugMode) {
        print('📊 Analytics: Theme changed (dark: $isDarkMode)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log screen view
  Future<void> logScreenView({required String screenName}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
      );

      if (kDebugMode) {
        print('📊 Analytics: Screen view - $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log user sign in
  Future<void> logSignIn({required String method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);

      if (kDebugMode) {
        print('📊 Analytics: User signed in ($method)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log user sign up
  Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);

      if (kDebugMode) {
        print('📊 Analytics: User signed up ($method)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);

      if (kDebugMode) {
        print('📊 Analytics: User property set ($name: $value)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Set user ID
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);

      if (kDebugMode) {
        print('📊 Analytics: User ID set');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log custom event: Price pulse validated
  Future<void> logPricePulseValidated({
    required String breed,
    required String weightBucket,
    required String county,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'price_pulse_validated',
        parameters: {
          'breed': breed,
          'weight_bucket': weightBucket,
          'county': county,
        },
      );

      if (kDebugMode) {
        print('📊 Analytics: Price pulse validated ($breed, $weightBucket)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log custom event: Price pulse flagged
  Future<void> logPricePulseFlagged({
    required String breed,
    required String weightBucket,
    required String county,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'price_pulse_flagged',
        parameters: {
          'breed': breed,
          'weight_bucket': weightBucket,
          'county': county,
        },
      );

      if (kDebugMode) {
        print('📊 Analytics: Price pulse flagged ($breed, $weightBucket)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }

  /// Log custom event: Price pulse sorting changed
  Future<void> logPricePulseSortChanged({required String sortType}) async {
    try {
      await _analytics.logEvent(
        name: 'price_pulse_sort_changed',
        parameters: {'sort_type': sortType},
      );

      if (kDebugMode) {
        print('📊 Analytics: Price pulse sort changed ($sortType)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics error: $e');
      }
    }
  }
}
