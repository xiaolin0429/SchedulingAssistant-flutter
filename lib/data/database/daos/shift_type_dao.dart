import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../../models/shift_type.dart';

/// 班次类型数据访问对象
class ShiftTypeDao {
  final Database _db;

  ShiftTypeDao(this._db);

  /// 获取所有班次类型
  Future<List<ShiftType>> getAllShiftTypes() async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query('shift_types');
      debugPrint('获取到 ${maps.length} 个班次类型');
      return List.generate(maps.length, (i) => ShiftType.fromMap(maps[i]));
    } catch (e) {
      debugPrint('获取班次类型失败: $e');
      rethrow;
    }
  }

  /// 根据ID获取班次类型
  Future<ShiftType?> getShiftTypeById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'shift_types',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ShiftType.fromMap(maps.first);
  }

  /// 获取自定义班次类型
  Future<List<ShiftType>> getCustomShiftTypes() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'shift_types',
      where: 'isPreset = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => ShiftType.fromMap(maps[i]));
  }

  /// 搜索班次类型
  Future<List<ShiftType>> searchShiftTypes(String keyword) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'shift_types',
      where: 'name LIKE ?',
      whereArgs: ['%$keyword%'],
    );
    return List.generate(maps.length, (i) => ShiftType.fromMap(maps[i]));
  }

  /// 插入班次类型
  Future<int> insertShiftType(ShiftType type) async {
    return await _db.insert('shift_types', type.toMap());
  }

  /// 更新班次类型
  Future<int> updateShiftType(ShiftType type) async {
    return await _db.update(
      'shift_types',
      type.toMap(),
      where: 'id = ?',
      whereArgs: [type.id],
    );
  }

  /// 删除班次类型
  Future<int> deleteShiftType(int id) async {
    return await _db.delete(
      'shift_types',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取班次类型数量
  Future<int> getShiftTypeCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) FROM shift_types');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 初始化预设班次类型
  Future<void> initializePresetTypes() async {
    try {
      final count = await getShiftTypeCount();
      debugPrint('当前班次类型数量: $count');
      if (count == 0) {
        debugPrint('开始初始化预设班次类型...');
        for (final type in ShiftType.presets) {
          final id = await insertShiftType(type);
          debugPrint('插入预设班次类型: ${type.name}, ID: $id');
        }
      }
    } catch (e) {
      debugPrint('初始化预设班次类型失败: $e');
      rethrow;
    }
  }
} 