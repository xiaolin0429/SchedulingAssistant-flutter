import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../blocs/alarm/alarm_bloc.dart';
import '../../blocs/alarm/alarm_event.dart';
import '../../blocs/alarm/alarm_state.dart';
import '../../../data/models/alarm.dart';

class AlarmPage extends StatelessWidget {
  const AlarmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部提示文本
            Container(
              padding: const EdgeInsets.all(16.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).translate('alarm_permission_tip'),
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),

            // 闹钟列表或空状态
            Expanded(
              child: BlocBuilder<AlarmBloc, AlarmState>(
                builder: (context, state) {
                  if (state is AlarmLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is AlarmError) {
                    return Center(child: Text('错误: ${state.message}'));
                  } else if (state is AlarmLoaded) {
                    if (state.alarms.isEmpty) {
                      return _buildEmptyState(context);
                    } else {
                      return _buildAlarmList(context, state.alarms);
                    }
                  }
                  return _buildEmptyState(context);
                },
              ),
            ),
          ],
        ),
      ),
      // 添加闹钟按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddAlarmBottomSheet(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).translate('no_alarm'),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmList(BuildContext context, List<AlarmEntity> alarms) {
    return ListView.builder(
      itemCount: alarms.length,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        return AlarmListItem(alarm: alarm);
      },
    );
  }

  void _showAddAlarmBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const AddAlarmBottomSheet();
      },
    );
  }
}

class AlarmListItem extends StatelessWidget {
  final AlarmEntity alarm;

  const AlarmListItem({super.key, required this.alarm});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch(alarm.timeInMillis);
    final formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 时间
            Text(
              formattedTime,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm.name ??
                        AppLocalizations.of(context).translate('alarm'),
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  if (alarm.repeat)
                    Text(
                      _getWeekdaysText(context, alarm.repeatDays),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            // 开关
            Switch(
              value: alarm.enabled,
              onChanged: (value) {
                context.read<AlarmBloc>().add(ToggleAlarmEnabled(alarm.id!));
              },
            ),
            // 删除按钮
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmation(context, alarm);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekdaysText(BuildContext context, int repeatDaysBits) {
    final List<String> weekdays = [
      AppLocalizations.of(context).translate('weekday_mon'),
      AppLocalizations.of(context).translate('weekday_tue'),
      AppLocalizations.of(context).translate('weekday_wed'),
      AppLocalizations.of(context).translate('weekday_thu'),
      AppLocalizations.of(context).translate('weekday_fri'),
      AppLocalizations.of(context).translate('weekday_sat'),
      AppLocalizations.of(context).translate('weekday_sun'),
    ];

    final List<String> activeDays = [];
    for (int i = 0; i < 7; i++) {
      if ((repeatDaysBits & (1 << i)) != 0) {
        activeDays.add(weekdays[i]);
      }
    }

    if (activeDays.length == 7) {
      return AppLocalizations.of(context).translate('every_day');
    } else if (activeDays.length == 5 && ((repeatDaysBits & 0x3E) == 0x3E)) {
      // 周一到周五
      return AppLocalizations.of(context).translate('weekdays');
    } else if (activeDays.length == 2 && ((repeatDaysBits & 0x41) == 0x41)) {
      // 周六和周日
      return AppLocalizations.of(context).translate('weekends');
    } else {
      return activeDays.join(', ');
    }
  }

  void _showDeleteConfirmation(BuildContext context, AlarmEntity alarm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('delete_alarm')),
        content: Text(
            AppLocalizations.of(context).translate('delete_alarm_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AlarmBloc>().add(DeleteAlarm(alarm.id!));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      AppLocalizations.of(context).translate('alarm_deleted')),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              AppLocalizations.of(context).translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class AddAlarmBottomSheet extends StatefulWidget {
  const AddAlarmBottomSheet({super.key});

  @override
  State<AddAlarmBottomSheet> createState() => _AddAlarmBottomSheetState();
}

class _AddAlarmBottomSheetState extends State<AddAlarmBottomSheet> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  final List<bool> _weekdays = List.generate(7, (_) => false); // 周一到周日的重复设置
  bool _syncToSystem = false; // 是否同步到系统闹钟

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final notificationService = di.getIt<NotificationService>();
    final hasPermission = await notificationService.checkPermissions();

    if (!hasPermission && mounted) {
      // 显示权限请求对话框
      _showPermissionDialog();
    }

    setState(() {
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title:
            Text(AppLocalizations.of(context).translate('permission_required')),
        content: Text(
            AppLocalizations.of(context).translate('alarm_permission_explain')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate('later')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final notificationService = di.getIt<NotificationService>();
              await notificationService.requestPermissions();
            },
            child: Text(
                AppLocalizations.of(context).translate('grant_permission')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          AppBar(
            title: Text(AppLocalizations.of(context).translate('add_alarm')),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // 保存闹钟设置到本地存储
                  _saveAlarm(context);
                },
                child: Text(AppLocalizations.of(context).translate('save')),
              ),
            ],
          ),

          // 时间选择器
          ListTile(
            title: Text(AppLocalizations.of(context).translate('alarm_time')),
            trailing: TextButton(
              onPressed: () async {
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
              child: Text(
                _selectedTime.format(context),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 重复设置
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).translate('repeat'),
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (int i = 0; i < 7; i++)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _weekdays[i] = !_weekdays[i];
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _weekdays[i] ? Colors.blue : Colors.grey[200],
                          ),
                          child: Center(
                            child: Text(
                              _getWeekdayShortName(context, i),
                              style: TextStyle(
                                color: _weekdays[i]
                                    ? Colors.white
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 同步到系统闹钟开关
          SwitchListTile(
            title: Text(
                AppLocalizations.of(context).translate('sync_to_system_alarm')),
            value: _syncToSystem,
            onChanged: (bool value) {
              setState(() {
                _syncToSystem = value;
              });
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getWeekdayShortName(BuildContext context, int index) {
    final weekdayKeys = [
      'weekday_mon',
      'weekday_tue',
      'weekday_wed',
      'weekday_thu',
      'weekday_fri',
      'weekday_sat',
      'weekday_sun'
    ];
    return AppLocalizations.of(context).translate(weekdayKeys[index]);
  }

  void _saveAlarm(BuildContext context) async {
    final notificationService = di.getIt<NotificationService>();
    final hasPermission = await notificationService.checkPermissions();

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).translate('alarm_permission_tip')),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: AppLocalizations.of(context).translate('grant_permission'),
              onPressed: () async {
                await notificationService.requestPermissions();
              },
            ),
          ),
        );
      }
      return;
    }

    // 继续保存闹钟逻辑
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // 检查闹钟时间是否有效
    if (!_hasRepeatDay() && selectedDateTime.isBefore(now)) {
      // 对于非重复闹钟，如果时间已过，则设置为明天
      selectedDateTime.add(const Duration(days: 1));
    }

    // 创建闹钟实体
    final alarm = AlarmEntity(
      id: null, // 新闹钟，ID为null
      name: 'Alarm',
      timeInMillis: selectedDateTime.millisecondsSinceEpoch,
      repeat: _hasRepeatDay(),
      repeatDays: _getRepeatDaysBits(),
      enabled: true,
      vibrate: true,
      createTime: DateTime.now().millisecondsSinceEpoch,
      updateTime: DateTime.now().millisecondsSinceEpoch,
    );

    // 添加闹钟
    context.read<AlarmBloc>().add(AddAlarm(alarm));

    // 关闭底部表单并显示成功提示
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('alarm_added_success'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  bool _hasRepeatDay() {
    return _weekdays.contains(true);
  }

  int _getRepeatDaysBits() {
    int repeatDaysBits = 0;
    if (_hasRepeatDay()) {
      for (int i = 0; i < _weekdays.length; i++) {
        if (_weekdays[i]) {
          repeatDaysBits |= (1 << i);
        }
      }
    }
    return repeatDaysBits;
  }
}
