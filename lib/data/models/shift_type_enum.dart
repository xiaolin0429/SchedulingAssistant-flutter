/// 班次类型枚举
enum ShiftType {
  /// 早班
  dayShift,
  
  /// 晚班
  nightShift,
  
  /// 休息
  rest, custom,
}

/// 班次类型扩展
extension ShiftTypeExtension on ShiftType {
  /// 获取班次类型名称
  String get name {
    switch (this) {
      case ShiftType.dayShift:
        return '早班';
      case ShiftType.nightShift:
        return '晚班';
      case ShiftType.rest:
        return '休息';
      case ShiftType.custom:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// 获取班次类型颜色
  int get color {
    switch (this) {
      case ShiftType.dayShift:
        return 0xFF4CAF50; // 绿色
      case ShiftType.nightShift:
        return 0xFF2196F3; // 蓝色
      case ShiftType.rest:
        return 0xFFFFA726; // 橙色
      case ShiftType.custom:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// 获取默认开始时间
  String? get defaultStartTime {
    switch (this) {
      case ShiftType.dayShift:
        return '08:00';
      case ShiftType.nightShift:
        return '16:00';
      case ShiftType.rest:
        return null;
      case ShiftType.custom:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// 获取默认结束时间
  String? get defaultEndTime {
    switch (this) {
      case ShiftType.dayShift:
        return '16:00';
      case ShiftType.nightShift:
        return '00:00';
      case ShiftType.rest:
        return null;
      case ShiftType.custom:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}

enum SortOption {
  dateAsc,     // 按日期升序
  dateDesc,    // 按日期降序
  type,        // 按类型
  updateTime   // 按更新时间
} 