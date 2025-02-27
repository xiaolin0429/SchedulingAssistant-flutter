import 'package:equatable/equatable.dart';

abstract class StatisticsEvent extends Equatable {
  const StatisticsEvent();

  @override
  List<Object?> get props => [];
}

/// 加载月度统计数据事件
class LoadMonthlyStatistics extends StatisticsEvent {
  final int year;
  final int month;

  const LoadMonthlyStatistics(this.year, this.month);

  @override
  List<Object?> get props => [year, month];
}

/// 加载日期范围统计数据事件
class LoadDateRangeStatistics extends StatisticsEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadDateRangeStatistics(this.startDate, this.endDate);

  @override
  List<Object?> get props => [startDate, endDate];
}

/// 更新选择的月份事件
class UpdateSelectedMonth extends StatisticsEvent {
  final DateTime selectedMonth;

  const UpdateSelectedMonth(this.selectedMonth);

  @override
  List<Object?> get props => [selectedMonth];
}