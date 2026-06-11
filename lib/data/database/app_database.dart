import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseName = 'gastro_costos.db';
  static const int _databaseVersion = 2;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ingredientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        precioCompra REAL NOT NULL,
        cantidadCompra REAL NOT NULL,
        unidadCompra TEXT NOT NULL,
        unidadBase TEXT NOT NULL,
        costoPorUnidadBase REAL NOT NULL,
        fechaCompra TEXT NOT NULL,
        fechaRegistro TEXT NOT NULL,
        imagePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE recetas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        porciones INTEGER NOT NULL,
        costoTotal REAL NOT NULL,
        costoPorPorcion REAL NOT NULL,
        fechaRegistro TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        recetaId INTEGER NOT NULL,
        costoBase REAL NOT NULL,
        otrosCostos REAL NOT NULL,
        margenGanancia REAL NOT NULL,
        precioVentaSugerido REAL NOT NULL,
        precioVentaFinal REAL NOT NULL,
        fechaRegistro TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productoId INTEGER NOT NULL,
        nombreProducto TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        precioUnitario REAL NOT NULL,
        totalVenta REAL NOT NULL,
        costoTotal REAL NOT NULL,
        ganancia REAL NOT NULL,
        fechaVenta TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE gastos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        concepto TEXT NOT NULL,
        monto REAL NOT NULL,
        categoria TEXT NOT NULL,
        fechaGasto TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cierres_caja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        totalVentas REAL NOT NULL,
        totalGastos REAL NOT NULL,
        gananciaBruta REAL NOT NULL,
        gananciaNeta REAL NOT NULL,
        observaciones TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ingredientes ADD COLUMN fechaCompra TEXT');
      await db.execute('ALTER TABLE ingredientes ADD COLUMN imagePath TEXT');
    }
  }
}
