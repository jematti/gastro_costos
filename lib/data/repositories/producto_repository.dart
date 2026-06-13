import '../database/app_database.dart';
import '../models/producto.dart';

class ProductoRepository {
  static const String _tableName = 'productos';

  Future<int> insertProducto(Producto producto) async {
    final db = await AppDatabase.instance.database;
    final values = producto.toMap()..remove('id');

    return db.insert(_tableName, values);
  }

  Future<List<Producto>> getProductos() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(_tableName, orderBy: 'nombre ASC');

    return maps.map(Producto.fromMap).toList();
  }

  Future<int> updateProducto(Producto producto) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      _tableName,
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> deleteProducto(int id) async {
    final db = await AppDatabase.instance.database;

    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }
}
