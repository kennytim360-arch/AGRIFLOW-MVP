import 'package:flutter/material.dart';
import 'package:agriflow/models/cattle_group.dart';

class WeightSlider extends StatelessWidget {
  final WeightBucket value;
  final ValueChanged<WeightBucket> onChanged;

  const WeightSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final buckets = WeightBucket.values;
    final currentIndex = buckets.indexOf(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weight Range',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '⚖️ ${value.displayName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 12,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
            valueIndicatorColor: Theme.of(context).colorScheme.primary,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Slider(
            value: currentIndex.toDouble(),
            min: 0,
            max: (buckets.length - 1).toDouble(),
            divisions: buckets.length - 1,
            onChanged: (val) => onChanged(buckets[val.toInt()]),
          ),
        ),
        // Weight bucket labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: buckets.map((bucket) {
            return Text(
              bucket.displayName.split(' ').first,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
