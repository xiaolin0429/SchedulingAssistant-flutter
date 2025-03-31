import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/statistics/statistics_bloc.dart';
import '../../../blocs/statistics/statistics_event.dart';

class MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final Function(DateTime) onMonthChanged;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final newMonth = DateTime(
                selectedMonth.year,
                selectedMonth.month - 1,
              );
              onMonthChanged(newMonth);
              context.read<StatisticsBloc>().add(
                    UpdateSelectedMonth(newMonth),
                  );
            },
          ),
          GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                onMonthChanged(picked);
                context.read<StatisticsBloc>().add(
                      UpdateSelectedMonth(picked),
                    );
              }
            },
            child: Text(
              '${selectedMonth.year}年${selectedMonth.month}月',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final newMonth = DateTime(
                    selectedMonth.year,
                    selectedMonth.month + 1,
                  );
                  onMonthChanged(newMonth);
                  context.read<StatisticsBloc>().add(
                        UpdateSelectedMonth(newMonth),
                      );
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () {
                  _showDateRangeDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDateRangeDialog(BuildContext context) {
    // 当前日期
    final now = DateTime.now();
    // 初始开始日期（当月1日）
    final initialStartDate = DateTime(now.year, now.month, 1);
    // 初始结束日期（当月最后一天）
    final initialEndDate = DateTime(now.year, now.month + 1, 0);

    // 选择的日期范围
    DateTime startDate = initialStartDate;
    DateTime endDate = initialEndDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择日期范围'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('开始日期'),
                    subtitle: Text(
                        '${startDate.year}-${startDate.month}-${startDate.day}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked;
                          // 确保结束日期不早于开始日期
                          if (endDate.isBefore(startDate)) {
                            endDate = startDate;
                          }
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('结束日期'),
                    subtitle:
                        Text('${endDate.year}-${endDate.month}-${endDate.day}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: startDate, // 开始日期之后
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          endDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<StatisticsBloc>().add(
                          LoadDateRangeStatistics(startDate, endDate),
                        );
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
