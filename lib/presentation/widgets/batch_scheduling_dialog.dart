import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/models/shift_type.dart';
import '../../data/repositories/shift_repository.dart';
import '../../core/di/injection_container.dart';
import '../../core/localization/app_localizations.dart';
import '../blocs/home/home_bloc.dart';
import '../blocs/home/home_event.dart';

class BatchSchedulingDialog extends StatefulWidget {
  final List<ShiftType> shiftTypes;
  final DateTime initialDate;

  const BatchSchedulingDialog({
    required this.shiftTypes,
    required this.initialDate,
    super.key,
  });

  @override
  State<BatchSchedulingDialog> createState() => _BatchSchedulingDialogState();
}

class _BatchSchedulingDialogState extends State<BatchSchedulingDialog> {
  late int _selectedShiftTypeId;
  bool _isLoading = false;

  // 日历相关变量
  late DateTime _focusedDay;
  final Set<DateTime> _selectedDays = {};

  // 获取ShiftRepository
  final ShiftRepository _shiftRepository = getIt<ShiftRepository>();

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _selectedShiftTypeId =
        widget.shiftTypes.isNotEmpty ? widget.shiftTypes[0].id ?? 0 : 0;

    // 默认添加初始日期到选中集合
    final initialDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _selectedDays.add(initialDate);
    debugPrint('初始化日期: $initialDate');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.translate('batch_scheduling')),
      content: SizedBox(
        width: double.maxFinite,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期选择日历视图
                  Text(localizations.translate('date_range'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // 日历视图
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TableCalendar(
                        firstDay:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDay:
                            DateTime.now().add(const Duration(days: 365 * 2)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) {
                          return _selectedDays.contains(_normalizeDate(day));
                        },
                        onDaySelected: _onDaySelected,
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarFormat: CalendarFormat.month,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        // 禁用滑动切换月份
                        availableGestures: AvailableGestures.horizontalSwipe,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 已选日期信息
                  Center(
                    child: Text(
                      '${localizations.translate('selected')}: ${_selectedDays.length} ${localizations.translate('days')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 班次类型选择
                  Text(localizations.translate('shift_type'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedShiftTypeId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: widget.shiftTypes.map((type) {
                      return DropdownMenuItem<int>(
                        value: type.id ?? 0,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: type.colorValue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(type.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedShiftTypeId = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(localizations.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: (_selectedDays.isNotEmpty && !_isLoading)
              ? () => _checkAndConfirmOverwrite()
              : null,
          child: Text(localizations.translate('confirm')),
        ),
      ],
    );
  }

  // 日期选择处理
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final normalizedDay = _normalizeDate(selectedDay);
    debugPrint('单击选择日期: $selectedDay, 标准化日期: $normalizedDay');

    setState(() {
      _focusedDay = focusedDay;

      // 单击日期的行为：选中或取消选中
      if (_selectedDays.contains(normalizedDay)) {
        debugPrint('取消选中日期: $normalizedDay');
        _selectedDays.remove(normalizedDay);
      } else {
        debugPrint('选中日期: $normalizedDay');
        _selectedDays.add(normalizedDay);
      }

      debugPrint('当前选中日期数: ${_selectedDays.length}');
    });
  }

  // 标准化日期（只保留年月日）
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // 检查并确认是否覆盖现有排班
  Future<void> _checkAndConfirmOverwrite() async {
    if (_selectedDays.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 检查所选日期是否已有排班
      final List<String> existingDates = [];

      for (final date in _selectedDays) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final shift = await _shiftRepository.getShiftByDate(date);

        if (shift != null) {
          existingDates.add('${dateStr} (${shift.type.name})');
        }
      }

      setState(() {
        _isLoading = false;
      });

      if (existingDates.isNotEmpty) {
        // 如果有已排班的日期，显示确认对话框
        if (!mounted) return;

        final shouldOverwrite =
            await _showOverwriteConfirmDialog(existingDates);
        if (shouldOverwrite) {
          _applyBatchScheduling();
        }
      } else {
        // 如果没有已排班的日期，直接应用批量排班
        _applyBatchScheduling();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('检查排班冲突时出错: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('检查排班冲突时出错: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // 显示覆盖确认对话框
  Future<bool> _showOverwriteConfirmDialog(List<String> existingDates) async {
    final localizations = AppLocalizations.of(context);

    // 限制显示的冲突数量，避免对话框过长
    final displayDates = existingDates.length > 5
        ? existingDates.sublist(0, 5) +
            ['...以及 ${existingDates.length - 5} 个其他日期']
        : existingDates;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(localizations.translate('shift_conflict')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localizations.translate('shift_conflict_message')),
                const SizedBox(height: 12),
                ...displayDates.map((date) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $date',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    )),
                const SizedBox(height: 12),
                Text(localizations.translate('shift_conflict_confirm')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(localizations.translate('cancel')),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(localizations.translate('overwrite')),
              ),
            ],
          ),
        ) ??
        false;
  }

  // 应用批量排班
  void _applyBatchScheduling() {
    // 如果没有选中的日期，不执行操作
    if (_selectedDays.isEmpty) {
      return;
    }

    // 查找选中日期范围内的最早和最晚日期
    final sortedDates = _selectedDays.toList()..sort();
    final startDate = sortedDates.first;
    final endDate = sortedDates.last;

    context.read<HomeBloc>().add(
          ExecuteBatchScheduling(
            startDate: startDate,
            endDate: endDate,
            shiftTypeId: _selectedShiftTypeId,
            selectedDates: _selectedDays.toList(),
          ),
        );

    Navigator.pop(context);
  }
}
