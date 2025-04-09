import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database_provider.dart';
import '../../data/repositories/shift_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/shift_type_repository.dart';
import '../../data/repositories/calendar_repository.dart';
import '../../data/repositories/alarm_repository.dart';
import '../../presentation/blocs/home/home_bloc.dart';
import '../../presentation/blocs/settings/settings_bloc.dart';
import '../../presentation/blocs/shift/shift_bloc.dart';
import '../../presentation/blocs/shift_type/shift_type_bloc.dart';
import '../../presentation/blocs/alarm/alarm_bloc.dart';
import 'statistics_injection.dart';
import '../../domain/services/settings_service.dart';
import '../../domain/services/backup_service.dart';
import '../../domain/services/alarm_service.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/utils/logger.dart';
import '../../presentation/blocs/backup/backup_bloc.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // 日志服务
  final logService = LogService();
  getIt.registerSingleton<LogService>(logService);

  // 初始化SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // 数据库提供者
  final databaseProvider = await DatabaseProvider.initialize();
  getIt.registerSingleton<DatabaseProvider>(databaseProvider);

  // 通知服务
  final notificationService = NotificationService();
  await notificationService.initialize();
  getIt.registerSingleton<NotificationService>(notificationService);

  // Repositories
  getIt.registerLazySingleton<ShiftRepository>(
    () => ShiftRepository(databaseProvider.shiftDao),
  );

  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(prefs),
  );

  getIt.registerLazySingleton<ShiftTypeRepository>(
    () => ShiftTypeRepository(databaseProvider.shiftTypeDao),
  );

  getIt.registerLazySingleton<CalendarRepository>(
    () => CalendarRepository(),
  );

  getIt.registerLazySingleton<AlarmRepository>(
    () => AlarmRepository(databaseProvider.alarmDao),
  );

  // Blocs
  getIt.registerFactory<ShiftBloc>(
    () => ShiftBloc(getIt<ShiftRepository>()),
  );

  getIt.registerFactory<SettingsBloc>(
    () => SettingsBloc(
      getIt<SettingsRepository>(),
      notificationService: getIt<NotificationService>(),
    ),
  );

  getIt.registerFactory<HomeBloc>(
    () => HomeBloc(
      shiftRepository: getIt<ShiftRepository>(),
      settingsRepository: getIt<SettingsRepository>(),
      shiftTypeRepository: getIt<ShiftTypeRepository>(),
      calendarRepository: getIt<CalendarRepository>(),
    ),
  );

  getIt.registerFactory<ShiftTypeBloc>(
    () => ShiftTypeBloc(getIt<ShiftTypeRepository>()),
  );

  // 保留AlarmBloc注册，但内部的服务禁用了闹钟功能
  // 这样可以确保系统中其他依赖AlarmBloc的地方不会崩溃
  getIt.registerFactory<AlarmBloc>(
    () => AlarmBloc(getIt<AlarmService>()),
  );

  // 注册统计模块相关依赖
  registerStatisticsDependencies(getIt);

  // Services
  getIt.registerLazySingleton<SettingsService>(
    () => SettingsService(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<BackupService>(() => BackupService());

  // 保留AlarmService注册，但通知服务设置为禁用闹钟功能
  getIt.registerLazySingleton<AlarmService>(() {
    final service =
        AlarmService(getIt<AlarmRepository>(), getIt<NotificationService>());
    return service;
  });

  // Blocs
  getIt.registerFactory<BackupBloc>(() => BackupBloc(getIt()));
}
