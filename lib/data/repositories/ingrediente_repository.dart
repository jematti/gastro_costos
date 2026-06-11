import '../database/app_database.dart';
import '../models/ingrediente.dart';

class IngredienteRepository {
  static const String _tableName = 'ingredientes';

  Future<int> insertIngrediente(Ingrediente ingrediente) async {
    final db = await AppDatabase.instance.database;
    final values = ingrediente.toMap()..remove('id');

    return db.insert(_tableName, values);
  }

  Future<List<Ingrediente>> getIngredientes() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(_tableName, orderBy: 'nombre ASC');

    return maps.map(Ingrediente.fromMap).toList();
  }

  Future<int> updateIngrediente(Ingrediente ingrediente) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      _tableName,
      ingrediente.toMap(),
      where: 'id = ?',
      whereArgs: [ingrediente.id],
    );
  }

  Future<int> deleteIngrediente(int id) async {
    final db = await AppDatabase.instance.database;

    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }
}
