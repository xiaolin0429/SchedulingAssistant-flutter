abstract class BaseRepository<T> {
  /// 获取所有记录
  Future<List<T>> getAll();

  /// 根据ID获取单条记录
  Future<T?> getById(int id);

  /// 插入记录
  Future<int> insert(T item);

  /// 更新记录
  Future<int> update(T item);

  /// 删除记录
  Future<int> delete(int id);

  /// 批量删除
  Future<int> deleteAll(List<int> ids);

  /// 获取记录总数
  Future<int> count();
} 