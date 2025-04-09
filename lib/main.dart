import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'core/di/injection_container.dart' as di;
import 'core/notifications/notification_service.dart';
import 'core/utils/logger.dart';
import 'presentation/blocs/home/home_bloc.dart';
import 'presentation/blocs/home/home_event.dart';
import 'presentation/blocs/shift/shift_bloc.dart';
import 'presentation/blocs/shift/shift_event.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/settings/settings_event.dart';
import 'presentation/blocs/settings/settings_state.dart';
import 'presentation/blocs/shift_type/shift_type_bloc.dart';
import 'presentation/blocs/shift_type/shift_type_event.dart';
import 'presentation/pages/main_screen.dart';
import 'core/localization/app_localizations.dart';
import 'core/themes/app_theme.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'data/repositories/settings_repository.dart';

void main() async {
  // 确保Flutter绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志服务
  final logger = LogService();
  await logger.initialize();
  logger.i('应用启动', tag: 'APP');

  // 获取设备信息
  final deviceInfo = DeviceInfoPlugin();
  String? osName;
  String? osVersion;

  try {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      osName = 'Android';
      osVersion = androidInfo.version.release;
      logger.i('运行在 Android $osVersion，SDK ${androidInfo.version.sdkInt}',
          tag: 'DEVICE');
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      osName = 'iOS';
      osVersion = iosInfo.systemVersion;
      logger.i('运行在 iOS $osVersion', tag: 'DEVICE');
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      osName = 'Windows';
      osVersion = windowsInfo.displayVersion;
      logger.i('运行在 Windows $osVersion', tag: 'DEVICE');
    } else if (Platform.isMacOS) {
      final macOsInfo = await deviceInfo.macOsInfo;
      osName = 'macOS';
      osVersion = macOsInfo.osRelease;
      logger.i('运行在 macOS $osVersion', tag: 'DEVICE');
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      osName = 'Linux';
      osVersion = linuxInfo.versionId;
      logger.i('运行在 Linux $osVersion', tag: 'DEVICE');
    }
  } catch (e) {
    logger.e('获取设备信息时出错', tag: 'DEVICE', error: e);
  }

  // 初始化依赖注入
  logger.i('开始初始化依赖注入', tag: 'DI');
  await di.initDependencies();
  logger.i('依赖注入初始化完成', tag: 'DI');

  // 获取依赖注入容器中的LogService实例
  final logService = di.getIt<LogService>();

  // 确保通知服务已初始化
  logService.i('开始初始化通知服务', tag: 'NOTIFICATION');
  final notificationService = di.getIt<NotificationService>();
  await notificationService.initialize(); // 如果已初始化，该方法会自动返回
  logService.i('通知服务初始化完成', tag: 'NOTIFICATION');

  // 设置闹钟功能禁用标志
  notificationService.setAlarmFeaturesEnabled(false);
  logService.i('闹钟功能已禁用', tag: 'NOTIFICATION');

  // 为iOS增强闹钟通知功能 - 暂时注释掉闹钟相关代码
  /*
  if (Platform.isIOS) {
    try {
      // 获取UNUserNotificationCenter实例
      final plugin = notificationService.flutterLocalNotificationsPlugin;
      final ios = plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (ios != null) {
        // 请求通知权限，包括声音、通知和徽章
        final bool? permissionResult = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true, // 关键通知（闹钟类）
        );

        debugPrint('iOS通知权限请求结果: ${permissionResult ?? false}');
      }
    } catch (e) {
      debugPrint('初始化iOS通知失败: $e');
    }
  }

  // 仅在通知功能已启用时才重新调度闹钟通知
  // 检查用户是否启用了通知
  if (await notificationService.isNotificationEnabled()) {
    debugPrint('通知功能已启用，准备初始化闹钟');
    // 在启动时重新调度所有闹钟通知
    final alarmService = di.getIt<AlarmService>();
    await alarmService.rescheduleAllAlarms();
  } else {
    debugPrint('通知功能未启用，不初始化闹钟');
  }
  */

  // 取消所有已设置的闹钟通知
  await notificationService.cancelAllNotifications();

  // 启动应用程序
  logService.i('准备启动应用程序UI', tag: 'APP');
  runApp(MyApp(osName: osName, osVersion: osVersion));
  logService.i('应用程序UI已启动', tag: 'APP');
}

class MyApp extends StatefulWidget {
  final String? osName;
  final String? osVersion;

  const MyApp({super.key, this.osName, this.osVersion});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 记录应用创建
    final logger = di.getIt<LogService>();
    logger.logAppState('应用初始化完成', details: '应用程序UI初始化完成');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final logger = di.getIt<LogService>();

    switch (state) {
      case AppLifecycleState.resumed:
        logger.logAppState('应用恢复', details: '应用从后台恢复到前台');
        break;
      case AppLifecycleState.inactive:
        logger.logAppState('应用不活跃', details: '应用处于不活跃状态');
        break;
      case AppLifecycleState.paused:
        logger.logAppState('应用暂停', details: '应用进入后台');
        // 确保日志缓冲区被刷新到文件
        logger.flushLogs();
        break;
      case AppLifecycleState.detached:
        logger.logAppState('应用分离', details: '应用与视图分离');
        // 确保日志缓冲区被刷新到文件
        logger.flushLogs();
        break;
      default:
        logger.logAppState('应用状态变化', details: '状态：$state');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (_) => di.getIt<HomeBloc>()..add(const LoadHomeData()),
        ),
        BlocProvider<ShiftBloc>(
          create: (_) => di.getIt<ShiftBloc>()..add(const LoadShifts()),
        ),
        // 移除闹钟Bloc，但保留引用以避免导致其他地方代码报错
        // BlocProvider<AlarmBloc>(
        //   create: (_) => di.getIt<AlarmBloc>()..add(const LoadAlarms()),
        // ),
        BlocProvider<SettingsBloc>(
          create: (_) => di.getIt<SettingsBloc>()..add(const LoadSettings()),
        ),
        BlocProvider<ShiftTypeBloc>(
          create: (_) => di.getIt<ShiftTypeBloc>()..add(const LoadShiftTypes()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoaded) {
            return MaterialApp(
              title: '排班助手',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: state.themeMode == 'dark'
                  ? ThemeMode.dark
                  : (state.themeMode == 'light'
                      ? ThemeMode.light
                      : ThemeMode.system),
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('zh', 'CN'),
                Locale('en', 'US'),
              ],
              locale: _getAppLocale(state.language),
              localeResolutionCallback: (locale, supportedLocales) {
                debugPrint('系统区域设置回调: $locale');
                if (widget.osName != null && widget.osVersion != null) {
                  debugPrint('操作系统信息: ${widget.osName} ${widget.osVersion}');
                }

                // 如果区域设置为null，则默认使用中文
                if (locale == null) {
                  debugPrint('系统区域设置为null，默认使用中文');
                  return const Locale('zh', 'CN');
                }

                // 中文处理 - 匹配任何中文变体
                if (locale.languageCode.startsWith('zh')) {
                  debugPrint('检测到中文系统区域: $locale，使用中文');
                  return const Locale('zh', 'CN');
                }

                // 标准匹配逻辑
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale.languageCode) {
                    debugPrint('找到匹配的区域设置: $supportedLocale');
                    return supportedLocale;
                  }
                }

                // 未找到匹配时默认使用中文，而不是第一个支持的语言
                debugPrint('未找到匹配的区域设置，默认使用中文');
                return const Locale('zh', 'CN');
              },
              home: const MainScreen(),
            );
          }
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        },
      ),
    );
  }

  Locale? _getAppLocale(String languageSetting) {
    // 如果设置为跟随系统
    if (languageSetting == SettingsRepository.languageSystem) {
      // 主动检测系统默认语言，而不是返回null
      final systemLocale = ui.PlatformDispatcher.instance.locale;
      debugPrint('主动检测到系统语言: $systemLocale');

      // 优先匹配中文 (zh, zh_CN, zh_Hans 等任何中文变体)
      if (systemLocale.languageCode.startsWith('zh')) {
        debugPrint('匹配到中文系统语言，使用中文');
        return const Locale('zh', 'CN');
      }

      // 匹配英文 (en, en_US 等任何英文变体)
      if (systemLocale.languageCode.startsWith('en')) {
        debugPrint('匹配到英文系统语言，使用英文');
        return const Locale('en', 'US');
      }

      // 默认使用中文
      debugPrint('未匹配到已支持的系统语言，默认使用中文');
      return const Locale('zh', 'CN');
    }
    // 如果明确指定了语言
    else if (languageSetting == SettingsRepository.languageZh) {
      return const Locale('zh', 'CN');
    } else if (languageSetting == SettingsRepository.languageEn) {
      return const Locale('en', 'US');
    }
    // 默认返回中文
    return const Locale('zh', 'CN');
  }
}
