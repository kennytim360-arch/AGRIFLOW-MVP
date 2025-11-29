import 'package:flutter/material.dart';
import 'package:agriflow/models/cattle_group.dart';
import 'package:agriflow/widgets/custom_card.dart';
import 'package:agriflow/services/portfolio_service.dart';
import 'package:agriflow/utils/constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final PortfolioService _portfolioService = PortfolioService();

  // State
  double _liveWeight = 520; // kg
  double _targetWeight = 650; // kg (Factory optimal)
  double _adg = 1.0; // kg/day
  double _feedCostPerDay = 1.80; // €/day

  // Mock data for margin calculation
  final double _currentMedianPrice = 4.10; // €/kg

  @override
  Widget build(BuildContext context) {
    // Calculations
    final daysToTarget = _calculateDaysToTarget();
    final targetDate = DateTime.now().add(Duration(days: daysToTarget));
    final totalFeedCost = daysToTarget * _feedCostPerDay;

    // Margin calculation (Simplified: Value at target - Value now - Feed Cost)
    // Value Now = Live Weight * Median Price
    // Value Target = Target Weight * Median Price (assuming price holds)
    // This is a "Margin if moved" vs "Margin if held" comparison?
    // The prompt says "Margin if moved: €X vs today's median".
    // This implies: (Target Value - Feed Cost) - (Current Value)
    final currentVal = _liveWeight * _currentMedianPrice;
    final targetVal = _targetWeight * _currentMedianPrice;
    final margin = targetVal - totalFeedCost - currentVal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time-to-Kill Calculator'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Main "Time to Kill" Card
                  CustomCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🕒', style: TextStyle(fontSize: 32)),
                            const SizedBox(width: 12),
                            Text(
                              'Time to Kill',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Live Weight Slider
                        _buildWeightRow(
                          context,
                          'Live weight',
                          '${_liveWeight.toInt()} kg',
                          '⚖️',
                          isEditable: true,
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 12,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 16,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 32,
                            ),
                            activeTrackColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            thumbColor: Theme.of(context).colorScheme.primary,
                          ),
                          child: Slider(
                            value: _liveWeight,
                            min: 400,
                            max: 900,
                            divisions: 50,
                            onChanged: (val) =>
                                setState(() => _liveWeight = val),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Target Weight Slider
                        _buildWeightRow(
                          context,
                          'Target weight',
                          '${_targetWeight.toInt()} kg',
                          '🎯',
                          subtitle: 'optimal 600-700 kg factory window',
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 12,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 16,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 32,
                            ),
                            activeTrackColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            thumbColor: Theme.of(context).colorScheme.primary,
                          ),
                          child: Slider(
                            value: _targetWeight,
                            min: 500,
                            max: 800,
                            divisions: 30,
                            onChanged: (val) =>
                                setState(() => _targetWeight = val),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ADG Slider
                        _buildWeightRow(
                          context,
                          'ADG',
                          '${_adg.toStringAsFixed(1)} kg/day',
                          '📈',
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 12,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 16,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 32,
                            ),
                            activeTrackColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            thumbColor: Theme.of(context).colorScheme.primary,
                          ),
                          child: Slider(
                            value: _adg,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            onChanged: (val) => setState(() => _adg = val),
                          ),
                        ),

                        const Divider(height: 48, thickness: 1),

                        // Results
                        _buildResultRow(
                          context,
                          'Days to target:',
                          '$daysToTarget days',
                          '📅',
                          highlight: true,
                          trailing: Text(
                            DateFormat('d MMM yyyy').format(targetDate),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Feed Cost Slider
                        _buildResultRow(
                          context,
                          'Feed cost:',
                          '€${totalFeedCost.toStringAsFixed(0)}',
                          '💰',
                          subtitle:
                              '$daysToTarget d × €${_feedCostPerDay.toStringAsFixed(2)}/day',
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 8,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 24,
                            ),
                            activeTrackColor: Colors.orange,
                            thumbColor: Colors.orange,
                            inactiveTrackColor: Colors.orange.withOpacity(0.2),
                          ),
                          child: Slider(
                            value: _feedCostPerDay,
                            min: 0.5,
                            max: 5.0,
                            divisions: 45,
                            onChanged: (val) =>
                                setState(() => _feedCostPerDay = val),
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildResultRow(
                          context,
                          'Margin if moved:',
                          '€${margin.toStringAsFixed(0)}',
                          '💚',
                          subtitle: 'vs today\'s median',
                          valueColor: margin >= 0 ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _shareCalculation(targetDate, totalFeedCost),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _addToPortfolio(targetDate, totalFeedCost),
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save to Portfolio'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightRow(
    BuildContext context,
    String label,
    String value,
    String emoji, {
    String? subtitle,
    bool isEditable = false,
    bool showEditIcon = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (showEditIcon) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
                ],
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isEditable
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultRow(
    BuildContext context,
    String label,
    String value,
    String emoji, {
    String? subtitle,
    bool highlight = false,
    Widget? trailing,
    Color? valueColor,
    bool showEditIcon = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (showEditIcon) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
                  ],
                ],
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color:
                    valueColor ??
                    (highlight ? Theme.of(context).colorScheme.primary : null),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ],
    );
  }

  int _calculateDaysToTarget() {
    if (_targetWeight <= _liveWeight) return 0;
    return ((_targetWeight - _liveWeight) / _adg).ceil();
  }

  void _shareCalculation(DateTime targetDate, double feedCost) {
    final dateStr = DateFormat('d MMM').format(targetDate);
    final text =
        '${_liveWeight.toInt()} kg steer – factory-ready $dateStr, feed cost €${feedCost.toStringAsFixed(0)} 💰 #ForFarmers';
    Share.share(text);
  }

  Future<void> _addToPortfolio(DateTime targetDate, double feedCost) async {
    // Create a cattle group from the calculation
    // Note: This is a simplified addition, user might want to edit details later
    final group = CattleGroup(
      breed: Breed.charolais, // Default
      quantity: 1,
      weightBucket: _getWeightBucket(_liveWeight),
      county: 'Cork', // Default
      desiredPricePerKg: 4.20, // Default
    );

    await _portfolioService.addGroup(group);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Saved to Portfolio!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  WeightBucket _getWeightBucket(double weight) {
    if (weight < 500) return WeightBucket.w400_500;
    if (weight < 600) return WeightBucket.w500_600;
    if (weight < 700) return WeightBucket.w600_700;
    return WeightBucket.w700Plus;
  }
}
