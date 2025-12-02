/// price_pulse_filter_bar.dart - Filter controls for price pulse screen
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:agriflow/models/cattle_group.dart';
import '../inputs/breed_picker.dart';

class PricePulseFilterBar extends StatelessWidget {
  final Breed selectedBreed;
  final WeightBucket selectedWeight;
  final String selectedCounty;
  final bool isAllIreland;
  final ValueChanged<Breed> onBreedChanged;
  final ValueChanged<WeightBucket> onWeightChanged;
  final VoidCallback onCountyToggle;
  final VoidCallback onCountyTap;

  const PricePulseFilterBar({
    super.key,
    required this.selectedBreed,
    required this.selectedWeight,
    required this.selectedCounty,
    required this.isAllIreland,
    required this.onBreedChanged,
    required this.onWeightChanged,
    required this.onCountyToggle,
    required this.onCountyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breed Picker
          BreedPicker(
            selectedBreed: selectedBreed,
            onBreedSelected: onBreedChanged,
          ),
          const SizedBox(height: 20),

          // Weight Slider
          _buildWeightSlider(context),
          const SizedBox(height: 20),

          // County Toggle
          _buildCountyToggle(context),
        ],
      ),
    );
  }

  Widget _buildWeightSlider(BuildContext context) {
    final buckets = WeightBucket.values;
    final currentIndex = buckets.indexOf(selectedWeight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weight Range',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚖️ ${selectedWeight.displayName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.2),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.2),
          ),
          child: Slider(
            value: currentIndex.toDouble(),
            min: 0,
            max: (buckets.length - 1).toDouble(),
            divisions: buckets.length - 1,
            onChanged: (val) => onWeightChanged(buckets[val.toInt()]),
          ),
        ),
      ],
    );
  }

  Widget _buildCountyToggle(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Location:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onCountyToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAllIreland ? Colors.blue.shade50 : Colors.green.shade50,
              border: Border.all(
                color: isAllIreland ? Colors.blue : Colors.green,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAllIreland ? '🇮🇪 All Ireland' : '📍 $selectedCounty',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isAllIreland
                        ? Colors.blue.shade900
                        : Colors.green.shade900,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.swap_horiz,
                  size: 16,
                  color: isAllIreland
                      ? Colors.blue.shade900
                      : Colors.green.shade900,
                ),
              ],
            ),
          ),
        ),
        if (!isAllIreland) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCountyTap,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.edit_location_alt,
                size: 18,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
