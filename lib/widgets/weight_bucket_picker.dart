import 'package:flutter/material.dart';
import 'package:agriflow/models/cattle_group.dart';

class WeightBucketPicker extends StatelessWidget {
  final WeightBucket? selectedBucket;
  final ValueChanged<WeightBucket> onBucketSelected;

  const WeightBucketPicker({
    super.key,
    this.selectedBucket,
    required this.onBucketSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weight Range', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...WeightBucket.values.map((bucket) {
          final isSelected = selectedBucket == bucket;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: () => onBucketSelected(bucket),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    Text(bucket.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 16),
                    Text(
                      bucket.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
