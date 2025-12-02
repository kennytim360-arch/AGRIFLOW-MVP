/// submit_pulse_sheet.dart - Modal bottom sheet for price pulse submissions
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agriflow/models/cattle_group.dart';
import 'package:agriflow/models/price_pulse.dart';
import 'package:agriflow/services/analytics_service.dart';
import '../inputs/breed_picker.dart';
import '../inputs/weight_bucket_picker.dart';
import '../inputs/county_picker.dart';

class SubmitPulseSheet extends StatefulWidget {
  final Function(PricePulse) onSubmit;

  const SubmitPulseSheet({super.key, required this.onSubmit});

  @override
  State<SubmitPulseSheet> createState() => _SubmitPulseSheetState();
}

class _SubmitPulseSheetState extends State<SubmitPulseSheet> {
  Breed _selectedBreed = Breed.charolais;
  WeightBucket _selectedBucket = WeightBucket.w600_700;
  String _selectedCounty = 'Antrim';
  double _desiredPrice = 4.20;
  double _offeredPrice = 4.00;

  bool get _isValid {
    return _desiredPrice >= 3.0 &&
        _desiredPrice <= 6.0 &&
        _offeredPrice >= 3.0 &&
        _offeredPrice <= 6.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit Price Pulse',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Anonymous • Helps everyone',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your submission is anonymous. Help farmers get fair prices by sharing real market data.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                BreedPicker(
                  selectedBreed: _selectedBreed,
                  onBreedSelected: (breed) =>
                      setState(() => _selectedBreed = breed),
                ),
                const SizedBox(height: 32),

                WeightBucketPicker(
                  selectedBucket: _selectedBucket,
                  onBucketSelected: (bucket) =>
                      setState(() => _selectedBucket = bucket),
                ),
                const SizedBox(height: 32),

                CountyPicker(
                  selectedCounty: _selectedCounty,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCounty = val);
                  },
                ),
                const SizedBox(height: 32),

                // Desired Price Slider
                _buildPriceSlider(
                  context,
                  'What price did you want?',
                  _desiredPrice,
                  (val) => setState(() => _desiredPrice = val),
                  Colors.blue,
                ),
                const SizedBox(height: 32),

                // Offered Price Slider
                _buildPriceSlider(
                  context,
                  'What price were you offered?',
                  _offeredPrice,
                  (val) => setState(() => _offeredPrice = val),
                  Colors.orange,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Sticky Action Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isValid ? _handleSubmit : null,
                child: const Text(
                  'Submit Price Pulse',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSlider(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> onChanged,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color,
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
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: 3.0,
            max: 6.0,
            divisions: 30, // 0.10 increments
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '€3.00',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            Text(
              '€6.00',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  void _handleSubmit() {
    final pulse = PricePulse(
      breed: _selectedBreed,
      weightBucket: _selectedBucket,
      county: _selectedCounty,
      desiredPrice: _desiredPrice,
      price: _offeredPrice,
      submissionDate: DateTime.now(),
    );

    // Track analytics
    Provider.of<AnalyticsService>(context, listen: false)
        .logPricePulseSubmitted(
      breed: _selectedBreed.name,
      weightBucket: _selectedBucket.name,
      price: _offeredPrice,
      county: _selectedCounty,
    );

    widget.onSubmit(pulse);
    Navigator.pop(context);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Price Pulse submitted successfully!'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
