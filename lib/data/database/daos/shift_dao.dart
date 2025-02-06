import 'package:sqflite/sqflite.dart';
import '../../models/shift.dart';
import 'base_dao.dart';

/// 班次数据访问对象
class ShiftDao extends BaseDao<Shift> {
  static const String _tableName = 'shifts';

  ShiftDao(Database database) : super(database, _tableName);

  /// 根据ID获取班次
  Future<Shift?> getShiftById(int id) async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return await Shift.fromMap(maps.first);
  }

  /// 获取所有班次
  Future<List<Shift>> getAllShifts() async {
    final List<Map<String, dynamic>> maps = await query(
      orderBy: 'date ASC',
    );
    final shifts = <Shift>[];
    for (final map in maps) {
      shifts.add(await Shift.fromMap(map));
    }
    return shifts;
  }

  /// 根据日期获取班次
  Future<Shift?> getShiftByDate(String date) async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isEmpty) return null;
    return await Shift.fromMap(maps.first);
  }

  /// 获取日期范围内的班次
  Future<List<Shift>> getShiftsByDateRange(String startDate, String endDate) async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    final shifts = <Shift>[];
    for (final map in maps) {
      shifts.add(await Shift.fromMap(map));
    }
    return shifts;
  }

  /// 获取指定类型的班次
  Future<List<Shift>> getShiftsByType(String type) async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date ASC',
    );
    final shifts = <Shift>[];
    for (final map in maps) {
      shifts.add(await Shift.fromMap(map));
    }
    return shifts;
  }

  /// 获取最近的班次
  Future<List<Shift>> getRecentShifts(int limit) async {
    final List<Map<String, dynamic>> maps = await query(
      orderBy: 'date DESC',
      limit: limit,
    );
    final shifts = <Shift>[];
    for (final map in maps) {
      shifts.add(await Shift.fromMap(map));
    }
    return shifts;
  }

  /// 获取下一个班次
  Future<Shift?> getNextShift(String currentDate) async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'date > ?',
      whereArgs: [currentDate],
      orderBy: 'date ASC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return await Shift.fromMap(maps.first);
  }

  /// 插入班次
  Future<int> insertShift(Shift shift) async {
    return await insert(shift.toMap());
  }

  /// 更新班次
  Future<int> updateShift(Shift shift) async {
    return await update(
      shift.toMap(),
      'id = ?',
      [shift.id],
    );
  }

  /// 删除班次
  Future<int> deleteShift(int id) async {
    return await delete('id = ?', [id]);
  }

  /// 删除所有班次
  Future<void> deleteAll() async {
    await delete('1 = 1', []);
  }

  /// 批量插入或更新班次
  Future<void> upsertShifts(List<Shift> shifts) async {
    final batch = database.batch();
    
    for (final shift in shifts) {
      if (shift.id != null) {
        batch.update(
          tableName,
          shift.toMap(),
          where: 'id = ?',
          whereArgs: [shift.id],
        );
      } else {
        batch.insert(tableName, shift.toMap());
      }
    }

    await batch.commit(noResult: true);
  }

  Future<List<Shift>> searchShifts(String keyword) async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'note LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'date DESC',
    );

    final shifts = <Shift>[];
    for (final map in maps) {
      shifts.add(await Shift.fromMap(map));
    }
    return shifts;
  }

  Future<int> getShiftCount() async {
    return await queryCount() ?? 0;
  }

  Future<int> deleteShiftByDate(String date) async {
    return await delete('date = ?', [date]);
  }
} 