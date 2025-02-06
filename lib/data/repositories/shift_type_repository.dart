import 'dart:async';
import '../database/daos/shift_type_dao.dart';
import '../models/shift_type.dart';
import 'base_repository.dart';

/// 班次类型仓库
class ShiftTypeRepository implements BaseRepository<ShiftType> {
  final ShiftTypeDao _shiftTypeDao;
  late final StreamController<List<ShiftType>> _shiftTypeController;

  ShiftTypeRepository(this._shiftTypeDao) {
    _shiftTypeController = StreamController<List<ShiftType>>.broadcast();
  }

  // 获取班次类型流，用于实时更新UI
  Stream<List<ShiftType>> get shiftTypesStream => _shiftTypeController.stream;

  /// 初始化预设班次类型
  Future<void> initializePresetTypes() async {
    await _shiftTypeDao.initializePresetTypes();
    getAll(); // 更新流
  }

  /// 获取自定义班次类型
  Future<List<ShiftType>> getCustomShiftTypes() async {
    return await _shiftTypeDao.getCustomShiftTypes();
  }

  /// 搜索班次类型
  Future<List<ShiftType>> searchShiftTypes(String keyword) async {
    return await _shiftTypeDao.searchShiftTypes(keyword);
  }

  @override
  Future<List<ShiftType>> getAll() async {
    final types = await _shiftTypeDao.getAllShiftTypes();
    _shiftTypeController.add(types);
    return types;
  }

  @override
  Future<ShiftType?> getById(int id) async {
    return await _shiftTypeDao.getShiftTypeById(id);
  }

  @override
  Future<int> insert(ShiftType type) async {
    final id = await _shiftTypeDao.insertShiftType(type);
    getAll(); // 更新流
    return id;
  }

  @override
  Future<int> update(ShiftType type) async {
    final result = await _shiftTypeDao.updateShiftType(type);
    getAll(); // 更新流
    return result;
  }

  @override
  Future<int> delete(int id) async {
    final result = await _shiftTypeDao.deleteShiftType(id);
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
    return await _shiftTypeDao.getShiftTypeCount();
  }

  void dispose() {
    _shiftTypeController.close();
  }
} 