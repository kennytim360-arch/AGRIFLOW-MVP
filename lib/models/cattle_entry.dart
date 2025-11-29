class CattleEntry {
  final String? id;
  final String cattleType;
  final int currentCount;
  final double currentWeightKg;
  final double targetWeightKg;
  final DateTime targetKillDate;
  final DateTime dateUpdated;

  CattleEntry({
    this.id,
    required this.cattleType,
    required this.currentCount,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.targetKillDate,
    required this.dateUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'cattleType': cattleType,
      'currentCount': currentCount,
      'currentWeightKg': currentWeightKg,
      'targetWeightKg': targetWeightKg,
      'targetKillDate': targetKillDate.toIso8601String(),
      'dateUpdated': dateUpdated.toIso8601String(),
    };
  }

  factory CattleEntry.fromMap(Map<String, dynamic> map, String id) {
    return CattleEntry(
      id: id,
      cattleType: map['cattleType'] ?? '',
      currentCount: map['currentCount']?.toInt() ?? 0,
      currentWeightKg: map['currentWeightKg']?.toDouble() ?? 0.0,
      targetWeightKg: map['targetWeightKg']?.toDouble() ?? 0.0,
      targetKillDate: DateTime.parse(map['targetKillDate'] ?? DateTime.now().toIso8601String()),
      dateUpdated: DateTime.parse(map['dateUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }
}
