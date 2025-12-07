/// price_log_screen.dart - Personal price tracking and logging
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/price_log.dart';
import '../models/cattle_group.dart';
import '../services/price_log_service.dart';
import '../services/price_pulse_service.dart';
import '../services/analytics_service.dart';
import '../utils/logger.dart';
import '../utils/snackbar_helper.dart';
import '../utils/error_handler.dart';
import '../widgets/cards/stat_card.dart';
import '../widgets/cards/custom_card.dart';
import '../widgets/sheets/add_price_log_sheet.dart';

class PriceLogScreen extends StatefulWidget {
  const PriceLogScreen({super.key});

  @override
  State<PriceLogScreen> createState() => _PriceLogScreenState();
}

class _PriceLogScreenState extends State<PriceLogScreen> {
  List<PriceLog> _logs = [];
  PriceLogStats _stats = PriceLogStats.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();

    // Track screen view
    Future.microtask(() {
      if (mounted) {
        Provider.of<AnalyticsService>(context, listen: false)
            .logScreenView(screenName: 'Price Log');
      }
    });
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final logService = Provider.of<PriceLogService>(context, listen: false);
      final logs = await logService.loadLogs();
      final stats = await logService.getStats();

      if (!mounted) return;
      setState(() {
        _logs = logs;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading price logs', e);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (ErrorHandler.isNetworkError(e)) {
        SnackBarHelper.showErrorWithRetry(
          context,
          'Network error loading logs. Pull to refresh or tap retry.',
          _loadLogs,
        );
      } else {
        SnackBarHelper.showError(
          context,
          'Failed to load logs: ${ErrorHandler.getGenericErrorMessage(e)}',
        );
      }
    }
  }

  Future<void> _deleteLog(PriceLog log) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Price Log?'),
          content: Text(
            'Remove ${log.type.icon} ${log.type.displayName} for ${log.breed.displayName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final logService = Provider.of<PriceLogService>(context, listen: false);
      await logService.deleteLog(log.id!);

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Price log deleted');
      _loadLogs();
    } catch (e) {
      Logger.error('Error deleting price log', e);
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        'Failed to delete: ${ErrorHandler.getGenericErrorMessage(e)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLogs,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(theme, currencyFormat),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLogSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Price'),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, NumberFormat currencyFormat) {
    if (_logs.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Summary
          _buildStatsSection(currencyFormat),
          const SizedBox(height: 24),

          // Logs List
          Text(
            'Recent Activity',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...List.generate(
            _logs.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildLogCard(_logs[index], theme, currencyFormat),
            ),
          ),

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '📝',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            'No price logs yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start tracking prices you receive',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddLogSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add First Log'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.list_alt,
                label: 'Total Logs',
                value: _stats.totalLogs.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.check_circle,
                label: 'Sales',
                value: _stats.salesCompleted.toString(),
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.euro,
                label: 'Avg Price',
                value: currencyFormat.format(_stats.averagePriceSold),
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.trending_up,
                label: 'Total Value',
                value: '€${(_stats.totalValueSold / 1000).toStringAsFixed(0)}k',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogCard(
    PriceLog log,
    ThemeData theme,
    NumberFormat currencyFormat,
  ) {
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');

    return Dismissible(
      key: Key(log.id!),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete this log?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _deleteLog(log),
      child: CustomCard(
        child: InkWell(
          onTap: () {
            // TODO: Show detail view or edit sheet
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      log.type.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.type.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          Text(
                            '${log.breed.displayName} · ${log.quantity} head',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format(log.pricePerKg),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getPriceColor(log),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Details
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(
                      Icons.scale,
                      log.weightBucket.displayName,
                      Colors.blue,
                    ),
                    _buildChip(
                      Icons.location_on,
                      log.county,
                      Colors.green,
                    ),
                    _buildChip(
                      Icons.calendar_today,
                      dateFormat.format(log.date),
                      Colors.orange,
                    ),
                  ],
                ),

                if (log.source.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.store, size: 14, color: theme.textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Text(
                        log.source,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],

                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    log.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],

                // Market comparison (async loaded)
                const SizedBox(height: 12),
                FutureBuilder<double>(
                  future: _getMarketPrice(log),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(height: 20);
                    }

                    final marketPrice = snapshot.data!;
                    final comparison = log.compareToMarketPrice(marketPrice);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              comparison,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
    );
  }

  Color _getPriceColor(PriceLog log) {
    switch (log.type) {
      case PriceLogType.sale:
        return Colors.green;
      case PriceLogType.offer:
        return Colors.blue;
      case PriceLogType.inquiry:
        return Colors.orange;
    }
  }

  Future<double> _getMarketPrice(PriceLog log) async {
    try {
      final priceService = Provider.of<PricePulseService>(context, listen: false);
      return await priceService.getMedianPrice(
        breed: log.breed,
        weightBucket: log.weightBucket,
        county: log.county,
      );
    } catch (e) {
      Logger.error('Failed to get market price for comparison', e);
      return 0.0;
    }
  }

  Future<void> _showAddLogSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddPriceLogSheet(),
    );

    if (result == true && mounted) {
      _loadLogs();
    }
  }
}
