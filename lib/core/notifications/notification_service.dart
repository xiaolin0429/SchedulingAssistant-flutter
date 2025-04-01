import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 设备信息插件实例
final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

/// 通知服务类 - 负责处理应用内所有通知相关功能
/// 包括权限申请、通知创建、调度和管理
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 平台方法通道 - 用于与原生闹钟功能通信
  static const MethodChannel _alarmChannel =
      MethodChannel('com.schedule.assistant/alarm');

  // 通知通道ID
  static const String _alarmChannelId = 'alarm_channel_id';
  static const String _alarmChannelName = '闹钟提醒';
  static const String _alarmChannelDesc = '用于显示闹钟提醒通知';

  // 普通通知通道
  static const String _generalChannelId = 'general_channel_id';
  static const String _generalChannelName = '一般通知';
  static const String _generalChannelDesc = '用于显示一般应用通知';

  // 是否已初始化标志
  bool _isInitialized = false;

  // 通知权限状态
  bool _hasNotificationPermission = false;

  // 通知回调处理
  Function(String?)? onNotificationTap;

  NotificationService._internal();

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 初始化时区数据
      tz_data.initializeTimeZones();

      // Android初始化设置
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS初始化设置 - 初始化时先不请求权限
      const DarwinInitializationSettings iOSInitializationSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        requestCriticalPermission: false,
        requestProvisionalPermission: false,
      );

      // 通用初始化设置
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidInitializationSettings,
        iOS: iOSInitializationSettings,
      );

      // 初始化插件，设置通知响应回调
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // 创建通知通道（仅Android 8.0+需要）
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      _isInitialized = true;
      debugPrint('通知服务初始化完成');

      // 初始化后检查权限状态，但不自动请求权限
      _hasNotificationPermission = await checkPermissions();
    } catch (e) {
      debugPrint('通知服务初始化失败: $e');
    }
  }

  /// 通知响应处理
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('收到通知响应: ${response.payload}');
    if (onNotificationTap != null) {
      onNotificationTap!(response.payload);
    }
  }

  /// 设置通知点击回调
  void setNotificationTapCallback(Function(String?) callback) {
    onNotificationTap = callback;
  }

  /// 创建通知通道（Android 8.0+）
  Future<void> _createNotificationChannels() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin == null) return;

      // 闹钟高优先级通道
      const AndroidNotificationChannel alarmChannel =
          AndroidNotificationChannel(
        _alarmChannelId,
        _alarmChannelName,
        description: _alarmChannelDesc,
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
      );

      // 一般通知通道
      const AndroidNotificationChannel generalChannel =
          AndroidNotificationChannel(
        _generalChannelId,
        _generalChannelName,
        description: _generalChannelDesc,
        importance: Importance.high,
      );

      // 注册通道
      await androidPlugin.createNotificationChannel(alarmChannel);
      await androidPlugin.createNotificationChannel(generalChannel);

      debugPrint('Android通知通道创建成功');
    } catch (e) {
      debugPrint('创建通知通道失败: $e');
    }
  }

  /// 检查是否有通知权限
  Future<bool> checkPermissions() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      debugPrint('开始检查通知权限状态');
      bool permissionResult = false;

      if (Platform.isIOS) {
        // iOS检查权限状态
        final IOSFlutterLocalNotificationsPlugin? iOSPlugin =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>();

        if (iOSPlugin == null) {
          debugPrint('iOS插件未初始化');
          return false;
        }

        // iOS 10+使用这种方式检查
        final bool? permissionStatus = await iOSPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        permissionResult = permissionStatus ?? false;
        debugPrint('iOS通知权限状态: $permissionResult');
      } else if (Platform.isAndroid) {
        // Android 13+ 需要检查权限
        if (await _isAndroid13OrHigher()) {
          final permissionStatus = await Permission.notification.status;
          permissionResult = permissionStatus.isGranted;
          debugPrint(
              'Android 13+ 通知权限状态: $permissionResult (${permissionStatus.name})');
        } else {
          // Android 12及以下默认有权限
          permissionResult = true;
          debugPrint('Android 12及以下默认有通知权限');
        }
      }

      // 更新权限状态
      _hasNotificationPermission = permissionResult;
      debugPrint('通知权限检查结果: $_hasNotificationPermission');
      return _hasNotificationPermission;
    } catch (e) {
      debugPrint('检查通知权限失败: $e');
      return false;
    }
  }

  /// 检查是否为Android 13或更高版本
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    // 使用Android平台API级别检查，Android 13 = API 33
    final androidInfo = await deviceInfoPlugin.androidInfo;
    return androidInfo.version.sdkInt >= 33;
  }

  /// 检查是否为Android 12或更高版本
  Future<bool> _isAndroid12OrHigher() async {
    if (!Platform.isAndroid) return false;

    // 使用Android平台API级别检查，Android 12 = API 31
    final androidInfo = await deviceInfoPlugin.androidInfo;
    return androidInfo.version.sdkInt >= 31;
  }

  /// 请求通知权限 - 仅应在用户明确同意后调用此方法
  /// 返回是否获得权限
  Future<bool> requestPermissions() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (Platform.isIOS) {
        // iOS权限请求
        final IOSFlutterLocalNotificationsPlugin? iOSPlugin =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>();

        if (iOSPlugin != null) {
          // 请求通知权限，包括声音、通知和徽章
          final bool? result = await iOSPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true, // 关键通知（闹钟类）
          );
          _hasNotificationPermission = result ?? false;
          return _hasNotificationPermission;
        }
      } else if (Platform.isAndroid) {
        // Android权限处理
        // 对于Android 13及以上版本，需要POST_NOTIFICATIONS权限
        if (await _isAndroid13OrHigher()) {
          // 使用permission_handler处理权限
          final status = await Permission.notification.request();
          _hasNotificationPermission = status.isGranted;

          // 如果用户拒绝但可以显示原因，提供重试机制
          if (status.isPermanentlyDenied) {
            debugPrint('通知权限被永久拒绝，需要用户在设置中手动开启');
          }

          // 请求精确闹钟权限（Android 12+）
          if (await _isAndroid12OrHigher()) {
            await _requestExactAlarmPermission();
          }

          return _hasNotificationPermission;
        } else {
          // Android 12及以下版本不需要特殊权限请求
          _hasNotificationPermission = true;

          // Android 12需要请求精确闹钟权限
          if (await _isAndroid12OrHigher()) {
            await _requestExactAlarmPermission();
          }

          return true;
        }
      }

      // 其他平台默认为false
      return false;
    } catch (e) {
      debugPrint('请求通知权限失败: $e');
      return false;
    }
  }

  /// 请求精确闹钟权限（Android 12+）
  Future<void> _requestExactAlarmPermission() async {
    try {
      if (Platform.isAndroid && await _isAndroid12OrHigher()) {
        final hasPermission = await _checkExactAlarmPermission();
        if (!hasPermission) {
          await _alarmChannel.invokeMethod('openAlarmSettings');
        }
      }
    } on PlatformException catch (e) {
      debugPrint('请求精确闹钟权限失败: ${e.message}');
    }
  }

  /// 打开应用设置页面（用于用户手动开启权限）
  Future<void> openNotificationSettings() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await openAppSettings();
    }
  }

  /// 检查通知是否已启用（从存储库中获取设置）
  Future<bool> isNotificationEnabled() async {
    try {
      // 使用与SettingsRepository相同的键名
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notification_enabled') ?? true;
      debugPrint('检查通知设置状态: $enabled');
      return enabled;
    } catch (e) {
      debugPrint('检查通知设置失败: $e');
      return false;
    }
  }

  /// 显示即时通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isAlarm = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 检查用户是否启用了通知
    final notificationEnabled = await isNotificationEnabled();
    debugPrint('准备显示通知，通知设置状态: $notificationEnabled');

    if (!notificationEnabled) {
      debugPrint('用户已禁用通知，不发送通知');
      return;
    }

    // 检查权限，但不自动请求权限
    debugPrint('通知权限状态: $_hasNotificationPermission');
    if (!_hasNotificationPermission) {
      debugPrint('通知权限未授予，无法显示通知');
      return;
    }

    try {
      // 创建通知详情
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        isAlarm ? _alarmChannelId : _generalChannelId,
        isAlarm ? _alarmChannelName : _generalChannelName,
        channelDescription: isAlarm ? _alarmChannelDesc : _generalChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        fullScreenIntent: isAlarm, // 闹钟尝试全屏显示
        category: isAlarm
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        playSound: true,
        sound: isAlarm
            ? const RawResourceAndroidNotificationSound('alarm_sound')
            : null,
      );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: isAlarm ? 'alarm_sound.aiff' : null,
        interruptionLevel: isAlarm
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 显示通知
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('通知已发送: $title (ID: $id)');
    } catch (e) {
      debugPrint('发送通知失败: $e');
    }
  }

  /// 安排定时通知（闹钟）
  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool repeatDaily = false,
    List<int>? weekdays,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 检查用户是否启用了通知
    final notificationEnabled = await isNotificationEnabled();
    debugPrint('准备设置闹钟，通知设置状态: $notificationEnabled');

    if (!notificationEnabled) {
      debugPrint('用户已禁用通知，不安排闹钟通知');
      return;
    }

    // 检查权限，但不自动请求权限
    if (!_hasNotificationPermission) {
      debugPrint('通知权限未授予，无法安排闹钟通知');
      return;
    }

    try {
      // 在Android上使用原生AlarmManager以确保准确触发
      if (Platform.isAndroid) {
        final bool useNativeAlarm = await _shouldUseNativeAlarm();
        debugPrint('是否使用原生闹钟: $useNativeAlarm');

        if (useNativeAlarm) {
          await _scheduleNativeAlarm(
              id, title, body, scheduledTime, repeatDaily, weekdays);
          return;
        }
      }

      // 如果不能使用原生闹钟或平台非Android，则使用Flutter Local Notifications
      await _schedulePlatformAlarm(
          id, title, body, scheduledTime, payload, repeatDaily, weekdays);
    } catch (e) {
      debugPrint('安排闹钟通知失败: $e');
    }
  }

  /// 使用Flutter Local Notifications调度闹钟
  Future<void> _schedulePlatformAlarm(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
    String? payload,
    bool repeatDaily,
    List<int>? weekdays,
  ) async {
    // 获取正确的触发时间
    final tz.TZDateTime correctScheduledDate =
        _nextInstanceOfTime(scheduledTime);
    debugPrint(
        '闹钟计划时间: ${scheduledTime.toString()}, 调整后时间: ${correctScheduledDate.toString()}');

    // 闹钟通知详情 - Android
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _alarmChannelId,
      _alarmChannelName,
      channelDescription: _alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true, // 尝试以全屏意图显示（在锁屏上也会显示）
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
    );

    // 闹钟通知详情 - iOS
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm_sound.aiff',
      interruptionLevel: InterruptionLevel.timeSensitive, // 时间敏感中断级别
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 取消之前的相同ID通知（如果存在）
    await flutterLocalNotificationsPlugin.cancel(id);

    // 根据重复配置安排通知
    if (repeatDaily) {
      // 每天重复
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        correctScheduledDate, // 使用调整后的时间
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      debugPrint(
          '每日重复闹钟已设置：$title，时间：${scheduledTime.hour}:${scheduledTime.minute}');
    } else if (weekdays != null && weekdays.isNotEmpty) {
      // 特定日期重复（如每周一、三、五）
      for (int weekday in weekdays) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id + weekday, // 使用不同ID避免冲突
          title,
          body,
          _nextInstanceOfWeekday(scheduledTime, weekday),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      }
      debugPrint('每周重复闹钟已设置：$title，指定星期：$weekdays');
    } else {
      // 单次通知
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        correctScheduledDate, // 使用调整后的时间，确保过去的时间会调整到明天
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('单次闹钟已设置：$title，调整后时间：$correctScheduledDate');
    }
  }

  /// 使用Android原生AlarmManager调度闹钟（更可靠）
  Future<void> _scheduleNativeAlarm(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
    bool repeatDaily,
    List<int>? weekdays,
  ) async {
    try {
      // 计算下一个有效的触发时间
      final DateTime now = DateTime.now();
      final DateTime effectiveTime;

      if (scheduledTime.isBefore(now)) {
        // 如果设置的时间已经过去，调整到明天同一时间
        effectiveTime = DateTime(
          now.year,
          now.month,
          now.day + 1,
          scheduledTime.hour,
          scheduledTime.minute,
          scheduledTime.second,
        );
        debugPrint('闹钟时间已过去，调整到明天: ${effectiveTime.toString()}');
      } else {
        effectiveTime = scheduledTime;
        debugPrint('设置闹钟时间: ${effectiveTime.toString()}');
      }

      final Map<String, dynamic> args = {
        'id': id,
        'title': title,
        'body': body,
        'triggerAtMillis': effectiveTime.millisecondsSinceEpoch,
        'exact': true,
      };

      final bool result =
          await _alarmChannel.invokeMethod('setExactAlarm', args);

      if (result) {
        debugPrint('原生闹钟已设置：$title，时间：$effectiveTime');
      } else {
        debugPrint('设置原生闹钟失败');
        // 失败时回退到插件实现
        await _schedulePlatformAlarm(
            id, title, body, scheduledTime, 'alarm_$id', repeatDaily, weekdays);
      }
    } on PlatformException catch (e) {
      debugPrint('设置原生闹钟出错: ${e.message}');
      // 出错时回退到插件实现
      await _schedulePlatformAlarm(
          id, title, body, scheduledTime, 'alarm_$id', repeatDaily, weekdays);
    }
  }

  /// 检查是否应该使用原生AlarmManager
  Future<bool> _shouldUseNativeAlarm() async {
    if (!Platform.isAndroid) return false;

    // 检查版本：在Android 12+上，使用原生AlarmManager需要特殊权限
    final androidInfo = await deviceInfoPlugin.androidInfo;

    if (androidInfo.version.sdkInt >= 31) {
      // Android 12+
      // 检查是否有精确闹钟权限
      final hasPermission = await _checkExactAlarmPermission();
      return hasPermission;
    }

    // 对于Android 12以下的版本，可以直接使用原生AlarmManager
    return true;
  }

  /// 检查精确闹钟权限（Android 12+）
  Future<bool> _checkExactAlarmPermission() async {
    try {
      if (Platform.isAndroid) {
        final bool hasPermission =
            await _alarmChannel.invokeMethod('checkAlarmPermissions');
        return hasPermission;
      }
      return false;
    } on PlatformException catch (e) {
      debugPrint('检查精确闹钟权限失败: ${e.message}');
      return false;
    }
  }

  /// 取消通知
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;

    try {
      // 如果是Android，同时取消原生闹钟
      if (Platform.isAndroid) {
        try {
          await _alarmChannel.invokeMethod('cancelAlarm', {'id': id});
        } catch (e) {
          debugPrint('取消原生闹钟失败: $e');
        }
      }

      // 取消Flutter Local Notifications的通知
      await flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('通知已取消: ID=$id');
    } catch (e) {
      debugPrint('取消通知失败: $e');
    }
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 如果是Android平台，同时取消所有原生闹钟
      if (Platform.isAndroid) {
        try {
          await _alarmChannel.invokeMethod('cancelAllAlarms');
          debugPrint('所有原生闹钟已取消');
        } catch (e) {
          debugPrint('取消所有原生闹钟失败: $e');
        }
      }

      // 取消Flutter Local Notifications的所有通知
      await flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('所有通知已取消');
    } catch (e) {
      debugPrint('取消所有通知失败: $e');
    }
  }

  /// 获取下一个时间点实例（用于每日重复）
  tz.TZDateTime _nextInstanceOfTime(DateTime time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      time.second,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 获取下一个指定工作日的时间（用于每周特定日期重复）
  tz.TZDateTime _nextInstanceOfWeekday(DateTime time, int weekday) {
    // 注意：weekday 1-7 对应周一到周日
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
