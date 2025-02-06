import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/shift_type_enum.dart';

class MonthlyStatisticsCard extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const MonthlyStatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final typeDistribution = statistics['typeDistribution'] as Map<ShiftType, int>? ?? {};
    final totalDays = statistics['totalDays'] as int? ?? 0;
    final totalHours = statistics['totalHours'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '月度统计',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  label: '工作天数',
                  value: totalDays.toString(),
                  unit: '天',
                ),
                _buildStatItem(
                  label: '工作时长',
                  value: totalHours.toString(),
                  unit: '小时',
                ),
              ],
            ),
            if (typeDistribution.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '班次分布',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieSections(typeDistribution, totalDays),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            children: [
              TextSpan(text: value),
              TextSpan(
                text: unit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(
    Map<ShiftType, int> distribution,
    int total,
  ) {
    if (total == 0) return [];

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    return distribution.entries.map((entry) {
      final index = entry.key.index % colors.length;
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      
      return PieChartSectionData(
        color: colors[index],
        value: entry.value.toDouble(),
        title: '$percentage%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
} 