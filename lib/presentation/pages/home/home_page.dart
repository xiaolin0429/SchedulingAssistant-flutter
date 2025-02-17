import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../blocs/home/home_state.dart';
import '../../widgets/shift_calendar.dart';
import '../../widgets/shift_type_selection_dialog.dart';
import '../../../data/models/shift.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is HomeError) {
          return Center(child: Text('错误: ${state.message}'));
        }

        if (state is HomeLoaded) {
          // 如果正在选择班次类型，显示选择对话框
          if (state.isSelectingShiftType && state.availableShiftTypes != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!state.isSelectingShiftType) return;
              if (!context.mounted) return;
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (dialogContext) => ShiftTypeSelectionDialog(
                  shiftTypes: state.availableShiftTypes!,
                  selectedDate: state.selectedDate,
                  onSelected: (selectedType) {
                    if (!context.mounted) return;
                    context.read<HomeBloc>().add(
                      UpdateTodayShift(
                        Shift(
                          date: DateFormat('yyyy-MM-dd').format(state.selectedDate),
                          type: selectedType,
                          startTime: selectedType.startTime,
                          endTime: selectedType.endTime,
                        ),
                      ),
                    );
                  },
                ),
              );
            });
          }

          return SafeArea(
            child: Column(
              children: [
                // 顶部标题栏
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy年MM月').format(state.selectedDate),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () {
                              context.read<HomeBloc>().add(const SyncCalendar());
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cloud_sync),
                            onPressed: () {
                              context.read<HomeBloc>().add(const SyncData());
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              Navigator.pushNamed(context, '/settings');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 班次统计
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildShiftTypeCount('早班', state.monthlyStatistics?.dayShiftCount ?? 0, Colors.green),
                      _buildShiftTypeCount('夜班', state.monthlyStatistics?.nightShiftCount ?? 0, Colors.blue),
                      _buildShiftTypeCount('休息', state.monthlyStatistics?.restDayCount ?? 0, Colors.orange),
                    ],
                  ),
                ),
                // 日历视图
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      ShiftCalendar(
                        selectedDate: state.selectedDate,
                        shifts: state.monthlyShifts,
                        onDateSelected: (date) {
                          // 只更新选中的日期，不触发排班对话框
                          context.read<HomeBloc>().add(SelectDate(date));
                        },
                      ),
                      const SizedBox(height: 16),
                      // 今日排班卡片
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Center(
                                child: Text(
                                  '今日排班',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (state.todayShift == null)
                                const Center(
                                  child: Text(
                                    '暂无班次',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '班次类型: ${state.todayShift!.type.name}',
                                      textAlign: TextAlign.center,
                                    ),
                                    if (state.todayShift!.startTime != null && state.todayShift!.endTime != null)
                                      Text(
                                        '时间: ${state.todayShift!.startTime} - ${state.todayShift!.endTime}',
                                        textAlign: TextAlign.center,
                                      ),
                                    if (state.todayShift!.note?.isNotEmpty ?? false)
                                      Text(
                                        '备注: ${state.todayShift!.note}',
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              // 按钮行
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        context.read<HomeBloc>().add(const ShowNoteDialog());
                                      },
                                      icon: const Icon(Icons.note_add, size: 20),
                                      label: const Text('添加备注'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // 只有点击开始排班按钮时，才触发排班对话框
                                        context.read<HomeBloc>().add(const StartShift());
                                      },
                                      icon: const Icon(Icons.add, size: 20),
                                      label: const Text('开始排班'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        context.read<HomeBloc>().add(const NextShift());
                                      },
                                      icon: const Icon(Icons.skip_next, size: 20),
                                      label: const Text('下一班次'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return const Center(child: Text('未知状态'));
      },
    );
  }

  Widget _buildShiftTypeCount(String type, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('$type: $count'),
      ],
    );
  }
}