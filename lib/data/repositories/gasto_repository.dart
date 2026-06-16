import '../database/app_database.dart';
import '../models/gasto.dart';

class GastoRepository {
  static const String _tableName = 'gastos';

  Future<int> insertGasto(Gasto gasto) async {
    final db = await AppDatabase.instance.database;
    final values = gasto.toMap()..remove('id');

    return db.insert(_tableName, values);
  }

  Future<List<Gasto>> getGastos() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      _tableName,
      orderBy: 'fechaGasto DESC, id DESC',
    );

    return maps.map(Gasto.fromMap).toList();
  }

  Future<int> updateGasto(Gasto gasto) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      _tableName,
      gasto.toMap(),
      where: 'id = ?',
      whereArgs: [gasto.id],
    );
  }

  Future<int> deleteGasto(int id) async {
    final db = await AppDatabase.instance.database;

    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Gasto>> getGastosByFecha(DateTime fecha) async {
    final db = await AppDatabase.instance.database;
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));
    final maps = await db.query(
      _tableName,
      where: 'fechaGasto >= ? AND fechaGasto < ?',
      whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
      orderBy: 'fechaGasto DESC, id DESC',
    );

    return maps.map(Gasto.fromMap).toList();
  }
}
