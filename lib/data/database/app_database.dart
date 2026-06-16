import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseName = 'gastro_costos.db';
  static const int _databaseVersion = 10;

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

    await _createRecetaIngredientesTable(db);

    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        recetaId INTEGER NOT NULL,
        nombreReceta TEXT,
        costoBase REAL NOT NULL,
        minutosElaboracion REAL NOT NULL,
        costoHoraManoObra REAL NOT NULL,
        costoManoObra REAL NOT NULL,
        costosVariables REAL NOT NULL,
        costosFijos REAL NOT NULL,
        unidadesEstimadasMes REAL NOT NULL DEFAULT 0,
        otrosCostos REAL NOT NULL,
        costoTotalProducto REAL NOT NULL,
        margenGanancia REAL NOT NULL,
        precioVentaSugerido REAL NOT NULL,
        precioVentaFinal REAL NOT NULL,
        fechaRegistro TEXT NOT NULL
      )
    ''');

    await _createProductoCostosTable(db);
    await _createCostosFijosTable(db);
    await _createProductoCostosFijosTable(db);
    await _createProductoCostosVariablesTable(db);

    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productoId INTEGER NOT NULL,
        nombreProducto TEXT NOT NULL,
        cantidad REAL NOT NULL,
        precioUnitario REAL NOT NULL,
        totalVenta REAL NOT NULL,
        costoUnitario REAL NOT NULL,
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

    if (oldVersion < 3) {
      await _createRecetaIngredientesTable(db);
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE productos ADD COLUMN nombreReceta TEXT');
      await db.execute('''
        UPDATE productos
        SET nombreReceta = (
          SELECT nombre
          FROM recetas
          WHERE recetas.id = productos.recetaId
        )
      ''');
    }

    if (oldVersion < 5) {
      await _createProductoCostosTable(db);
    } else if (oldVersion < 6) {
      await db.execute(
        "ALTER TABLE producto_costos ADD COLUMN tipoCosto TEXT NOT NULL DEFAULT 'variable'",
      );
      await db.execute('''
        UPDATE producto_costos
        SET tipoCosto = CASE
          WHEN tipoCalculo = 'mensual_prorrateado' THEN 'fijo'
          ELSE 'variable'
        END
      ''');
    }

    if (oldVersion < 7) {
      await _createCostosFijosTable(db);
    }

    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE productos ADD COLUMN minutosElaboracion REAL NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE productos ADD COLUMN costoHoraManoObra REAL NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE productos ADD COLUMN costoManoObra REAL NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE productos ADD COLUMN costosVariables REAL NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE productos ADD COLUMN costosFijos REAL NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE productos ADD COLUMN costoTotalProducto REAL NOT NULL DEFAULT 0',
      );
      await db.execute('''
        UPDATE productos
        SET costoTotalProducto = costoBase + otrosCostos
      ''');
      await _createProductoCostosFijosTable(db);
      await _createProductoCostosVariablesTable(db);
    }

    if (oldVersion < 9) {
      await db.execute(
        'ALTER TABLE productos ADD COLUMN unidadesEstimadasMes REAL NOT NULL DEFAULT 0',
      );
    }

    if (oldVersion < 10) {
      await _migrateVentasV10(db);
    }
  }

  Future<void> _migrateVentasV10(Database db) async {
    final ventasInfo = await db.rawQuery("PRAGMA table_info('ventas')");

    if (ventasInfo.isEmpty) {
      await _createVentasTable(db);
      return;
    }

    await _createVentasTable(db, tableName: 'ventas_nueva');
    await db.execute('''
      INSERT INTO ventas_nueva (
        id,
        productoId,
        nombreProducto,
        cantidad,
        precioUnitario,
        totalVenta,
        costoUnitario,
        costoTotal,
        ganancia,
        fechaVenta
      )
      SELECT
        id,
        productoId,
        nombreProducto,
        cantidad,
        precioUnitario,
        totalVenta,
        CASE
          WHEN cantidad > 0 THEN costoTotal / cantidad
          ELSE 0
        END,
        costoTotal,
        ganancia,
        fechaVenta
      FROM ventas
    ''');
    await db.execute('DROP TABLE ventas');
    await db.execute('ALTER TABLE ventas_nueva RENAME TO ventas');
  }

  Future<void> _createVentasTable(
    Database db, {
    String tableName = 'ventas',
  }) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productoId INTEGER NOT NULL,
        nombreProducto TEXT NOT NULL,
        cantidad REAL NOT NULL,
        precioUnitario REAL NOT NULL,
        totalVenta REAL NOT NULL,
        costoUnitario REAL NOT NULL,
        costoTotal REAL NOT NULL,
        ganancia REAL NOT NULL,
        fechaVenta TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createRecetaIngredientesTable(Database db) async {
    await db.execute('''
      CREATE TABLE receta_ingredientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recetaId INTEGER NOT NULL,
        ingredienteId INTEGER NOT NULL,
        nombreIngrediente TEXT NOT NULL,
        cantidadUsada REAL NOT NULL,
        unidadUsada TEXT NOT NULL,
        costoUnitario REAL NOT NULL,
        costoTotal REAL NOT NULL,
        fechaRegistro TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createProductoCostosTable(Database db) async {
    await db.execute('''
      CREATE TABLE producto_costos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productoId INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        tipoCosto TEXT NOT NULL,
        categoria TEXT NOT NULL,
        tipoCalculo TEXT NOT NULL,
        monto REAL NOT NULL,
        unidadesEstimadasMes REAL,
        minutosElaboracion REAL,
        costoHora REAL,
        porcentaje REAL,
        costoCalculado REAL NOT NULL,
        fechaRegistro TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createCostosFijosTable(Database db) async {
    await db.execute('''
      CREATE TABLE costos_fijos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        categoria TEXT NOT NULL,
        montoMensual REAL NOT NULL,
        activo INTEGER NOT NULL,
        fechaRegistro TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createProductoCostosFijosTable(Database db) async {
    await db.execute('''
      CREATE TABLE producto_costos_fijos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productoId INTEGER NOT NULL,
        costoFijoId INTEGER NOT NULL,
        nombreCostoFijo TEXT NOT NULL,
        montoMensual REAL NOT NULL,
        unidadesEstimadasMes REAL NOT NULL,
        costoProrrateado REAL NOT NULL,
        fechaRegistro TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createProductoCostosVariablesTable(Database db) async {
    await db.execute('''
      CREATE TABLE producto_costos_variables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productoId INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        categoria TEXT NOT NULL,
        tipoCalculo TEXT NOT NULL,
        monto REAL,
        porcentaje REAL,
        costoCalculado REAL NOT NULL,
        fechaRegistro TEXT NOT NULL
      )
    ''');
  }
}
