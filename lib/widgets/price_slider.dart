import 'package:flutter/material.dart';

class PriceSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const PriceSlider({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Desired Price (€/kg)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '€${value.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
            activeTrackColor: Colors.green.shade700,
            inactiveTrackColor: Colors.green.shade100,
            thumbColor: Colors.green.shade700,
            overlayColor: Colors.green.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: 3.50,
            max: 5.50,
            divisions: 20, // (5.50 - 3.50) / 0.10 = 20 steps
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
