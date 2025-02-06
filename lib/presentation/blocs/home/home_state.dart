import 'package:equatable/equatable.dart';
import '../../../data/models/shift.dart';
import '../../../data/models/shift_type.dart';
import '../../../data/models/monthly_statistics.dart';

/// 主页状态基类
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// 加载中状态
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// 加载错误状态
class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}

/// 加载完成状态
class HomeLoaded extends HomeState {
  final DateTime selectedDate;
  final Shift? todayShift;
  final List<Shift> monthlyShifts;
  final MonthlyStatistics? monthlyStatistics;
  final bool isSyncing;
  final List<ShiftType>? availableShiftTypes;
  final bool isSelectingShiftType;

  const HomeLoaded({
    required this.selectedDate,
    this.todayShift,
    this.monthlyShifts = const [],
    this.monthlyStatistics,
    this.isSyncing = false,
    this.availableShiftTypes,
    this.isSelectingShiftType = false,
  });

  @override
  List<Object?> get props => [
    selectedDate,
    todayShift,
    monthlyShifts,
    monthlyStatistics,
    isSyncing,
    availableShiftTypes,
    isSelectingShiftType,
  ];

  HomeLoaded copyWith({
    DateTime? selectedDate,
    Shift? todayShift,
    List<Shift>? monthlyShifts,
    MonthlyStatistics? monthlyStatistics,
    bool? isSyncing,
    List<ShiftType>? availableShiftTypes,
    bool? isSelectingShiftType,
  }) {
    return HomeLoaded(
      selectedDate: selectedDate ?? this.selectedDate,
      todayShift: todayShift,
      monthlyShifts: monthlyShifts ?? this.monthlyShifts,
      monthlyStatistics: monthlyStatistics ?? this.monthlyStatistics,
      isSyncing: isSyncing ?? this.isSyncing,
      availableShiftTypes: availableShiftTypes ?? this.availableShiftTypes,
      isSelectingShiftType: isSelectingShiftType ?? this.isSelectingShiftType,
    );
  }
} 