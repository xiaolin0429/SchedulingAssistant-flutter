import 'package:sqflite/sqflite.dart';
import '../../models/shift_template.dart';
import '../../models/shift_type.dart';
import 'base_dao.dart';

class ShiftTemplateDao extends BaseDao<ShiftTemplate> {
  static const String _tableName = 'shift_templates';

  ShiftTemplateDao(Database database) : super(database, _tableName);

  Future<ShiftTemplate?> getTemplateById(int id) async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return ShiftTemplate.fromMap(maps.first);
  }

  Future<List<ShiftTemplate>> getAllTemplates() async {
    final List<Map<String, dynamic>> maps = await query(
      orderBy: 'updateTime DESC',
    );

    return maps.map((map) => ShiftTemplate.fromMap(map)).toList();
  }

  Future<List<ShiftTemplate>> getTemplatesByType(ShiftType type) async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'updateTime DESC',
    );

    return maps.map((map) => ShiftTemplate.fromMap(map)).toList();
  }

  Future<List<ShiftTemplate>> getDefaultTemplates() async {
    final List<Map<String, dynamic>> maps = await query(
      where: 'isDefault = ?',
      whereArgs: [1],
      orderBy: 'updateTime DESC',
    );

    return maps.map((map) => ShiftTemplate.fromMap(map)).toList();
  }

  Future<int> insertTemplate(ShiftTemplate template) async {
    return await insert(template.toMap());
  }

  Future<int> updateTemplate(ShiftTemplate template) async {
    return await update(
      template.toMap(),
      'id = ?',
      [template.id],
    );
  }

  Future<int> deleteTemplate(int id) async {
    return await delete('id = ?', [id]);
  }

  Future<int> getTemplateCount() async {
    return await queryCount() ?? 0;
  }

  Future<void> deleteAll() async {
    await delete('1 = 1', []);
  }
}
