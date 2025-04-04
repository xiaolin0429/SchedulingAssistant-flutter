import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../../models/alarm.dart';
import 'base_dao.dart';

class AlarmDao extends BaseDao<Alarm> {
  static const String _tableName = 'alarms';

  AlarmDao(Database database) : super(database, _tableName);

  Future<Alarm?> getAlarmById(int id) async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Alarm.fromMap(maps.first);
  }

  Future<List<Alarm>> getAllAlarms() async {
    final List<Map<String, dynamic>> maps = await query();
    return maps.map((map) => Alarm.fromMap(map)).toList();
  }

  Future<List<Alarm>> getEnabledAlarms() async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'enabled = ?',
      whereArgs: [1],
    );

    return maps.map((map) => Alarm.fromMap(map)).toList();
  }

  Future<int> insertAlarm(Alarm alarm) async {
    return await insert(alarm.toMap());
  }

  Future<int> updateAlarm(Alarm alarm) async {
    return await update(
      alarm.toMap(),
      'id = ?',
      [alarm.id],
    );
  }

  Future<int> deleteAlarm(int id) async {
    return await delete('id = ?', [id]);
  }

  Future<int> toggleAlarm(int id, bool enabled) async {
    return await update(
      {'enabled': enabled ? 1 : 0},
      'id = ?',
      [id],
    );
  }

  Future<void> deleteAll() async {
    await delete('1 = 1', []);
  }

  Future<int> getAlarmCount() async {
    return await queryCount() ?? 0;
  }

  Future<List<Alarm>> getRepeatingAlarms() async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'repeat = ?',
      whereArgs: [1],
      orderBy: 'timeInMillis ASC',
    );

    return maps.map((map) => Alarm.fromMap(map)).toList();
  }

  Future<List<Alarm>> getAlarmsByTimeRange(int startTime, int endTime) async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'timeInMillis BETWEEN ? AND ?',
      whereArgs: [startTime, endTime],
      orderBy: 'timeInMillis ASC',
    );

    return maps.map((map) => Alarm.fromMap(map)).toList();
  }
}

class AlarmEntityDao extends BaseDao<AlarmEntity> {
  static const String _tableName = 'alarm_entities';

  AlarmEntityDao(Database database) : super(database, _tableName);

  Future<AlarmEntity?> getAlarmById(int id) async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return AlarmEntity.fromMap(maps.first);
  }

  Future<List<AlarmEntity>> getAllAlarms() async {
    final List<Map<String, dynamic>> maps = await query(
      orderBy: 'timeInMillis ASC',
    );
    return maps.map((map) => AlarmEntity.fromMap(map)).toList();
  }

  Future<List<AlarmEntity>> getEnabledAlarms() async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'enabled = ?',
      whereArgs: [1],
      orderBy: 'timeInMillis ASC',
    );

    return maps.map((map) => AlarmEntity.fromMap(map)).toList();
  }

  Future<List<AlarmEntity>> getRepeatAlarms() async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'repeat = ?',
      whereArgs: [1],
      orderBy: 'timeInMillis ASC',
    );

    return maps.map((map) => AlarmEntity.fromMap(map)).toList();
  }

  Future<int> insertAlarm(AlarmEntity alarm) async {
    try {
      debugPrint('AlarmEntityDao准备插入闹钟: ${alarm.toMap()}');
      final id = await insert(alarm.toMap());
      debugPrint('AlarmEntityDao插入成功，ID: $id');
      return id;
    } catch (e) {
      debugPrint('AlarmEntityDao插入闹钟失败: $e');
      throw Exception('数据库插入闹钟失败: $e');
    }
  }

  Future<int> updateAlarm(AlarmEntity alarm) async {
    return await update(
      alarm.toMap(),
      'id = ?',
      [alarm.id],
    );
  }

  Future<int> deleteAlarm(int id) async {
    return await delete('id = ?', [id]);
  }

  Future<int> toggleAlarm(int id, bool enabled) async {
    return await update(
      {'enabled': enabled ? 1 : 0},
      'id = ?',
      [id],
    );
  }

  Future<void> deleteAll() async {
    await delete('1 = 1', []);
  }

  Future<int> getAlarmCount() async {
    return await queryCount() ?? 0;
  }
}
