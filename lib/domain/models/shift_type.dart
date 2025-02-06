import 'package:flutter/material.dart';

class ShiftType {
  final String id;
  final String name;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Color color;
  final bool isRestDay;

  const ShiftType({
    required this.id,
    required this.name,
    this.startTime,
    this.endTime,
    required this.color,
    this.isRestDay = false,
  });

  // 用于数据库存储的转换方法
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime != null ? '${startTime!.hour}:${startTime!.minute}' : null,
      'endTime': endTime != null ? '${endTime!.hour}:${endTime!.minute}' : null,
      'color': color.toARGB32(),
      'isRestDay': isRestDay ? 1 : 0,
    };
  }

  // 从数据库数据创建实例的工厂方法
  factory ShiftType.fromMap(Map<String, dynamic> map) {
    return ShiftType(
      id: map['id'],
      name: map['name'],
      startTime: map['startTime'] != null
          ? TimeOfDay(
              hour: int.parse(map['startTime'].split(':')[0]),
              minute: int.parse(map['startTime'].split(':')[1]),
            )
          : null,
      endTime: map['endTime'] != null
          ? TimeOfDay(
              hour: int.parse(map['endTime'].split(':')[0]),
              minute: int.parse(map['endTime'].split(':')[1]),
            )
          : null,
      color: Color(map['color']),
      isRestDay: map['isRestDay'] == 1,
    );
  }

  // 复制方法，用于更新实例
  ShiftType copyWith({
    String? id,
    String? name,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Color? color,
    bool? isRestDay,
  }) {
    return ShiftType(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      isRestDay: isRestDay ?? this.isRestDay,
    );
  }
} 