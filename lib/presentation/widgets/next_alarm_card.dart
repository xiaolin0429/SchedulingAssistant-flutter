import 'package:flutter/material.dart';
import '../../data/models/alarm.dart';

class NextAlarmCard extends StatelessWidget {
  final AlarmEntity? alarm;

  const NextAlarmCard({
    super.key,
    this.alarm,
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
              '下一个闹钟',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (alarm != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTime(alarm!.timeInMillis),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTimeUntil(alarm!.timeInMillis),
                          style: const TextStyle(color: Colors.blue),
                        ),
                        if (alarm!.repeat) ...[
                          const SizedBox(height: 4),
                          Text(
                            '重复: ${_getRepeatDaysText(alarm!.repeatDays)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                        if (alarm!.name?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          Text(
                            '备注: ${alarm!.name}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ] else
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // TODO: 导航到闹钟设置页面
                  },
                  icon: const Icon(Icons.add_alarm),
                  label: const Text('设置闹钟'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int timeInMillis) {
    final time = DateTime.fromMillisecondsSinceEpoch(timeInMillis);
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeUntil(int timeInMillis) {
    final alarmTime = DateTime.fromMillisecondsSinceEpoch(timeInMillis);
    final now = DateTime.now();
    final difference = alarmTime.difference(now);
    return '${difference.inHours}小时${difference.inMinutes % 60}分钟后';
  }

  String _getRepeatDaysText(int repeatDays) {
    const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final selectedDays = <String>[];
    
    for (var i = 0; i < 7; i++) {
      if ((repeatDays & (1 << i)) != 0) {
        selectedDays.add(days[i]);
      }
    }
    
    return selectedDays.join(', ');
  }
} 