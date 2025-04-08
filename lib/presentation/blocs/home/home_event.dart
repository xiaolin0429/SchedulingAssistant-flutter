import 'package:equatable/equatable.dart';
import '../../../data/models/shift.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// 加载主页数据
class LoadHomeData extends HomeEvent {
  final DateTime? date;

  const LoadHomeData({this.date});

  @override
  List<Object?> get props => [date];
}

/// 刷新主页数据
class RefreshHomeData extends HomeEvent {
  const RefreshHomeData();
}

/// 选择日期
class SelectDate extends HomeEvent {
  final DateTime date;

  const SelectDate(this.date);

  @override
  List<Object?> get props => [date];
}

/// 同步日历
class SyncCalendar extends HomeEvent {
  const SyncCalendar();
}

/// 同步数据
class SyncData extends HomeEvent {
  const SyncData();
}

/// 显示备注对话框
class ShowNoteDialog extends HomeEvent {
  const ShowNoteDialog();

  @override
  List<Object?> get props => [];
}

/// 保存班次备注
class SaveNoteToShift extends HomeEvent {
  final String note;
  final Shift shift;

  const SaveNoteToShift({
    required this.note,
    required this.shift,
  });

  @override
  List<Object?> get props => [note, shift];
}

/// 开始排班
class StartShift extends HomeEvent {
  const StartShift();
}

/// 下一个班次
class NextShift extends HomeEvent {
  const NextShift();
}

/// 更新今日班次
class UpdateTodayShift extends HomeEvent {
  final Shift shift;

  const UpdateTodayShift(this.shift);

  @override
  List<Object?> get props => [shift];
}

class QuickAddShift extends HomeEvent {
  final Shift shift;

  const QuickAddShift(this.shift);

  @override
  List<Object> get props => [shift];
}

class LoadMonthlyStatistics extends HomeEvent {
  final int year;
  final int month;

  const LoadMonthlyStatistics({
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [year, month];
}

/// 启动批量排班
class StartBatchScheduling extends HomeEvent {
  const StartBatchScheduling();
}

/// 执行批量排班
class ExecuteBatchScheduling extends HomeEvent {
  final DateTime startDate;
  final DateTime endDate;
  final int shiftTypeId;
  final List<DateTime>? selectedDates; // 选中的具体日期

  const ExecuteBatchScheduling({
    required this.startDate,
    required this.endDate,
    required this.shiftTypeId,
    required this.selectedDates,
  });

  @override
  List<Object> get props => [
        startDate,
        endDate,
        shiftTypeId,
        if (selectedDates != null) selectedDates!
      ];
}

/// 重置排班选择状态
class ResetShiftSelection extends HomeEvent {
  const ResetShiftSelection();
}
