import 'package:equatable/equatable.dart';
import '../../../data/models/shift_type.dart';

abstract class ShiftTypeEvent extends Equatable {
  const ShiftTypeEvent();

  @override
  List<Object?> get props => [];
}

/// 加载班次类型列表
class LoadShiftTypes extends ShiftTypeEvent {
  const LoadShiftTypes();
}

/// 添加班次类型
class AddShiftType extends ShiftTypeEvent {
  final ShiftType shiftType;

  const AddShiftType(this.shiftType);

  @override
  List<Object?> get props => [shiftType];
}

/// 更新班次类型
class UpdateShiftType extends ShiftTypeEvent {
  final ShiftType shiftType;

  const UpdateShiftType(this.shiftType);

  @override
  List<Object?> get props => [shiftType];
}

/// 删除班次类型
class DeleteShiftType extends ShiftTypeEvent {
  final int id;

  const DeleteShiftType(this.id);

  @override
  List<Object?> get props => [id];
}

/// 搜索班次类型
class SearchShiftTypes extends ShiftTypeEvent {
  final String keyword;

  const SearchShiftTypes(this.keyword);

  @override
  List<Object?> get props => [keyword];
} 