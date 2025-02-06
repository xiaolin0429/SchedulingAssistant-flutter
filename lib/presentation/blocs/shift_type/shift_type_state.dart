import 'package:equatable/equatable.dart';
import '../../../data/models/shift_type.dart';

abstract class ShiftTypeState extends Equatable {
  const ShiftTypeState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class ShiftTypeInitial extends ShiftTypeState {
  const ShiftTypeInitial();
}

/// 加载中状态
class ShiftTypeLoading extends ShiftTypeState {
  const ShiftTypeLoading();
}

/// 加载错误状态
class ShiftTypeError extends ShiftTypeState {
  final String message;

  const ShiftTypeError(this.message);

  @override
  List<Object> get props => [message];
}

/// 加载完成状态
class ShiftTypeLoaded extends ShiftTypeState {
  final List<ShiftType> shiftTypes;
  final bool isSearching;
  final String? searchKeyword;

  const ShiftTypeLoaded({
    required this.shiftTypes,
    this.isSearching = false,
    this.searchKeyword,
  });

  @override
  List<Object?> get props => [shiftTypes, isSearching, searchKeyword];

  ShiftTypeLoaded copyWith({
    List<ShiftType>? shiftTypes,
    bool? isSearching,
    String? searchKeyword,
  }) {
    return ShiftTypeLoaded(
      shiftTypes: shiftTypes ?? this.shiftTypes,
      isSearching: isSearching ?? this.isSearching,
      searchKeyword: searchKeyword ?? this.searchKeyword,
    );
  }
} 