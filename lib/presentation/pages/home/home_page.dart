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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat(AppLocalizations.of(context)
                                    .translate('date_format_year_month'))
                                .format(state.selectedDate),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          Text(
                            AppLocalizations.of(context).translate('app_title'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.calendar_today_outlined),
                            onPressed: () =>
                                context.read<HomeBloc>().add(const SyncCalendar()),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => Navigator.pushNamed(context, '/settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 班次统计
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: state.availableShiftTypes?.where((type) {
                          final count = state.monthlyStatistics
                                  ?.getTypeCount(type.id ?? 0) ??
                              0;
                          return count > 0;
                        }).map((type) {
                          final count = state.monthlyStatistics
                                  ?.getTypeCount(type.id ?? 0) ??
                              0;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text('${type.name} $count'),
                              onSelected: (_) {},
                              selected: false,
                              backgroundColor: type.colorValue.withValues(alpha: 0.1),
                              labelStyle: TextStyle(
                                color: type.colorValue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: type.colorValue.withValues(alpha: 0.2),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        }).toList() ??
                        [],
                  ),
                ),
                // 日历视图
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          ShiftCalendar(
                            selectedDate: state.selectedDate,
                            shifts: state.monthlyShifts,
                            onDateSelected: (date) {
                              context.read<HomeBloc>().add(SelectDate(date));
                            },
                            enableDaySelection: true,
                          ),
                          const SizedBox(height: 80), // 底部留白，防止内容被遮挡
                        ],
                      ),
                    ),
                  ),
                ),
                // 今日排班卡片 (固定在底部)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SafeArea(
                    top: false,
                    child: Card(
                      margin: EdgeInsets.zero,
                      // 移除卡片默认阴影，与底部容器融为一体
                      elevation: 0,
                      color: Theme.of(context).cardTheme.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // 确保高度自适应
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context)
                                      .translate('today_shift'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                                // 如果有排班，显示简要信息
                                if (state.todayShift != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: state.todayShift!.type.colorValue
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      state.todayShift!.type.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: state.todayShift!.type.colorValue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (state.todayShift == null)
                              // 无排班状态 - 简化显示
                              Row(
                                children: [
                                  Icon(Icons.event_busy_rounded,
                                      size: 24,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.5)),
                                  const SizedBox(width: 12),
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate('no_shift'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  const Spacer(),
                                  FilledButton.icon(
                                    onPressed: () {
                                      if (state.availableShiftTypes != null) {
                                        _showShiftTypeSelectionDialog(
                                          context,
                                          state.availableShiftTypes!,
                                          state.selectedDate,
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.edit_calendar_rounded,
                                        size: 18),
                                    label: Text(
                                        AppLocalizations.of(context)
                                            .translate('add_shift'),
                                        style: const TextStyle(fontSize: 13)),
                                    style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact),
                                  ),
                                ],
                              )
                            else
                              // 有排班状态 - 紧凑显示
                              Column(
                                children: [
                                  if (state.todayShift!.startTime != null &&
                                      state.todayShift!.endTime != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${state.todayShift!.startTime} - ${state.todayShift!.endTime}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // 按钮行
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.tonalIcon(
                                          onPressed: () {
                                            _showNoteDialog(
                                                context, state.todayShift!);
                                          },
                                          icon: const Icon(
                                              Icons.note_add_outlined,
                                              size: 18),
                                          label: Text(
                                            AppLocalizations.of(context)
                                                .translate('add_note'),
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          style: FilledButton.styleFrom(
                                              visualDensity:
                                                  VisualDensity.compact),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () {
                                            if (state.availableShiftTypes !=
                                                null) {
                                              _showShiftTypeSelectionDialog(
                                                context,
                                                state.availableShiftTypes!,
                                                state.selectedDate,
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                              Icons.edit_calendar_rounded,
                                              size: 18),
                                          label: Text(
                                            AppLocalizations.of(context)
                                                .translate('add_shift'),
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          style: FilledButton.styleFrom(
                                              visualDensity:
                                                  VisualDensity.compact),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        context
                                            .read<HomeBloc>()
                                            .add(const StartBatchScheduling());
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
                                      icon: const Icon(Icons.date_range_rounded,
                                          size: 18),
                                      label: Text(
                                          AppLocalizations.of(context)
                                              .translate('batch_scheduling'),
                                          style: const TextStyle(fontSize: 13)),
                                      style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
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
