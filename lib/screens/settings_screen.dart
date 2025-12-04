/// settings_screen.dart - User settings and preferences screen
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:agriflow/widgets/cards/custom_card.dart';
import 'package:agriflow/widgets/inputs/county_picker.dart';
import 'package:agriflow/services/portfolio_service.dart';
import 'package:agriflow/services/user_preferences_service.dart';
import 'package:agriflow/services/analytics_service.dart';
import 'package:agriflow/services/auth_service.dart';
import 'package:agriflow/providers/theme_provider.dart';
import 'package:agriflow/widgets/sheets/account_linking_sheet.dart';

import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PortfolioService _portfolioService = PortfolioService();

  // Mock User Data
  final String _phoneNumber = '+353 87 ••• •••';
  final String _memberId = '#247';
  final String _status = 'Active';
  final String _plan = 'Basic Monthly €20';
  final String _nextPayment = '04 Aug 2025';

  @override
  void initState() {
    super.initState();
    // Track screen view
    Future.microtask(() {
      if (mounted) {
        Provider.of<AnalyticsService>(context, listen: false)
            .logScreenView(screenName: 'Settings');
      }
    });

    // Load preferences on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefsService = Provider.of<UserPreferencesService>(
        context,
        listen: false,
      );
      prefsService.loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access services via Provider
    final prefsService = Provider.of<UserPreferencesService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final prefs = prefsService.preferences;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: prefsService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Account Type Section
                if (authService.isAnonymous) ...[
                  _buildSectionHeader(context, 'Account Security'),
                  CustomCard(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.upgrade, color: Colors.orange),
                      ),
                      title: const Text(
                        'Upgrade Account',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Keep your data safe across devices'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Recommended',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const AccountLinkingSheet(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Account Info Section
                _buildSectionHeader(context, 'Account'),
                CustomCard(
                  child: Column(
                    children: [
                      _buildListTile(
                        context,
                        icon: authService.isAnonymous
                            ? Icons.person_outline
                            : Icons.verified_user,
                        title: 'Account Type',
                        value: authService.isAnonymous
                            ? 'Anonymous'
                            : 'Verified',
                        emoji: authService.isAnonymous ? '👤' : '✅',
                        valueColor:
                            authService.isAnonymous ? Colors.orange : Colors.green,
                      ),
                      if (!authService.isAnonymous &&
                          authService.user?.email != null) ...[
                        const Divider(),
                        _buildListTile(
                          context,
                          icon: Icons.email,
                          title: 'Email',
                          value: authService.user!.email!,
                          emoji: '📧',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // User Details Section
                _buildSectionHeader(context, 'User Details'),
                CustomCard(
                  child: Column(
                    children: [
                      _buildListTile(
                        context,
                        icon: Icons.phone_iphone,
                        title: 'Phone Number',
                        value: _phoneNumber,
                        emoji: '📱',
                      ),
                      const Divider(),
                      _buildListTile(
                        context,
                        icon: Icons.tag,
                        title: 'Member ID',
                        value: _memberId,
                        emoji: '🏷️',
                      ),
                      const Divider(),
                      _buildListTile(
                        context,
                        icon: Icons.location_on,
                        title: 'County',
                        value: prefs.county,
                        emoji: '📍',
                        onTap: () => _showCountyPicker(prefsService),
                        showArrow: true,
                      ),
                      const Divider(),
                      _buildListTile(
                        context,
                        icon: Icons.check_circle,
                        title: 'Status',
                        value: _status,
                        emoji: '✅',
                        valueColor: Colors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Subscription Section
                _buildSectionHeader(context, 'Subscription'),
                CustomCard(
                  child: Column(
                    children: [
                      _buildListTile(
                        context,
                        icon: Icons.monetization_on,
                        title: 'Current Plan',
                        value: _plan,
                        emoji: '💰',
                      ),
                      const Divider(),
                      _buildListTile(
                        context,
                        icon: Icons.calendar_today,
                        title: 'Next Payment',
                        value: _nextPayment,
                        emoji: '📅',
                      ),
                      const Divider(),
                      _buildListTile(
                        context,
                        icon: Icons.swap_horiz,
                        title: 'Change Plan',
                        value: '€20/mo or €200/yr',
                        emoji: '🔄',
                        onTap: () =>
                            _launchUrl('https://stripe.com'), // Mock URL
                        showArrow: true,
                      ),
                      const Divider(),
                      _buildListTile(
                        context,
                        icon: Icons.receipt,
                        title: 'Payment History',
                        value: 'PDF Invoices',
                        emoji: '📄',
                        onTap: () {},
                        showArrow: true,
                      ),
                      const Divider(),
                      _buildListTile(
                        context,
                        icon: Icons.cancel,
                        title: 'Cancel Subscription',
                        value: 'Keeps access till end',
                        emoji: '❌',
                        onTap: _showCancelSubscriptionDialog,
                        textColor: Colors.red,
                        iconColor: Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Data & Privacy Section
                _buildSectionHeader(context, 'Data & Privacy'),
                CustomCard(
                  child: Column(
                    children: [
                      _buildListTile(
                        context,
                        icon: Icons.download,
                        title: 'Export My Data',
                        value: 'JSON download',
                        emoji: '📥',
                        onTap: _exportData,
                        showArrow: true,
                      ),
                      const Divider(),
                      _buildListTile(
                        context,
                        icon: Icons.delete_forever,
                        title: 'Delete All Data',
                        value: 'Irreversible',
                        emoji: '🗑️',
                        onTap: _showDeleteDataDialog,
                        textColor: Colors.red,
                        iconColor: Colors.red,
                      ),
                      const Divider(),
                      _buildListTile(
                        context,
                        icon: Icons.timer,
                        title: 'Auto-Expire',
                        value: 'Posts removed after 7 days',
                        emoji: '⏱️',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // App Settings Section
                _buildSectionHeader(context, 'App Settings'),
                CustomCard(
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        context,
                        title: 'Dark Mode',
                        emoji: '🌙',
                        value: prefs.darkMode,
                        onChanged: (val) {
                          prefsService.updateDarkMode(val);
                          themeProvider.toggleDarkMode(val);

                          // Track analytics
                          Provider.of<AnalyticsService>(context, listen: false)
                              .logThemeChanged(isDarkMode: val);
                        },
                      ),
                      const Divider(),
                      _buildSwitchTile(
                        context,
                        title: 'Rain Alerts',
                        emoji: '☔',
                        value: prefs.rainAlerts,
                        onChanged: prefsService.updateRainAlerts,
                      ),
                      const Divider(),
                      _buildSwitchTile(
                        context,
                        title: 'Holiday Alerts',
                        emoji: '🏭',
                        value: prefs.holidayAlerts,
                        onChanged: prefsService.updateHolidayAlerts,
                      ),
                      const Divider(),
                      _buildSwitchTile(
                        context,
                        title: 'Target Date Alerts',
                        emoji: '🎯',
                        value: prefs.targetDateAlerts,
                        onChanged: prefsService.updateTargetDateAlerts,
                      ),
                      const Divider(),
                      _buildSwitchTile(
                        context,
                        title: 'Gaeilge',
                        emoji: '🗣️',
                        value: prefs.isGaeilge,
                        onChanged: prefsService.updateIsGaeilge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Support Section
                _buildSectionHeader(context, 'Support'),
                CustomCard(
                  child: Column(
                    children: [
                      _buildListTile(
                        context,
                        icon: Icons.help,
                        title: 'Help Centre',
                        value: 'FAQ',
                        emoji: '❓',
                        onTap: () {},
                        showArrow: true,
                      ),
                      const Divider(),
                      _buildListTile(
                        context,
                        icon: Icons.email,
                        title: 'Contact Us',
                        value: 'help@forfarmers.ie',
                        emoji: '✉️',
                        onTap: () => _launchUrl('mailto:help@forfarmers.ie'),
                        showArrow: true,
                      ),
                      const Divider(),
                      _buildListTile(
                        context,
                        icon: Icons.bug_report,
                        title: 'Report Bug',
                        value: 'Send device info',
                        emoji: '🐛',
                        onTap: () => _launchUrl(
                          'mailto:bugs@forfarmers.ie?subject=Bug Report',
                        ),
                        showArrow: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Legal Section
                _buildSectionHeader(context, 'Legal'),
                CustomCard(
                  child: Column(
                    children: [
                      _buildListTile(
                        context,
                        icon: Icons.privacy_tip,
                        title: 'Privacy Policy',
                        value: 'GDPR compliant',
                        emoji: '🔒',
                        onTap: _showPrivacyPolicy,
                        showArrow: true,
                      ),
                      const Divider(),
                      _buildListTile(
                        context,
                        icon: Icons.description,
                        title: 'Terms of Service',
                        value: 'Legal agreement',
                        emoji: '📜',
                        onTap: () {},
                        showArrow: true,
                      ),
                      const Divider(),
                      _buildListTile(
                        context,
                        icon: Icons.info,
                        title: 'About AgriFlow',
                        value: 'v1.0.0',
                        emoji: 'ℹ️',
                        onTap: () {},
                        showArrow: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                Center(
                  child: Text(
                    'AgriFlow v1.0.0',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String emoji,
    VoidCallback? onTap,
    bool showArrow = false,
    Color? valueColor,
    Color? textColor,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color:
                          textColor ?? (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    valueColor ??
                    (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String emoji,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _showCountyPicker(UserPreferencesService prefsService) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select County',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            CountyPicker(
              selectedCounty: prefsService.preferences.county,
              onChanged: (val) {
                if (val != null) {
                  prefsService.updateCounty(val);
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _showCancelSubscriptionDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text(
          'Are you sure you want to cancel? You will keep access until 04 Aug 2025.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Plan'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subscription cancelled')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDataDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account?'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is IRREVERSIBLE and will permanently delete:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• Your entire Firebase account'),
            Text('• All cattle portfolios'),
            Text('• All preferences and settings'),
            Text('• Your authentication'),
            SizedBox(height: 12),
            Text(
              'You will be signed out immediately.',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Track analytics before deleting
              Provider.of<AnalyticsService>(context, listen: false)
                  .logDataDeleted();

              Navigator.pop(context);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              // Delete account (includes all subcollections)
              final authService = Provider.of<AuthService>(context, listen: false);
              final success = await authService.deleteUserAccount();

              if (context.mounted) {
                Navigator.pop(context); // Close loading indicator

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Account and all data deleted'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Navigate to login or home
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 12),
                          Text('Error: ${authService.lastError ?? "Unknown error"}'),
                        ],
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      // Track analytics
      Provider.of<AnalyticsService>(context, listen: false).logDataExported();

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Exporting your data...'),
            ],
          ),
        ),
      );

      // Export data using AuthService
      final authService = Provider.of<AuthService>(context, listen: false);
      final exportData = await authService.exportUserData();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show preview dialog with option to download
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Data Export Ready'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Export Summary:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('• Portfolios: ${exportData['total_portfolios']}'),
                  Text('• Preferences: ${exportData['total_preferences']}'),
                  Text('• Account Type: ${exportData['is_anonymous'] ? 'Anonymous' : 'Verified'}'),
                  const SizedBox(height: 12),
                  Text(
                    'Export Date: ${exportData['export_date']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Note: Data is ready. In production, this would download as a JSON file.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // In production: Save JSON file or share
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.download_done, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Data exported successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Download JSON'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Text('Export failed: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPrivacyPolicy() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.privacy_tip),
            SizedBox(width: 8),
            Text('Privacy Policy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'AgriFlow Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Last Updated: December 2025',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),

              _buildPolicySection(
                'Data We Collect',
                '• Cattle portfolio data (breed, quantity, weight, prices)\n'
                '• Anonymous price pulse submissions\n'
                '• User preferences and settings\n'
                '• Firebase authentication data',
              ),

              _buildPolicySection(
                'How We Use Your Data',
                '• Portfolio management and tracking\n'
                '• Market price analytics (anonymized)\n'
                '• App functionality and personalization\n'
                '• Service improvements',
              ),

              _buildPolicySection(
                'Data Storage & Security',
                '• All data stored in Firebase Firestore (encrypted at rest)\n'
                '• Secure user isolation via Firestore security rules\n'
                '• Price pulses auto-deleted after 7 days\n'
                '• Portfolio data stored indefinitely (until deleted by you)',
              ),

              _buildPolicySection(
                'Your GDPR Rights',
                '• Right to access your data (Export My Data)\n'
                '• Right to deletion (Delete All Data)\n'
                '• Right to data portability (JSON export)\n'
                '• Right to rectification (edit your data)',
              ),

              _buildPolicySection(
                'Data Sharing',
                '• We DO NOT sell your personal data\n'
                '• Price submissions are anonymous (no user identification)\n'
                '• Portfolio data is private to your account only\n'
                '• Firebase Analytics for app improvements (anonymized)',
              ),

              const SizedBox(height: 12),
              const Text(
                'Contact: privacy@agriflow.ie',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl('mailto:privacy@agriflow.ie?subject=Privacy Policy Inquiry');
            },
            child: const Text('Contact Us'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }
}
