class PricePulse {
  final String? id;
  final String cattleType;
  final String locationRegion;
  final double weightKg;
  final double desiredPricePerKg;
  final double offeredPricePerKg;
  final DateTime submissionDate;

  PricePulse({
    this.id,
    required this.cattleType,
    required this.locationRegion,
    required this.weightKg,
    required this.desiredPricePerKg,
    required this.offeredPricePerKg,
    required this.submissionDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'cattle_type': cattleType,
      'location_region': locationRegion,
      'weight_kg': weightKg,
      'desired_price_per_kg': desiredPricePerKg,
      'offered_price_per_kg': offeredPricePerKg,
      'submission_date': submissionDate.toIso8601String(),
    };
  }

  factory PricePulse.fromMap(Map<String, dynamic> map, String id) {
    return PricePulse(
      id: id,
      cattleType: map['cattle_type'] ?? '',
      locationRegion: map['location_region'] ?? '',
      weightKg: map['weight_kg']?.toDouble() ?? 0.0,
      desiredPricePerKg: map['desired_price_per_kg']?.toDouble() ?? 0.0,
      offeredPricePerKg: map['offered_price_per_kg']?.toDouble() ?? 0.0,
      submissionDate: DateTime.parse(
        map['submission_date'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
