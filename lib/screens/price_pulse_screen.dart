/// price_pulse_screen.dart - Market price pulse and analytics screen
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/price_pulse_service.dart';
import '../services/analytics_service.dart';
import '../models/price_pulse.dart';
import '../models/cattle_group.dart';
import '../utils/constants.dart';
import '../widgets/sheets/price_pulse_filter_bar.dart';
import '../widgets/cards/median_band_card.dart';
import '../widgets/cards/trend_mini_chart.dart';
import '../widgets/cards/county_heatmap_card.dart';
import '../widgets/cards/price_pulse_feed_card.dart';
import '../widgets/sheets/submit_pulse_sheet.dart';
import 'package:share_plus/share_plus.dart';

class PricePulseScreen extends StatefulWidget {
  const PricePulseScreen({super.key});

  @override
  State<PricePulseScreen> createState() => _PricePulseScreenState();
}

class _PricePulseScreenState extends State<PricePulseScreen>
    with SingleTickerProviderStateMixin {
  // Filter state
  Breed _selectedBreed = Breed.charolais;
  WeightBucket _selectedWeight = WeightBucket.w600_700;
  String _selectedCounty = 'Antrim';
  bool _isAllIreland = true;

  // Sorting state
  late TabController _tabController;
  String _currentSort = 'hot'; // hot, recent, best

  // Auto-refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Track screen view
    Future.microtask(() {
      if (mounted) {
        Provider.of<AnalyticsService>(context, listen: false)
            .logScreenView(screenName: 'PricePulse');
      }
    });

    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentSort = ['hot', 'recent', 'best'][_tabController.index];
      });

      // Log analytics
      Provider.of<AnalyticsService>(context, listen: false)
          .logPricePulseSortChanged(sortType: _currentSort);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricePulseService = Provider.of<PricePulseService>(
      context,
      listen: false,
    );

    // Choose stream based on current sort
    Stream<List<PricePulse>> stream;
    switch (_currentSort) {
      case 'hot':
        stream = pricePulseService.getPricePulsesHot();
        break;
      case 'recent':
        stream = pricePulseService.getPricePulsesRecent();
        break;
      case 'best':
        stream = pricePulseService.getPricePulsesBest();
        break;
      default:
        stream = pricePulseService.getPricePulsesHot();
    }

    return StreamBuilder<List<PricePulse>>(
      stream: stream,
      builder: (context, snapshot) {
        // Prepare data for the UI
        List<PricePulse> allPulses = [];
        List<PricePulse> filteredPulses = [];
        List<PricePulse> cleanedPulses = [];
        MedianBandData? medianData;

        if (snapshot.hasData) {
          allPulses = snapshot.data!;
          filteredPulses = _filterPulses(allPulses);
          cleanedPulses = _apply95thPercentileFilter(filteredPulses);
          medianData = _calculateMedianData(cleanedPulses);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Price Pulse'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _handleShare(medianData),
                tooltip: 'Share',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() {}),
                tooltip: 'Refresh',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(
                  icon: Icon(Icons.local_fire_department),
                  text: 'Hot',
                ),
                Tab(
                  icon: Icon(Icons.access_time),
                  text: 'Recent',
                ),
                Tab(
                  icon: Icon(Icons.star),
                  text: 'Best',
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Compact Filter Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: InkWell(
                  onTap: _showFilterSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_selectedBreed.emoji} ${_selectedBreed.displayName} • ${_selectedWeight.displayName} • ${_isAllIreland ? "🇮🇪 All Ireland" : "📍 $_selectedCounty"}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (filteredPulses.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
                        itemCount: filteredPulses.length + 4, // +4 for analytics cards
                        itemBuilder: (context, index) {
                          // First show individual price feed cards
                          if (index < filteredPulses.length) {
                            return PricePulseFeedCard(
                              pulse: filteredPulses[index],
                            );
                          }

                          // After feed, show aggregated analytics
                          final analyticsIndex = index - filteredPulses.length;

                          if (analyticsIndex == 0) {
                            // Section divider
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 24,
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'Market Analytics',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                          ),
                                    ),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                            );
                          } else if (analyticsIndex == 1) {
                            // Median Band Card
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: MedianBandCard(
                                breed: _selectedBreed,
                                weightBucket: _selectedWeight,
                                county: _isAllIreland
                                    ? 'All Ireland'
                                    : _selectedCounty,
                                data: medianData,
                                isLoading: false,
                              ),
                            );
                          } else if (analyticsIndex == 2) {
                            // Trend Chart
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: TrendMiniChart(
                                data: _calculateTrendData(cleanedPulses),
                                isLoading: false,
                              ),
                            );
                          } else if (analyticsIndex == 3) {
                            // County Heatmap
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: CountyHeatmapCard(
                                countyData: _calculateCountyData(allPulses),
                                nationalMedian:
                                    _calculateNationalMedian(allPulses),
                                isLoading: false,
                                onCountyTap: (county) {
                                  setState(() {
                                    _selectedCounty = county;
                                    _isAllIreland = false;
                                  });
                                },
                              ),
                            );
                          }

                          return const SizedBox.shrink();
                        },
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
      },
    );
  }

  // Filter pulses based on current selection
  List<PricePulse> _filterPulses(List<PricePulse> pulses) {
    return pulses.where((pulse) {
      // Match breed
      if (pulse.breed != _selectedBreed) return false;

      // Match weight bucket
      if (pulse.weightBucket != _selectedWeight) return false;

      // Match county (if not All Ireland)
      if (!_isAllIreland && pulse.county != _selectedCounty) {
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
      ..sort((a, b) => a.price.compareTo(b.price));

    // Remove bottom 2.5% and top 2.5%
    final removeCount = (sorted.length * 0.025).ceil();
    final startIndex = removeCount;
    final endIndex = sorted.length - removeCount;

    return sorted.sublist(startIndex, endIndex);
  }

  // Calculate median band data
  MedianBandData? _calculateMedianData(List<PricePulse> pulses) {
    if (pulses.isEmpty) return null;

    final desiredPrices = pulses.map((p) => p.desiredPrice).toList()..sort();
    final offeredPrices = pulses.map((p) => p.price).toList()..sort();

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
        final desiredPrices = entry.value.map((p) => p.desiredPrice).toList()
          ..sort();
        final offeredPrices = entry.value.map((p) => p.price).toList()..sort();
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
      if (pulse.breed != _selectedBreed) return false;
      if (pulse.weightBucket != _selectedWeight) return false;
      return true;
    }).toList();

    // Group by county
    final Map<String, List<double>> countyPrices = {};
    for (var pulse in filtered) {
      countyPrices.putIfAbsent(pulse.county, () => []);
      countyPrices[pulse.county]!.add(pulse.price);
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
    final prices = allPulses.map((p) => p.price).toList()..sort();
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Filter Prices',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Filter Content
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: PricePulseFilterBar(
                selectedBreed: _selectedBreed,
                selectedWeight: _selectedWeight,
                selectedCounty: _selectedCounty,
                isAllIreland: _isAllIreland,
                onBreedChanged: (breed) {
                  setState(() => _selectedBreed = breed);
                },
                onWeightChanged: (weight) {
                  setState(() => _selectedWeight = weight);
                },
                onCountyToggle: () {
                  setState(() => _isAllIreland = !_isAllIreland);
                },
                onCountyTap: () {
                  Navigator.pop(context);
                  _showCountyPicker();
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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

  void _handleShare(MedianBandData? data) {
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feed_outlined,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No prices yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to submit a price for ${_selectedBreed.name} ${_selectedWeight.name}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showSubmitPulseSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Submit First Price'),
            ),
          ],
        ),
      ),
    );
  }
}
