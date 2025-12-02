/// cattle_group.dart - Data models for cattle groups and related enums
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:cloud_firestore/cloud_firestore.dart';

// Animal Type - First Selection
enum AnimalType {
  cattle('Cattle', '🐄'),
  goat('Goat', '🐐'),
  sheep('Sheep', '🐑'),
  chicken('Chicken', '🐔'),
  pig('Pig', '🐷');

  final String displayName;
  final String emoji;

  const AnimalType(this.displayName, this.emoji);
}

// Breed - Second Selection (filtered by animal type)
enum Breed {
  // Cattle Breeds
  charolais('Charolais', '🐄', 0.15, AnimalType.cattle),
  angus('Angus', '🐂', 0.10, AnimalType.cattle),
  limousin('Limousin', '🐮', 0.12, AnimalType.cattle),
  hereford('Hereford', '🐄', 0.08, AnimalType.cattle),
  belgianBlue('Belgian Blue', '🐂', 0.18, AnimalType.cattle),
  simmental('Simmental', '🐮', 0.11, AnimalType.cattle),

  // Goat Breeds
  boer('Boer', '🐐', 0.10, AnimalType.goat),
  saanen('Saanen', '🐐', 0.08, AnimalType.goat),
  alpine('Alpine', '🐐', 0.09, AnimalType.goat),

  // Sheep Breeds
  suffolk('Suffolk', '🐑', 0.12, AnimalType.sheep),
  texel('Texel', '🐑', 0.14, AnimalType.sheep),
  cheviot('Cheviot', '🐑', 0.10, AnimalType.sheep),

  // Chicken Breeds
  broiler('Broiler', '🐔', 0.05, AnimalType.chicken),
  layer('Layer', '🐔', 0.03, AnimalType.chicken),

  // Pig Breeds
  landrace('Landrace', '🐷', 0.11, AnimalType.pig),
  duroc('Duroc', '🐷', 0.13, AnimalType.pig),
  largeWhite('Large White', '🐷', 0.10, AnimalType.pig);

  final String displayName;
  final String emoji;
  final double premiumMultiplier; // Premium as % of base price
  final AnimalType animalType;

  const Breed(
    this.displayName,
    this.emoji,
    this.premiumMultiplier,
    this.animalType,
  );

  // Get breeds for a specific animal type
  static List<Breed> getByAnimalType(AnimalType type) {
    return Breed.values.where((breed) => breed.animalType == type).toList();
  }
}

enum WeightBucket {
  w400_500('400-500 kg', 450, '⚖️'),
  w500_600('500-600 kg', 550, '⚖️'),
  w600_700('600-700 kg', 650, '⚖️'),
  w700Plus('700+ kg', 750, '⚖️');

  final String displayName;
  final double averageWeight;
  final String emoji;

  const WeightBucket(this.displayName, this.averageWeight, this.emoji);
}

class CattleGroup {
  final String? id;
  final Breed breed;
  final int quantity;
  final WeightBucket weightBucket;
  final String county; // Irish county
  final double desiredPricePerKg; // €/kg
  final DateTime createdAt;
  final DateTime updatedAt;

  CattleGroup({
    this.id,
    required this.breed,
    required this.quantity,
    required this.weightBucket,
    required this.county,
    required this.desiredPricePerKg,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Calculate total weight
  double get totalWeight => quantity * weightBucket.averageWeight;

  // Calculate kill-out value (55% dressing percentage)
  double calculateKillOutValue(double currentMarketPrice) {
    return totalWeight * 0.55 * currentMarketPrice;
  }

  // Calculate breed premium
  double calculateBreedPremium(double basePrice) {
    return totalWeight * basePrice * breed.premiumMultiplier;
  }

  // Calculate difference from market
  double calculateMarketDifference(double countyMedianPrice) {
    return totalWeight * (desiredPricePerKg - countyMedianPrice);
  }

  // Calculate per-head difference
  double calculatePerHeadDifference(double countyMedianPrice) {
    return weightBucket.averageWeight * (desiredPricePerKg - countyMedianPrice);
  }

  Map<String, dynamic> toMap() {
    return {
      'breed': breed.name,
      'quantity': quantity,
      'weight_bucket': weightBucket.name,
      'county': county,
      'desired_price_per_kg': desiredPricePerKg,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory CattleGroup.fromMap(Map<String, dynamic> map, String id) {
    // Handle both Timestamp (from Firestore) and String (from JSON)
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        return DateTime.now();
      }
    }

    return CattleGroup(
      id: id,
      breed: Breed.values.firstWhere(
        (b) => b.name == map['breed'],
        orElse: () => Breed.charolais,
      ),
      quantity: map['quantity']?.toInt() ?? 1,
      weightBucket: WeightBucket.values.firstWhere(
        (w) => w.name == map['weight_bucket'],
        orElse: () => WeightBucket.w600_700,
      ),
      county: map['county'] ?? 'Dublin',
      desiredPricePerKg: map['desired_price_per_kg']?.toDouble() ?? 4.0,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  CattleGroup copyWith({
    String? id,
    Breed? breed,
    int? quantity,
    WeightBucket? weightBucket,
    String? county,
    double? desiredPricePerKg,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CattleGroup(
      id: id ?? this.id,
      breed: breed ?? this.breed,
      quantity: quantity ?? this.quantity,
      weightBucket: weightBucket ?? this.weightBucket,
      county: county ?? this.county,
      desiredPricePerKg: desiredPricePerKg ?? this.desiredPricePerKg,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
