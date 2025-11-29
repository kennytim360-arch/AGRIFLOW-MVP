import 'package:flutter/material.dart';
import 'package:agriflow/models/cattle_group.dart';
import 'package:agriflow/widgets/custom_card.dart';

enum ConfidenceLevel {
  high,
  medium,
  low,
}

class MedianBandData {
  final double desiredMedian;
  final double offeredMedian;
  final int bandCount;
  final double weeklyChange; // in cents
  final ConfidenceLevel confidence;

  MedianBandData({
    required this.desiredMedian,
    required this.offeredMedian,
    required this.bandCount,
    required this.weeklyChange,
    required this.confidence,
  });

  // Calculate confidence based on post count
  static ConfidenceLevel calculateConfidence(int postCount) {
    if (postCount >= 20) return ConfidenceLevel.high;
    if (postCount >= 5) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }
}

class MedianBandCard extends StatelessWidget {
  final Breed breed;
  final WeightBucket weightBucket;
  final String county;
  final MedianBandData? data;
  final bool isLoading;

  const MedianBandCard({
    super.key,
    required this.breed,
    required this.weightBucket,
    required this.county,
    this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return CustomCard(
        child: SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Loading market data...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (data == null || data!.confidence == ConfidenceLevel.low) {
      return CustomCard(
        color: Colors.grey.shade50,
        child: SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '📊',
                  style: TextStyle(
                    fontSize: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Not enough data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  data == null
                      ? 'No submissions yet'
                      : 'Only ${data!.bandCount} submission${data!.bandCount == 1 ? '' : 's'} (need 5+)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Text(
                breed.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      breed.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${weightBucket.displayName} · 📍 $county',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
              _buildConfidencePill(context),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Price Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPriceColumn(
                context,
                'Desired',
                data!.desiredMedian,
                Colors.blue,
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.grey.shade300,
              ),
              _buildPriceColumn(
                context,
                'Offered',
                data!.offeredMedian,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getTrendColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      data!.weeklyChange >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: _getTrendColor(),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${data!.weeklyChange >= 0 ? '+' : ''}${data!.weeklyChange.toStringAsFixed(0)}c vs last week',
                      style: TextStyle(
                        color: _getTrendColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${data!.bandCount} bands',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
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

  Widget _buildPriceColumn(
    BuildContext context,
    String label,
    double price,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '€${price.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
        ),
      ],
    );
  }

  Widget _buildConfidencePill(BuildContext context) {
    final confidence = data!.confidence;
    Color color;
    String text;
    IconData icon;

    switch (confidence) {
      case ConfidenceLevel.high:
        color = Colors.green;
        text = 'High';
        icon = Icons.check_circle;
        break;
      case ConfidenceLevel.medium:
        color = Colors.orange;
        text = 'Medium';
        icon = Icons.info;
        break;
      case ConfidenceLevel.low:
        color = Colors.red;
        text = 'Low';
        icon = Icons.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor() {
    if (data!.weeklyChange > 0) return Colors.green;
    if (data!.weeklyChange < 0) return Colors.red;
    return Colors.grey;
  }
}
