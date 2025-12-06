/// market_trends_screen.dart - Market intelligence and trend analysis
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/user_metrics.dart';
import '../models/cattle_group.dart';
import '../services/user_metrics_service.dart';
import '../services/analytics_service.dart';
import '../utils/logger.dart';
import '../utils/snackbar_helper.dart';
import '../utils/error_handler.dart';
import '../widgets/cards/custom_card.dart';

class MarketTrendsScreen extends StatefulWidget {
  const MarketTrendsScreen({super.key});

  @override
  State<MarketTrendsScreen> createState() => _MarketTrendsScreenState();
}

class _MarketTrendsScreenState extends State<MarketTrendsScreen> {
  List<MarketTrendData> _trends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrends();

    // Track screen view
    Future.microtask(() {
      if (mounted) {
        Provider.of<AnalyticsService>(context, listen: false)
            .logScreenView(screenName: 'Market Trends');
      }
    });
  }

  Future<void> _loadTrends() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final metricsService = Provider.of<UserMetricsService>(
        context,
        listen: false,
      );
      final trends = await metricsService.getPopularMarketTrends();

      if (!mounted) return;
      setState(() {
        _trends = trends;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading market trends', e);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (ErrorHandler.isNetworkError(e)) {
        SnackBarHelper.showErrorWithRetry(
          context,
          'Network error loading trends. Pull to refresh or tap retry.',
          _loadTrends,
        );
      } else {
        SnackBarHelper.showError(
          context,
          'Failed to load trends: ${ErrorHandler.getGenericErrorMessage(e)}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Trends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTrends,
            tooltip: 'Refresh trends',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrends,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _trends.isEmpty
                ? _buildEmptyState()
                : _buildTrendsContent(theme),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.trending_up, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No market data available yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Submit price pulses to see trends',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadTrends,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsContent(ThemeData theme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Popular Markets',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time price trends from across Ireland',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),

          // Trend Cards
          ...List.generate(
            _trends.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTrendCard(_trends[index], theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(MarketTrendData trend, ThemeData theme) {
    final currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trend.breed,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatWeightBucket(trend.weightBucket),
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                // Trend Indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTrendColor(trend).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trend.trendIcon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(trend.trendPercentage * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getTrendColor(trend),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price Statistics
            Row(
              children: [
                Expanded(
                  child: _buildPriceStat(
                    'Median',
                    currencyFormat.format(trend.medianPrice),
                    Icons.show_chart,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPriceStat(
                    'Average',
                    currencyFormat.format(trend.averagePrice),
                    Icons.analytics,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPriceStat(
                    'Min',
                    currencyFormat.format(trend.minPrice),
                    Icons.arrow_downward,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPriceStat(
                    'Max',
                    currencyFormat.format(trend.maxPrice),
                    Icons.arrow_upward,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Submission Count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.dataset,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${trend.submissionCount} submissions',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Price History Chart (if available)
            if (trend.priceHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildMiniChart(trend, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(MarketTrendData trend, ThemeData theme) {
    final sortedEntries = trend.priceHistory.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (sortedEntries.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedEntries[i].value));
    }

    final maxValue = sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = sortedEntries.map((e) => e.value).reduce((a, b) => a < b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '30-Day Price History',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '€${value.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: spots.length > 7 ? (spots.length / 7).ceilToDouble() : 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < sortedEntries.length) {
                        final date = sortedEntries[value.toInt()].key;
                        return Text(
                          DateFormat('MM/dd').format(date),
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: minValue * 0.95,
              maxY: maxValue * 1.05,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: _getTrendColor(trend),
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: _getTrendColor(trend),
                        strokeWidth: 0,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _getTrendColor(trend).withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getTrendColor(MarketTrendData trend) {
    if (trend.isTrendingUp) return Colors.green;
    if (trend.isTrendingDown) return Colors.red;
    return Colors.grey;
  }

  String _formatWeightBucket(String bucket) {
    // Convert from enum name to display string
    final weights = {
      'w400_500': '400-500 kg',
      'w500_600': '500-600 kg',
      'w600_700': '600-700 kg',
      'w700_plus': '700+ kg',
    };
    return weights[bucket] ?? bucket;
  }
}
