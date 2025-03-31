import 'package:flutter/material.dart';
import '../../../../data/models/shift_type.dart';

class ShiftTypeDistribution extends StatelessWidget {
  final Map<ShiftType, double> shiftTypePercentages;
  final Map<ShiftType, int> shiftTypeCountMap;

  const ShiftTypeDistribution({
    super.key,
    required this.shiftTypePercentages,
    required this.shiftTypeCountMap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '班次类型分布',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...shiftTypePercentages.entries.map(
              (entry) => _buildDistributionItem(
                entry.key.name,
                '${shiftTypeCountMap[entry.key] ?? 0}（${entry.value.toStringAsFixed(1)}%）',
                entry.key.colorValue,
              ),
            ),
            if (shiftTypePercentages.isEmpty) const Center(child: Text('暂无数据')),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
