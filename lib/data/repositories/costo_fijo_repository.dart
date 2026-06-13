import '../database/app_database.dart';
import '../models/costo_fijo.dart';

class CostoFijoRepository {
  static const String _tableName = 'costos_fijos';

  Future<int> insertCostoFijo(CostoFijo costo) async {
    final db = await AppDatabase.instance.database;
    final values = costo.toMap()..remove('id');

    return db.insert(_tableName, values);
  }

  Future<List<CostoFijo>> getCostosFijos() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(_tableName, orderBy: 'nombre ASC');

    return maps.map(CostoFijo.fromMap).toList();
  }

  Future<List<CostoFijo>> getCostosFijosActivos() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      _tableName,
      where: 'activo = ?',
      whereArgs: [1],
      orderBy: 'nombre ASC',
    );

    return maps.map(CostoFijo.fromMap).toList();
  }

  Future<int> updateCostoFijo(CostoFijo costo) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      _tableName,
      costo.toMap(),
      where: 'id = ?',
      whereArgs: [costo.id],
    );
  }

  Future<int> deleteCostoFijo(int id) async {
    final db = await AppDatabase.instance.database;

    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }
}
