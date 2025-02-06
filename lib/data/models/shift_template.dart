import 'shift_type_enum.dart';

class ShiftTemplate {
  final int? id;
  final String name; // 非空
  final String? startTime;
  final String? endTime;
  final int color;
  final bool isDefault;
  final int updateTime;
  final ShiftType type;

  const ShiftTemplate({
    this.id,
    required this.name,
    this.startTime,
    this.endTime,
    required this.color,
    required this.isDefault,
    required this.updateTime,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'startTime': startTime,
    'endTime': endTime,
    'color': color,
    'isDefault': isDefault ? 1 : 0,
    'updateTime': updateTime,
    'type': type.toString(),
  };

  factory ShiftTemplate.fromMap(Map<String, dynamic> map) => ShiftTemplate(
    id: map['id'] as int?,
    name: map['name'] as String,
    startTime: map['startTime'] as String?,
    endTime: map['endTime'] as String?,
    color: map['color'] as int,
    isDefault: (map['isDefault'] as int) == 1,
    updateTime: map['updateTime'] as int,
    type: ShiftType.values.firstWhere(
      (e) => e.toString() == map['type'],
      orElse: () => ShiftType.custom,
    ),
  );

  ShiftTemplate copyWith({
    int? id,
    String? name,
    String? startTime,
    String? endTime,
    int? color,
    bool? isDefault,
    int? updateTime,
    ShiftType? type,
  }) {
    return ShiftTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      updateTime: updateTime ?? this.updateTime,
      type: type ?? this.type,
    );
  }
} 