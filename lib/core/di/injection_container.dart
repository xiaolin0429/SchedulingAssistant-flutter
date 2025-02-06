import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database_provider.dart';
import '../../data/repositories/shift_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/shift_type_repository.dart';
import '../../data/repositories/calendar_repository.dart';
import '../../presentation/blocs/home/home_bloc.dart';
import '../../presentation/blocs/settings/settings_bloc.dart';
import '../../presentation/blocs/shift/shift_bloc.dart';
import '../../presentation/blocs/shift_type/shift_type_bloc.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // 初始化SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // 数据库提供者
  final databaseProvider = await DatabaseProvider.initialize();
  getIt.registerSingleton<DatabaseProvider>(databaseProvider);

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

  // Blocs
  getIt.registerFactory<ShiftBloc>(
    () => ShiftBloc(getIt<ShiftRepository>()),
  );

  getIt.registerFactory<SettingsBloc>(
    () => SettingsBloc(getIt<SettingsRepository>()),
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
} 