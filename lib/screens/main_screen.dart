/// main_screen.dart - Main navigation container with bottom navigation bar
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agriflow/screens/dashboard_screen.dart';
import 'package:agriflow/screens/portfolio_screen.dart';
import 'package:agriflow/screens/calculator_screen.dart';
import 'package:agriflow/screens/price_pulse_screen.dart';
import 'package:agriflow/screens/settings_screen.dart';
import 'package:agriflow/services/price_log_service.dart';
import 'package:agriflow/widgets/dialogs/weekly_price_reminder_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    PortfolioScreen(),
    CalculatorScreen(),
    PricePulseScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkWeeklyReminder();
  }

  Future<void> _checkWeeklyReminder() async {
    // Wait for build to complete
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final priceLogService = Provider.of<PriceLogService>(context, listen: false);
    final shouldShow = await priceLogService.shouldShowReminder();

    if (shouldShow && mounted) {
      await WeeklyPriceReminderDialog.show(context);
      await priceLogService.markReminderShown();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up),
            selectedIcon: Icon(Icons.trending_up),
            label: 'Price Pulse',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
