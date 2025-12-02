/// breed_picker.dart - Emoji-first breed selector widget
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:agriflow/models/cattle_group.dart';

class BreedPicker extends StatefulWidget {
  final Breed? selectedBreed;
  final ValueChanged<Breed> onBreedSelected;

  const BreedPicker({
    super.key,
    this.selectedBreed,
    required this.onBreedSelected,
  });

  @override
  State<BreedPicker> createState() => _BreedPickerState();
}

class _BreedPickerState extends State<BreedPicker> {
  AnimalType? _selectedAnimalType;

  @override
  void initState() {
    super.initState();
    _updateAnimalType();
  }

  @override
  void didUpdateWidget(BreedPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedBreed != oldWidget.selectedBreed) {
      _updateAnimalType();
    }
  }

  void _updateAnimalType() {
    if (widget.selectedBreed != null) {
      _selectedAnimalType = widget.selectedBreed!.animalType;
    } else {
      _selectedAnimalType ??= AnimalType.cattle; // Default if not set
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step 1: Animal Type Selection
        Text(
          '1. Select Animal Type',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AnimalType.values.map((type) {
              final isSelected = _selectedAnimalType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedAnimalType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(type.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          type.displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Step 2: Breed Selection
        if (_selectedAnimalType != null) ...[
          Text(
            '2. Select Breed',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: Breed.getByAnimalType(_selectedAnimalType!).map((breed) {
              final isSelected = widget.selectedBreed == breed;
              return GestureDetector(
                onTap: () => widget.onBreedSelected(breed),
                child: Container(
                  width: 100,
                  height: 90,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.15)
                        : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(breed.emoji, style: const TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Text(
                        breed.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
