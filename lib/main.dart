import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'core/di/injection_container.dart' as di;
import 'core/notifications/notification_service.dart';
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

  // 获取设备信息
  final deviceInfo = DeviceInfoPlugin();
  String? osName;
  String? osVersion;

  try {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      osName = 'Android';
      osVersion = androidInfo.version.release;
      debugPrint('运行在 Android $osVersion，SDK ${androidInfo.version.sdkInt}');
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      osName = 'iOS';
      osVersion = iosInfo.systemVersion;
      debugPrint('运行在 iOS $osVersion');
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      osName = 'Windows';
      osVersion = windowsInfo.displayVersion;
      debugPrint('运行在 Windows $osVersion');
    } else if (Platform.isMacOS) {
      final macOsInfo = await deviceInfo.macOsInfo;
      osName = 'macOS';
      osVersion = macOsInfo.osRelease;
      debugPrint('运行在 macOS $osVersion');
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      osName = 'Linux';
      osVersion = linuxInfo.versionId;
      debugPrint('运行在 Linux $osVersion');
    }
  } catch (e) {
    debugPrint('获取设备信息时出错: $e');
  }

  // 初始化依赖注入
  await di.initDependencies();

  // 确保通知服务已初始化
  final notificationService = di.getIt<NotificationService>();
  await notificationService.initialize(); // 如果已初始化，该方法会自动返回

  // 设置闹钟功能禁用标志
  notificationService.setAlarmFeaturesEnabled(false);

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

  runApp(MyApp(osName: osName, osVersion: osVersion));
}

class MyApp extends StatefulWidget {
  final String? osName;
  final String? osVersion;

  const MyApp({super.key, this.osName, this.osVersion});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
