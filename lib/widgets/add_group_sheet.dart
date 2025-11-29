import 'package:flutter/material.dart';
import 'package:agriflow/models/cattle_group.dart';
import 'package:agriflow/widgets/breed_picker.dart';
import 'package:agriflow/widgets/weight_bucket_picker.dart';
import 'package:agriflow/widgets/quantity_slider.dart';
import 'package:agriflow/widgets/price_slider.dart';
import 'package:agriflow/widgets/county_picker.dart';

class AddGroupSheet extends StatefulWidget {
  final Function(CattleGroup) onSave;

  const AddGroupSheet({super.key, required this.onSave});

  @override
  State<AddGroupSheet> createState() => _AddGroupSheetState();
}

class _AddGroupSheetState extends State<AddGroupSheet> {
  Breed _selectedBreed = Breed.charolais;
  int _quantity = 30;
  WeightBucket _selectedBucket = WeightBucket.w600_700;
  String _selectedCounty = 'Antrim';
  double _desiredPrice = 4.20;

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
                Text(
                  'New Group',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                BreedPicker(
                  selectedBreed: _selectedBreed,
                  onBreedSelected: (breed) =>
                      setState(() => _selectedBreed = breed),
                ),
                const SizedBox(height: 32),

                QuantitySlider(
                  value: _quantity,
                  onChanged: (val) => setState(() => _quantity = val),
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

                PriceSlider(
                  value: _desiredPrice,
                  onChanged: (val) => setState(() => _desiredPrice = val),
                ),
                const SizedBox(height: 40), // Bottom padding
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
                onPressed: () {
                  final group = CattleGroup(
                    breed: _selectedBreed,
                    quantity: _quantity,
                    weightBucket: _selectedBucket,
                    county: _selectedCounty,
                    desiredPricePerKg: _desiredPrice,
                  );
                  widget.onSave(group);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Add Group to Portfolio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
