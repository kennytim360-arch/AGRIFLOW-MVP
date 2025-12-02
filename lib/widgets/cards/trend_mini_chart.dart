/// trend_mini_chart.dart - 7-day price trend line chart widget
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'custom_card.dart';
import 'package:intl/intl.dart';

class TrendDataPoint {
  final DateTime date;
  final double desiredPrice;
  final double offeredPrice;

  TrendDataPoint({
    required this.date,
    required this.desiredPrice,
    required this.offeredPrice,
  });
}

class TrendMiniChart extends StatelessWidget {
  final List<TrendDataPoint> data;
  final bool isLoading;

  const TrendMiniChart({super.key, required this.data, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return CustomCard(
        child: SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (data.isEmpty) {
      return CustomCard(
        color: Colors.grey.shade50,
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '📉',
                  style: TextStyle(fontSize: 36, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 8),
                Text(
                  'No trend data available',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-Day Price Trend',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _buildLegendItem(context, 'Desired', Colors.blue),
                  const SizedBox(width: 12),
                  _buildLegendItem(context, 'Offered', Colors.orange),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              _buildLineChartData(context),
              duration: const Duration(milliseconds: 250),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData(BuildContext context) {
    // Find min and max for Y-axis
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var point in data) {
      if (point.desiredPrice < minY) minY = point.desiredPrice;
      if (point.offeredPrice < minY) minY = point.offeredPrice;
      if (point.desiredPrice > maxY) maxY = point.desiredPrice;
      if (point.offeredPrice > maxY) maxY = point.offeredPrice;
    }

    // Add padding to Y-axis
    final padding = (maxY - minY) * 0.1;
    minY -= padding;
    maxY += padding;

    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY - minY) / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '€${value.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.length) {
                return const SizedBox.shrink();
              }
              final date = data[index].date;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('EEE').format(date),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        // Desired Price Line
        LineChartBarData(
          spots: data.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.desiredPrice);
          }).toList(),
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.blue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
        ),
        // Offered Price Line
        LineChartBarData(
          spots: data.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.offeredPrice);
          }).toList(),
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.orange,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.orange.withOpacity(0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.black87,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              final date = data[spot.x.toInt()].date;
              final isDesired = spot.barIndex == 0;
              return LineTooltipItem(
                '${DateFormat('MMM d').format(date)}\n€${spot.y.toStringAsFixed(2)} ${isDesired ? '(Desired)' : '(Offered)'}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
    );
  }
}
