import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/models/monthly_statistics.dart';
import '../../../data/models/shift.dart';
import '../../../data/models/shift_type.dart';
import '../../../data/repositories/shift_repository.dart';
import '../../../data/repositories/shift_type_repository.dart';
import 'statistics_event.dart';
import 'statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final ShiftRepository _shiftRepository;
  final ShiftTypeRepository _shiftTypeRepository;

  StatisticsBloc({
    required ShiftRepository shiftRepository,
    required ShiftTypeRepository shiftTypeRepository,
  }) : _shiftRepository = shiftRepository,
       _shiftTypeRepository = shiftTypeRepository,
       super(StatisticsInitial()) {
    on<LoadMonthlyStatistics>(_onLoadMonthlyStatistics);
    on<LoadDateRangeStatistics>(_onLoadDateRangeStatistics);
    on<UpdateSelectedMonth>(_onUpdateSelectedMonth);
  }

  /// 处理加载月度统计数据事件
  Future<void> _onLoadMonthlyStatistics(
    LoadMonthlyStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(StatisticsLoading());

    try {
      // 获取所有班次类型
      final shiftTypes = await _shiftTypeRepository.getAll();
      
      // 获取月度统计数据
      final statistics = await _shiftRepository.getMonthlyStatistics(
        event.year,
        event.month,
      );
      
      // 获取月度班次列表
      final shifts = await _shiftRepository.getShiftsByMonth(
        event.year,
        event.month,
      );

      // 计算每种班次类型的数量
      final Map<ShiftType, int> shiftTypeCountMap = {};
      for (final shiftType in shiftTypes) {
        final count = statistics.getTypeCount(shiftType.id!);
        if (count > 0) {
          shiftTypeCountMap[shiftType] = count;
        }
      }
      
      // 处理已删除班次类型的统计
      final deletedTypeCount = statistics.getTypeCount(-1);
      if (deletedTypeCount > 0) {
        // 创建一个表示已删除班次类型的ShiftType对象
        final deletedShiftType = ShiftType(
          id: -1,
          name: '已删除',
          color: 0xFF808080, // 灰色
          isRestDay: false,
        );
        shiftTypeCountMap[deletedShiftType] = deletedTypeCount;
      }

      // 计算每日工作时长
      final Map<String, double> dailyWorkHours = {};
      final daysInMonth = DateTime(event.year, event.month + 1, 0).day;
      
      // 初始化每天的工作时长为0
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(event.year, event.month, day);
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        dailyWorkHours[dateStr] = 0;
      }
      
      // 更新有班次的日期的工作时长
      for (final shift in shifts) {
        if (!shift.type.isRestDay && shift.startTime != null && shift.endTime != null) {
          // 计算工作时长
          final startTimeParts = shift.startTime!.split(':');
          final endTimeParts = shift.endTime!.split(':');
          
          final startHour = int.parse(startTimeParts[0]);
          final startMinute = int.parse(startTimeParts[1]);
          final endHour = int.parse(endTimeParts[0]);
          final endMinute = int.parse(endTimeParts[1]);
          
          double hours = endHour - startHour + (endMinute - startMinute) / 60;
          // 处理跨天情况
          if (hours < 0) {
            hours += 24;
          }
          
          dailyWorkHours[shift.date] = hours;
        }
      }

      // 更新状态
      emit(StatisticsLoaded(
        statistics: statistics,
        shifts: shifts,
        shiftTypes: shiftTypes,
        selectedMonth: DateTime(event.year, event.month),
        shiftTypeCountMap: shiftTypeCountMap,
        dailyWorkHours: dailyWorkHours,
      ));
    } catch (e) {
      emit(StatisticsError('加载统计数据失败: $e'));
    }
  }

  /// 处理加载日期范围统计数据事件
  Future<void> _onLoadDateRangeStatistics(
    LoadDateRangeStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(StatisticsLoading());

    try {
      // 获取所有班次类型
      final shiftTypes = await _shiftTypeRepository.getAll();
      
      // 获取日期范围内的班次
      final startDateStr = DateFormat('yyyy-MM-dd').format(event.startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(event.endDate);
      final shifts = await _shiftRepository.getShiftsByDateRange(startDateStr, endDateStr);
      
      // 计算每种班次类型的数量
      final Map<ShiftType, int> shiftTypeCountMap = {};
      final Map<int, int> typeCounts = {}; // 用于记录已删除班次类型
      
      for (final shift in shifts) {
        try {
          final shiftType = shift.type;
          if (shiftType.id == null) continue;
          
          shiftTypeCountMap[shiftType] = (shiftTypeCountMap[shiftType] ?? 0) + 1;
          typeCounts[shiftType.id!] = (typeCounts[shiftType.id!] ?? 0) + 1;
        } catch (e) {
          debugPrint('统计班次时出错（可能是已删除的班次类型）');
          // 对于已删除的班次类型，使用特殊的ID（-1）标记
          typeCounts[-1] = (typeCounts[-1] ?? 0) + 1;
        }
      }
      
      // 处理已删除班次类型的统计
      final deletedTypeCount = typeCounts[-1] ?? 0;
      if (deletedTypeCount > 0) {
        // 创建一个表示已删除班次类型的ShiftType对象
        final deletedShiftType = ShiftType(
          id: -1,
          name: '已删除',
          color: 0xFF808080, // 灰色
          isRestDay: false,
        );
        shiftTypeCountMap[deletedShiftType] = deletedTypeCount;
      }
      
      // 计算每日工作时长
      final Map<String, double> dailyWorkHours = {};
      
      // 初始化日期范围内每天的工作时长为0
      for (DateTime date = event.startDate;
           date.isBefore(event.endDate.add(const Duration(days: 1)));
           date = date.add(const Duration(days: 1))) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        dailyWorkHours[dateStr] = 0;
      }
      
      // 更新有班次的日期的工作时长
      for (final shift in shifts) {
        if (!shift.type.isRestDay && shift.startTime != null && shift.endTime != null) {
          // 计算工作时长
          final startTimeParts = shift.startTime!.split(':');
          final endTimeParts = shift.endTime!.split(':');
          
          final startHour = int.parse(startTimeParts[0]);
          final startMinute = int.parse(startTimeParts[1]);
          final endHour = int.parse(endTimeParts[0]);
          final endMinute = int.parse(endTimeParts[1]);
          
          double hours = endHour - startHour + (endMinute - startMinute) / 60;
          // 处理跨天情况
          if (hours < 0) {
            hours += 24;
          }
          
          dailyWorkHours[shift.date] = hours;
        }
      }
      
      // 创建一个临时的月度统计对象
      final Map<int, int> shiftTypeCounts = {};
      for (final entry in shiftTypeCountMap.entries) {
        if (entry.key.id != null) {
          shiftTypeCounts[entry.key.id!] = entry.value;
        }
      }
      
      final totalWorkDays = shifts.where((s) => !s.type.isRestDay).length;
      final totalWorkHours = dailyWorkHours.values.fold(0.0, (sum, hours) => sum + hours).toInt();
      
      final statistics = MonthlyStatistics(
        shiftTypeCounts: shiftTypeCounts,
        totalWorkDays: totalWorkDays,
        totalWorkHours: totalWorkHours,
      );

      // 更新状态
      emit(StatisticsLoaded(
        statistics: statistics,
        shifts: shifts,
        shiftTypes: shiftTypes,
        selectedMonth: event.startDate, // 使用开始日期作为选中月份
        shiftTypeCountMap: shiftTypeCountMap,
        dailyWorkHours: dailyWorkHours,
      ));
    } catch (e) {
      emit(StatisticsError('加载统计数据失败: $e'));
    }
  }

  /// 处理更新选择的月份事件
  void _onUpdateSelectedMonth(
    UpdateSelectedMonth event,
    Emitter<StatisticsState> emit,
  ) {
    add(LoadMonthlyStatistics(event.selectedMonth.year, event.selectedMonth.month));
  }
}