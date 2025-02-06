import 'dart:async';
import 'package:intl/intl.dart';
import '../database/daos/shift_dao.dart';
import '../models/shift.dart';
import '../models/monthly_statistics.dart';
import '../models/shift_type.dart';
import 'base_repository.dart';

/// 班次数据仓库
class ShiftRepository implements BaseRepository<Shift> {
  final ShiftDao _shiftDao;
  late final StreamController<List<Shift>> _shiftController;

  ShiftRepository(this._shiftDao) {
    _shiftController = StreamController<List<Shift>>.broadcast();
  }

  // 获取班次流，用于实时更新UI
  Stream<List<Shift>> get shiftsStream => _shiftController.stream;

  /// 根据日期获取班次
  Future<Shift?> getShiftByDate(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return await _shiftDao.getShiftByDate(dateStr);
  }

  /// 获取指定月份的所有班次
  Future<List<Shift>> getShiftsByMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // 月份的最后一天
    return await _shiftDao.getShiftsByDateRange(
      DateFormat('yyyy-MM-dd').format(startDate),
      DateFormat('yyyy-MM-dd').format(endDate),
    );
  }

  /// 获取月度统计数据
  Future<MonthlyStatistics> getMonthlyStatistics(int year, int month) async {
    final shifts = await getShiftsByMonth(year, month);
    
    int dayShiftCount = 0;
    int nightShiftCount = 0;
    int restDayCount = 0;
    int totalWorkHours = 0;

    for (final shift in shifts) {
      if (shift.type.isRestDay) {
        restDayCount++;
      } else if (shift.type.startTimeOfDay != null) {
        final hour = shift.type.startTimeOfDay!.hour;
        if (hour >= 6 && hour < 18) {
          dayShiftCount++;
        } else {
          nightShiftCount++;
        }
      }

      if (shift.startTime != null && shift.endTime != null) {
        final duration = shift.duration;
        if (duration != null) {
          totalWorkHours += duration.toInt();
        }
      }
    }

    return MonthlyStatistics(
      dayShiftCount: dayShiftCount,
      nightShiftCount: nightShiftCount,
      restDayCount: restDayCount,
      totalWorkDays: dayShiftCount + nightShiftCount,
      totalWorkHours: totalWorkHours,
    );
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
    final id = await _shiftDao.insertShift(shift);
    getAll(); // 更新流
    return id;
  }

  @override
  Future<int> update(Shift shift) async {
    final result = await _shiftDao.updateShift(shift);
    getAll(); // 更新流
    return result;
  }

  @override
  Future<int> delete(int id) async {
    final result = await _shiftDao.deleteShift(id);
    getAll(); // 更新流
    return result;
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
    await _shiftDao.upsertShifts(shifts);
    getAll(); // 更新流
  }

  /// 更新班次备注
  Future<int> updateShiftNote(int id, String note) async {
    final shift = await getById(id);
    if (shift == null) {
      throw Exception('班次不存在');
    }
    
    final updatedShift = shift.copyWith(note: note);
    final result = await update(updatedShift);
    getAll(); // 更新流
    return result;
  }

  /// 获取指定日期范围的班次
  Future<List<Shift>> getShiftsByDateRange(String startDate, String endDate) async {
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