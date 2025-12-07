/// price_log.dart - Personal price tracking model
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'cattle_group.dart';

/// Type of price entry
enum PriceLogType {
  offer,       // Price was offered to you
  sale,        // Actual completed sale
  inquiry,     // Price inquiry/quote
}

extension PriceLogTypeExtension on PriceLogType {
  String get displayName {
    switch (this) {
      case PriceLogType.offer:
        return 'Offer Received';
      case PriceLogType.sale:
        return 'Sale Completed';
      case PriceLogType.inquiry:
        return 'Price Inquiry';
    }
  }

  String get icon {
    switch (this) {
      case PriceLogType.offer:
        return '💰';
      case PriceLogType.sale:
        return '✅';
      case PriceLogType.inquiry:
        return '❓';
    }
  }
}

/// Represents a personal price log entry
///
/// Farmers use this to track actual prices they were offered or received,
/// allowing them to compare against market data (Price Pulse) and make
/// better selling decisions.
///
/// This data is PRIVATE to the user (stored in users/{uid}/price_logs)
class PriceLog {
  /// Firestore document ID
  final String? id;

  /// Type of entry (offer, sale, inquiry)
  final PriceLogType type;

  /// Breed of cattle
  final Breed breed;

  /// Weight bucket
  final WeightBucket weightBucket;

  /// County where offer was made
  final String county;

  /// Price per kg offered/received (in EUR)
  final double pricePerKg;

  /// Number of animals involved
  final int quantity;

  /// Source of the price (mart name, buyer name, etc.)
  /// Example: "Bandon Mart", "John Smith (buyer)", "Co-op"
  final String source;

  /// Additional notes
  final String? notes;

  /// Whether the offer was accepted (null if not applicable)
  final bool? accepted;

  /// Date of the offer/sale
  final DateTime date;

  /// When this log was created
  final DateTime createdAt;

  const PriceLog({
    this.id,
    required this.type,
    required this.breed,
    required this.weightBucket,
    required this.county,
    required this.pricePerKg,
    required this.quantity,
    required this.source,
    this.notes,
    this.accepted,
    required this.date,
    required this.createdAt,
  });

  /// Converts this model to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'breed': breed.name,
      'weight_bucket': weightBucket.name,
      'county': county,
      'price_per_kg': pricePerKg,
      'quantity': quantity,
      'source': source,
      'notes': notes,
      'accepted': accepted,
      'date': Timestamp.fromDate(date),
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a PriceLog instance from a Firestore document
  factory PriceLog.fromMap(Map<String, dynamic> map, String id) {
    return PriceLog(
      id: id,
      type: PriceLogType.values.byName(map['type'] as String),
      breed: Breed.values.byName(map['breed'] as String),
      weightBucket: WeightBucket.values.byName(map['weight_bucket'] as String),
      county: map['county'] as String,
      pricePerKg: (map['price_per_kg'] as num).toDouble(),
      quantity: map['quantity'] as int? ?? 1,
      source: map['source'] as String? ?? '',
      notes: map['notes'] as String?,
      accepted: map['accepted'] as bool?,
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['created_at'] as Timestamp).toDate(),
    );
  }

  /// Calculates total value of this entry
  double get totalValue {
    // Estimate average weight for the bucket
    final avgWeight = weightBucket.averageWeight;

    // Total live weight
    final totalWeight = avgWeight * quantity;

    // Apply dressing percentage (55%)
    const dressingPercentage = 0.55;
    final deadWeight = totalWeight * dressingPercentage;

    // Calculate total value
    return deadWeight * pricePerKg;
  }

  /// Returns a comparison string relative to a market price
  String compareToMarketPrice(double marketPrice) {
    final difference = pricePerKg - marketPrice;
    final percentDiff = (difference / marketPrice) * 100;

    if (difference.abs() < 0.05) {
      return 'On par with market';
    } else if (difference > 0) {
      return '+€${difference.toStringAsFixed(2)} (+${percentDiff.toStringAsFixed(1)}%) above market';
    } else {
      return '€${difference.abs().toStringAsFixed(2)} (-${percentDiff.abs().toStringAsFixed(1)}%) below market';
    }
  }

  /// Whether this log is from the current week
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartMidnight = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return date.isAfter(weekStartMidnight);
  }

  /// Copy with method for immutable updates
  PriceLog copyWith({
    String? id,
    PriceLogType? type,
    Breed? breed,
    WeightBucket? weightBucket,
    String? county,
    double? pricePerKg,
    int? quantity,
    String? source,
    String? notes,
    bool? accepted,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return PriceLog(
      id: id ?? this.id,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      weightBucket: weightBucket ?? this.weightBucket,
      county: county ?? this.county,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      quantity: quantity ?? this.quantity,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      accepted: accepted ?? this.accepted,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Statistics for price logs
class PriceLogStats {
  final int totalLogs;
  final int offersReceived;
  final int salesCompleted;
  final int inquiriesMade;
  final double averagePriceOffered;
  final double averagePriceSold;
  final double totalValueSold;
  final int totalAnimalsSold;

  const PriceLogStats({
    required this.totalLogs,
    required this.offersReceived,
    required this.salesCompleted,
    required this.inquiriesMade,
    required this.averagePriceOffered,
    required this.averagePriceSold,
    required this.totalValueSold,
    required this.totalAnimalsSold,
  });

  factory PriceLogStats.empty() {
    return const PriceLogStats(
      totalLogs: 0,
      offersReceived: 0,
      salesCompleted: 0,
      inquiriesMade: 0,
      averagePriceOffered: 0.0,
      averagePriceSold: 0.0,
      totalValueSold: 0.0,
      totalAnimalsSold: 0,
    );
  }

  /// Calculates stats from a list of logs
  factory PriceLogStats.fromLogs(List<PriceLog> logs) {
    if (logs.isEmpty) return PriceLogStats.empty();

    final offers = logs.where((l) => l.type == PriceLogType.offer).toList();
    final sales = logs.where((l) => l.type == PriceLogType.sale).toList();
    final inquiries = logs.where((l) => l.type == PriceLogType.inquiry).toList();

    final avgOffer = offers.isEmpty
        ? 0.0
        : offers.map((l) => l.pricePerKg).reduce((a, b) => a + b) / offers.length;

    final avgSale = sales.isEmpty
        ? 0.0
        : sales.map((l) => l.pricePerKg).reduce((a, b) => a + b) / sales.length;

    final totalValue = sales.map((l) => l.totalValue).fold<double>(0.0, (a, b) => a + b);
    final totalAnimals = sales.map((l) => l.quantity).fold<int>(0, (a, b) => a + b);

    return PriceLogStats(
      totalLogs: logs.length,
      offersReceived: offers.length,
      salesCompleted: sales.length,
      inquiriesMade: inquiries.length,
      averagePriceOffered: avgOffer,
      averagePriceSold: avgSale,
      totalValueSold: totalValue,
      totalAnimalsSold: totalAnimals,
    );
  }
}
