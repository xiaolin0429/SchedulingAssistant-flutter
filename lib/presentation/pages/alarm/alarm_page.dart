import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../blocs/alarm/alarm_bloc.dart';
import '../../blocs/alarm/alarm_event.dart';
import '../../blocs/alarm/alarm_state.dart';
import '../../../data/models/alarm.dart';
import 'dart:io';

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
        return const AlarmBottomSheet();
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
            // 编辑按钮
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                _showEditAlarmBottomSheet(context, alarm);
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

  void _showEditAlarmBottomSheet(BuildContext context, AlarmEntity alarm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AlarmBottomSheet(alarm: alarm);
      },
    );
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

class AlarmBottomSheet extends StatefulWidget {
  final AlarmEntity? alarm; // 如果为null则是新增，否则是编辑

  const AlarmBottomSheet({super.key, this.alarm});

  @override
  State<AlarmBottomSheet> createState() => _AlarmBottomSheetState();
}

class _AlarmBottomSheetState extends State<AlarmBottomSheet> {
  late TimeOfDay _selectedTime;
  late List<bool> _weekdays; // 周一到周日的重复设置
  bool _syncToSystem = false; // 是否同步到系统闹钟
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.alarm != null;

    if (_isEditing) {
      // 编辑模式初始化
      final alarmTime =
          DateTime.fromMillisecondsSinceEpoch(widget.alarm!.timeInMillis);
      _selectedTime = TimeOfDay(hour: alarmTime.hour, minute: alarmTime.minute);

      // 初始化重复日期
      _weekdays = List.generate(
          7,
          (index) =>
              widget.alarm!.repeat &&
              ((widget.alarm!.repeatDays & (1 << index)) != 0));

      // 初始化同步到系统闹钟的状态
      _syncToSystem = widget.alarm!.syncToSystem;
    } else {
      // 新建模式初始化
      _selectedTime = TimeOfDay.now();
      _weekdays = List.generate(7, (_) => false);
    }

    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final notificationService = di.getIt<NotificationService>();
    final hasPermission = await notificationService.checkPermissions();

    if (!hasPermission && mounted) {
      // 显示权限请求对话框
      _showPermissionDialog();
    }

    setState(() {});
  }

  // 检查并请求系统闹钟权限
  Future<void> _checkSystemAlarmPermission() async {
    final notificationService = di.getIt<NotificationService>();

    // 如果不需要同步到系统闹钟，直接返回
    if (!_syncToSystem) return;

    try {
      if (Platform.isAndroid) {
        // 对于Android，检查精确闹钟权限
        final hasPermission = await notificationService.checkPermissions();
        if (!hasPermission && mounted) {
          // 显示权限请求对话框
          _showSystemAlarmPermissionDialog();
        }
      } else if (Platform.isIOS) {
        // iOS一般不需要特殊闹钟权限，但需要通知权限
        final hasNotificationPermission =
            await notificationService.checkPermissions();
        if (!hasNotificationPermission && mounted) {
          _showPermissionDialog();
        }
      }
    } catch (e) {
      debugPrint('检查系统闹钟权限失败: $e');
    }
  }

  void _showSystemAlarmPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title:
            Text(AppLocalizations.of(context).translate('permission_required')),
        content: const Text('为了确保系统闹钟功能正常工作，需要获取精确闹钟权限。请在接下来的系统设置中授予权限。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _syncToSystem = false; // 用户拒绝授权，关闭同步选项
              });
            },
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // 调用NotificationService中的方法请求精确闹钟权限
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
            title: Text(_isEditing
                ? AppLocalizations.of(context).translate('edit_alarm')
                : AppLocalizations.of(context).translate('add_alarm')),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // 保存闹钟设置到本地存储
                  _saveAlarm();
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

              if (value) {
                // 当启用同步系统闹钟时，检查权限
                _checkSystemAlarmPermission();
              }
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

  void _saveAlarm() async {
    final notificationService = di.getIt<NotificationService>();
    final hasPermission = await notificationService.checkPermissions();

    debugPrint('保存闹钟，当前权限状态: $hasPermission');

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

    // 如果启用了同步到系统闹钟，再次检查相关权限
    if (_syncToSystem) {
      // 检查系统闹钟权限
      if (Platform.isAndroid) {
        final hasExactAlarmPermission =
            await notificationService.checkPermissions();
        if (!hasExactAlarmPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('需要精确闹钟权限才能同步到系统闹钟'),
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: '授权',
                  onPressed: () async {
                    await notificationService.requestPermissions();

                    // 权限请求后再次保存
                    _saveAlarm();
                  },
                ),
              ),
            );
          }
          return;
        }
      }
    }

    // 继续保存闹钟逻辑
    final now = DateTime.now();
    debugPrint('当前时间: $now');

    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    debugPrint('选择的时间: $selectedDateTime');

    // 检查闹钟时间是否有效
    DateTime effectiveDateTime = selectedDateTime;
    if (!_hasRepeatDay() && selectedDateTime.isBefore(now)) {
      // 对于非重复闹钟，如果时间已过，则设置为明天
      effectiveDateTime = selectedDateTime.add(const Duration(days: 1));
      debugPrint('时间已过，调整为明天: $effectiveDateTime');
    }

    try {
      if (_isEditing) {
        // 编辑现有闹钟
        final updatedAlarm = widget.alarm!.copyWith(
          timeInMillis: effectiveDateTime.millisecondsSinceEpoch,
          repeat: _hasRepeatDay(),
          repeatDays: _getRepeatDaysBits(),
          enabled: true,
          syncToSystem: _syncToSystem,
          updateTime: DateTime.now().millisecondsSinceEpoch,
        );
        debugPrint('更新闹钟: $updatedAlarm');

        if (mounted) {
          // 更新闹钟
          context.read<AlarmBloc>().add(UpdateAlarm(updatedAlarm));
          debugPrint('已分发更新闹钟事件');

          // 处理系统闹钟同步
          if (_syncToSystem) {
            _syncToSystemAlarm(updatedAlarm);
          }

          // 关闭底部表单并显示成功提示
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('alarm_updated_success'),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // 创建新闹钟
        final alarm = AlarmEntity(
          id: null, // 新闹钟，ID为null
          name: 'Alarm',
          timeInMillis: effectiveDateTime.millisecondsSinceEpoch,
          repeat: _hasRepeatDay(),
          repeatDays: _getRepeatDaysBits(),
          enabled: true,
          vibrate: true,
          syncToSystem: _syncToSystem,
          createTime: DateTime.now().millisecondsSinceEpoch,
          updateTime: DateTime.now().millisecondsSinceEpoch,
        );
        debugPrint('创建新闹钟: ${alarm.toMap()}');

        if (mounted) {
          // 添加闹钟
          context.read<AlarmBloc>().add(AddAlarm(alarm));
          debugPrint('已分发添加闹钟事件');

          // 关闭底部表单并显示成功提示
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
    } catch (e) {
      debugPrint('保存闹钟时出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存闹钟失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 同步到系统闹钟功能
  Future<void> _syncToSystemAlarm(AlarmEntity alarm) async {
    try {
      final notificationService = di.getIt<NotificationService>();

      // 构建闹钟的基本信息
      final DateTime alarmTime =
          DateTime.fromMillisecondsSinceEpoch(alarm.timeInMillis);
      final String title = alarm.name ?? '闹钟提醒';
      const String body = '到达设定的闹钟时间了';

      // 根据不同平台实现闹钟同步
      if (Platform.isAndroid) {
        // Android平台使用NotificationService中的方法安排原生闹钟
        // 在notification_service.dart中的scheduleAlarm方法会自动检测并使用原生AlarmManager
        // 告诉服务这是系统级闹钟
        await notificationService.scheduleAlarm(
          id: alarm.id!,
          title: title,
          body: body,
          scheduledTime: alarmTime,
          repeatDaily: !alarm.repeat,
          weekdays: _getWeekdaysFromBits(alarm.repeatDays),
          payload: 'system_alarm_${alarm.id}',
        );

        debugPrint('Android设备：闹钟已同步到系统, 时间: ${alarmTime.toString()}');
      } else if (Platform.isIOS) {
        // iOS平台也可以使用NotificationService中的方法
        // 在iOS上，通过设置interruptionLevel为timeSensitive来尽可能接近系统级闹钟
        await notificationService.scheduleAlarm(
          id: alarm.id!,
          title: title,
          body: body,
          scheduledTime: alarmTime,
          repeatDaily: !alarm.repeat,
          weekdays: _getWeekdaysFromBits(alarm.repeatDays),
          payload: 'system_alarm_${alarm.id}',
        );

        debugPrint('iOS设备：闹钟已同步到系统, 时间: ${alarmTime.toString()}');
      }
    } catch (e) {
      debugPrint('同步到系统闹钟失败: $e');
    }
  }

  // 从位图获取星期几列表
  List<int> _getWeekdaysFromBits(int repeatDaysBits) {
    final List<int> weekdays = [];
    for (int i = 0; i < 7; i++) {
      if ((repeatDaysBits & (1 << i)) != 0) {
        weekdays.add(i + 1); // 1-7 表示周一到周日
      }
    }
    return weekdays;
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
