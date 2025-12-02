/// county_picker.dart - Irish county dropdown selector widget
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:agriflow/utils/constants.dart';

class CountyPicker extends StatelessWidget {
  final String selectedCounty;
  final ValueChanged<String?> onChanged;

  const CountyPicker({
    super.key,
    required this.selectedCounty,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCounty,
              isExpanded: true,
              icon: const Icon(Icons.location_on_outlined),
              items: irishCounties.map((String county) {
                return DropdownMenuItem<String>(
                  value: county,
                  child: Text(county),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
