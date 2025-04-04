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

  // 闹钟功能是否启用 - 新增功能开关
  bool _alarmFeaturesEnabled = true;

  // 通知回调处理
  Function(String?)? onNotificationTap;

  NotificationService._internal();

  /// 设置闹钟功能开关
  void setAlarmFeaturesEnabled(bool enabled) {
    _alarmFeaturesEnabled = enabled;
    debugPrint('闹钟功能已${enabled ? '启用' : '禁用'}');
  }

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

      // 不在初始化时检查权限状态，避免触发权限对话框
      // 权限检查将仅在用户主动使用通知功能时执行
      _hasNotificationPermission = false; // 默认假设没有权限，直到用户主动请求
      debugPrint('通知服务初始化完成，权限状态将在需要时检查');
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
        // iOS上强制检查权限状态
        final IOSFlutterLocalNotificationsPlugin? iOSPlugin =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>();

        if (iOSPlugin == null) {
          debugPrint('iOS插件未初始化');
          return false;
        }

        // 在iOS上，即使检查权限状态也可能会触发系统权限请求对话框
        // 我们选择不在这个方法中触发权限请求，而是返回false以便在需要时通过requestPermissions触发
        try {
          // 检查SharedPreferences中缓存的权限状态
          final prefs = await SharedPreferences.getInstance();
          final cachedPermissionStatus =
              prefs.getBool('notification_permission_granted');

          // 如果有缓存状态且为true，则返回true，否则返回false
          if (cachedPermissionStatus == true) {
            debugPrint('iOS通知权限已被缓存为允许状态');
            return true;
          }

          // 如果缓存状态不存在或为false，就假设没有权限
          debugPrint('iOS通知权限状态无效或缓存为false，将重新请求权限');
          return false;
        } catch (e) {
          debugPrint('检查iOS通知权限状态失败: $e');
          return false;
        }
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

      debugPrint('强制请求通知权限');

      if (Platform.isIOS) {
        // iOS权限请求
        final IOSFlutterLocalNotificationsPlugin? iOSPlugin =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>();

        if (iOSPlugin != null) {
          debugPrint('调用iOS原生权限请求...');
          // 请求通知权限，包括声音、通知和徽章
          final bool? result = await iOSPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true, // 关键通知（闹钟类）
          );

          final bool hasPermission = result ?? false;
          _hasNotificationPermission = hasPermission;

          // 缓存权限结果
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(
                'notification_permission_granted', hasPermission);
            debugPrint('已缓存iOS通知权限状态: $hasPermission');
          } catch (e) {
            debugPrint('缓存iOS通知权限状态失败: $e');
          }

          debugPrint('iOS通知权限请求结果: $hasPermission');
          return hasPermission;
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
          // 提示用户需要打开精确闹钟权限
          debugPrint('需要精确闹钟权限，打开系统设置');
          final result = await _alarmChannel.invokeMethod('openAlarmSettings');
          debugPrint('打开闹钟设置结果: $result');
        }
      }
    } on PlatformException catch (e) {
      debugPrint('请求精确闹钟权限失败: ${e.message}');
    }
  }

  /// 检查并申请通知权限（如果需要）
  /// 返回是否已获得权限
  Future<bool> ensureNotificationPermission() async {
    // 重置权限状态，避免错误地认为已有权限
    _hasNotificationPermission = false;

    // 强制检查权限状态
    _hasNotificationPermission = await checkPermissions();

    if (_hasNotificationPermission) {
      debugPrint('检查到已有通知权限，无需申请');
      return true;
    }

    // 不论之前是否已尝试过，都强制申请权限
    debugPrint('正在申请通知权限...');
    final granted = await requestPermissions();
    if (granted) {
      debugPrint('通知权限申请成功');
      // 在Android平台上，还需要检查精确闹钟权限
      if (Platform.isAndroid && await _isAndroid12OrHigher()) {
        await _requestExactAlarmPermission();
      }
    } else {
      debugPrint('用户拒绝通知权限');
    }

    return granted;
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
      final enabled = prefs.getBool('notification_enabled') ?? false;
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

    // 检查并申请通知权限
    if (!await ensureNotificationPermission()) {
      debugPrint('无法获取通知权限，无法显示通知');
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

      // 增强iOS通知配置
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // 尝试多种可能的声音文件命名
        sound: isAlarm ? 'alarm_sound.mp3' : null,
        interruptionLevel: isAlarm
            ? InterruptionLevel.timeSensitive // 闹钟使用时间敏感级别
            : InterruptionLevel.active,
        threadIdentifier: isAlarm ? 'alarm' : 'general', // 分组通知
        categoryIdentifier: isAlarm ? 'alarm_category' : 'message', // 通知类别
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

  /// 获取下一个时间点实例（用于每日重复）
  tz.TZDateTime _nextInstanceOfTime(DateTime time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    debugPrint('当前时间: ${now.toString()}');
    debugPrint('输入的闹钟时间: ${time.toString()}');

    // 提取时分秒
    final int hour = time.hour;
    final int minute = time.minute;
    final int second = time.second;
    debugPrint('提取的时间组件: $hour:$minute:$second');

    // 创建今天的时间点
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      second,
    );

    debugPrint('初始计算的闹钟时间: ${scheduledDate.toString()}');

    // 如果今天的这个时间点已经过去，则安排到明天
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      debugPrint('时间已过去，调整到明天: ${scheduledDate.toString()}');
    }

    // 计算时间差（分钟）
    int minutesUntilAlarm = scheduledDate.difference(now).inMinutes;
    int hoursUntilAlarm = minutesUntilAlarm ~/ 60;
    int remainingMinutes = minutesUntilAlarm % 60;

    debugPrint(
        '闹钟将在 $hoursUntilAlarm 小时 $remainingMinutes 分钟后触发 (总计 $minutesUntilAlarm 分钟)');

    // 再次验证闹钟时间是否合理
    if (hoursUntilAlarm > 23) {
      debugPrint('警告: 计算的小时数过大(${hoursUntilAlarm}h)，可能存在时间计算错误');
    }

    return scheduledDate;
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
    // 检查闹钟功能是否已禁用
    if (!_alarmFeaturesEnabled) {
      debugPrint('闹钟功能已禁用，不安排闹钟通知');
      return;
    }

    if (!_isInitialized) {
      await initialize();
    }

    // 输出原始设置时间，以便于调试
    debugPrint('原始闹钟设置时间: ${scheduledTime.toString()}');
    debugPrint(
        '设置的时间组件 - 小时: ${scheduledTime.hour}, 分钟: ${scheduledTime.minute}');

    // 检查用户是否启用了通知
    final notificationEnabled = await isNotificationEnabled();
    debugPrint('准备设置闹钟，通知设置状态: $notificationEnabled');

    if (!notificationEnabled) {
      debugPrint('用户已禁用通知，不安排闹钟通知');
      return;
    }

    // 检查并申请通知权限
    final hasPermission = await ensureNotificationPermission();
    if (!hasPermission) {
      debugPrint('无法获取通知权限，无法安排闹钟通知');
      // 这里可以添加一些用户可见的提示，告诉用户需要开启通知权限
      return;
    }

    try {
      // 在iOS上使用特殊处理
      if (Platform.isIOS) {
        debugPrint('iOS平台：使用修改后的闹钟调度方案');
        await _scheduleIOSAlarm(
            id, title, body, scheduledTime, payload, repeatDaily, weekdays);
        return;
      }

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

  /// 专门针对iOS平台的闹钟调度方法
  Future<void> _scheduleIOSAlarm(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
    String? payload,
    bool repeatDaily,
    List<int>? weekdays,
  ) async {
    // 检查闹钟功能是否已禁用
    if (!_alarmFeaturesEnabled) {
      debugPrint('闹钟功能已禁用，不安排iOS闹钟通知');
      return;
    }

    // 获取正确的触发时间
    final tz.TZDateTime correctScheduledDate =
        _nextInstanceOfTime(scheduledTime);
    debugPrint(
        'iOS闹钟计划时间: ${scheduledTime.toString()}, 调整后时间: ${correctScheduledDate.toString()}');

    // 格式化显示时间，便于用户理解
    final String formattedTime =
        '${correctScheduledDate.hour.toString().padLeft(2, '0')}:${correctScheduledDate.minute.toString().padLeft(2, '0')}';
    final bool isToday = correctScheduledDate.day == DateTime.now().day;

    // 准备确认通知的文本
    String confirmationTitle = '闹钟已设置';
    String confirmationBody;

    if (isToday) {
      confirmationBody = '闹钟将于今天 $formattedTime 提醒';
    } else {
      confirmationBody = '闹钟将于明天 $formattedTime 提醒';
    }

    // 计算与当前时间的差异（以分钟为单位，更精确）
    final now = tz.TZDateTime.now(tz.local);
    final int minutesUntilAlarm =
        correctScheduledDate.difference(now).inMinutes;
    final int hoursUntilAlarm = minutesUntilAlarm ~/ 60;
    final int remainingMinutes = minutesUntilAlarm % 60;

    debugPrint(
        'iOS闹钟将在 $hoursUntilAlarm 小时 $remainingMinutes 分钟后触发 (总计 $minutesUntilAlarm 分钟)');

    // 如果时间差大于一天，iOS可能不会可靠地触发通知
    if (minutesUntilAlarm > 1440) {
      // 24小时 * 60分钟 = 1440分钟
      debugPrint('警告：iOS闹钟设置时间超过24小时，可能不会可靠触发');
    }

    // 创建iOS专用的通知详情
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm_sound.mp3',
      interruptionLevel: InterruptionLevel.timeSensitive,
      threadIdentifier: 'alarm',
      categoryIdentifier: 'alarm_category',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      iOS: iosDetails,
      android: null, // 因为这是iOS专用方法，所以这里为空
    );

    // 取消之前的相同ID通知（如果存在）
    await flutterLocalNotificationsPlugin.cancel(id);

    // 显示即将到来的闹钟信息
    debugPrint(
        'iOS通知设置详情: ID=$id, 标题=$title, 内容=$body, 时间=${correctScheduledDate.toString()}');

    // 根据重复配置安排通知
    if (repeatDaily) {
      // 每天重复
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        correctScheduledDate,
        notificationDetails,
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle, // 虽然是iOS但插件需要此参数
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload ?? 'alarm_$id',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint(
          'iOS每日重复闹钟已设置：$title，时间：${scheduledTime.hour}:${scheduledTime.minute}');
    } else if (weekdays != null && weekdays.isNotEmpty) {
      // 特定日期重复（如每周一、三、五）
      for (int weekday in weekdays) {
        final repeatDate = _nextInstanceOfWeekday(scheduledTime, weekday);
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id + weekday, // 使用不同ID避免冲突
          title,
          body,
          repeatDate,
          notificationDetails,
          androidScheduleMode:
              AndroidScheduleMode.exactAllowWhileIdle, // 虽然是iOS但插件需要此参数
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload ?? 'alarm_${id}_$weekday',
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
      debugPrint('iOS每周重复闹钟已设置：$title，指定星期：$weekdays');
    } else {
      // 单次通知
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        correctScheduledDate,
        notificationDetails,
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle, // 虽然是iOS但插件需要此参数
        payload: payload ?? 'alarm_$id',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('iOS单次闹钟已设置：$title，调整后时间：$correctScheduledDate');

      // 作为双重保障，也使用立即通知 + 倒计时方式
      if (minutesUntilAlarm < 1440) {
        // 仅对24小时内的闹钟使用此方法
        // 创建一个立即触发但仅在锁屏时显示的提示通知
        await showNotification(
          id: id + 10000, // 使用不同ID避免冲突
          title: confirmationTitle,
          body: confirmationBody,
          payload: 'pending_alarm_$id',
        );
        debugPrint('iOS发送了闹钟确认通知: $confirmationBody');
      }
    }
  }

  /// 格式化持续时间为可读字符串（直接使用小时和分钟）
  String _formatDuration(int hours, int minutes) {
    final List<String> parts = [];

    // 验证时间是否合理，超过24小时的时间可能是计算错误
    if (hours >= 24) {
      // 转换为更易理解的格式 - 天数和小时
      final int days = hours ~/ 24;
      final int remainingHours = hours % 24;

      if (days > 0) parts.add('$days天');
      if (remainingHours > 0) parts.add('$remainingHours小时');
    } else {
      // 正常显示小时
      if (hours > 0) parts.add('$hours小时');
    }

    // 始终显示分钟，即使是0分钟
    if (minutes > 0 || parts.isEmpty) parts.add('$minutes分钟');

    // 如果没有任何部分（极少数情况），显示"马上"
    if (parts.isEmpty) {
      return "马上";
    }

    return parts.join(' ');
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
    // 检查闹钟功能是否已禁用
    if (!_alarmFeaturesEnabled) {
      debugPrint('闹钟功能已禁用，不安排平台闹钟通知');
      return;
    }

    // 获取正确的触发时间
    final tz.TZDateTime correctScheduledDate =
        _nextInstanceOfTime(scheduledTime);
    debugPrint(
        '闹钟计划时间: ${scheduledTime.toString()}, 调整后时间: ${correctScheduledDate.toString()}');

    // 计算与当前时间的差异（以分钟为单位）
    final now = tz.TZDateTime.now(tz.local);
    final int minutesUntilAlarm =
        correctScheduledDate.difference(now).inMinutes;
    final int hoursUntilAlarm = minutesUntilAlarm ~/ 60;
    final int remainingMinutes = minutesUntilAlarm % 60;

    debugPrint('闹钟将在 $hoursUntilAlarm 小时 $remainingMinutes 分钟后触发');

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

    // 更新iOS通知详情以确保声音能够正确播放
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm_sound.mp3', // 确保与项目中的文件名匹配
      // 如果自定义声音无法工作，可以尝试系统声音
      // sound: 'alarm.caf',
      interruptionLevel: InterruptionLevel.timeSensitive, // 时间敏感中断级别
      threadIdentifier: 'alarm', // 用于分组通知
      categoryIdentifier: 'alarm_category', // 通知类别标识符
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 取消之前的相同ID通知（如果存在）
    await flutterLocalNotificationsPlugin.cancel(id);

    // 在iOS上特别记录通知
    if (Platform.isIOS) {
      debugPrint('在iOS上调度闹钟通知，ID: $id, 时间: $correctScheduledDate');
    }

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
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
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
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
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
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('单次闹钟已设置：$title，调整后时间：$correctScheduledDate');

      // 对于非iOS平台，也发送一个确认通知作为双重保障
      if (Platform.isAndroid && minutesUntilAlarm < 1440) {
        // 仅对24小时内的闹钟
        final pendingMessage =
            '闹钟已设置，将在 ${_formatDuration(hoursUntilAlarm, remainingMinutes)} 后提醒';
        await showNotification(
          id: id + 10000, // 使用不同ID避免冲突
          title: '闹钟已设置',
          body: pendingMessage,
          payload: 'pending_alarm_$id',
        );
        debugPrint('Android发送了闹钟确认通知: $pendingMessage');
      }
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
    // 检查闹钟功能是否已禁用
    if (!_alarmFeaturesEnabled) {
      debugPrint('闹钟功能已禁用，不安排原生闹钟通知');
      return;
    }

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

  /// 获取下一个指定工作日的时间（用于每周特定日期重复）
  tz.TZDateTime _nextInstanceOfWeekday(DateTime time, int weekday) {
    // 注意：weekday 1-7 对应周一到周日
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 用户明确开启通知功能后调用，强制请求权限
  /// 这个方法会在用户打开通知开关时调用，会直接触发系统权限请求对话框
  Future<bool> requestPermissionsWhenEnabled() async {
    debugPrint('用户主动启用通知功能，开始请求系统权限');

    if (!_isInitialized) {
      await initialize();
    }

    // 无论当前权限状态如何，都强制请求权限
    bool result = false;

    try {
      if (Platform.isIOS) {
        // iOS权限请求
        final IOSFlutterLocalNotificationsPlugin? iOSPlugin =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>();

        if (iOSPlugin != null) {
          debugPrint('开始请求iOS通知权限');
          // 请求通知权限，包括声音、通知和徽章
          final bool? permissionResult = await iOSPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true, // 关键通知（闹钟类）
          );
          result = permissionResult ?? false;
          debugPrint('iOS通知权限请求结果: $result');

          // 将权限状态缓存到SharedPreferences
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('notification_permission_granted', result);
            debugPrint('iOS通知权限状态已缓存: $result');
          } catch (e) {
            debugPrint('缓存iOS通知权限状态失败: $e');
          }
        }
      } else if (Platform.isAndroid) {
        // Android权限处理
        if (await _isAndroid13OrHigher()) {
          debugPrint('开始请求Android通知权限');
          final status = await Permission.notification.request();
          result = status.isGranted;
          debugPrint('Android通知权限请求结果: $result (${status.name})');

          // 对于Android，也缓存权限状态
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('notification_permission_granted', result);
            debugPrint('Android通知权限状态已缓存: $result');
          } catch (e) {
            debugPrint('缓存Android通知权限状态失败: $e');
          }
        } else {
          // Android 12及以下版本不需要特殊权限请求
          result = true;

          // Android 12及以下自动拥有通知权限，也进行缓存
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('notification_permission_granted', true);
            debugPrint('Android低版本通知权限状态已缓存: true');
          } catch (e) {
            debugPrint('缓存Android低版本通知权限状态失败: $e');
          }
        }

        // 请求精确闹钟权限（Android 12+）
        if (result && await _isAndroid12OrHigher()) {
          await _requestExactAlarmPermission();
        }
      }

      // 更新权限状态
      _hasNotificationPermission = result;
      return result;
    } catch (e) {
      debugPrint('请求通知权限失败: $e');
      return false;
    }
  }
}
