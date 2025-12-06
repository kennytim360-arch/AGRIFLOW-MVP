/// dashboard_screen.dart - Home screen with herd overview and insights
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agriflow/models/cattle_group.dart';
import 'package:agriflow/services/portfolio_service.dart';
import 'package:agriflow/services/price_pulse_service.dart';
import 'package:agriflow/services/analytics_service.dart';
import 'package:agriflow/utils/constants.dart';
import 'package:agriflow/utils/logger.dart';
import 'package:agriflow/utils/snackbar_helper.dart';
import 'package:agriflow/utils/error_handler.dart';
import 'package:agriflow/widgets/cards/stat_card.dart';
import 'package:agriflow/widgets/cards/custom_card.dart';
import 'package:agriflow/screens/user_metrics_screen.dart';
import 'package:agriflow/screens/market_trends_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<CattleGroup> _groups = [];
  Map<String, double> _marketPrices = {}; // Cache for market prices
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Track screen view
    Future.microtask(() {
      if (mounted) {
        Provider.of<AnalyticsService>(context, listen: false)
            .logScreenView(screenName: 'Dashboard');
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Load groups
      final portfolioService = Provider.of<PortfolioService>(
        context,
        listen: false,
      );
      final groups = await portfolioService.loadGroups();

      // 2. Load market prices for each group
      final priceService = Provider.of<PricePulseService>(
        context,
        listen: false,
      );
      final Map<String, double> prices = {};

      for (var group in groups) {
        // Use group ID as key, or generate a unique key based on breed/weight/county
        // Here we just map by group ID for simplicity in the build method
        if (group.id != null) {
          final price = await priceService.getMedianPrice(
            breed: group.breed,
            weightBucket: group.weightBucket,
            county: group.county,
          );
          prices[group.id!] = price;
        }
      }

      if (!mounted) return;
      setState(() {
        _groups = groups;
        _marketPrices = prices;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading dashboard data', e);
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Show error with retry option if it's a network error
      if (ErrorHandler.isNetworkError(e)) {
        SnackBarHelper.showErrorWithRetry(
          context,
          'Network error loading dashboard. Pull to refresh or tap retry.',
          _loadData,
        );
      } else {
        SnackBarHelper.showError(
          context,
          'Failed to load dashboard: ${ErrorHandler.getGenericErrorMessage(e)}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate metrics
    int totalHead = 0;
    double totalValue = 0;
    double totalWeight = 0;
    double avgPriceTarget = 0;

    for (var group in _groups) {
      // Use fetched market price, or fallback to default if 0.0 (no data)
      double marketPrice = 0.0;
      if (group.id != null && _marketPrices.containsKey(group.id)) {
        marketPrice = _marketPrices[group.id!]!;
      }

      // If no market data, use default constant
      if (marketPrice == 0.0) {
        marketPrice = defaultDesiredPrice;
      }

      totalHead += group.quantity;
      totalValue += group.calculateKillOutValue(marketPrice);
      totalWeight += group.totalWeight;
      avgPriceTarget += group.desiredPricePerKg * group.quantity;
    }

    if (totalHead > 0) {
      avgPriceTarget = avgPriceTarget / totalHead;
    }

    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // App Bar with Greeting
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        greeting,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Date
                        Text(
                          _formatDate(now),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),

                        // Quick Stats
                        if (_groups.isNotEmpty) ...[
                          Text(
                            'Your Herd at a Glance',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  icon: Icons.pets,
                                  label: 'Total Head',
                                  value: '$totalHead',
                                  iconColor: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCard(
                                  icon: Icons.euro,
                                  label: 'Est. Value',
                                  value:
                                      '€${(totalValue / 1000).toStringAsFixed(0)}k',
                                  iconColor: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  icon: Icons.scale,
                                  label: 'Total Weight',
                                  value:
                                      '${(totalWeight / 1000).toStringAsFixed(1)}t',
                                  iconColor: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCard(
                                  icon: Icons.trending_up,
                                  label: 'Avg Target',
                                  value:
                                      '€${avgPriceTarget.toStringAsFixed(2)}',
                                  iconColor: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Today's Insights
                          Text(
                            'Today\'s Insights',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildInsightCard(
                            context,
                            '📊 Market Watch',
                            'Charolais prices holding steady at €4.10/kg across most counties.',
                            Colors.blue.shade50,
                            Colors.blue.shade700,
                          ),
                          const SizedBox(height: 12),
                          _buildInsightCard(
                            context,
                            '🌤️ Weather Alert',
                            'Clear skies expected this week - good conditions for moving cattle.',
                            Colors.green.shade50,
                            Colors.green.shade700,
                          ),
                          const SizedBox(height: 12),
                          _buildInsightCard(
                            context,
                            '💡 Tip of the Day',
                            'Check Price Pulse before making selling decisions - prices vary by county!',
                            Colors.orange.shade50,
                            Colors.orange.shade700,
                          ),
                          const SizedBox(height: 32),

                          // Analytics Quick Access
                          Text(
                            'Analytics',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildAnalyticsCard(
                                  context,
                                  'My Metrics',
                                  'View your stats',
                                  Icons.analytics,
                                  Colors.purple,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const UserMetricsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildAnalyticsCard(
                                  context,
                                  'Market Trends',
                                  'See price trends',
                                  Icons.trending_up,
                                  Colors.green,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MarketTrendsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Empty State
                          CustomCard(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  const Text(
                                    '🐄',
                                    style: TextStyle(fontSize: 64),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Welcome to AgriFlow!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start by adding your cattle groups in the Portfolio tab.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 80), // Space for bottom nav
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    String title,
    String message,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return CustomCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'Good Morning 🌅';
    } else if (hour < 17) {
      return 'Good Afternoon ☀️';
    } else {
      return 'Good Evening 🌙';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
