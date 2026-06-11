import '../database/app_database.dart';
import '../models/receta.dart';

class RecetaRepository {
  static const String _tableName = 'recetas';

  Future<int> insertReceta(Receta receta) async {
    final db = await AppDatabase.instance.database;
    final values = receta.toMap()..remove('id');

    return db.insert(_tableName, values);
  }

  Future<List<Receta>> getRecetas() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(_tableName, orderBy: 'nombre ASC');

    return maps.map(Receta.fromMap).toList();
  }

  Future<int> updateReceta(Receta receta) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      _tableName,
      receta.toMap(),
      where: 'id = ?',
      whereArgs: [receta.id],
    );
  }

  Future<int> deleteReceta(int id) async {
    final db = await AppDatabase.instance.database;

    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }
}
