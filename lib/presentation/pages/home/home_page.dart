import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
//import 'package:table_calendar/table_calendar.dart';
import '../../../core/localization/app_localizations.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../blocs/home/home_state.dart';
import '../../widgets/shift_calendar.dart';
import '../../widgets/batch_scheduling_dialog.dart';
import '../../../data/models/shift.dart';
import '../../../data/models/shift_type.dart';
import '../../../core/utils/logger.dart';
import '../../../core/di/injection_container.dart' as di;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    // 记录页面访问
    final logger = di.getIt<LogService>();
    logger.logPageVisit('首页');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is HomeError) {
          return Center(
              child: Text(
                  '${AppLocalizations.of(context).translate('error_message')}: ${state.message}'));
        }

        if (state is HomeLoaded) {
          return SafeArea(
            child: Column(
              children: [
                // 顶部标题栏
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: const Border(
                      bottom: BorderSide(
                        color: Color.fromARGB(51, 158, 158, 158), // 0.2透明度的灰色
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat(AppLocalizations.of(context)
                                .translate('date_format_year_month'))
                            .format(state.selectedDate),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () {
                              context
                                  .read<HomeBloc>()
                                  .add(const SyncCalendar());
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
                    children: state.availableShiftTypes?.map((type) {
                          final count = state.monthlyStatistics
                                  ?.getTypeCount(type.id ?? 0) ??
                              0;
                          return _buildShiftTypeCount(
                            type.name,
                            count,
                            type.colorValue,
                          );
                        }).toList() ??
                        [],
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
                        enableDaySelection: true,
                      ),
                      const SizedBox(height: 16),
                      // 今日排班卡片
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Center(
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('today_shift'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (state.todayShift == null)
                                Center(
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .translate('no_shift'),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${AppLocalizations.of(context).translate('shift_type_label')} ${state.todayShift!.type.name}',
                                      textAlign: TextAlign.center,
                                    ),
                                    if (state.todayShift!.startTime != null &&
                                        state.todayShift!.endTime != null)
                                      Text(
                                        '${AppLocalizations.of(context).translate('shift_time_label')} ${state.todayShift!.startTime} - ${state.todayShift!.endTime}',
                                        textAlign: TextAlign.center,
                                      ),
                                    if (state.todayShift!.note?.isNotEmpty ??
                                        false)
                                      Text(
                                        '${AppLocalizations.of(context).translate('note_label')} ${state.todayShift!.note}',
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
                                        if (state.todayShift != null) {
                                          final logger = di.getIt<LogService>();
                                          logger.logUserAction('点击添加备注按钮');
                                          _showNoteDialog(
                                              context, state.todayShift!);
                                        } else {
                                          // 显示提示信息
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'no_shift_for_note')),
                                              duration:
                                                  const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      icon:
                                          const Icon(Icons.note_add, size: 20),
                                      label: Text(AppLocalizations.of(context)
                                          .translate('add_note')),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        if (state.availableShiftTypes != null) {
                                          final logger = di.getIt<LogService>();
                                          logger.logUserAction('点击添加班次按钮');
                                          _showShiftTypeSelectionDialog(
                                            context,
                                            state.availableShiftTypes!,
                                            state.selectedDate,
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.add, size: 20),
                                      label: Text(AppLocalizations.of(context)
                                          .translate('add_shift')),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        final logger = di.getIt<LogService>();
                                        logger.logUserAction('点击批量排班按钮');

                                        context
                                            .read<HomeBloc>()
                                            .add(const StartBatchScheduling());

                                        // 显示批量排班对话框
                                        if (state.availableShiftTypes != null) {
                                          showDialog(
                                            context: context,
                                            builder: (context) =>
                                                BatchSchedulingDialog(
                                              shiftTypes:
                                                  state.availableShiftTypes!,
                                              initialDate: state.selectedDate,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.date_range,
                                          size: 20),
                                      label: Text(AppLocalizations.of(context)
                                          .translate('batch_scheduling')),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
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

  // 显示添加备注对话框
  void _showNoteDialog(BuildContext context, Shift shift) {
    debugPrint('正在打开备注对话框，班次: ${shift.type.name}');
    final controller = TextEditingController(text: shift.note);

    // 记录用户打开备注对话框
    final logger = di.getIt<LogService>();
    logger.logUserAction('打开备注对话框', data: {
      'date': shift.date,
      'shiftType': shift.type.name,
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('add_note')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).translate('note_hint'),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('取消添加备注');

              // 记录用户取消添加备注
              logger.logUserAction('取消添加备注');

              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              final noteText = controller.text;
              debugPrint('保存备注: $noteText');

              // 记录用户保存备注
              logger.logUserAction('保存备注', data: {
                'date': shift.date,
                'noteLength': noteText.length,
              });

              Navigator.pop(context);

              // 使用新的事件来保存备注
              if (context.mounted) {
                context.read<HomeBloc>().add(
                      SaveNoteToShift(
                        note: noteText,
                        shift: shift,
                      ),
                    );
              }
            },
            child: Text(AppLocalizations.of(context).translate('save')),
          ),
        ],
      ),
    );
  }

  // 显示班次选择对话框
  void _showShiftTypeSelectionDialog(
      BuildContext context, List<ShiftType> shiftTypes, DateTime selectedDate) {
    final dateStr =
        '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日';

    // 记录用户打开班次选择对话框
    final logger = di.getIt<LogService>();
    logger.logUserAction('打开班次选择对话框', data: {
      'date': DateFormat('yyyy-MM-dd').format(selectedDate),
      'availableTypes': shiftTypes.length,
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
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
                subtitle: type.startTimeOfDay != null &&
                        type.endTimeOfDay != null
                    ? Text(
                        '${type.startTimeOfDay!.format(context)} - ${type.endTimeOfDay!.format(context)}')
                    : null,
                onTap: () {
                  // 记录用户选择班次类型
                  logger.logUserAction('选择班次类型', data: {
                    'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                    'shiftTypeId': type.id,
                    'shiftTypeName': type.name,
                  });

                  Navigator.of(context).pop();
                  // 选择班次后，添加更新事件
                  if (context.mounted) {
                    context.read<HomeBloc>().add(
                          UpdateTodayShift(
                            Shift(
                              date:
                                  DateFormat('yyyy-MM-dd').format(selectedDate),
                              type: type,
                              startTime: type.startTime,
                              endTime: type.endTime,
                            ),
                          ),
                        );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 记录用户取消选择班次
              logger.logUserAction('取消选择班次', data: {
                'date': DateFormat('yyyy-MM-dd').format(selectedDate),
              });

              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
        ],
      ),
    );
  }
}
