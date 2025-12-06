/// user_metrics_screen.dart - User statistics and performance metrics
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/user_metrics.dart';
import '../services/user_metrics_service.dart';
import '../services/analytics_service.dart';
import '../utils/logger.dart';
import '../utils/snackbar_helper.dart';
import '../utils/error_handler.dart';
import '../widgets/cards/stat_card.dart';
import '../widgets/cards/custom_card.dart';

class UserMetricsScreen extends StatefulWidget {
  const UserMetricsScreen({super.key});

  @override
  State<UserMetricsScreen> createState() => _UserMetricsScreenState();
}

class _UserMetricsScreenState extends State<UserMetricsScreen> {
  UserMetrics? _metrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();

    // Track screen view
    Future.microtask(() {
      if (mounted) {
        Provider.of<AnalyticsService>(context, listen: false)
            .logScreenView(screenName: 'User Metrics');
      }
    });
  }

  Future<void> _loadMetrics() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final metricsService = Provider.of<UserMetricsService>(
        context,
        listen: false,
      );
      final metrics = await metricsService.getUserMetrics();

      if (!mounted) return;
      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading user metrics', e);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (ErrorHandler.isNetworkError(e)) {
        SnackBarHelper.showErrorWithRetry(
          context,
          'Network error loading metrics. Pull to refresh or tap retry.',
          _loadMetrics,
        );
      } else {
        SnackBarHelper.showError(
          context,
          'Failed to load metrics: ${ErrorHandler.getGenericErrorMessage(e)}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Metrics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadMetrics,
            tooltip: 'Refresh metrics',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMetrics,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _metrics == null
                ? _buildErrorState()
                : _buildMetricsContent(theme),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Unable to load metrics',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadMetrics,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsContent(ThemeData theme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Section
          _buildSectionHeader('Portfolio Overview', Icons.dashboard),
          const SizedBox(height: 12),
          _buildPortfolioOverview(theme),
          const SizedBox(height: 24),

          // Contribution Stats
          _buildSectionHeader('Contribution Stats', Icons.people),
          const SizedBox(height: 12),
          _buildContributionStats(theme),
          const SizedBox(height: 24),

          // Trust Badge
          _buildSectionHeader('Community Standing', Icons.verified),
          const SizedBox(height: 12),
          _buildTrustBadge(theme),
          const SizedBox(height: 24),

          // Portfolio Performance Chart
          if (_metrics!.portfolioValueHistory.isNotEmpty) ...[
            _buildSectionHeader('Portfolio Performance', Icons.trending_up),
            const SizedBox(height: 12),
            _buildPortfolioChart(theme),
            const SizedBox(height: 24),
          ],

          // Activity Timeline
          _buildSectionHeader('Activity', Icons.timeline),
          const SizedBox(height: 12),
          _buildActivityTimeline(theme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioOverview(ThemeData theme) {
    final currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.groups,
            label: 'Groups',
            value: _metrics!.totalGroups.toString(),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.pets,
            label: 'Animals',
            value: _metrics!.totalAnimals.toString(),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.euro,
            label: 'Value',
            value: currencyFormat.format(_metrics!.totalPortfolioValue),
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildContributionStats(ThemeData theme) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow(
              'Price Pulses Submitted',
              _metrics!.pricePulsesSubmitted.toString(),
              Icons.send,
              Colors.blue,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Validations Received',
              _metrics!.validationsReceived.toString(),
              Icons.thumb_up,
              Colors.green,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Flags Received',
              _metrics!.flagsReceived.toString(),
              Icons.flag,
              Colors.red,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Trust Score',
              '${(_metrics!.trustScore * 100).toStringAsFixed(1)}%',
              Icons.verified_user,
              _getTrustScoreColor(_metrics!.trustScore),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadge(ThemeData theme) {
    final trustLevel = _metrics!.trustLevel;
    final badgeColor = _getTrustLevelColor(trustLevel);
    final badgeIcon = _getTrustLevelIcon(trustLevel);

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                badgeIcon,
                size: 48,
                color: badgeColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              trustLevel,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getTrustLevelDescription(trustLevel),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioChart(ThemeData theme) {
    final history = _metrics!.portfolioValueHistory;
    if (history.isEmpty) return const SizedBox.shrink();

    // Sort by date
    final sortedEntries = history.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Build spots for chart
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedEntries[i].value));
    }

    final maxValue = sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = sortedEntries.map((e) => e.value).reduce((a, b) => a < b ? a : b);

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Portfolio Value Over Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '€${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
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
                  borderData: FlBorderData(show: true),
                  minY: minValue * 0.9,
                  maxY: maxValue * 1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTimeline(ThemeData theme) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTimelineItem(
              'Account Created',
              dateFormat.format(_metrics!.accountCreatedAt),
              Icons.person_add,
              Colors.blue,
            ),
            const Divider(height: 24),
            _buildTimelineItem(
              'Last Active',
              dateFormat.format(_metrics!.lastActiveAt),
              Icons.access_time,
              Colors.green,
            ),
            const Divider(height: 24),
            _buildTimelineItem(
              'Active Days',
              '${_metrics!.activeDays} days',
              Icons.calendar_today,
              Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getTrustScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.amber;
    return Colors.grey;
  }

  Color _getTrustLevelColor(String level) {
    switch (level) {
      case 'Expert':
        return Colors.purple;
      case 'Verified':
        return Colors.green;
      case 'Trusted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrustLevelIcon(String level) {
    switch (level) {
      case 'Expert':
        return Icons.star;
      case 'Verified':
        return Icons.verified;
      case 'Trusted':
        return Icons.check_circle;
      default:
        return Icons.person;
    }
  }

  String _getTrustLevelDescription(String level) {
    switch (level) {
      case 'Expert':
        return 'Top contributor with excellent track record';
      case 'Verified':
        return 'Reliable contributor with good validations';
      case 'Trusted':
        return 'Active contributor building reputation';
      default:
        return 'New to the community - submit more pulses to build trust';
    }
  }
}
