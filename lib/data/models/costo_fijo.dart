class CostoFijo {
  const CostoFijo({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.montoMensual,
    required this.activo,
    required this.fechaRegistro,
  });

  final int id;
  final String nombre;
  final String categoria;
  final double montoMensual;
  final bool activo;
  final DateTime fechaRegistro;

  CostoFijo copyWith({
    int? id,
    String? nombre,
    String? categoria,
    double? montoMensual,
    bool? activo,
    DateTime? fechaRegistro,
  }) {
    return CostoFijo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      montoMensual: montoMensual ?? this.montoMensual,
      activo: activo ?? this.activo,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'montoMensual': montoMensual,
      'activo': activo ? 1 : 0,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  factory CostoFijo.fromMap(Map<String, dynamic> map) {
    return CostoFijo(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      categoria: map['categoria'] as String,
      montoMensual: (map['montoMensual'] as num).toDouble(),
      activo: map['activo'] == 1,
      fechaRegistro: DateTime.parse(map['fechaRegistro'] as String),
    );
  }
}
