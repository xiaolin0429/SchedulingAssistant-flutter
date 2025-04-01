import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../core/localization/app_localizations.dart';
import '../../../blocs/statistics/statistics_bloc.dart';
import '../../../blocs/statistics/statistics_event.dart';

class MonthSelector extends StatefulWidget {
  final DateTime selectedMonth;
  final Function(DateTime) onMonthChanged;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  State<MonthSelector> createState() => _MonthSelectorState();
}

class _MonthSelectorState extends State<MonthSelector> {
  Timer? _debounceTimer;

  // 使用防抖函数包装月份变更操作
  void _debouncedMonthChange(DateTime newMonth) {
    // 取消之前的定时器
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    // 立即更新UI显示，但延迟触发数据加载
    widget.onMonthChanged(newMonth);

    // 设置新的定时器，300毫秒后再触发数据加载
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<StatisticsBloc>().add(UpdateSelectedMonth(newMonth));
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

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
                widget.selectedMonth.year,
                widget.selectedMonth.month - 1,
              );
              _debouncedMonthChange(newMonth);
            },
          ),
          GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: widget.selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                _debouncedMonthChange(picked);
              }
            },
            child: Text(
              _getLocalizedMonth(context, widget.selectedMonth),
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
                    widget.selectedMonth.year,
                    widget.selectedMonth.month + 1,
                  );
                  _debouncedMonthChange(newMonth);
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
              title: Text(
                  AppLocalizations.of(context).translate('date_range_select')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                        AppLocalizations.of(context).translate('start_date')),
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
                    title: Text(
                        AppLocalizations.of(context).translate('end_date')),
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
                  child: Text(AppLocalizations.of(context).translate('cancel')),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<StatisticsBloc>().add(
                          LoadDateRangeStatistics(startDate, endDate),
                        );
                  },
                  child:
                      Text(AppLocalizations.of(context).translate('confirm')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 获取本地化的月份显示
  String _getLocalizedMonth(BuildContext context, DateTime date) {
    // 根据当前语言环境决定显示格式
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'zh') {
      return '${date.year}年${date.month}月';
    } else {
      // 英文和其他语言环境使用标准格式
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${months[date.month - 1]} ${date.year}';
    }
  }
}
