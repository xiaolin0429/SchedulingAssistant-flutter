import 'package:sqflite/sqflite.dart';

abstract class BaseDao<T> {
  final Database database;
  final String tableName;

  BaseDao(this.database, this.tableName);

  Future<int> insert(Map<String, dynamic> row) async {
    return await database.insert(
      tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(Map<String, dynamic> row, String where, List<dynamic> whereArgs) async {
    return await database.update(
      tableName,
      row,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(String where, List<dynamic> whereArgs) async {
    return await database.delete(
      tableName,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<List<Map<String, dynamic>>> query({
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return await database.query(
      tableName,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int?> queryCount({
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final result = await database.query(
      tableName,
      columns: ['COUNT(*) as count'],
      where: where,
      whereArgs: whereArgs,
    );
    return Sqflite.firstIntValue(result);
  }
} 