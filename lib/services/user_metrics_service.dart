/// user_metrics_service.dart - Aggregates user statistics and metrics
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/cattle_group.dart';
import '../models/price_pulse.dart';
import '../models/user_metrics.dart';
import '../utils/logger.dart';

/// Service for calculating and managing user metrics and analytics
///
/// This service aggregates data from:
/// - User's portfolio (cattle groups)
/// - User's price pulse submissions
/// - User's validation/flag activity
/// - Market trends from all price pulses
///
/// The service provides insights to help users:
/// - Track portfolio performance over time
/// - See contribution statistics
/// - View market trends and predictions
/// - Understand their standing in the community
class UserMetricsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserMetrics? _cachedMetrics;
  DateTime? _lastCacheTime;
  static const _cacheValidityDuration = Duration(minutes: 5);

  /// Gets current user's aggregated metrics
  ///
  /// This method calculates real-time statistics from Firestore.
  /// Results are cached for 5 minutes to reduce reads.
  ///
  /// Returns null if user is not authenticated.
  Future<UserMetrics?> getUserMetrics() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        Logger.warning('Cannot get metrics: User not authenticated');
        return null;
      }

      // Return cached metrics if still valid
      if (_cachedMetrics != null &&
          _lastCacheTime != null &&
          DateTime.now().difference(_lastCacheTime!) < _cacheValidityDuration) {
        Logger.debug('Returning cached user metrics');
        return _cachedMetrics;
      }

      Logger.info('Calculating user metrics for user $userId');

      // Fetch portfolio data
      final portfolioSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('portfolios')
          .get();

      int totalGroups = portfolioSnapshot.docs.length;
      int totalAnimals = 0;
      double totalPortfolioValue = 0.0;

      for (var doc in portfolioSnapshot.docs) {
        final group = CattleGroup.fromMap(doc.data(), doc.id);
        totalAnimals += group.quantity;
        totalPortfolioValue += group.estimatedValue;
      }

      // Fetch user's price pulse submissions
      final pulsesSnapshot = await _firestore
          .collection('pricePulses')
          .where('submitted_by', isEqualTo: userId)
          .get();

      int pricePulsesSubmitted = pulsesSnapshot.docs.length;
      int validationsReceived = 0;
      int flagsReceived = 0;

      for (var doc in pulsesSnapshot.docs) {
        final pulse = PricePulse.fromMap(doc.data(), doc.id);
        validationsReceived += pulse.validationCount;
        flagsReceived += pulse.flagCount;
      }

      // Calculate trust score
      // Trust score = (validations - flags * 2) / max(submissions * 5, 1)
      // Range: 0.0 to 1.0+
      double trustScore = 0.0;
      if (pricePulsesSubmitted > 0) {
        final rawScore =
            (validationsReceived - flagsReceived * 2) / (pricePulsesSubmitted * 5);
        trustScore = rawScore.clamp(0.0, 1.0);
      }

      // Fetch user's validation activity
      // Note: This requires tracking in a separate collection
      // For MVP, we'll use placeholder values
      int validationsGiven = 0;
      int flagsGiven = 0;

      // TODO: Implement validation tracking collection
      // final validationSnapshot = await _firestore
      //     .collection('user_validations')
      //     .where('user_id', isEqualTo: userId)
      //     .get();

      // Get account creation time (from Firebase Auth)
      final accountCreatedAt =
          _auth.currentUser?.metadata.creationTime ?? DateTime.now();
      final lastActiveAt = DateTime.now();

      // Calculate active days
      final activeDays = DateTime.now().difference(accountCreatedAt).inDays;

      // Build portfolio value history
      // For MVP, we'll store current value
      // TODO: Implement historical tracking
      final portfolioValueHistory = <DateTime, double>{
        DateTime.now(): totalPortfolioValue,
      };

      final metrics = UserMetrics(
        totalGroups: totalGroups,
        totalAnimals: totalAnimals,
        totalPortfolioValue: totalPortfolioValue,
        pricePulsesSubmitted: pricePulsesSubmitted,
        validationsReceived: validationsReceived,
        flagsReceived: flagsReceived,
        trustScore: trustScore,
        validationsGiven: validationsGiven,
        flagsGiven: flagsGiven,
        accountCreatedAt: accountCreatedAt,
        lastActiveAt: lastActiveAt,
        activeDays: activeDays,
        portfolioValueHistory: portfolioValueHistory,
      );

      // Cache the results
      _cachedMetrics = metrics;
      _lastCacheTime = DateTime.now();

      Logger.success('User metrics calculated successfully');
      notifyListeners();

      return metrics;
    } catch (e, stackTrace) {
      Logger.error('Failed to calculate user metrics', e, stackTrace);
      return null;
    }
  }

  /// Gets market trend data for a specific breed and weight bucket
  ///
  /// Analyzes all price pulses to calculate:
  /// - Average, median, min, max prices
  /// - Trend percentage (compared to last period)
  /// - Price history over time
  ///
  /// Returns null if no data available.
  Future<MarketTrendData?> getMarketTrend({
    required Breed breed,
    required WeightBucket weightBucket,
    String? county,
  }) async {
    try {
      Logger.info(
          'Fetching market trend for ${breed.displayName} ${weightBucket.name}');

      // Build query
      Query query = _firestore
          .collection('pricePulses')
          .where('breed', isEqualTo: breed.name)
          .where('weight_bucket', isEqualTo: weightBucket.name);

      if (county != null) {
        query = query.where('county', isEqualTo: county);
      }

      // Fetch last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      query = query
          .where('submission_date', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('submission_date', descending: true);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        Logger.warning('No market data available for ${breed.displayName}');
        return null;
      }

      // Extract prices
      final prices = <double>[];
      final priceHistory = <DateTime, double>{};

      for (var doc in snapshot.docs) {
        final pulse = PricePulse.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        prices.add(pulse.price);

        // Group by date (ignoring time)
        final date = DateTime(
          pulse.submissionDate.year,
          pulse.submissionDate.month,
          pulse.submissionDate.day,
        );

        // Calculate average for that day
        if (!priceHistory.containsKey(date)) {
          priceHistory[date] = pulse.price;
        } else {
          priceHistory[date] = (priceHistory[date]! + pulse.price) / 2;
        }
      }

      // Calculate statistics
      prices.sort();
      final averagePrice = prices.reduce((a, b) => a + b) / prices.length;
      final medianPrice = prices[prices.length ~/ 2];
      final minPrice = prices.first;
      final maxPrice = prices.last;
      final submissionCount = prices.length;

      // Calculate trend (compare first half to second half)
      final midpoint = prices.length ~/ 2;
      final oldPrices = prices.sublist(0, midpoint);
      final newPrices = prices.sublist(midpoint);

      final oldAvg = oldPrices.reduce((a, b) => a + b) / oldPrices.length;
      final newAvg = newPrices.reduce((a, b) => a + b) / newPrices.length;

      final trendPercentage = (newAvg - oldAvg) / oldAvg;

      final trendData = MarketTrendData(
        breed: breed.displayName,
        weightBucket: weightBucket.name,
        county: county,
        averagePrice: averagePrice,
        medianPrice: medianPrice,
        minPrice: minPrice,
        maxPrice: maxPrice,
        submissionCount: submissionCount,
        trendPercentage: trendPercentage,
        priceHistory: priceHistory,
      );

      Logger.success('Market trend calculated: ${trendData.trendDescription}');
      return trendData;
    } catch (e, stackTrace) {
      Logger.error('Failed to calculate market trend', e, stackTrace);
      return null;
    }
  }

  /// Gets market trends for all popular breed/weight combinations
  ///
  /// Returns a list of trend data for the most active market segments.
  /// Useful for the Market Trends dashboard page.
  Future<List<MarketTrendData>> getPopularMarketTrends() async {
    try {
      Logger.info('Fetching popular market trends');

      final trends = <MarketTrendData>[];

      // Popular combinations (most common in Ireland)
      final popularCombinations = [
        (Breed.charolais, WeightBucket.w600_700),
        (Breed.angus, WeightBucket.w600_700),
        (Breed.limousin, WeightBucket.w600_700),
        (Breed.hereford, WeightBucket.w500_600),
        (Breed.belgianBlue, WeightBucket.w600_700),
      ];

      for (var combo in popularCombinations) {
        final trend = await getMarketTrend(
          breed: combo.$1,
          weightBucket: combo.$2,
        );
        if (trend != null) {
          trends.add(trend);
        }
      }

      Logger.success('Fetched ${trends.length} popular market trends');
      return trends;
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch popular market trends', e, stackTrace);
      return [];
    }
  }

  /// Clears the metrics cache
  ///
  /// Use this when user makes changes that affect metrics
  /// (e.g., adding a cattle group, submitting price pulse)
  void clearCache() {
    _cachedMetrics = null;
    _lastCacheTime = null;
    Logger.debug('Metrics cache cleared');
    notifyListeners();
  }

  /// Saves portfolio value snapshot for historical tracking
  ///
  /// Call this periodically (e.g., daily) to build value history over time.
  Future<void> savePortfolioValueSnapshot(double value) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final today = DateTime.now();
      final dateKey = DateTime(today.year, today.month, today.day);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('portfolio_history')
          .doc(dateKey.toIso8601String())
          .set({
        'date': Timestamp.fromDate(dateKey),
        'value': value,
      });

      Logger.success('Portfolio value snapshot saved: €${value.toStringAsFixed(2)}');
      clearCache(); // Invalidate cache
    } catch (e, stackTrace) {
      Logger.error('Failed to save portfolio value snapshot', e, stackTrace);
    }
  }

  /// Loads portfolio value history from Firestore
  ///
  /// Returns a map of date → value for the last N days.
  Future<Map<DateTime, double>> getPortfolioValueHistory({int days = 30}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('portfolio_history')
          .where('date', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('date', descending: false)
          .get();

      final history = <DateTime, double>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final value = (data['value'] as num).toDouble();
        history[date] = value;
      }

      Logger.info('Loaded ${history.length} days of portfolio history');
      return history;
    } catch (e, stackTrace) {
      Logger.error('Failed to load portfolio value history', e, stackTrace);
      return {};
    }
  }
}
