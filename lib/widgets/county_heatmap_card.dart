import 'package:flutter/material.dart';
import 'package:agriflow/widgets/custom_card.dart';
import 'package:agriflow/utils/constants.dart';

class CountyPriceData {
  final String county;
  final double offeredPrice;
  final int submissionCount;

  CountyPriceData({
    required this.county,
    required this.offeredPrice,
    required this.submissionCount,
  });
}

class CountyHeatmapCard extends StatelessWidget {
  final List<CountyPriceData> countyData;
  final double nationalMedian;
  final bool isLoading;
  final ValueChanged<String>? onCountyTap;

  const CountyHeatmapCard({
    super.key,
    required this.countyData,
    required this.nationalMedian,
    this.isLoading = false,
    this.onCountyTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return CustomCard(
        child: SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (countyData.isEmpty) {
      return CustomCard(
        color: Colors.grey.shade50,
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🗺️',
                  style: TextStyle(fontSize: 36, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 8),
                Text(
                  'No county data available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Sort by price descending
    final sortedData = List<CountyPriceData>.from(countyData)
      ..sort((a, b) => b.offeredPrice.compareTo(a.offeredPrice));

    // Take top 10 counties
    final topCounties = sortedData.take(10).toList();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'County Price Map',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Yesterday',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Offered €/kg by county (tap to filter)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                context,
                '🟢',
                '≥ National',
                Colors.green.shade700,
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                context,
                '🟡',
                '−1 to −5c',
                Colors.orange.shade700,
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                context,
                '🔴',
                '< −5c',
                Colors.red.shade700,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // County List
          ...topCounties.map((data) => _buildCountyRow(context, data)),

          if (sortedData.length > 10) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                '+${sortedData.length - 10} more counties',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String emoji,
    String label,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCountyRow(BuildContext context, CountyPriceData data) {
    final difference = data.offeredPrice - nationalMedian;
    final differenceInCents = difference * 100;

    String emoji;
    Color backgroundColor;
    Color textColor;

    if (difference >= 0) {
      emoji = '🟢';
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade900;
    } else if (difference >= -0.05) {
      emoji = '🟡';
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
    } else {
      emoji = '🔴';
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade900;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onCountyTap != null ? () => onCountyTap!(data.county) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.county,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '€${data.offeredPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                  ),
                  Text(
                    '${differenceInCents >= 0 ? '+' : ''}${differenceInCents.toStringAsFixed(0)}c',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: textColor,
                        ),
                  ),
                ],
              ),
              if (onCountyTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
