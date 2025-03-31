import '../models/shift_type.dart';
import '../repositories/shift_type_repository.dart';
import '../../core/di/injection_container.dart';
import 'package:flutter/foundation.dart';

/// 班次模型
class Shift {
  /// ID
  final int? id;

  /// 日期（格式：yyyy-MM-dd）
  final String date;

  /// 班次类型
  final ShiftType type;

  /// 开始时间（格式：HH:mm）
  final String? startTime;

  /// 结束时间（格式：HH:mm）
  final String? endTime;

  /// 备注
  final String? note;

  /// 备注更新时间
  final int noteUpdatedAt;

  /// 更新时间
  final int updateTime;

  Shift({
    this.id,
    required this.date,
    required this.type,
    this.startTime,
    this.endTime,
    this.note,
    int? noteUpdatedAt,
    int? updateTime,
  })  : noteUpdatedAt = noteUpdatedAt ?? DateTime.now().millisecondsSinceEpoch,
        updateTime = updateTime ?? DateTime.now().millisecondsSinceEpoch;

  /// 从Map创建实例
  static Future<Shift> fromMap(Map<String, dynamic> map) async {
    final shiftTypeRepository = getIt<ShiftTypeRepository>();
    final shiftTypeId = map['shiftTypeId'] as int;
    ShiftType? shiftType;

    try {
      shiftType = await shiftTypeRepository.getById(shiftTypeId);
    } catch (e) {
      debugPrint('获取班次类型失败: $e');
    }

    // 如果找不到班次类型，使用默认的"已删除"类型
    if (shiftType == null) {
      debugPrint('班次类型已被删除: $shiftTypeId，使用默认类型');
      shiftType = ShiftType(
        id: -1, // 使用-1表示已删除的类型
        name: '已删除',
        color: 0xFF808080, // 灰色
        isRestDay: false,
      );
    }

    return Shift(
      id: map['id'] as int?,
      date: map['date'] as String,
      type: shiftType,
      startTime: map['startTime'] as String?,
      endTime: map['endTime'] as String?,
      note: map['note'] as String?,
      noteUpdatedAt: map['noteUpdatedAt'] as int?,
      updateTime: map['updateTime'] as int?,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    if (type.id == null) {
      throw Exception('ShiftType must have an ID before saving to database');
    }
    return {
      if (id != null) 'id': id,
      'date': date,
      'type': type.name,
      'shiftTypeId': type.id,
      'startTime': startTime,
      'endTime': endTime,
      'note': note,
      'noteUpdatedAt': noteUpdatedAt,
      'updateTime': updateTime,
    };
  }

  /// 创建新实例
  Shift copyWith({
    int? id,
    String? date,
    ShiftType? type,
    String? startTime,
    String? endTime,
    String? note,
    int? noteUpdatedAt,
    int? updateTime,
  }) {
    return Shift(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      note: note ?? this.note,
      noteUpdatedAt: noteUpdatedAt ?? this.noteUpdatedAt,
      updateTime: updateTime ?? this.updateTime,
    );
  }

  /// 计算工作时长（小时）
  double? get duration {
    if (startTime == null || endTime == null) return null;

    final start = _parseTime(startTime!);
    final end = _parseTime(endTime!);

    if (_compareTime(end, start) < 0) {
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

  /// 比较两个时间
  int _compareTime(DateTime a, DateTime b) {
    if (a.hour != b.hour) {
      return a.hour.compareTo(b.hour);
    }
    return a.minute.compareTo(b.minute);
  }
}
