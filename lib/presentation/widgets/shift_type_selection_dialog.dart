import 'package:flutter/material.dart';
import '../../data/models/shift_type.dart';

/// 班次类型选择对话框
/// 用于在主页中选择要分配的班次类型
class ShiftTypeSelectionDialog extends StatelessWidget {
  final List<ShiftType> shiftTypes;
  final Function(ShiftType) onSelected;
  final DateTime selectedDate;

  const ShiftTypeSelectionDialog({
    required this.shiftTypes,
    required this.onSelected,
    required this.selectedDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日';
    
    return AlertDialog(
      title: Text('选择$dateStr的班次'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: shiftTypes.length,
          itemBuilder: (context, index) {
            final type = shiftTypes[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: type.colorValue,
                child: Text(
                  type.name.substring(0, 1),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(type.name),
              subtitle: type.startTimeOfDay != null && type.endTimeOfDay != null
                  ? Text('${type.startTimeOfDay!.format(context)} - ${type.endTimeOfDay!.format(context)}')
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                onSelected(type);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
} 