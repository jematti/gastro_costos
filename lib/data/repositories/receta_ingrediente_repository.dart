import '../database/app_database.dart';
import '../models/receta_ingrediente.dart';

class RecetaIngredienteRepository {
  static const String _tableName = 'receta_ingredientes';

  Future<int> insertRecetaIngrediente(RecetaIngrediente item) async {
    final db = await AppDatabase.instance.database;
    final values = item.toMap()..remove('id');

    return db.insert(_tableName, values);
  }

  Future<List<RecetaIngrediente>> getIngredientesByReceta(int recetaId) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      _tableName,
      where: 'recetaId = ?',
      whereArgs: [recetaId],
      orderBy: 'nombreIngrediente ASC',
    );

    return maps.map(RecetaIngrediente.fromMap).toList();
  }

  Future<int> updateRecetaIngrediente(RecetaIngrediente item) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      _tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteRecetaIngrediente(int id) async {
    final db = await AppDatabase.instance.database;

    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<double> calcularCostoTotalReceta(int recetaId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(costoTotal) AS total FROM $_tableName WHERE recetaId = ?',
      [recetaId],
    );

    final total = result.first['total'];
    if (total == null) {
      return 0;
    }

    return (total as num).toDouble();
  }
}
