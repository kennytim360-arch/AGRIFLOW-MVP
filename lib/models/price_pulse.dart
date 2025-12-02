/// price_pulse.dart - Price pulse submission data model
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'cattle_group.dart';

/// Confidence level for price submissions
enum ConfidenceLevel {
  low,
  medium,
  high,
}

class PricePulse {
  final String? id;
  final Breed breed;
  final WeightBucket weightBucket;
  final double price; // Actual sale price €/kg (Offered)
  final double desiredPrice; // Target price €/kg
  final String county; // Irish county
  final DateTime submissionDate;

  // Validation & engagement fields
  final int validationCount; // Number of "Accurate" validations
  final int flagCount; // Number of "Seems off" flags
  final double hotScore; // Calculated score for Hot sorting

  PricePulse({
    this.id,
    required this.breed,
    required this.weightBucket,
    required this.price,
    required this.desiredPrice,
    required this.county,
    required this.submissionDate,
    this.validationCount = 0,
    this.flagCount = 0,
    this.hotScore = 0.0,
  });

  /// Get human-readable time ago string
  String get timeAgo {
    final diff = DateTime.now().difference(submissionDate);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays}d ago';
  }

  /// Calculate trust/confidence level based on validations
  ConfidenceLevel get trustLevel {
    if (validationCount >= 10) return ConfidenceLevel.high;
    if (validationCount >= 3) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  /// Check if this price is flagged as suspicious
  bool get isSuspicious => flagCount >= 10;

  /// Get net validation score (validations - flags)
  int get netScore => validationCount - flagCount;

  Map<String, dynamic> toMap() {
    return {
      'breed': breed.name,
      'weight_bucket': weightBucket.name,
      'price': price,
      'desired_price': desiredPrice,
      'county': county,
      'submission_date': Timestamp.fromDate(submissionDate),
      'validation_count': validationCount,
      'flag_count': flagCount,
      'hot_score': hotScore,
      'last_updated': FieldValue.serverTimestamp(),
    };
  }

  factory PricePulse.fromMap(Map<String, dynamic> map, String id) {
    // Handle both Timestamp (from Firestore) and String (from JSON)
    DateTime submissionDate;
    if (map['submission_date'] is Timestamp) {
      submissionDate = (map['submission_date'] as Timestamp).toDate();
    } else if (map['submission_date'] is String) {
      submissionDate = DateTime.parse(map['submission_date']);
    } else {
      submissionDate = DateTime.now();
    }

    return PricePulse(
      id: id,
      breed: Breed.values.firstWhere(
        (b) => b.name == map['breed'],
        orElse: () => Breed.charolais,
      ),
      weightBucket: WeightBucket.values.firstWhere(
        (w) => w.name == map['weight_bucket'],
        orElse: () => WeightBucket.w600_700,
      ),
      price: map['price']?.toDouble() ?? 0.0,
      desiredPrice: map['desired_price']?.toDouble() ?? 0.0,
      county: map['county'] ?? 'Dublin',
      submissionDate: submissionDate,
      validationCount: map['validation_count'] ?? 0,
      flagCount: map['flag_count'] ?? 0,
      hotScore: map['hot_score']?.toDouble() ?? 0.0,
    );
  }

  /// Copy with method for updating fields
  PricePulse copyWith({
    String? id,
    Breed? breed,
    WeightBucket? weightBucket,
    double? price,
    double? desiredPrice,
    String? county,
    DateTime? submissionDate,
    int? validationCount,
    int? flagCount,
    double? hotScore,
  }) {
    return PricePulse(
      id: id ?? this.id,
      breed: breed ?? this.breed,
      weightBucket: weightBucket ?? this.weightBucket,
      price: price ?? this.price,
      desiredPrice: desiredPrice ?? this.desiredPrice,
      county: county ?? this.county,
      submissionDate: submissionDate ?? this.submissionDate,
      validationCount: validationCount ?? this.validationCount,
      flagCount: flagCount ?? this.flagCount,
      hotScore: hotScore ?? this.hotScore,
    );
  }
}
