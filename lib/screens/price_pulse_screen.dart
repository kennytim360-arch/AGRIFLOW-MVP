import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/price_pulse_service.dart';
import '../models/price_pulse.dart';
import '../models/cattle_group.dart';
import '../utils/constants.dart';
import '../widgets/price_pulse_filter_bar.dart';
import '../widgets/median_band_card.dart';
import '../widgets/trend_mini_chart.dart';
import '../widgets/county_heatmap_card.dart';
import '../widgets/submit_pulse_sheet.dart';
import 'package:share_plus/share_plus.dart';

class PricePulseScreen extends StatefulWidget {
  const PricePulseScreen({super.key});

  @override
  State<PricePulseScreen> createState() => _PricePulseScreenState();
}

class _PricePulseScreenState extends State<PricePulseScreen> {
  // Filter state
  Breed _selectedBreed = Breed.charolais;
  WeightBucket _selectedWeight = WeightBucket.w600_700;
  String _selectedCounty = 'Antrim';
  bool _isAllIreland = true;

  // Auto-refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pricePulseService = Provider.of<PricePulseService>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Pulse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _handleShare,
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          PricePulseFilterBar(
            selectedBreed: _selectedBreed,
            selectedWeight: _selectedWeight,
            selectedCounty: _selectedCounty,
            isAllIreland: _isAllIreland,
            onBreedChanged: (breed) => setState(() => _selectedBreed = breed),
            onWeightChanged: (weight) =>
                setState(() => _selectedWeight = weight),
            onCountyToggle: () =>
                setState(() => _isAllIreland = !_isAllIreland),
            onCountyTap: _showCountyPicker,
          ),

          // Content
          Expanded(
            child: StreamBuilder<List<PricePulse>>(
              stream: pricePulseService.getPricePulses(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allPulses = snapshot.data ?? [];
                final filteredPulses = _filterPulses(allPulses);
                final cleanedPulses = _apply95thPercentileFilter(
                  filteredPulses,
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Median Band Card
                      MedianBandCard(
                        breed: _selectedBreed,
                        weightBucket: _selectedWeight,
                        county: _isAllIreland ? 'All Ireland' : _selectedCounty,
                        data: _calculateMedianData(cleanedPulses),
                        isLoading: false,
                      ),
                      const SizedBox(height: 16),

                      // Trend Chart
                      TrendMiniChart(
                        data: _calculateTrendData(cleanedPulses),
                        isLoading: false,
                      ),
                      const SizedBox(height: 16),

                      // County Heatmap
                      CountyHeatmapCard(
                        countyData: _calculateCountyData(allPulses),
                        nationalMedian: _calculateNationalMedian(allPulses),
                        isLoading: false,
                        onCountyTap: (county) {
                          setState(() {
                            _selectedCounty = county;
                            _isAllIreland = false;
                          });
                        },
                      ),

                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitPulseSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Submit Pulse'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // Filter pulses based on current selection
  List<PricePulse> _filterPulses(List<PricePulse> pulses) {
    return pulses.where((pulse) {
      // Match breed
      if (pulse.cattleType != _selectedBreed.displayName) return false;

      // Match weight bucket (with tolerance)
      final weightLower = _selectedWeight.averageWeight - 50;
      final weightUpper = _selectedWeight.averageWeight + 50;
      if (pulse.weightKg < weightLower || pulse.weightKg > weightUpper) {
        return false;
      }

      // Match county (if not All Ireland)
      if (!_isAllIreland && pulse.locationRegion != _selectedCounty) {
        return false;
      }

      return true;
    }).toList();
  }

  // Apply 95th percentile filter to remove outliers
  List<PricePulse> _apply95thPercentileFilter(List<PricePulse> pulses) {
    if (pulses.length < 20) return pulses; // Need enough data for filtering

    // Sort by offered price
    final sorted = List<PricePulse>.from(pulses)
      ..sort((a, b) => a.offeredPricePerKg.compareTo(b.offeredPricePerKg));

    // Remove bottom 2.5% and top 2.5%
    final removeCount = (sorted.length * 0.025).ceil();
    final startIndex = removeCount;
    final endIndex = sorted.length - removeCount;

    return sorted.sublist(startIndex, endIndex);
  }

  // Calculate median band data
  MedianBandData? _calculateMedianData(List<PricePulse> pulses) {
    if (pulses.isEmpty) return null;

    final desiredPrices = pulses.map((p) => p.desiredPricePerKg).toList()
      ..sort();
    final offeredPrices = pulses.map((p) => p.offeredPricePerKg).toList()
      ..sort();

    final desiredMedian = _calculateMedian(desiredPrices);
    final offeredMedian = _calculateMedian(offeredPrices);

    // Calculate weekly change (mock for now - would need historical data)
    final weeklyChange = _calculateWeeklyChange(pulses);

    final confidence = MedianBandData.calculateConfidence(pulses.length);

    return MedianBandData(
      desiredMedian: desiredMedian,
      offeredMedian: offeredMedian,
      bandCount: pulses.length,
      weeklyChange: weeklyChange,
      confidence: confidence,
    );
  }

  double _calculateMedian(List<double> sortedValues) {
    if (sortedValues.isEmpty) return 0.0;
    final middle = sortedValues.length ~/ 2;
    if (sortedValues.length % 2 == 1) {
      return sortedValues[middle];
    } else {
      return (sortedValues[middle - 1] + sortedValues[middle]) / 2.0;
    }
  }

  double _calculateWeeklyChange(List<PricePulse> pulses) {
    // Mock calculation - in production, compare with last week's data
    // For now, return a random-ish value based on current median
    if (pulses.isEmpty) return 0.0;
    return 3.0; // +3 cents
  }

  // Calculate 7-day trend data
  List<TrendDataPoint> _calculateTrendData(List<PricePulse> pulses) {
    if (pulses.isEmpty) return [];

    // Group by day
    final Map<DateTime, List<PricePulse>> dailyGroups = {};
    final now = DateTime.now();

    for (var i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      dailyGroups[day] = [];
    }

    for (var pulse in pulses) {
      final day = DateTime(
        pulse.submissionDate.year,
        pulse.submissionDate.month,
        pulse.submissionDate.day,
      );
      if (dailyGroups.containsKey(day)) {
        dailyGroups[day]!.add(pulse);
      }
    }

    // Calculate daily medians
    final List<TrendDataPoint> trendData = [];
    for (var entry in dailyGroups.entries) {
      if (entry.value.isEmpty) {
        // Use previous day's value or default
        final previousValue = trendData.isEmpty
            ? 4.10
            : trendData.last.offeredPrice;
        trendData.add(
          TrendDataPoint(
            date: entry.key,
            desiredPrice: previousValue + 0.10,
            offeredPrice: previousValue,
          ),
        );
      } else {
        final desiredPrices =
            entry.value.map((p) => p.desiredPricePerKg).toList()..sort();
        final offeredPrices =
            entry.value.map((p) => p.offeredPricePerKg).toList()..sort();
        trendData.add(
          TrendDataPoint(
            date: entry.key,
            desiredPrice: _calculateMedian(desiredPrices),
            offeredPrice: _calculateMedian(offeredPrices),
          ),
        );
      }
    }

    return trendData;
  }

  // Calculate county price data
  List<CountyPriceData> _calculateCountyData(List<PricePulse> allPulses) {
    // Filter for selected breed and weight only
    final filtered = allPulses.where((pulse) {
      if (pulse.cattleType != _selectedBreed.displayName) return false;
      final weightLower = _selectedWeight.averageWeight - 50;
      final weightUpper = _selectedWeight.averageWeight + 50;
      return pulse.weightKg >= weightLower && pulse.weightKg <= weightUpper;
    }).toList();

    // Group by county
    final Map<String, List<double>> countyPrices = {};
    for (var pulse in filtered) {
      countyPrices.putIfAbsent(pulse.locationRegion, () => []);
      countyPrices[pulse.locationRegion]!.add(pulse.offeredPricePerKg);
    }

    // Calculate median for each county
    final List<CountyPriceData> result = [];
    for (var entry in countyPrices.entries) {
      final prices = entry.value..sort();
      result.add(
        CountyPriceData(
          county: entry.key,
          offeredPrice: _calculateMedian(prices),
          submissionCount: prices.length,
        ),
      );
    }

    return result;
  }

  double _calculateNationalMedian(List<PricePulse> allPulses) {
    if (allPulses.isEmpty) return 4.10;
    final prices = allPulses.map((p) => p.offeredPricePerKg).toList()..sort();
    return _calculateMedian(prices);
  }

  void _showSubmitPulseSheet(BuildContext context) {
    final pricePulseService = Provider.of<PricePulseService>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubmitPulseSheet(
        onSubmit: (pulse) {
          pricePulseService.addPricePulse(pulse);
        },
      ),
    );
  }

  void _showCountyPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Select County',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: irishCounties.length,
                itemBuilder: (context, index) {
                  final county = irishCounties[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(county),
                    selected: county == _selectedCounty,
                    onTap: () {
                      setState(() => _selectedCounty = county);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleShare() {
    final data = _calculateMedianData([]);
    if (data != null) {
      final text =
          '${_selectedBreed.emoji} ${_selectedBreed.displayName} ${_selectedWeight.displayName} – offered €${data.offeredMedian.toStringAsFixed(2)} in ${_isAllIreland ? 'Ireland' : _selectedCounty} today 🐄 #ForFarmers';

      Share.share(text);
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
