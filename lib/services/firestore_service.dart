import 'dart:async';
import '../models/cattle_entry.dart';
import '../models/price_pulse.dart';
import '../models/cattle_group.dart';

// Mock Firestore service for development without Firebase
class FirestoreService {
  final String _appId = 'agripulse_mvp';

  // In-memory storage for mock data
  final List<CattleEntry> _mockCattleEntries = [];
  final List<PricePulse> _mockPricePulses = [];
  final _cattleEntriesController = StreamController<List<CattleEntry>>.broadcast();
  final _pricePulsesController = StreamController<List<PricePulse>>.broadcast();

  FirestoreService() {
    // Add some mock price pulse data for testing
    _generateMockPricePulses();
  }

  void _generateMockPricePulses() {
    final now = DateTime.now();
    final breeds = Breed.values;
    final weights = WeightBucket.values;

    // Generate 30 mock price pulses over the last 7 days
    for (int i = 0; i < 30; i++) {
      final daysAgo = (i / 4).floor(); // 4 pulses per day
      final date = now.subtract(Duration(days: daysAgo, hours: i % 24));
      final breed = breeds[i % breeds.length];
      final weight = weights[i % weights.length];

      _mockPricePulses.add(PricePulse(
        id: 'mock_pulse_$i',
        cattleType: breed.displayName,
        locationRegion: ['Antrim', 'Cork', 'Galway', 'Dublin', 'Kerry'][i % 5],
        weightKg: weight.averageWeight,
        desiredPricePerKg: 4.10 + (i % 10) * 0.05,
        offeredPricePerKg: 3.95 + (i % 10) * 0.05,
        submissionDate: date,
      ));
    }
    _pricePulsesController.add(_mockPricePulses);
  }

  // --- Portfolio (Private) ---

  Stream<List<CattleEntry>> getCattleEntries(String userId) {
    return _cattleEntriesController.stream;
  }

  Future<void> addCattleEntry(String userId, CattleEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    _mockCattleEntries.add(entry);
    _cattleEntriesController.add(List.from(_mockCattleEntries));
  }

  Future<void> deleteCattleEntry(String userId, String entryId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _mockCattleEntries.removeWhere((entry) => entry.id == entryId);
    _cattleEntriesController.add(List.from(_mockCattleEntries));
  }

  // --- Price Pulse (Public) ---

  Stream<List<PricePulse>> getPricePulses() {
    // Filter to last 7 days
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final filtered = _mockPricePulses
        .where((pulse) => pulse.submissionDate.isAfter(sevenDaysAgo))
        .toList()
      ..sort((a, b) => b.submissionDate.compareTo(a.submissionDate));

    return Stream.value(filtered);
  }

  Future<void> addPricePulse(PricePulse pulse) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _mockPricePulses.add(pulse);
    _pricePulsesController.add(List.from(_mockPricePulses));
  }

  void dispose() {
    _cattleEntriesController.close();
    _pricePulsesController.close();
  }
}
