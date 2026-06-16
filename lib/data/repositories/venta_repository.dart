import '../database/app_database.dart';
import '../models/venta.dart';

class VentaRepository {
  static const String _tableName = 'ventas';

  Future<int> insertVenta(Venta venta) async {
    final db = await AppDatabase.instance.database;
    final values = venta.toMap()..remove('id');

    return db.insert(_tableName, values);
  }

  Future<List<Venta>> getVentas() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      _tableName,
      orderBy: 'fechaVenta DESC, id DESC',
    );

    return maps.map(Venta.fromMap).toList();
  }

  Future<int> updateVenta(Venta venta) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      _tableName,
      venta.toMap(),
      where: 'id = ?',
      whereArgs: [venta.id],
    );
  }

  Future<int> deleteVenta(int id) async {
    final db = await AppDatabase.instance.database;

    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Venta>> getVentasByFecha(DateTime fecha) async {
    final db = await AppDatabase.instance.database;
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));
    final maps = await db.query(
      _tableName,
      where: 'fechaVenta >= ? AND fechaVenta < ?',
      whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
      orderBy: 'fechaVenta DESC, id DESC',
    );

    return maps.map(Venta.fromMap).toList();
  }
}
