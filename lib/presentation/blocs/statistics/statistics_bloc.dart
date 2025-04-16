import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/shift_repository.dart';
import '../../../data/repositories/shift_type_repository.dart';
import 'handlers/monthly_statistics_handler.dart';
import 'handlers/date_range_statistics_handler.dart';
import 'statistics_event.dart';
import 'statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final ShiftRepository _shiftRepository;
  final ShiftTypeRepository _shiftTypeRepository;

  // 事件处理器
  late final MonthlyStatisticsHandler _monthlyStatisticsHandler;
  late final DateRangeStatisticsHandler _dateRangeStatisticsHandler;

  StatisticsBloc({
    required ShiftRepository shiftRepository,
    required ShiftTypeRepository shiftTypeRepository,
  })  : _shiftRepository = shiftRepository,
        _shiftTypeRepository = shiftTypeRepository,
        super(StatisticsInitial()) {
    // 初始化处理器
    _monthlyStatisticsHandler = MonthlyStatisticsHandler(
      shiftRepository: _shiftRepository,
      shiftTypeRepository: _shiftTypeRepository,
    );

    _dateRangeStatisticsHandler = DateRangeStatisticsHandler(
      shiftRepository: _shiftRepository,
      shiftTypeRepository: _shiftTypeRepository,
    );

    // 注册事件处理函数
    on<LoadMonthlyStatistics>(_onLoadMonthlyStatistics);
    on<LoadDateRangeStatistics>(_onLoadDateRangeStatistics);
    on<UpdateSelectedMonth>(_onUpdateSelectedMonth);
  }

  /// 处理加载月度统计数据事件
  Future<void> _onLoadMonthlyStatistics(
    LoadMonthlyStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    // 如果当前已经有加载的状态，先保存当前月份相关信息
    if (state is StatisticsLoaded) {
      final currentState = state as StatisticsLoaded;

      // 先更新选中月份，保持其他数据，避免闪屏
      emit(currentState.copyWith(
        selectedMonth: DateTime(event.year, event.month),
      ));
    } else {
      // 第一次加载时显示加载状态
      emit(StatisticsLoading());
    }

    // 进行实际数据加载
    final result = await _monthlyStatisticsHandler.handle(event, emit);
    emit(result);
  }

  /// 处理加载日期范围统计数据事件
  Future<void> _onLoadDateRangeStatistics(
    LoadDateRangeStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    final result = await _dateRangeStatisticsHandler.handle(event, emit);
    emit(result);
  }

  /// 处理更新选中月份事件
  Future<void> _onUpdateSelectedMonth(
    UpdateSelectedMonth event,
    Emitter<StatisticsState> emit,
  ) async {
    // 更新选中的月份后，重新加载该月的统计数据
    add(LoadMonthlyStatistics(
      event.selectedMonth.year,
      event.selectedMonth.month,
    ));
  }
}
