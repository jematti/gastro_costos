import '../database/app_database.dart';
import '../models/producto_costo_variable.dart';

class ProductoCostoVariableRepository {
  static const _table = 'producto_costos_variables';

  Future<int> insertProductoCostoVariable(ProductoCostoVariable costo) async {
    final db = await AppDatabase.instance.database;
    final values = costo.toMap()..remove('id');
    return db.insert(_table, values);
  }

  Future<List<ProductoCostoVariable>> getCostosVariablesByProducto(
    int productoId,
  ) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      _table,
      where: 'productoId = ?',
      whereArgs: [productoId],
      orderBy: 'id ASC',
    );
    return maps.map(ProductoCostoVariable.fromMap).toList();
  }

  Future<int> deleteCostosVariablesByProducto(int productoId) async {
    final db = await AppDatabase.instance.database;
    return db.delete(_table, where: 'productoId = ?', whereArgs: [productoId]);
  }
}
