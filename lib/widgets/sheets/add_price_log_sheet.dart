/// add_price_log_sheet.dart - Sheet for adding/editing price logs
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/price_log.dart';
import '../../models/cattle_group.dart';
import '../../services/price_log_service.dart';
import '../../utils/logger.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/error_handler.dart';
import '../../utils/constants.dart';
import '../inputs/breed_picker.dart';
import '../inputs/weight_bucket_picker.dart';
import '../inputs/county_picker.dart';

class AddPriceLogSheet extends StatefulWidget {
  final PriceLog? existingLog;

  const AddPriceLogSheet({super.key, this.existingLog});

  @override
  State<AddPriceLogSheet> createState() => _AddPriceLogSheetState();
}

class _AddPriceLogSheetState extends State<AddPriceLogSheet> {
  late PriceLogType _selectedType;
  late Breed _selectedBreed;
  late WeightBucket _selectedWeightBucket;
  late String _selectedCounty;
  late double _pricePerKg;
  late int _quantity;
  late DateTime _selectedDate;

  final _sourceController = TextEditingController();
  final _notesController = TextEditingController();
  bool? _accepted;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingLog != null) {
      // Edit mode
      final log = widget.existingLog!;
      _selectedType = log.type;
      _selectedBreed = log.breed;
      _selectedWeightBucket = log.weightBucket;
      _selectedCounty = log.county;
      _pricePerKg = log.pricePerKg;
      _quantity = log.quantity;
      _selectedDate = log.date;
      _sourceController.text = log.source;
      _notesController.text = log.notes ?? '';
      _accepted = log.accepted;
    } else {
      // Add mode - defaults
      _selectedType = PriceLogType.offer;
      _selectedBreed = Breed.charolais;
      _selectedWeightBucket = WeightBucket.w600_700;
      _selectedCounty = defaultCounty;
      _pricePerKg = defaultDesiredPrice;
      _quantity = 30;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    if (!mounted) return;

    // Validation
    if (_pricePerKg <= 0 || _pricePerKg > maxPricePerKg) {
      SnackBarHelper.showWarning(
        context,
        'Please enter a valid price (€0.01 - €${maxPricePerKg.toStringAsFixed(2)})',
      );
      return;
    }

    if (_quantity < minAnimalsPerGroup || _quantity > maxAnimalsPerGroup) {
      SnackBarHelper.showWarning(
        context,
        'Quantity must be between $minAnimalsPerGroup and $maxAnimalsPerGroup',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final log = PriceLog(
        id: widget.existingLog?.id,
        type: _selectedType,
        breed: _selectedBreed,
        weightBucket: _selectedWeightBucket,
        county: _selectedCounty,
        pricePerKg: _pricePerKg,
        quantity: _quantity,
        source: _sourceController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        accepted: _accepted,
        date: _selectedDate,
        createdAt: widget.existingLog?.createdAt ?? DateTime.now(),
      );

      final logService = Provider.of<PriceLogService>(context, listen: false);

      if (widget.existingLog != null) {
        await logService.updateLog(log);
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Price log updated');
      } else {
        await logService.addLog(log);
        if (!mounted) return;
        SnackBarHelper.showSuccess(
          context,
          '${_selectedType.icon} Price log added: €${_pricePerKg.toStringAsFixed(2)}/kg',
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      Logger.error('Failed to save price log', e);
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackBarHelper.showError(
        context,
        'Failed to save: ${ErrorHandler.getGenericErrorMessage(e)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingLog != null ? 'Edit Price Log' : 'Log Price',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Type Selector
              Text(
                'Type',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<PriceLogType>(
                segments: PriceLogType.values
                    .map((type) => ButtonSegment(
                          value: type,
                          label: Text('${type.icon} ${type.displayName}'),
                        ))
                    .toList(),
                selected: {_selectedType},
                onSelectionChanged: (Set<PriceLogType> selection) {
                  setState(() => _selectedType = selection.first);
                },
              ),
              const SizedBox(height: 20),

              // Breed
              Text(
                'Breed',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              BreedPicker(
                animalType: AnimalType.cattle,
                selectedBreed: _selectedBreed,
                onBreedSelected: (breed) {
                  setState(() => _selectedBreed = breed);
                },
              ),
              const SizedBox(height: 20),

              // Weight Bucket
              Text(
                'Weight',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              WeightBucketPicker(
                selectedBucket: _selectedWeightBucket,
                onBucketSelected: (bucket) {
                  setState(() => _selectedWeightBucket = bucket);
                },
              ),
              const SizedBox(height: 20),

              // County
              Text(
                'County',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              CountyPicker(
                selectedCounty: _selectedCounty,
                onCountySelected: (county) {
                  setState(() => _selectedCounty = county);
                },
              ),
              const SizedBox(height: 20),

              // Price and Quantity
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price (€/kg)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            prefixText: '€',
                            hintText: '4.20',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          controller: TextEditingController(
                            text: _pricePerKg.toStringAsFixed(2),
                          ),
                          onChanged: (value) {
                            final parsed = double.tryParse(value);
                            if (parsed != null) {
                              setState(() => _pricePerKg = parsed);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '30',
                            suffixText: 'head',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          controller: TextEditingController(
                            text: _quantity.toString(),
                          ),
                          onChanged: (value) {
                            final parsed = int.tryParse(value);
                            if (parsed != null) {
                              setState(() => _quantity = parsed);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Date
              Text(
                'Date',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.dividerColor),
                ),
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('EEE, MMM dd, yyyy').format(_selectedDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Source
              Text(
                'Source (Optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _sourceController,
                decoration: InputDecoration(
                  hintText: 'e.g., Bandon Mart, John Smith',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 20),

              // Notes
              Text(
                'Notes (Optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Additional details...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Accepted toggle (only for offers)
              if (_selectedType == PriceLogType.offer)
                CheckboxListTile(
                  title: const Text('Offer accepted'),
                  value: _accepted ?? false,
                  onChanged: (value) {
                    setState(() => _accepted = value);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveLog,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.existingLog != null ? 'Update Log' : 'Save Log',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
