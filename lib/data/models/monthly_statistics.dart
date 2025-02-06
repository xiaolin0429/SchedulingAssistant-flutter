/// 月度统计数据模型
class MonthlyStatistics {
  /// 早班天数
  final int dayShiftCount;
  
  /// 夜班天数
  final int nightShiftCount;
  
  /// 休息天数
  final int restDayCount;
  
  /// 总工作天数
  final int totalWorkDays;
  
  /// 总工作时长（小时）
  final int totalWorkHours;

  const MonthlyStatistics({
    required this.dayShiftCount,
    required this.nightShiftCount,
    required this.restDayCount,
    this.totalWorkDays = 0,
    this.totalWorkHours = 0,
  });

  /// 从Map创建实例
  factory MonthlyStatistics.fromMap(Map<String, dynamic> map) {
    return MonthlyStatistics(
      dayShiftCount: map['dayShiftCount'] as int,
      nightShiftCount: map['nightShiftCount'] as int,
      restDayCount: map['restDayCount'] as int,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'dayShiftCount': dayShiftCount,
      'nightShiftCount': nightShiftCount,
      'restDayCount': restDayCount,
    };
  }

  /// 创建新实例
  MonthlyStatistics copyWith({
    int? dayShiftCount,
    int? nightShiftCount,
    int? restDayCount,
  }) {
    return MonthlyStatistics(
      dayShiftCount: dayShiftCount ?? this.dayShiftCount,
      nightShiftCount: nightShiftCount ?? this.nightShiftCount,
      restDayCount: restDayCount ?? this.restDayCount,
    );
  }
} 