/// price_pulse_test.dart - Unit tests for PricePulse model
///
/// Tests model serialization, validation, and scoring logic
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agriflow/models/price_pulse.dart';
import 'package:agriflow/models/cattle_group.dart';

void main() {
  group('PricePulse Model Tests', () {
    test('toMap() serializes correctly', () {
      final now = DateTime(2025, 1, 1, 12, 0, 0);
      final pulse = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: now,
        validationCount: 5,
        flagCount: 1,
        hotScore: 12.5,
      );

      final map = pulse.toMap();

      expect(map['breed'], 'charolais');
      expect(map['weight_bucket'], 'w600_700');
      expect(map['price'], 4.20);
      expect(map['desired_price'], 4.50);
      expect(map['county'], 'Cork');
      expect(map['submission_date'], isA<Timestamp>());
      expect(map['validation_count'], 5);
      expect(map['flag_count'], 1);
      expect(map['hot_score'], 12.5);
      expect(map['last_updated'], isA<FieldValue>());
    });

    test('fromMap() deserializes correctly with Timestamp', () {
      final now = DateTime(2025, 1, 1, 12, 0, 0);
      final map = {
        'breed': 'angus',
        'weight_bucket': 'w500_600',
        'price': 4.10,
        'desired_price': 4.40,
        'county': 'Dublin',
        'submission_date': Timestamp.fromDate(now),
        'validation_count': 8,
        'flag_count': 2,
        'hot_score': 15.3,
      };

      final pulse = PricePulse.fromMap(map, 'test_id');

      expect(pulse.id, 'test_id');
      expect(pulse.breed, Breed.angus);
      expect(pulse.weightBucket, WeightBucket.w500_600);
      expect(pulse.price, 4.10);
      expect(pulse.desiredPrice, 4.40);
      expect(pulse.county, 'Dublin');
      expect(pulse.submissionDate, now);
      expect(pulse.validationCount, 8);
      expect(pulse.flagCount, 2);
      expect(pulse.hotScore, 15.3);
    });

    test('fromMap() handles missing fields with defaults', () {
      final map = <String, dynamic>{
        // Only providing minimal required fields
        'breed': 'limousin',
        'weight_bucket': 'w400_500',
      };

      final pulse = PricePulse.fromMap(map, 'test_id');

      expect(pulse.id, 'test_id');
      expect(pulse.breed, Breed.limousin);
      expect(pulse.weightBucket, WeightBucket.w400_500);
      expect(pulse.price, 0.0); // Default
      expect(pulse.desiredPrice, 0.0); // Default
      expect(pulse.county, 'Dublin'); // Default
      expect(pulse.validationCount, 0); // Default
      expect(pulse.flagCount, 0); // Default
      expect(pulse.hotScore, 0.0); // Default
    });

    test('timeAgo formats correctly for different time ranges', () {
      // Just now (< 1 minute)
      final justNow = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      expect(justNow.timeAgo, 'just now');

      // Minutes ago
      final minutesAgo = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now().subtract(const Duration(minutes: 15)),
      );
      expect(minutesAgo.timeAgo, '15m ago');

      // Hours ago
      final hoursAgo = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now().subtract(const Duration(hours: 5)),
      );
      expect(hoursAgo.timeAgo, '5h ago');

      // Days ago
      final daysAgo = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(daysAgo.timeAgo, '3d ago');
    });

    test('trustLevel categorizes validation counts correctly', () {
      // Low trust (< 3 validations)
      final lowTrust = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now(),
        validationCount: 2,
      );
      expect(lowTrust.trustLevel, ConfidenceLevel.low);

      // Medium trust (3-9 validations)
      final mediumTrust = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now(),
        validationCount: 5,
      );
      expect(mediumTrust.trustLevel, ConfidenceLevel.medium);

      // High trust (>= 10 validations)
      final highTrust = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now(),
        validationCount: 15,
      );
      expect(highTrust.trustLevel, ConfidenceLevel.high);
    });

    test('isSuspicious flags high flag counts', () {
      // Not suspicious (< 10 flags)
      final notSuspicious = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now(),
        flagCount: 5,
      );
      expect(notSuspicious.isSuspicious, false);

      // Suspicious (>= 10 flags)
      final suspicious = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now(),
        flagCount: 12,
      );
      expect(suspicious.isSuspicious, true);
    });

    test('netScore calculates correctly', () {
      final pulse = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now(),
        validationCount: 15,
        flagCount: 3,
      );

      expect(pulse.netScore, 12); // 15 - 3
    });

    test('netScore can be negative', () {
      final pulse = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now(),
        validationCount: 2,
        flagCount: 8,
      );

      expect(pulse.netScore, -6); // 2 - 8
    });

    test('copyWith creates modified copy', () {
      final original = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now(),
        validationCount: 5,
        flagCount: 1,
        hotScore: 10.0,
      );

      final modified = original.copyWith(
        validationCount: 10,
        hotScore: 15.5,
      );

      // Changed fields
      expect(modified.validationCount, 10);
      expect(modified.hotScore, 15.5);

      // Unchanged fields
      expect(modified.breed, original.breed);
      expect(modified.weightBucket, original.weightBucket);
      expect(modified.price, original.price);
      expect(modified.desiredPrice, original.desiredPrice);
      expect(modified.county, original.county);
      expect(modified.submissionDate, original.submissionDate);
      expect(modified.flagCount, original.flagCount);
    });

    test('serialization round-trip preserves data', () {
      final now = DateTime(2025, 1, 1, 12, 0, 0);
      final original = PricePulse(
        breed: Breed.limousin,
        weightBucket: WeightBucket.w700Plus,
        price: 4.35,
        desiredPrice: 4.60,
        county: 'Galway',
        submissionDate: now,
        validationCount: 7,
        flagCount: 2,
        hotScore: 11.2,
      );

      final map = original.toMap();
      final restored = PricePulse.fromMap(map, 'test_id');

      expect(restored.breed, original.breed);
      expect(restored.weightBucket, original.weightBucket);
      expect(restored.price, original.price);
      expect(restored.desiredPrice, original.desiredPrice);
      expect(restored.county, original.county);
      expect(restored.validationCount, original.validationCount);
      expect(restored.flagCount, original.flagCount);
      expect(restored.hotScore, original.hotScore);
    });
  });

  group('ConfidenceLevel Enum Tests', () {
    test('confidence levels are defined', () {
      expect(ConfidenceLevel.low, isNotNull);
      expect(ConfidenceLevel.medium, isNotNull);
      expect(ConfidenceLevel.high, isNotNull);
    });

    test('confidence levels have correct ordering', () {
      expect(ConfidenceLevel.low.index < ConfidenceLevel.medium.index, true);
      expect(ConfidenceLevel.medium.index < ConfidenceLevel.high.index, true);
    });
  });

  group('Edge Cases', () {
    test('handles zero validations and flags', () {
      final pulse = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now(),
      );

      expect(pulse.validationCount, 0);
      expect(pulse.flagCount, 0);
      expect(pulse.netScore, 0);
      expect(pulse.isSuspicious, false);
      expect(pulse.trustLevel, ConfidenceLevel.low);
    });

    test('handles very high validation counts', () {
      final pulse = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now(),
        validationCount: 1000,
        flagCount: 50,
      );

      expect(pulse.netScore, 950);
      expect(pulse.trustLevel, ConfidenceLevel.high);
      expect(pulse.isSuspicious, true); // High flags even with high validations
    });

    test('handles equal validations and flags', () {
      final pulse = PricePulse(
        breed: Breed.charolais,
        weightBucket: WeightBucket.w600_700,
        price: 4.20,
        desiredPrice: 4.50,
        county: 'Cork',
        submissionDate: DateTime.now(),
        validationCount: 10,
        flagCount: 10,
      );

      expect(pulse.netScore, 0);
      expect(pulse.trustLevel, ConfidenceLevel.high); // Based on validations
      expect(pulse.isSuspicious, true); // Based on flags
    });
  });
}
