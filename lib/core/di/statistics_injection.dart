import 'package:get_it/get_it.dart';
import '../../presentation/blocs/statistics/statistics_bloc.dart';
import '../../data/repositories/shift_repository.dart';
import '../../data/repositories/shift_type_repository.dart';

/// 注册统计模块相关的依赖
void registerStatisticsDependencies(GetIt getIt) {
  // 注册StatisticsBloc
  getIt.registerFactory<StatisticsBloc>(
    () => StatisticsBloc(
      shiftRepository: getIt<ShiftRepository>(),
      shiftTypeRepository: getIt<ShiftTypeRepository>(),
    ),
  );
}