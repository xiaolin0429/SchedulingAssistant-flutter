import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io';
import 'core/di/injection_container.dart' as di;
import 'core/notifications/notification_service.dart';
import 'domain/services/alarm_service.dart';
import 'presentation/blocs/home/home_bloc.dart';
import 'presentation/blocs/home/home_event.dart';
import 'presentation/blocs/shift/shift_bloc.dart';
import 'presentation/blocs/shift/shift_event.dart';
import 'presentation/blocs/alarm/alarm_bloc.dart';
import 'presentation/blocs/alarm/alarm_event.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/settings/settings_event.dart';
import 'presentation/blocs/settings/settings_state.dart';
import 'presentation/blocs/shift_type/shift_type_bloc.dart';
import 'presentation/blocs/shift_type/shift_type_event.dart';
import 'presentation/pages/main_screen.dart';
import 'core/localization/app_localizations.dart';
import 'core/themes/app_theme.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  // 确保Flutter绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
              locale: state.language == 'zh'
                  ? const Locale('zh', 'CN')
                  : const Locale('en', 'US'),
              localeResolutionCallback: (locale, supportedLocales) {
                debugPrint('系统区域设置: $locale');
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale?.languageCode) {
                    debugPrint('使用匹配的区域设置: $supportedLocale');
                    return supportedLocale;
                  }
                }
                debugPrint('使用默认区域设置: ${supportedLocales.first}');
                return supportedLocales.first;
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
}
