import 'package:flutter/material.dart';

/// 班次类型模型
class ShiftType {
  /// ID
  final int? id;

  /// 名称
  final String name;

  /// 开始时间（格式：HH:mm）
  final String? startTime;

  /// 结束时间（格式：HH:mm）
  final String? endTime;

  /// 颜色值
  final int color;

  /// 是否为系统预设类型（仅用于标识，不影响操作）
  final bool isPreset;

  /// 是否为休息日
  final bool isRestDay;

  /// 更新时间
  final int updateTime;

  /// 非常量构造函数，用于创建带有当前时间戳的实例
  ShiftType({
    this.id,
    required this.name,
    this.startTime,
    this.endTime,
    required this.color,
    this.isPreset = false,
    this.isRestDay = false,
    int? updateTime,
  }) : updateTime = updateTime ?? DateTime.now().millisecondsSinceEpoch;

  /// 常量构造函数，用于创建预设实例
  const ShiftType.preset({
    this.id,
    required this.name,
    this.startTime,
    this.endTime,
    required this.color,
    this.isPreset = false,
    this.isRestDay = false,
    required this.updateTime,
  });

  /// 获取开始时间的TimeOfDay对象
  TimeOfDay? get startTimeOfDay {
    if (startTime == null) return null;
    final parts = startTime!.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// 获取结束时间的TimeOfDay对象
  TimeOfDay? get endTimeOfDay {
    if (endTime == null) return null;
    final parts = endTime!.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// 获取颜色对象
  Color get colorValue => Color(color);

  /// 预设的班次类型（可以修改和删除）
  static const List<ShiftType> presets = [
    ShiftType.preset(
      id: 1,
      name: '早班',
      startTime: '08:00',
      endTime: '16:00',
      color: 0xFF4CAF50, // 绿色
      isPreset: true,
      updateTime: 0,
    ),
    ShiftType.preset(
      id: 2,
      name: '晚班',
      startTime: '16:00',
      endTime: '00:00',
      color: 0xFF2196F3, // 蓝色
      isPreset: true,
      updateTime: 0,
    ),
    ShiftType.preset(
      id: 3,
      name: '休息',
      color: 0xFFFFA726, // 橙色
      isPreset: true,
      isRestDay: true,
      updateTime: 0,
    ),
  ];

  /// 从Map创建实例
  factory ShiftType.fromMap(Map<String, dynamic> map) {
    return ShiftType(
      id: map['id'] as int?,
      name: map['name'] as String,
      startTime: map['startTime'] as String?,
      endTime: map['endTime'] as String?,
      color: map['color'] as int,
      isPreset: (map['isPreset'] as int?) == 1,
      isRestDay: (map['isRestDay'] as int?) == 1,
      updateTime: map['updateTime'] as int?,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'color': color,
      'isPreset': isPreset ? 1 : 0,
      'isRestDay': isRestDay ? 1 : 0,
      'updateTime': updateTime,
    };
  }

  /// 创建新实例
  ShiftType copyWith({
    int? id,
    String? name,
    String? startTime,
    String? endTime,
    int? color,
    bool? isPreset,
    bool? isRestDay,
    int? updateTime,
  }) {
    return ShiftType(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      isPreset: isPreset ?? this.isPreset,
      isRestDay: isRestDay ?? this.isRestDay,
      updateTime: updateTime ?? this.updateTime,
    );
  }

  /// 计算工作时长（小时）
  double? get duration {
    if (startTime == null || endTime == null) return null;

    final start = _parseTime(startTime!);
    final end = _parseTime(endTime!);

    if (end.isBefore(start)) {
      // 跨天的情况
      return (24 - start.hour - start.minute / 60) +
          (end.hour + end.minute / 60);
    } else {
      return (end.hour - start.hour) + (end.minute - start.minute) / 60;
    }
  }

  /// 解析时间字符串
  DateTime _parseTime(String time) {
    final parts = time.split(':');
    return DateTime(
      2000,
      1,
      1,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
