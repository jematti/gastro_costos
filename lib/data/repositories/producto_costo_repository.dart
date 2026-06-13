import '../database/app_database.dart';
import '../models/producto_costo.dart';

class ProductoCostoRepository {
  static const String _tableName = 'producto_costos';

  Future<int> insertProductoCosto(ProductoCosto costo) async {
    final db = await AppDatabase.instance.database;
    final values = costo.toMap()..remove('id');

    return db.insert(_tableName, values);
  }

  Future<List<ProductoCosto>> getCostosByProducto(int productoId) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      _tableName,
      where: 'productoId = ?',
      whereArgs: [productoId],
      orderBy: 'id ASC',
    );

    return maps.map(ProductoCosto.fromMap).toList();
  }

  Future<int> updateProductoCosto(ProductoCosto costo) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      _tableName,
      costo.toMap(),
      where: 'id = ?',
      whereArgs: [costo.id],
    );
  }

  Future<int> deleteProductoCosto(int id) async {
    final db = await AppDatabase.instance.database;

    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCostosByProducto(int productoId) async {
    final db = await AppDatabase.instance.database;

    return db.delete(
      _tableName,
      where: 'productoId = ?',
      whereArgs: [productoId],
    );
  }

  Future<double> calcularTotalCostosProducto(int productoId) async {
    final costos = await getCostosByProducto(productoId);
    return costos.fold<double>(
      0,
      (total, costo) => total + costo.costoCalculado,
    );
  }
}
