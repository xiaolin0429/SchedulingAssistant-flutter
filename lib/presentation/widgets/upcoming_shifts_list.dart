import 'package:flutter/material.dart';
import '../../data/models/shift.dart';

class UpcomingShiftsList extends StatelessWidget {
  final List<Shift> shifts;

  const UpcomingShiftsList({
    super.key,
    required this.shifts,
  });

  @override
  Widget build(BuildContext context) {
    if (shifts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('暂无未来排班'),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '未来排班',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shifts.length,
            itemBuilder: (context, index) {
              final shift = shifts[index];
              return ListTile(
                title: Text(shift.type.name),
                subtitle: Text(shift.date),
                trailing: Text(
                  '${shift.startTime} - ${shift.endTime}',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 