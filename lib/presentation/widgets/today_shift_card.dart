import 'package:flutter/material.dart';
import '../../data/models/shift.dart';

class TodayShiftCard extends StatelessWidget {
  final Shift? shift;
  final Function(Shift) onShiftUpdated;

  const TodayShiftCard({
    super.key,
    this.shift,
    required this.onShiftUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日排班',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (shift != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('班次类型: ${shift!.type}'),
                        const SizedBox(height: 4),
                        Text('时间: ${shift!.startTime} - ${shift!.endTime}'),
                        if (shift!.note?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          Text('备注: ${shift!.note}'),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showNoteDialog(context),
                    icon: const Icon(Icons.edit),
                    tooltip: '编辑备注',
                  ),
                ],
              ),
            ] else
              Center(
                child: TextButton.icon(
                  onPressed: () => _showShiftDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('添加排班'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNoteDialog(BuildContext context) async {
    final controller = TextEditingController(text: shift?.note);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加备注'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入备注内容',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (shift != null) {
                onShiftUpdated(shift!.copyWith(
                  note: controller.text,
                  noteUpdatedAt: DateTime.now().millisecondsSinceEpoch,
                ));
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _showShiftDialog(BuildContext context) async {
    // TODO: 实现编辑排班对话框
  }
} 