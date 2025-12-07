/// weekly_price_reminder_dialog.dart - Weekly reminder to log prices
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import '../../screens/price_log_screen.dart';

/// Shows a friendly reminder dialog to log prices weekly
///
/// This dialog appears based on user's reminder settings (typically Friday evening)
/// if they haven't logged any prices this week.
class WeeklyPriceReminderDialog extends StatelessWidget {
  const WeeklyPriceReminderDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const WeeklyPriceReminderDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.blue,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Price Log Reminder',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time to update your price log! 📝',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Text(
            'Have you received any price offers or made any sales this week?',
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tracking prices helps you spot trends and negotiate better deals!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Maybe Later'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PriceLogScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Log Price'),
        ),
      ],
    );
  }
}
