import 'package:equatable/equatable.dart';
import '../../../data/models/monthly_statistics.dart';
import '../../../data/models/shift.dart';
import '../../../data/models/shift_type.dart';

abstract class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class StatisticsInitial extends StatisticsState {}

/// 加载中状态
class StatisticsLoading extends StatisticsState {}

/// 加载失败状态
class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 加载成功状态
class StatisticsLoaded extends StatisticsState {
  final MonthlyStatistics statistics;
  final List<Shift> shifts;
  final List<ShiftType> shiftTypes;
  final DateTime selectedMonth;
  final Map<ShiftType, int> shiftTypeCountMap;
  final Map<String, double> dailyWorkHours;

  const StatisticsLoaded({
    required this.statistics,
    required this.shifts,
    required this.shiftTypes,
    required this.selectedMonth,
    required this.shiftTypeCountMap,
    required this.dailyWorkHours,
  });

  @override
  List<Object?> get props => [
    statistics,
    shifts,
    shiftTypes,
    selectedMonth,
    shiftTypeCountMap,
    dailyWorkHours,
  ];

  /// 获取总班次数
  int get totalShifts => shifts.length;

  /// 获取班次类型分布百分比
  Map<ShiftType, double> get shiftTypePercentages {
    if (totalShifts == 0) return {};
    
    final Map<ShiftType, double> percentages = {};
    for (final entry in shiftTypeCountMap.entries) {
      percentages[entry.key] = entry.value / totalShifts * 100;
    }
    return percentages;
  }

  /// 获取总工作时长
  double get totalWorkHours {
    return dailyWorkHours.values.fold(0, (sum, hours) => sum + hours);
  }

  /// 获取平均每日工作时长
  double get averageWorkHours {
    final workDays = dailyWorkHours.values.where((hours) => hours > 0).length;
    if (workDays == 0) return 0;
    return totalWorkHours / workDays;
  }

  /// 创建新实例
  StatisticsLoaded copyWith({
    MonthlyStatistics? statistics,
    List<Shift>? shifts,
    List<ShiftType>? shiftTypes,
    DateTime? selectedMonth,
    Map<ShiftType, int>? shiftTypeCountMap,
    Map<String, double>? dailyWorkHours,
  }) {
    return StatisticsLoaded(
      statistics: statistics ?? this.statistics,
      shifts: shifts ?? this.shifts,
      shiftTypes: shiftTypes ?? this.shiftTypes,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      shiftTypeCountMap: shiftTypeCountMap ?? this.shiftTypeCountMap,
      dailyWorkHours: dailyWorkHours ?? this.dailyWorkHours,
    );
  }
}