/// price_pulse_service.dart - Market price pulse submission and analytics service
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/price_pulse.dart';
import '../models/cattle_group.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';

class PricePulseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the Firestore path for public price pulses
  /// Path: pricePulses
  String _getPublicPath() {
    return 'pricePulses';
  }

  /// Get price pulses from the last 7 days as a stream
  Stream<List<PricePulse>> getPricePulses() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return _firestore
        .collection(_getPublicPath())
        .where(
          'submission_date',
          isGreaterThan: Timestamp.fromDate(sevenDaysAgo),
        )
        .orderBy('submission_date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PricePulse.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Add a new price pulse (anonymous submission)
  Future<void> addPricePulse(PricePulse pulse) async {
    try {
      // Verify user is authenticated (but don't store user ID for anonymity)
      if (_auth.currentUser == null) {
        Logger.error('User not authenticated, cannot submit pulse');
        return;
      }

      final data = pulse.toMap();

      // Convert DateTime to Timestamp for Firestore
      data['submission_date'] = Timestamp.fromDate(pulse.submissionDate);

      // Add required fields for security rules validation
      data['timestamp'] = data['submission_date']; // Alias for security rules
      data['ttl'] = pricePulseTtlSeconds; // For auto-deletion
      data['submitted_by'] = _auth.currentUser!.uid; // For security validation

      await _firestore.collection(_getPublicPath()).add(data);
      Logger.success('Price pulse submitted successfully');
    } catch (e) {
      Logger.error('Error adding price pulse', e);
    }
  }

  /// Get median price for filters
  /// Returns 0.0 if no data found
  Future<double> getMedianPrice({
    required Breed breed,
    required WeightBucket weightBucket,
    String? county,
  }) async {
    try {
      // Fetch all recent pulses (last 7 days)
      // We filter in memory to avoid complex Firestore composite indexes
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection(_getPublicPath())
          .where(
            'submission_date',
            isGreaterThan: Timestamp.fromDate(sevenDaysAgo),
          )
          .get();

      final pulses = snapshot.docs
          .map((doc) => PricePulse.fromMap(doc.data(), doc.id))
          .where((p) {
            final breedMatch = p.breed == breed;
            final weightMatch = p.weightBucket == weightBucket;
            final countyMatch = county == null || p.county == county;
            return breedMatch && weightMatch && countyMatch;
          })
          .toList();

      if (pulses.isEmpty) return 0.0;

      // Calculate median
      final prices = pulses.map((p) => p.price).toList()..sort();
      final middle = prices.length ~/ 2;
      if (prices.length % 2 == 1) {
        return prices[middle];
      } else {
        return (prices[middle - 1] + prices[middle]) / 2;
      }
    } catch (e) {
      Logger.error('Error calculating median price', e);
      return 0.0;
    }
  }

  /// Get 7-day trend data
  /// Returns daily median prices for the specified breed/weight/county
  Future<List<Map<String, dynamic>>> getTrendData({
    required Breed breed,
    required WeightBucket weightBucket,
    String? county,
  }) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection(_getPublicPath())
          .where(
            'submission_date',
            isGreaterThan: Timestamp.fromDate(sevenDaysAgo),
          )
          .get();

      // Filter and group by date
      final Map<String, List<double>> pricesByDate = {};

      for (var doc in snapshot.docs) {
        final pulse = PricePulse.fromMap(doc.data(), doc.id);

        // Apply filters
        if (pulse.breed != breed) continue;
        if (pulse.weightBucket != weightBucket) continue;
        if (county != null && pulse.county != county) continue;

        // Group by date (ignore time)
        final dateKey = '${pulse.submissionDate.year}-${pulse.submissionDate.month.toString().padLeft(2, '0')}-${pulse.submissionDate.day.toString().padLeft(2, '0')}';

        pricesByDate.putIfAbsent(dateKey, () => []);
        pricesByDate[dateKey]!.add(pulse.price);
      }

      // Calculate median for each day and sort by date
      final List<Map<String, dynamic>> trendData = [];

      for (var entry in pricesByDate.entries) {
        final prices = entry.value..sort();
        final middle = prices.length ~/ 2;
        final median = prices.length % 2 == 1
            ? prices[middle]
            : (prices[middle - 1] + prices[middle]) / 2;

        trendData.add({
          'date': DateTime.parse(entry.key),
          'price': median,
          'count': prices.length,
        });
      }

      // Sort by date ascending
      trendData.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      Logger.info('Calculated trend data: ${trendData.length} days');
      return trendData;
    } catch (e) {
      Logger.error('Error calculating trend data', e);
      return [];
    }
  }

  /// Get county price map for heatmap
  /// Returns median prices by county for the specified breed/weight
  Future<Map<String, double>> getCountyPrices({
    required Breed breed,
    required WeightBucket weightBucket,
  }) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: pricePulseDays));
      final snapshot = await _firestore
          .collection(_getPublicPath())
          .where(
            'submission_date',
            isGreaterThan: Timestamp.fromDate(sevenDaysAgo),
          )
          .get();

      // Group prices by county
      final Map<String, List<double>> pricesByCounty = {};

      for (var doc in snapshot.docs) {
        final pulse = PricePulse.fromMap(doc.data(), doc.id);

        // Apply filters
        if (pulse.breed != breed) continue;
        if (pulse.weightBucket != weightBucket) continue;

        pricesByCounty.putIfAbsent(pulse.county, () => []);
        pricesByCounty[pulse.county]!.add(pulse.price);
      }

      // Calculate median for each county
      final Map<String, double> countyMedians = {};

      for (var entry in pricesByCounty.entries) {
        final prices = entry.value..sort();
        final middle = prices.length ~/ 2;
        final median = prices.length % 2 == 1
            ? prices[middle]
            : (prices[middle - 1] + prices[middle]) / 2;

        countyMedians[entry.key] = median;
      }

      Logger.info('Calculated county prices: ${countyMedians.length} counties');
      return countyMedians;
    } catch (e) {
      Logger.error('Error calculating county prices', e);
      return {};
    }
  }

  /// Add a validation (upvote) to a price pulse
  Future<void> addValidation(String pulseId) async {
    try {
      await _firestore.collection(_getPublicPath()).doc(pulseId).update({
        'validation_count': FieldValue.increment(1),
        'last_updated': FieldValue.serverTimestamp(),
      });
      Logger.success('Validation added to pulse $pulseId');

      // Recalculate hot score after validation
      await _recalculateHotScore(pulseId);
    } catch (e) {
      Logger.error('Error adding validation', e);
      rethrow;
    }
  }

  /// Add a flag (downvote) to a price pulse
  Future<void> addFlag(String pulseId) async {
    try {
      await _firestore.collection(_getPublicPath()).doc(pulseId).update({
        'flag_count': FieldValue.increment(1),
        'last_updated': FieldValue.serverTimestamp(),
      });
      Logger.success('Flag added to pulse $pulseId');

      // Recalculate hot score after flag
      await _recalculateHotScore(pulseId);
    } catch (e) {
      Logger.error('Error adding flag', e);
      rethrow;
    }
  }

  /// Recalculate hot score using Reddit-style algorithm
  /// Formula: log10(max(abs(score), 1)) * sign(score) + (age_in_hours / time_decay_hours)
  Future<void> _recalculateHotScore(String pulseId) async {
    try {
      final doc = await _firestore.collection(_getPublicPath()).doc(pulseId).get();
      if (!doc.exists) return;

      final pulse = PricePulse.fromMap(doc.data()!, doc.id);
      final score = pulse.netScore; // validationCount - flagCount
      final ageInHours = DateTime.now().difference(pulse.submissionDate).inMinutes / 60.0;

      // Reddit-style hot score
      final absScore = score.abs();
      final sign = score > 0 ? 1 : (score < 0 ? -1 : 0);
      final order = absScore > 0 ? (absScore + 1).toDouble() : 1.0;
      final hotScore = (sign * order) - (ageInHours / timeDecayHours);

      await _firestore.collection(_getPublicPath()).doc(pulseId).update({
        'hot_score': hotScore,
      });
    } catch (e) {
      Logger.error('Error recalculating hot score', e);
    }
  }

  /// Get price pulses sorted by HOT (Reddit-style algorithm)
  /// Hot = high engagement + recency
  Stream<List<PricePulse>> getPricePulsesHot() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return _firestore
        .collection(_getPublicPath())
        .where(
          'submission_date',
          isGreaterThan: Timestamp.fromDate(sevenDaysAgo),
        )
        .orderBy('submission_date', descending: true) // Required for where clause
        .snapshots()
        .map((snapshot) {
          final pulses = snapshot.docs
              .map((doc) => PricePulse.fromMap(doc.data(), doc.id))
              .toList();

          // Sort by hot score in memory (to avoid compound index)
          pulses.sort((a, b) => b.hotScore.compareTo(a.hotScore));
          return pulses;
        });
  }

  /// Get price pulses sorted by RECENT (newest first)
  /// Recent = submission_date descending
  Stream<List<PricePulse>> getPricePulsesRecent() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return _firestore
        .collection(_getPublicPath())
        .where(
          'submission_date',
          isGreaterThan: Timestamp.fromDate(sevenDaysAgo),
        )
        .orderBy('submission_date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PricePulse.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get price pulses sorted by BEST (highest net score)
  /// Best = validationCount - flagCount (all time best)
  Stream<List<PricePulse>> getPricePulsesBest() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return _firestore
        .collection(_getPublicPath())
        .where(
          'submission_date',
          isGreaterThan: Timestamp.fromDate(sevenDaysAgo),
        )
        .orderBy('submission_date', descending: true) // Required for where clause
        .snapshots()
        .map((snapshot) {
          final pulses = snapshot.docs
              .map((doc) => PricePulse.fromMap(doc.data(), doc.id))
              .toList();

          // Sort by net score in memory (to avoid compound index)
          pulses.sort((a, b) => b.netScore.compareTo(a.netScore));
          return pulses;
        });
  }
}
