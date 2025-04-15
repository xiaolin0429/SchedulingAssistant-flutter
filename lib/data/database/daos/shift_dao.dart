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
  Future<List<Shift>> getShiftsByDateRange(
      String startDate, String endDate) async {
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

  /// 获取月度统计数据
  /// 直接在数据库层面计算班次类型分布和工作天数
  Future<Map<String, dynamic>> getMonthlyStatisticsData(
      int year, int month) async {
    // 构建日期范围
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final endDate =
        '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    // 1. 按班次类型计数查询
    final typeCounts = await database.rawQuery('''
      SELECT shiftTypeId, COUNT(*) as count 
      FROM shifts 
      WHERE date BETWEEN ? AND ? 
      GROUP BY shiftTypeId
    ''', [startDate, endDate]);

    // 2. 工作时长查询（仅计算有开始和结束时间的班次）
    // 注意：数据库无法直接处理跨天时长计算，所以这里只统计具体记录的数量，详细计算仍在应用层
    final workShiftsCount = await database.rawQuery('''
      SELECT COUNT(*) as count 
      FROM shifts s
      JOIN shift_types st ON s.shiftTypeId = st.id
      WHERE date BETWEEN ? AND ? 
      AND st.isRestDay = 0
    ''', [startDate, endDate]);

    // 将结果转换为统一的格式
    final Map<int, int> shiftTypeCounts = {};
    for (var row in typeCounts) {
      final typeId = row['shiftTypeId'] as int;
      final count = row['count'] as int;
      shiftTypeCounts[typeId] = count;
    }

    // 工作天数为非休息日的班次数量
    final totalWorkDays = Sqflite.firstIntValue(workShiftsCount) ?? 0;

    return {
      'shiftTypeCounts': shiftTypeCounts,
      'totalWorkDays': totalWorkDays,
    };
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
