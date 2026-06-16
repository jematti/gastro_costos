import '../database/app_database.dart';
import '../models/cierre_caja.dart';

class CierreCajaRepository {
  static const String _tableName = 'cierres_caja';

  Future<int> insertCierreCaja(CierreCaja cierre) async {
    final db = await AppDatabase.instance.database;
    final values = cierre.toMap()..remove('id');

    return db.insert(_tableName, values);
  }

  Future<List<CierreCaja>> getCierres() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(_tableName, orderBy: 'fecha DESC, id DESC');

    return maps.map(CierreCaja.fromMap).toList();
  }

  Future<int> updateCierreCaja(CierreCaja cierre) async {
    final db = await AppDatabase.instance.database;

    return db.update(
      _tableName,
      cierre.toMap(),
      where: 'id = ?',
      whereArgs: [cierre.id],
    );
  }

  Future<int> deleteCierreCaja(int id) async {
    final db = await AppDatabase.instance.database;

    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<CierreCaja?> getCierreByFecha(DateTime fecha) async {
    final db = await AppDatabase.instance.database;
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));
    final maps = await db.query(
      _tableName,
      where: 'fecha >= ? AND fecha < ?',
      whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
      orderBy: 'fecha DESC, id DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return CierreCaja.fromMap(maps.first);
  }
}
