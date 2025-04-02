import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/alarm.dart';
import '../../data/repositories/alarm_repository.dart';
import '../../core/notifications/notification_service.dart';

class AlarmService {
  final AlarmRepository _alarmRepository;
  final NotificationService _notificationService;

  AlarmService(this._alarmRepository, this._notificationService);

  // 获取闹钟流
  Stream<List<AlarmEntity>> get alarmsStream => _alarmRepository.alarmsStream;

  // 基础CRUD操作
  Future<List<AlarmEntity>> getAllAlarms() => _alarmRepository.getAll();

  Future<AlarmEntity?> getAlarmById(int id) => _alarmRepository.getById(id);

  // 添加新闹钟
  Future<int> addAlarm(AlarmEntity alarm) async {
    debugPrint('AlarmService开始添加闹钟: ${alarm.toMap()}');
    // 验证时间是否有效
    if (alarm.timeInMillis < DateTime.now().millisecondsSinceEpoch) {
      throw Exception('闹钟时间不能早于当前时间');
    }

    try {
      // 添加到数据库
      debugPrint('准备插入闹钟到数据库');
      final id = await _alarmRepository.insert(alarm);
      debugPrint('闹钟成功插入数据库，ID: $id');

      // 如果闹钟已启用，则安排通知
      final newAlarm = alarm.copyWith(id: id);
      if (newAlarm.enabled) {
        debugPrint('闹钟已启用，安排通知');
        await _scheduleAlarmNotification(newAlarm);
        debugPrint('闹钟通知已安排');
      }

      return id;
    } catch (e) {
      debugPrint('添加闹钟失败: $e');
      throw Exception('添加闹钟失败: $e');
    }
  }

  // 更新闹钟
  Future<int> updateAlarm(AlarmEntity alarm) async {
    // 对于非重复闹钟，验证时间是否有效
    if (!alarm.repeat &&
        alarm.timeInMillis < DateTime.now().millisecondsSinceEpoch) {
      throw Exception('闹钟时间不能早于当前时间');
    }

    // 更新数据库
    final result = await _alarmRepository.update(alarm);

    // 取消原有通知
    if (alarm.id != null) {
      await _notificationService.cancelNotification(alarm.id!);
    }

    // 如果已启用，重新安排通知
    if (alarm.enabled) {
      await _scheduleAlarmNotification(alarm);
    }

    return result;
  }

  // 删除闹钟
  Future<int> deleteAlarm(int id) async {
    // 取消通知
    await _notificationService.cancelNotification(id);

    // 从数据库删除
    return _alarmRepository.delete(id);
  }

  // 获取所有启用的闹钟
  Future<List<AlarmEntity>> getEnabledAlarms() =>
      _alarmRepository.getEnabledAlarms();

  // 获取所有重复的闹钟
  Future<List<AlarmEntity>> getRepeatingAlarms() =>
      _alarmRepository.getRepeatingAlarms();

  // 获取指定时间范围内的闹钟
  Future<List<AlarmEntity>> getAlarmsByTimeRange(
    DateTime start,
    DateTime end,
  ) =>
      _alarmRepository.getAlarmsByTimeRange(
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      );

  // 更新闹钟启用状态
  Future<int> toggleAlarmEnabled(int id) async {
    final alarm = await getAlarmById(id);
    if (alarm == null) {
      throw Exception('闹钟不存在');
    }

    // 更新启用状态
    final newEnabledState = !alarm.enabled;
    final result =
        await _alarmRepository.updateAlarmEnabled(id, newEnabledState);

    // 处理通知
    if (newEnabledState) {
      // 如果新状态是启用，安排通知
      await _scheduleAlarmNotification(alarm.copyWith(enabled: true));
    } else {
      // 如果新状态是禁用，取消通知
      await _notificationService.cancelNotification(id);
    }

    return result;
  }

  // 更新闹钟重复设置
  Future<int> updateAlarmRepeat(
    int id,
    bool repeat,
    List<int> repeatDays,
  ) async {
    if (repeat && repeatDays.isEmpty) {
      throw Exception('请选择重复日期');
    }

    int repeatDaysBits = 0;
    for (final day in repeatDays) {
      repeatDaysBits |= (1 << day);
    }

    // 更新数据库
    final result =
        await _alarmRepository.updateAlarmRepeat(id, repeat, repeatDaysBits);

    // 更新通知
    final alarm = await getAlarmById(id);
    if (alarm != null && alarm.enabled) {
      // 先取消现有通知
      await _notificationService.cancelNotification(id);

      // 重新安排通知
      await _scheduleAlarmNotification(
          alarm.copyWith(repeat: repeat, repeatDays: repeatDaysBits));
    }

    return result;
  }

  // 获取下一个要触发的闹钟
  Future<AlarmEntity?> getNextAlarm() => _alarmRepository.getNextAlarm();

  // 批量删除闹钟
  Future<int> deleteAlarms(List<int> ids) async {
    // 取消所有相关通知
    for (final id in ids) {
      await _notificationService.cancelNotification(id);
    }

    return _alarmRepository.deleteAll(ids);
  }

  // 安排闹钟通知
  Future<void> _scheduleAlarmNotification(AlarmEntity alarm) async {
    if (alarm.id == null) return;

    // 首先检查通知功能是否已启用
    if (!await _notificationService.isNotificationEnabled()) {
      debugPrint('通知功能未启用，不安排闹钟通知');
      return;
    }

    // 检查并确保有通知权限
    if (!await _notificationService.ensureNotificationPermission()) {
      debugPrint('无法获取通知权限，无法安排闹钟通知');
      return;
    }

    final DateTime alarmTime =
        DateTime.fromMillisecondsSinceEpoch(alarm.timeInMillis);

    final String title = alarm.name ?? '闹钟提醒';
    const String body = '到达设定的闹钟时间了';

    if (alarm.repeat) {
      // 重复闹钟
      if (alarm.repeatDays > 0) {
        // 提取星期几的列表
        final List<int> weekdays = [];
        for (int i = 0; i < 7; i++) {
          if ((alarm.repeatDays & (1 << i)) != 0) {
            weekdays.add(i + 1); // 1-7 表示周一到周日
          }
        }

        await _notificationService.scheduleAlarm(
          id: alarm.id!,
          title: title,
          body: body,
          scheduledTime: alarmTime,
          weekdays: weekdays,
          payload: 'alarm_${alarm.id}',
        );
      } else {
        // 每天重复
        await _notificationService.scheduleAlarm(
          id: alarm.id!,
          title: title,
          body: body,
          scheduledTime: alarmTime,
          repeatDaily: true,
          payload: 'alarm_${alarm.id}',
        );
      }
    } else {
      // 单次闹钟
      await _notificationService.scheduleAlarm(
        id: alarm.id!,
        title: title,
        body: body,
        scheduledTime: alarmTime,
        payload: 'alarm_${alarm.id}',
      );
    }
  }

  // 在应用启动时重新调度所有启用的闹钟
  Future<void> rescheduleAllAlarms() async {
    // 首先检查通知功能是否已启用
    if (!await _notificationService.isNotificationEnabled()) {
      debugPrint('通知功能未启用，不重新调度闹钟');
      return;
    }

    // 检查并申请通知权限（如果需要）
    // 注意：此处不强制申请权限，因为应用启动时不应该主动弹出权限请求
    final hasPermission = await _notificationService.checkPermissions();
    if (!hasPermission) {
      debugPrint('无通知权限，不重新调度闹钟通知');
      return;
    }

    try {
      debugPrint('正在重新调度所有闹钟...');
      // 获取所有启用的闹钟
      final alarms = await getEnabledAlarms();
      // 先取消所有通知
      await _notificationService.cancelAllNotifications();

      // 重新安排每个闹钟的通知
      for (final alarm in alarms) {
        await _scheduleAlarmNotification(alarm);
      }
      debugPrint('共重新调度了 ${alarms.length} 个闹钟');
    } catch (e) {
      debugPrint('重新调度闹钟时出错: $e');
    }
  }

  void dispose() {
    _alarmRepository.dispose();
  }
}
