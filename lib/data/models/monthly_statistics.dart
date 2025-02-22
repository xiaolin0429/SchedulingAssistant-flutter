/// 月度统计数据模型
class MonthlyStatistics {
  /// 按班次类型统计的天数
  final Map<int, int> shiftTypeCounts;
  
  /// 总工作天数
  final int totalWorkDays;
  
  /// 总工作时长（小时）
  final int totalWorkHours;

  const MonthlyStatistics({
    required this.shiftTypeCounts,
    this.totalWorkDays = 0,
    this.totalWorkHours = 0,
  });

  /// 从Map创建实例
  factory MonthlyStatistics.fromMap(Map<String, dynamic> map) {
    return MonthlyStatistics(
      shiftTypeCounts: Map<int, int>.from(map['shiftTypeCounts'] as Map),
      totalWorkDays: map['totalWorkDays'] as int? ?? 0,
      totalWorkHours: map['totalWorkHours'] as int? ?? 0,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'shiftTypeCounts': shiftTypeCounts,
      'totalWorkDays': totalWorkDays,
      'totalWorkHours': totalWorkHours,
    };
  }

  /// 创建新实例
  MonthlyStatistics copyWith({
    Map<int, int>? shiftTypeCounts,
    int? totalWorkDays,
    int? totalWorkHours,
  }) {
    return MonthlyStatistics(
      shiftTypeCounts: shiftTypeCounts ?? this.shiftTypeCounts,
      totalWorkDays: totalWorkDays ?? this.totalWorkDays,
      totalWorkHours: totalWorkHours ?? this.totalWorkHours,
    );
  }

  /// 获取指定班次类型的天数
  int getTypeCount(int typeId) => shiftTypeCounts[typeId] ?? 0;
} 