import 'dart:async';
import 'package:intl/intl.dart';
import '../database/daos/shift_dao.dart';
import '../models/shift.dart';
import '../models/monthly_statistics.dart';
import '../models/shift_type.dart';
import 'base_repository.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/logger.dart';
import '../../core/di/injection_container.dart';

/// 班次数据仓库
class ShiftRepository implements BaseRepository<Shift> {
  final ShiftDao _shiftDao;
  late final StreamController<List<Shift>> _shiftController;
  late final LogService _logger;

  ShiftRepository(this._shiftDao) {
    _shiftController = StreamController<List<Shift>>.broadcast();
    _logger = getIt<LogService>();
  }

  // 获取班次流，用于实时更新UI
  Stream<List<Shift>> get shiftsStream => _shiftController.stream;

  /// 根据日期获取班次
  Future<Shift?> getShiftByDate(DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final shift = await _shiftDao.getShiftByDate(dateStr);
      if (shift == null) return null;

      // 验证班次类型是否存在
      try {
        // 访问班次类型的属性以触发可能的错误
        shift.type.name;
        return shift;
      } catch (e) {
        debugPrint('班次的类型已被删除: ${shift.type.id}');
        _logger.w('班次的类型已被删除', tag: 'SHIFT_REPO');
        // 返回带有默认类型的班次
        return shift.copyWith(
          type: ShiftType(
            name: '已删除',
            color: 0xFF808080, // 灰色
            isRestDay: false,
          ),
        );
      }
    } catch (e) {
      debugPrint('获取班次时发生错误: $e');
      _logger.e('获取班次失败', tag: 'SHIFT_REPO', error: e);
      return null;
    }
  }

  /// 获取指定月份的所有班次
  Future<List<Shift>> getShiftsByMonth(int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // 月份的最后一天
      final shifts = await _shiftDao.getShiftsByDateRange(
        DateFormat('yyyy-MM-dd').format(startDate),
        DateFormat('yyyy-MM-dd').format(endDate),
      );

      // 处理每个班次的类型
      return shifts.map((shift) {
        try {
          // 验证班次类型
          shift.type.name;
          return shift;
        } catch (e) {
          debugPrint('班次的类型已被删除: ${shift.type.id}');
          // 返回带有默认类型的班次
          return shift.copyWith(
            type: ShiftType(
              name: '已删除',
              color: 0xFF808080, // 灰色
              isRestDay: false,
            ),
          );
        }
      }).toList();
    } catch (e) {
      debugPrint('获取月度班次时发生错误: $e');
      return [];
    }
  }

  /// 获取月度统计数据
  Future<MonthlyStatistics> getMonthlyStatistics(int year, int month) async {
    try {
      // 使用数据库层的统计功能直接获取统计结果
      final statsData = await _shiftDao.getMonthlyStatisticsData(year, month);

      // 从数据库获取类型计数和工作天数
      final Map<int, int> typeCounts =
          Map<int, int>.from(statsData['shiftTypeCounts']);
      final int totalWorkDays = statsData['totalWorkDays'] as int;

      // 对于工作时长，由于涉及复杂的跨天计算，仍需要获取班次数据进行计算
      final shifts = await getShiftsByMonth(year, month);
      int totalWorkHours = 0;

      // 扫描一遍班次数据，检查是否有已删除的班次类型
      int deletedTypeCount = 0;

      // 仅计算非休息日且有时间信息的班次
      for (final shift in shifts) {
        try {
          if (shift.type.id == null || shift.type.id == -1) {
            // 已删除的班次类型
            deletedTypeCount++;
            continue;
          }

          if (!shift.type.isRestDay && shift.duration != null) {
            totalWorkHours += shift.duration!.toInt();
          }
        } catch (e) {
          debugPrint('统计班次时出错（可能是已删除的班次类型）: $e');
          // 对于已删除的班次类型，记录计数
          deletedTypeCount++;
        }
      }

      // 如果有已删除的班次类型，添加到统计中，使用特殊ID (-1)
      if (deletedTypeCount > 0) {
        typeCounts[-1] = deletedTypeCount;
      }

      return MonthlyStatistics(
        shiftTypeCounts: typeCounts,
        totalWorkDays: totalWorkDays,
        totalWorkHours: totalWorkHours,
      );
    } catch (e) {
      debugPrint('获取月度统计数据失败: $e');
      _logger.e('获取月度统计数据失败', tag: 'SHIFT_REPO', error: e);
      // 出错时返回空统计
      return const MonthlyStatistics(
        shiftTypeCounts: {},
        totalWorkDays: 0,
        totalWorkHours: 0,
      );
    }
  }

  /// 获取下一个班次
  Future<Shift?> getNextShift(DateTime currentDate) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);
    return await _shiftDao.getNextShift(dateStr);
  }

  @override
  Future<List<Shift>> getAll() async {
    final shifts = await _shiftDao.getAllShifts();
    _shiftController.add(shifts);
    return shifts;
  }

  @override
  Future<Shift?> getById(int id) async {
    return await _shiftDao.getShiftById(id);
  }

  @override
  Future<int> insert(Shift shift) async {
    try {
      final id = await _shiftDao.insertShift(shift);
      _logger.logUserAction('添加班次', data: {
        'date': shift.date,
        'shiftType': shift.type.name,
      });
      getAll(); // 更新流
      return id;
    } catch (e) {
      _logger.e('添加班次失败', tag: 'SHIFT_REPO', error: e);
      rethrow;
    }
  }

  @override
  Future<int> update(Shift shift) async {
    try {
      final result = await _shiftDao.updateShift(shift);
      _logger.logUserAction('更新班次', data: {
        'date': shift.date,
        'shiftType': shift.type.name,
      });
      getAll(); // 更新流
      return result;
    } catch (e) {
      _logger.e('更新班次失败', tag: 'SHIFT_REPO', error: e);
      rethrow;
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      final shift = await getById(id);
      final result = await _shiftDao.deleteShift(id);
      if (shift != null) {
        _logger.logUserAction('删除班次', data: {
          'date': shift.date,
          'shiftType': shift.type.name,
        });
      }
      getAll(); // 更新流
      return result;
    } catch (e) {
      _logger.e('删除班次失败', tag: 'SHIFT_REPO', error: e);
      rethrow;
    }
  }

  @override
  Future<int> deleteAll(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      count += await delete(id);
    }
    return count;
  }

  @override
  Future<int> count() async {
    return await _shiftDao.getShiftCount();
  }

  /// 获取指定类型的班次
  Future<List<Shift>> getShiftsByType(ShiftType type) async {
    return await _shiftDao.getShiftsByType(type.name);
  }

  /// 获取最近的班次
  Future<List<Shift>> getRecentShifts({int limit = 10}) async {
    return await _shiftDao.getRecentShifts(limit);
  }

  /// 批量插入或更新班次
  Future<void> upsertShifts(List<Shift> shifts) async {
    try {
      await _shiftDao.upsertShifts(shifts);
      _logger.logUserAction('批量更新班次', data: {
        'count': shifts.length,
      });
      getAll(); // 更新流
    } catch (e) {
      _logger.e('批量更新班次失败', tag: 'SHIFT_REPO', error: e);
      rethrow;
    }
  }

  /// 更新班次备注
  Future<int> updateShiftNote(int id, String note) async {
    try {
      final shift = await getById(id);
      if (shift == null) {
        throw Exception('班次不存在');
      }

      final updatedShift = shift.copyWith(note: note);
      final result = await update(updatedShift);
      _logger.logUserAction('更新班次备注', data: {
        'date': shift.date,
      });
      getAll(); // 更新流
      return result;
    } catch (e) {
      _logger.e('更新班次备注失败', tag: 'SHIFT_REPO', error: e);
      rethrow;
    }
  }

  /// 获取指定日期范围的班次
  Future<List<Shift>> getShiftsByDateRange(
      String startDate, String endDate) async {
    return await _shiftDao.getShiftsByDateRange(startDate, endDate);
  }

  /// 更新或插入班次
  Future<int> upsertShift(Shift shift) async {
    if (shift.id != null) {
      return await update(shift);
    } else {
      return await insert(shift);
    }
  }

  void dispose() {
    _shiftController.close();
  }
}
