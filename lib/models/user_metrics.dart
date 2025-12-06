/// user_metrics.dart - User statistics and metrics model
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents aggregated user statistics and metrics
///
/// This model contains all user-specific metrics including:
/// - Portfolio statistics (total value, animal count)
/// - Price Pulse contribution stats
/// - Activity timeline
/// - Performance indicators
class UserMetrics {
  /// Total number of cattle groups in portfolio
  final int totalGroups;

  /// Total number of animals across all groups
  final int totalAnimals;

  /// Estimated total portfolio value (in EUR)
  final double totalPortfolioValue;

  /// Number of price pulses submitted by user
  final int pricePulsesSubmitted;

  /// Number of validations received on user's submissions
  final int validationsReceived;

  /// Number of flags received on user's submissions
  final int flagsReceived;

  /// User's trust score (based on validation/flag ratio)
  final double trustScore;

  /// Total number of validations given by user
  final int validationsGiven;

  /// Total number of flags given by user
  final int flagsGiven;

  /// When the user first created their account
  final DateTime accountCreatedAt;

  /// Last time user was active (any action)
  final DateTime lastActiveAt;

  /// Number of days user has been active
  final int activeDays;

  /// Portfolio value history (date → value)
  /// Used for trend charts
  final Map<DateTime, double> portfolioValueHistory;

  /// Constructor
  const UserMetrics({
    required this.totalGroups,
    required this.totalAnimals,
    required this.totalPortfolioValue,
    required this.pricePulsesSubmitted,
    required this.validationsReceived,
    required this.flagsReceived,
    required this.trustScore,
    required this.validationsGiven,
    required this.flagsGiven,
    required this.accountCreatedAt,
    required this.lastActiveAt,
    required this.activeDays,
    required this.portfolioValueHistory,
  });

  /// Creates empty metrics (for new users)
  factory UserMetrics.empty() {
    final now = DateTime.now();
    return UserMetrics(
      totalGroups: 0,
      totalAnimals: 0,
      totalPortfolioValue: 0.0,
      pricePulsesSubmitted: 0,
      validationsReceived: 0,
      flagsReceived: 0,
      trustScore: 0.0,
      validationsGiven: 0,
      flagsGiven: 0,
      accountCreatedAt: now,
      lastActiveAt: now,
      activeDays: 0,
      portfolioValueHistory: {},
    );
  }

  /// Converts this model to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'total_groups': totalGroups,
      'total_animals': totalAnimals,
      'total_portfolio_value': totalPortfolioValue,
      'price_pulses_submitted': pricePulsesSubmitted,
      'validations_received': validationsReceived,
      'flags_received': flagsReceived,
      'trust_score': trustScore,
      'validations_given': validationsGiven,
      'flags_given': flagsGiven,
      'account_created_at': Timestamp.fromDate(accountCreatedAt),
      'last_active_at': Timestamp.fromDate(lastActiveAt),
      'active_days': activeDays,
      'portfolio_value_history': portfolioValueHistory
          .map((date, value) => MapEntry(date.toIso8601String(), value)),
    };
  }

  /// Creates a UserMetrics instance from a Firestore document
  factory UserMetrics.fromMap(Map<String, dynamic> map) {
    // Parse portfolio value history
    final Map<DateTime, double> history = {};
    if (map['portfolio_value_history'] != null) {
      final historyMap = map['portfolio_value_history'] as Map<String, dynamic>;
      historyMap.forEach((key, value) {
        history[DateTime.parse(key)] = (value as num).toDouble();
      });
    }

    return UserMetrics(
      totalGroups: map['total_groups'] as int? ?? 0,
      totalAnimals: map['total_animals'] as int? ?? 0,
      totalPortfolioValue:
          (map['total_portfolio_value'] as num?)?.toDouble() ?? 0.0,
      pricePulsesSubmitted: map['price_pulses_submitted'] as int? ?? 0,
      validationsReceived: map['validations_received'] as int? ?? 0,
      flagsReceived: map['flags_received'] as int? ?? 0,
      trustScore: (map['trust_score'] as num?)?.toDouble() ?? 0.0,
      validationsGiven: map['validations_given'] as int? ?? 0,
      flagsGiven: map['flags_given'] as int? ?? 0,
      accountCreatedAt: (map['account_created_at'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      lastActiveAt:
          (map['last_active_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activeDays: map['active_days'] as int? ?? 0,
      portfolioValueHistory: history,
    );
  }

  /// Calculates trust level based on trust score
  ///
  /// Returns: 'New', 'Trusted', 'Verified', or 'Expert'
  String get trustLevel {
    if (pricePulsesSubmitted < 5) return 'New';
    if (trustScore >= 0.8) return 'Expert';
    if (trustScore >= 0.6) return 'Verified';
    if (trustScore >= 0.4) return 'Trusted';
    return 'New';
  }

  /// Calculates validation rate (0.0 to 1.0)
  double get validationRate {
    if (pricePulsesSubmitted == 0) return 0.0;
    return validationsReceived / (pricePulsesSubmitted * 10); // Assume avg 10 validations possible
  }

  /// Calculates flag rate (0.0 to 1.0)
  double get flagRate {
    if (pricePulsesSubmitted == 0) return 0.0;
    return flagsReceived / (pricePulsesSubmitted * 10); // Assume avg 10 flags possible
  }

  /// Whether user is an active contributor
  bool get isActiveContributor {
    return pricePulsesSubmitted >= 10 && trustScore >= 0.5;
  }

  /// Copy with method for immutable updates
  UserMetrics copyWith({
    int? totalGroups,
    int? totalAnimals,
    double? totalPortfolioValue,
    int? pricePulsesSubmitted,
    int? validationsReceived,
    int? flagsReceived,
    double? trustScore,
    int? validationsGiven,
    int? flagsGiven,
    DateTime? accountCreatedAt,
    DateTime? lastActiveAt,
    int? activeDays,
    Map<DateTime, double>? portfolioValueHistory,
  }) {
    return UserMetrics(
      totalGroups: totalGroups ?? this.totalGroups,
      totalAnimals: totalAnimals ?? this.totalAnimals,
      totalPortfolioValue: totalPortfolioValue ?? this.totalPortfolioValue,
      pricePulsesSubmitted: pricePulsesSubmitted ?? this.pricePulsesSubmitted,
      validationsReceived: validationsReceived ?? this.validationsReceived,
      flagsReceived: flagsReceived ?? this.flagsReceived,
      trustScore: trustScore ?? this.trustScore,
      validationsGiven: validationsGiven ?? this.validationsGiven,
      flagsGiven: flagsGiven ?? this.flagsGiven,
      accountCreatedAt: accountCreatedAt ?? this.accountCreatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      activeDays: activeDays ?? this.activeDays,
      portfolioValueHistory:
          portfolioValueHistory ?? this.portfolioValueHistory,
    );
  }
}

/// Market trend data for analytics
class MarketTrendData {
  /// The breed being analyzed
  final String breed;

  /// The weight bucket being analyzed
  final String weightBucket;

  /// County (optional - null means all counties)
  final String? county;

  /// Average price
  final double averagePrice;

  /// Median price
  final double medianPrice;

  /// Lowest price in range
  final double minPrice;

  /// Highest price in range
  final double maxPrice;

  /// Number of submissions
  final int submissionCount;

  /// Price trend (positive = increasing, negative = decreasing)
  final double trendPercentage;

  /// Historical price data (date → price)
  final Map<DateTime, double> priceHistory;

  const MarketTrendData({
    required this.breed,
    required this.weightBucket,
    this.county,
    required this.averagePrice,
    required this.medianPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.submissionCount,
    required this.trendPercentage,
    required this.priceHistory,
  });

  /// Whether price is trending up
  bool get isTrendingUp => trendPercentage > 0.02; // > 2% increase

  /// Whether price is trending down
  bool get isTrendingDown => trendPercentage < -0.02; // > 2% decrease

  /// Whether price is stable
  bool get isStable => !isTrendingUp && !isTrendingDown;

  /// Trend indicator icon
  String get trendIcon {
    if (isTrendingUp) return '📈';
    if (isTrendingDown) return '📉';
    return '➡️';
  }

  /// Trend description
  String get trendDescription {
    if (isTrendingUp) return 'Increasing';
    if (isTrendingDown) return 'Decreasing';
    return 'Stable';
  }
}
