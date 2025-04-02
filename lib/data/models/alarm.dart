// 基础闹钟实体 - 用于班次提醒
class Alarm {
  final int? id;
  final int hoursBefore; // 提前小时数
  final int minutesBefore; // 提前分钟数
  final bool enabled; // 是否启用

  const Alarm({
    this.id,
    required this.hoursBefore,
    required this.minutesBefore,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'hoursBefore': hoursBefore,
        'minutesBefore': minutesBefore,
        'enabled': enabled ? 1 : 0,
      };

  factory Alarm.fromMap(Map<String, dynamic> map) => Alarm(
        id: map['id'] as int?,
        hoursBefore: map['hoursBefore'] as int,
        minutesBefore: map['minutesBefore'] as int,
        enabled: (map['enabled'] as int) == 1,
      );

  Alarm copyWith({
    int? id,
    int? hoursBefore,
    int? minutesBefore,
    bool? enabled,
  }) {
    return Alarm(
      id: id ?? this.id,
      hoursBefore: hoursBefore ?? this.hoursBefore,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      enabled: enabled ?? this.enabled,
    );
  }
}

// 扩展闹钟实体 - 用于自定义闹钟
class AlarmEntity {
  final int? id;
  final String? name; // 闹钟名称
  final int timeInMillis; // 闹钟时间（毫秒）
  final bool enabled; // 是否启用
  final bool repeat; // 是否重复
  final int repeatDays; // 重复日期（位图：周日=1，周一=2，周二=4，以此类推）
  final String? soundUri; // 铃声URI
  final bool vibrate; // 是否震动
  final int createTime; // 创建时间
  final int updateTime; // 更新时间
  final int snoozeInterval; // 贪睡间隔（分钟）
  final int maxSnoozeCount; // 最大贪睡次数
  final bool syncToSystem; // 是否同步到系统闹钟

  const AlarmEntity({
    this.id,
    this.name,
    required this.timeInMillis,
    this.enabled = true,
    this.repeat = false,
    this.repeatDays = 0,
    this.soundUri,
    this.vibrate = true,
    required this.createTime,
    required this.updateTime,
    this.snoozeInterval = 5, // 默认5分钟
    this.maxSnoozeCount = 3, // 默认3次
    this.syncToSystem = false, // 默认不同步到系统闹钟
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'timeInMillis': timeInMillis,
        'enabled': enabled ? 1 : 0,
        'repeat': repeat ? 1 : 0,
        'repeatDays': repeatDays,
        'soundUri': soundUri,
        'vibrate': vibrate ? 1 : 0,
        'createTime': createTime,
        'updateTime': updateTime,
        'snoozeInterval': snoozeInterval,
        'maxSnoozeCount': maxSnoozeCount,
        'syncToSystem': syncToSystem ? 1 : 0,
      };

  factory AlarmEntity.fromMap(Map<String, dynamic> map) => AlarmEntity(
        id: map['id'] as int?,
        name: map['name'] as String?,
        timeInMillis: map['timeInMillis'] as int,
        enabled: (map['enabled'] as int) == 1,
        repeat: (map['repeat'] as int) == 1,
        repeatDays: map['repeatDays'] as int,
        soundUri: map['soundUri'] as String?,
        vibrate: (map['vibrate'] as int) == 1,
        createTime: map['createTime'] as int,
        updateTime: map['updateTime'] as int,
        snoozeInterval: map['snoozeInterval'] as int,
        maxSnoozeCount: map['maxSnoozeCount'] as int,
        syncToSystem: map.containsKey('syncToSystem')
            ? (map['syncToSystem'] as int) == 1
            : false,
      );

  AlarmEntity copyWith({
    int? id,
    String? name,
    int? timeInMillis,
    bool? enabled,
    bool? repeat,
    int? repeatDays,
    String? soundUri,
    bool? vibrate,
    int? createTime,
    int? updateTime,
    int? snoozeInterval,
    int? maxSnoozeCount,
    bool? syncToSystem,
  }) {
    return AlarmEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      timeInMillis: timeInMillis ?? this.timeInMillis,
      enabled: enabled ?? this.enabled,
      repeat: repeat ?? this.repeat,
      repeatDays: repeatDays ?? this.repeatDays,
      soundUri: soundUri ?? this.soundUri,
      vibrate: vibrate ?? this.vibrate,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      snoozeInterval: snoozeInterval ?? this.snoozeInterval,
      maxSnoozeCount: maxSnoozeCount ?? this.maxSnoozeCount,
      syncToSystem: syncToSystem ?? this.syncToSystem,
    );
  }
}
