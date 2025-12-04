/// cattle_group_test.dart - Unit tests for CattleGroup model
///
/// Tests model serialization, calculations, and enum functionality
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agriflow/models/cattle_group.dart';
import 'package:agriflow/utils/constants.dart';

void main() {
  group('CattleGroup Model Tests', () {
    test('toMap() serializes correctly', () {
      final now = DateTime(2025, 1, 1, 12, 0, 0);
      final group = CattleGroup(
        breed: Breed.charolais,
        quantity: 30,
        weightBucket: WeightBucket.w600_700,
        county: 'Cork',
        desiredPricePerKg: 4.50,
        createdAt: now,
        updatedAt: now,
      );

      final map = group.toMap();

      expect(map['breed'], 'charolais');
      expect(map['quantity'], 30);
      expect(map['weight_bucket'], 'w600_700');
      expect(map['county'], 'Cork');
      expect(map['desired_price_per_kg'], 4.50);
      expect(map['created_at'], isA<Timestamp>());
      expect(map['updated_at'], isA<Timestamp>());
    });

    test('fromMap() deserializes correctly with Timestamp', () {
      final now = DateTime(2025, 1, 1, 12, 0, 0);
      final map = {
        'breed': 'angus',
        'quantity': 25,
        'weight_bucket': 'w500_600',
        'county': 'Dublin',
        'desired_price_per_kg': 4.25,
        'created_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
      };

      final group = CattleGroup.fromMap(map, 'test_id');

      expect(group.id, 'test_id');
      expect(group.breed, Breed.angus);
      expect(group.quantity, 25);
      expect(group.weightBucket, WeightBucket.w500_600);
      expect(group.county, 'Dublin');
      expect(group.desiredPricePerKg, 4.25);
      expect(group.createdAt, now);
      expect(group.updatedAt, now);
    });

    test('fromMap() handles missing/invalid fields with defaults', () {
      final map = <String, dynamic>{
        // Missing required fields - should use defaults
      };

      final group = CattleGroup.fromMap(map, 'test_id');

      expect(group.id, 'test_id');
      expect(group.breed, Breed.charolais); // Default breed
      expect(group.quantity, 1); // Default quantity
      expect(group.weightBucket, WeightBucket.w600_700); // Default weight
      expect(group.county, 'Dublin'); // Default county
      expect(group.desiredPricePerKg, 4.0); // Default price
    });

    test('totalWeight calculation is correct', () {
      final group = CattleGroup(
        breed: Breed.charolais,
        quantity: 10,
        weightBucket: WeightBucket.w600_700, // 650 kg average
        county: 'Cork',
        desiredPricePerKg: 4.50,
      );

      expect(group.totalWeight, 6500.0); // 10 * 650
    });

    test('calculateKillOutValue uses dressing percentage correctly', () {
      final group = CattleGroup(
        breed: Breed.charolais,
        quantity: 10,
        weightBucket: WeightBucket.w600_700, // 650 kg average
        county: 'Cork',
        desiredPricePerKg: 4.50,
      );

      final marketPrice = 4.0;
      final killOutValue = group.calculateKillOutValue(marketPrice);

      // Expected: 10 * 650 * 0.55 * 4.0 = 14,300
      expect(killOutValue, closeTo(14300.0, 0.01));
    });

    test('calculateBreedPremium uses breed multiplier correctly', () {
      final group = CattleGroup(
        breed: Breed.charolais, // 0.15 premium
        quantity: 10,
        weightBucket: WeightBucket.w600_700, // 650 kg average
        county: 'Cork',
        desiredPricePerKg: 4.50,
      );

      final basePrice = 4.0;
      final premium = group.calculateBreedPremium(basePrice);

      // Expected: 6500 * 4.0 * 0.15 = 3,900
      expect(premium, 6500 * basePrice * Breed.charolais.premiumMultiplier);
      expect(premium, 3900.0);
    });

    test('calculateMarketDifference shows price gap correctly', () {
      final group = CattleGroup(
        breed: Breed.charolais,
        quantity: 10,
        weightBucket: WeightBucket.w600_700, // 650 kg average
        county: 'Cork',
        desiredPricePerKg: 4.50,
      );

      final countyMedianPrice = 4.20;
      final difference = group.calculateMarketDifference(countyMedianPrice);

      // Expected: 6500 * (4.50 - 4.20) = 6500 * 0.30 = 1,950
      expect(difference, closeTo(1950.0, 0.01));
    });

    test('calculatePerHeadDifference calculates per-animal price gap', () {
      final group = CattleGroup(
        breed: Breed.charolais,
        quantity: 10,
        weightBucket: WeightBucket.w600_700, // 650 kg average
        county: 'Cork',
        desiredPricePerKg: 4.50,
      );

      final countyMedianPrice = 4.20;
      final perHeadDiff = group.calculatePerHeadDifference(countyMedianPrice);

      // Expected: 650 * (4.50 - 4.20) = 650 * 0.30 = 195
      expect(perHeadDiff, closeTo(195.0, 0.01));
    });

    test('serialization round-trip preserves data', () {
      final original = CattleGroup(
        breed: Breed.limousin,
        quantity: 42,
        weightBucket: WeightBucket.w700Plus,
        county: 'Galway',
        desiredPricePerKg: 4.75,
      );

      final map = original.toMap();
      final restored = CattleGroup.fromMap(map, 'test_id');

      expect(restored.breed, original.breed);
      expect(restored.quantity, original.quantity);
      expect(restored.weightBucket, original.weightBucket);
      expect(restored.county, original.county);
      expect(restored.desiredPricePerKg, original.desiredPricePerKg);
    });
  });

  group('Breed Enum Tests', () {
    test('getByAnimalType filters correctly', () {
      final cattleBreeds = Breed.getByAnimalType(AnimalType.cattle);
      expect(cattleBreeds.length, 6);
      expect(cattleBreeds.every((b) => b.animalType == AnimalType.cattle), true);

      final goatBreeds = Breed.getByAnimalType(AnimalType.goat);
      expect(goatBreeds.length, 3);

      final sheepBreeds = Breed.getByAnimalType(AnimalType.sheep);
      expect(sheepBreeds.length, 3);

      final chickenBreeds = Breed.getByAnimalType(AnimalType.chicken);
      expect(chickenBreeds.length, 2);

      final pigBreeds = Breed.getByAnimalType(AnimalType.pig);
      expect(pigBreeds.length, 3);
    });

    test('breed has correct properties', () {
      expect(Breed.charolais.displayName, 'Charolais');
      expect(Breed.charolais.emoji, '🐄');
      expect(Breed.charolais.premiumMultiplier, 0.15);
      expect(Breed.charolais.animalType, AnimalType.cattle);
    });
  });

  group('WeightBucket Enum Tests', () {
    test('weight buckets have correct average weights', () {
      expect(WeightBucket.w400_500.averageWeight, 450);
      expect(WeightBucket.w500_600.averageWeight, 550);
      expect(WeightBucket.w600_700.averageWeight, 650);
      expect(WeightBucket.w700Plus.averageWeight, 750);
    });

    test('weight buckets have display names', () {
      expect(WeightBucket.w400_500.displayName, '400-500 kg');
      expect(WeightBucket.w500_600.displayName, '500-600 kg');
      expect(WeightBucket.w600_700.displayName, '600-700 kg');
      expect(WeightBucket.w700Plus.displayName, '700+ kg');
    });
  });

  group('AnimalType Enum Tests', () {
    test('animal types have correct display names and emojis', () {
      expect(AnimalType.cattle.displayName, 'Cattle');
      expect(AnimalType.cattle.emoji, '🐄');

      expect(AnimalType.goat.displayName, 'Goat');
      expect(AnimalType.goat.emoji, '🐐');

      expect(AnimalType.sheep.displayName, 'Sheep');
      expect(AnimalType.sheep.emoji, '🐑');

      expect(AnimalType.chicken.displayName, 'Chicken');
      expect(AnimalType.chicken.emoji, '🐔');

      expect(AnimalType.pig.displayName, 'Pig');
      expect(AnimalType.pig.emoji, '🐷');
    });
  });
}
