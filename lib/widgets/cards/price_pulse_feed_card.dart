/// price_pulse_feed_card.dart - Individual price pulse card for social feed
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
/// Displays a single price submission with validation buttons
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/price_pulse.dart';
import '../../models/cattle_group.dart';
import '../../services/price_pulse_service.dart';
import '../../services/validation_tracker_service.dart';
import '../../services/analytics_service.dart';

class PricePulseFeedCard extends StatefulWidget {
  final PricePulse pulse;

  const PricePulseFeedCard({
    super.key,
    required this.pulse,
  });

  @override
  State<PricePulseFeedCard> createState() => _PricePulseFeedCardState();
}

class _PricePulseFeedCardState extends State<PricePulseFeedCard> {
  bool _isValidated = false;
  bool _isFlagged = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadValidationStatus();
  }

  Future<void> _loadValidationStatus() async {
    if (widget.pulse.id == null) return;

    final tracker = context.read<ValidationTrackerService>();
    final validated = await tracker.hasValidated(widget.pulse.id!);
    final flagged = await tracker.hasFlagged(widget.pulse.id!);

    if (mounted) {
      setState(() {
        _isValidated = validated;
        _isFlagged = flagged;
      });
    }
  }

  Future<void> _handleValidation() async {
    if (widget.pulse.id == null || _isLoading) return;

    final tracker = context.read<ValidationTrackerService>();
    final pricePulseService = context.read<PricePulseService>();
    final analytics = context.read<AnalyticsService>();

    // Check rate limiting
    final canValidate = await tracker.canValidate();
    if (!canValidate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait a moment before validating again'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isValidated) {
        // Remove validation (undo)
        // Note: This is a local-only operation, we don't decrement server count
        await tracker.removeValidation(widget.pulse.id!);
        setState(() => _isValidated = false);
      } else {
        // Add validation
        await pricePulseService.addValidation(widget.pulse.id!);
        await tracker.markValidated(widget.pulse.id!);
        setState(() {
          _isValidated = true;
          _isFlagged = false;
        });

        // Log analytics
        await analytics.logPricePulseValidated(
          breed: widget.pulse.breed.name,
          weightBucket: widget.pulse.weightBucket.name,
          county: widget.pulse.county,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleFlag() async {
    if (widget.pulse.id == null || _isLoading) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag this price?'),
        content: const Text(
          'Flagging helps identify inaccurate prices. Are you sure this price seems incorrect?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Flag', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final tracker = context.read<ValidationTrackerService>();
    final pricePulseService = context.read<PricePulseService>();
    final analytics = context.read<AnalyticsService>();

    setState(() => _isLoading = true);

    try {
      if (_isFlagged) {
        // Remove flag (undo)
        await tracker.removeValidation(widget.pulse.id!);
        setState(() => _isFlagged = false);
      } else {
        // Add flag
        await pricePulseService.addFlag(widget.pulse.id!);
        await tracker.markFlagged(widget.pulse.id!);
        setState(() {
          _isFlagged = true;
          _isValidated = false;
        });

        // Log analytics
        await analytics.logPricePulseFlagged(
          breed: widget.pulse.breed.name,
          weightBucket: widget.pulse.weightBucket.name,
          county: widget.pulse.county,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getConfidenceColor() {
    switch (widget.pulse.trustLevel) {
      case ConfidenceLevel.high:
        return Colors.green;
      case ConfidenceLevel.medium:
        return Colors.orange;
      case ConfidenceLevel.low:
        return Colors.grey;
    }
  }

  String _getConfidenceLabel() {
    switch (widget.pulse.trustLevel) {
      case ConfidenceLevel.high:
        return 'High Confidence';
      case ConfidenceLevel.medium:
        return 'Medium Confidence';
      case ConfidenceLevel.low:
        return 'New Price';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Time + Confidence Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.pulse.timeAgo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getConfidenceColor().withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 14,
                        color: _getConfidenceColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getConfidenceLabel(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getConfidenceColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Content: Breed + Weight
            Row(
              children: [
                // Breed icon (cow emoji)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      '🐄',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatBreed(widget.pulse.breed),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatWeightBucket(widget.pulse.weightBucket)} • ${widget.pulse.county}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade900
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Offered Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offered',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '€${widget.pulse.price.toStringAsFixed(2)}/kg',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.arrow_forward,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  // Desired Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Desired',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '€${widget.pulse.desiredPrice.toStringAsFixed(2)}/kg',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Actions: Validation + Flag
            Row(
              children: [
                // Validation Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleValidation,
                    icon: Icon(
                      _isValidated ? Icons.check_circle : Icons.check_circle_outline,
                      color: _isValidated ? Colors.green : null,
                    ),
                    label: Text(
                      _isValidated
                          ? 'Validated (${widget.pulse.validationCount})'
                          : 'Accurate (${widget.pulse.validationCount})',
                      style: TextStyle(
                        color: _isValidated ? Colors.green : null,
                        fontWeight: _isValidated ? FontWeight.bold : null,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isValidated
                            ? Colors.green
                            : theme.dividerColor,
                      ),
                      backgroundColor: _isValidated
                          ? Colors.green.withOpacity(0.1)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Flag Button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleFlag,
                  icon: Icon(
                    _isFlagged ? Icons.flag : Icons.flag_outlined,
                    color: _isFlagged ? Colors.red : null,
                    size: 20,
                  ),
                  label: Text(
                    '${widget.pulse.flagCount}',
                    style: TextStyle(
                      color: _isFlagged ? Colors.red : null,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _isFlagged ? Colors.red : theme.dividerColor,
                    ),
                    backgroundColor: _isFlagged
                        ? Colors.red.withOpacity(0.1)
                        : null,
                  ),
                ),
              ],
            ),

            // "You validated this" indicator
            if (_isValidated || _isFlagged) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isValidated ? Icons.check_circle : Icons.flag,
                    size: 14,
                    color: _isValidated ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isValidated ? 'You validated this' : 'You flagged this',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _isValidated ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatBreed(Breed breed) {
    final name = breed.name;
    return name[0].toUpperCase() + name.substring(1).replaceAll('_', ' ');
  }

  String _formatWeightBucket(WeightBucket bucket) {
    final name = bucket.name;
    // Convert "w600_700" to "600-700kg"
    if (name.startsWith('w')) {
      final parts = name.substring(1).split('_');
      if (parts.length == 2) {
        return '${parts[0]}-${parts[1]}kg';
      }
    }
    return name;
  }
}
