import 'package:equatable/equatable.dart';
import '../../../data/models/shift.dart';
import '../../../data/models/monthly_statistics.dart';

abstract class ShiftState extends Equatable {
  const ShiftState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class ShiftInitial extends ShiftState {
  const ShiftInitial();
}

/// 加载中状态
class ShiftLoading extends ShiftState {
  const ShiftLoading();
}

/// 加载错误状态
class ShiftError extends ShiftState {
  final String message;

  const ShiftError(this.message);

  @override
  List<Object> get props => [message];
}

/// 加载完成状态
class ShiftLoaded extends ShiftState {
  final List<Shift> shifts;
  final DateTime selectedDate;
  final MonthlyStatistics? monthlyStatistics;

  const ShiftLoaded({
    required this.shifts,
    required this.selectedDate,
    this.monthlyStatistics,
  });

  @override
  List<Object?> get props => [shifts, selectedDate, monthlyStatistics];

  ShiftLoaded copyWith({
    List<Shift>? shifts,
    DateTime? selectedDate,
    MonthlyStatistics? monthlyStatistics,
  }) {
    return ShiftLoaded(
      shifts: shifts ?? this.shifts,
      selectedDate: selectedDate ?? this.selectedDate,
      monthlyStatistics: monthlyStatistics ?? this.monthlyStatistics,
    );
  }
} 