import 'package:flutter/material.dart';
import 'package:agriflow/models/cattle_group.dart';
import 'package:agriflow/utils/constants.dart';
import 'package:agriflow/widgets/add_group_sheet.dart';
import 'package:agriflow/widgets/custom_card.dart';
import 'package:agriflow/services/portfolio_service.dart';
import 'package:agriflow/services/pdf_export_service.dart';
import 'package:share_plus/share_plus.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final PortfolioService _portfolioService = PortfolioService();
  final PDFExportService _pdfService = PDFExportService();
  List<CattleGroup> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    final groups = await _portfolioService.loadGroups();
    setState(() {
      _groups = groups;
      _isLoading = false;
    });
  }

  Future<void> _addNewGroup(CattleGroup group) async {
    await _portfolioService.addGroup(group);
    await _loadGroups();
  }

  Future<void> _removeGroup(String id) async {
    await _portfolioService.removeGroup(id);
    await _loadGroups();
  }

  void _sharePortfolio() {
    // Construct the share text
    final summary = _groups
        .map(
          (g) =>
              '${g.breed.emoji}×${g.quantity} ${g.weightBucket.displayName} ${g.county} – holding for €${g.desiredPricePerKg.toStringAsFixed(2)}+',
        )
        .join('\n');

    final text = '$summary\n\n🚀 #ForFarmers #AgriPulse';

    Share.share(text);
  }

  Future<void> _exportPDF() async {
    if (_groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some cattle groups first!')),
      );
      return;
    }

    try {
      await _pdfService.exportPortfolio(_groups);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate Portfolio Totals
    double totalValue = 0;
    double totalHead = 0;

    for (var group in _groups) {
      final medianPrice = countyMedianPrices[group.county] ?? 4.0;
      totalValue += group.calculateKillOutValue(medianPrice);
      totalHead += group.quantity;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Herd'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _exportPDF,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 📊 Instant Portfolio Card
                _buildInstantPortfolioCard(totalValue, totalHead),

                // List of Groups
                Expanded(
                  child: _groups.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _groups.length,
                          itemBuilder: (context, index) {
                            return _buildGroupCard(_groups[index], index);
                          },
                        ),
                ),

                // Sticky Bottom Actions
                _buildStickyActions(context),
              ],
            ),
    );
  }

  Widget _buildInstantPortfolioCard(double totalValue, double totalHead) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Net Worth Today',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '€${totalValue.toStringAsFixed(0)}', // e.g. €75,600
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Emoji Summary Row (Aggregated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🐄 × ${totalHead.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '📈 +€30/head 🟢', // Mocked comparison
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(CattleGroup group, int index) {
    final medianPrice = countyMedianPrices[group.county] ?? 4.0;
    final perHeadDiff = group.calculatePerHeadDifference(medianPrice);
    final isPositive = perHeadDiff >= 0;

    return Dismissible(
      key: Key('group_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Group?'),
            content: Text(
              'Remove ${group.quantity} ${group.breed.displayName} from portfolio?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (group.id != null) {
          _removeGroup(group.id!);
        }
      },
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji Header Row
            Row(
              children: [
                Text(group.breed.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  '× ${group.quantity}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    group.weightBucket.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Details Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem('Location', '📍 ${group.county}'),
                _buildDetailItem(
                  'Target',
                  '💰 €${group.desiredPricePerKg.toStringAsFixed(2)}',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Auto-Calc Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPositive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vs Market (${medianPrice.toStringAsFixed(2)})',
                    style: TextStyle(
                      color: isPositive
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${isPositive ? '+' : ''}€${perHeadDiff.toStringAsFixed(0)}/head ${isPositive ? '🟢' : '🔴'}',
                    style: TextStyle(
                      color: isPositive
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🐄', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No Cattle Groups Yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Tap "Add Group" to start tracking'),
        ],
      ),
    );
  }

  Widget _buildStickyActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddGroupSheet(onSave: _addNewGroup),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Group'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: _sharePortfolio,
            icon: const Icon(Icons.share),
            style: IconButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ],
      ),
    );
  }
}
