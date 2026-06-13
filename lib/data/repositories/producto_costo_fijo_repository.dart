import '../database/app_database.dart';
import '../models/producto_costo_fijo.dart';

class ProductoCostoFijoRepository {
  static const _table = 'producto_costos_fijos';

  Future<int> insertProductoCostoFijo(ProductoCostoFijo costo) async {
    final db = await AppDatabase.instance.database;
    final values = costo.toMap()..remove('id');
    return db.insert(_table, values);
  }

  Future<List<ProductoCostoFijo>> getCostosFijosByProducto(
    int productoId,
  ) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      _table,
      where: 'productoId = ?',
      whereArgs: [productoId],
      orderBy: 'nombreCostoFijo ASC',
    );
    return maps.map(ProductoCostoFijo.fromMap).toList();
  }

  Future<int> deleteCostosFijosByProducto(int productoId) async {
    final db = await AppDatabase.instance.database;
    return db.delete(_table, where: 'productoId = ?', whereArgs: [productoId]);
  }
}
