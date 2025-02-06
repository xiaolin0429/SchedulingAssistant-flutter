import 'dart:async';
import '../../data/models/shift.dart';
import '../../data/models/shift_type.dart';
import '../../data/repositories/shift_repository.dart';
import 'package:intl/intl.dart';

class ShiftService {
  final ShiftRepository _shiftRepository;

  ShiftService(this._shiftRepository);

  // 获取班次流
  Stream<List<Shift>> get shiftsStream => _shiftRepository.shiftsStream;

  // 基础CRUD操作
  Future<List<Shift>> getAllShifts() => _shiftRepository.getAll();
  
  Future<Shift?> getShiftById(int id) => _shiftRepository.getById(id);

  Future<Shift?> getShiftByDate(DateTime date) => _shiftRepository.getShiftByDate(date);

  // 添加新班次，包含业务逻辑验证
  Future<int> addShift(Shift shift) async {
    // 检查同一天是否已经有班次
    final existingShift = await _shiftRepository.getShiftByDate(
      DateTime.parse(shift.date),
    );
    if (existingShift != null) {
      throw Exception('该日期已存在班次安排');
    }

    return _shiftRepository.insert(shift);
  }

  // 更新班次
  Future<int> updateShift(Shift shift) async {
    final existingShift = await _shiftRepository.getShiftByDate(
      DateTime.parse(shift.date),
    );
    if (existingShift != null && existingShift.id != shift.id) {
      throw Exception('该日期已存在班次安排');
    }

    return _shiftRepository.update(shift);
  }

  // 删除班次
  Future<int> deleteShift(int id) => _shiftRepository.delete(id);

  // 获取指定月份的班次
  Future<List<Shift>> getMonthShifts(int year, int month) => 
    _shiftRepository.getShiftsByMonth(year, month);

  // 获取指定日期范围的班次
  Future<List<Shift>> getShiftsByDateRange(DateTime start, DateTime end) {
    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end);
    return _shiftRepository.getShiftsByDateRange(startStr, endStr);
  }

  // 获取指定类型的班次
  Future<List<Shift>> getShiftsByType(ShiftType type) =>
    _shiftRepository.getShiftsByType(type);

  // 获取最近的班次
  Future<List<Shift>> getRecentShifts({int limit = 10}) =>
    _shiftRepository.getRecentShifts(limit: limit);

  // 批量添加或更新班次
  Future<void> batchUpsertShifts(List<Shift> shifts) =>
    _shiftRepository.upsertShifts(shifts);

  // 更新班次备注
  Future<int> updateShiftNote(int id, String note) =>
    _shiftRepository.updateShiftNote(id, note);

  // 计算指定月份的工作统计
  Future<Map<String, dynamic>> calculateMonthlyStatistics(int year, int month) async {
    final shifts = await getMonthShifts(year, month);
    
    int dayShiftCount = 0;
    int nightShiftCount = 0;
    int restDayCount = 0;
    double totalHours = 0;

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

      if (shift.duration != null) {
        totalHours += shift.duration!;
      }
    }

    return {
      'dayShiftCount': dayShiftCount,
      'nightShiftCount': nightShiftCount,
      'restDayCount': restDayCount,
      'totalDays': dayShiftCount + nightShiftCount + restDayCount,
      'totalHours': totalHours,
    };
  }

  void dispose() {
    _shiftRepository.dispose();
  }
} 