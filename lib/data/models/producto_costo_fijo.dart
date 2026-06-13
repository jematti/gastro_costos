class ProductoCostoFijo {
  const ProductoCostoFijo({
    required this.id,
    required this.productoId,
    required this.costoFijoId,
    required this.nombreCostoFijo,
    required this.montoMensual,
    required this.unidadesEstimadasMes,
    required this.costoProrrateado,
    required this.fechaRegistro,
  });

  final int id;
  final int productoId;
  final int costoFijoId;
  final String nombreCostoFijo;
  final double montoMensual;
  final double unidadesEstimadasMes;
  final double costoProrrateado;
  final DateTime fechaRegistro;

  ProductoCostoFijo copyWith({
    int? id,
    int? productoId,
    int? costoFijoId,
    String? nombreCostoFijo,
    double? montoMensual,
    double? unidadesEstimadasMes,
    double? costoProrrateado,
    DateTime? fechaRegistro,
  }) {
    return ProductoCostoFijo(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      costoFijoId: costoFijoId ?? this.costoFijoId,
      nombreCostoFijo: nombreCostoFijo ?? this.nombreCostoFijo,
      montoMensual: montoMensual ?? this.montoMensual,
      unidadesEstimadasMes: unidadesEstimadasMes ?? this.unidadesEstimadasMes,
      costoProrrateado: costoProrrateado ?? this.costoProrrateado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'productoId': productoId,
    'costoFijoId': costoFijoId,
    'nombreCostoFijo': nombreCostoFijo,
    'montoMensual': montoMensual,
    'unidadesEstimadasMes': unidadesEstimadasMes,
    'costoProrrateado': costoProrrateado,
    'fechaRegistro': fechaRegistro.toIso8601String(),
  };

  factory ProductoCostoFijo.fromMap(Map<String, dynamic> map) {
    return ProductoCostoFijo(
      id: map['id'] as int,
      productoId: map['productoId'] as int,
      costoFijoId: map['costoFijoId'] as int,
      nombreCostoFijo: map['nombreCostoFijo'] as String,
      montoMensual: (map['montoMensual'] as num).toDouble(),
      unidadesEstimadasMes: (map['unidadesEstimadasMes'] as num).toDouble(),
      costoProrrateado: (map['costoProrrateado'] as num).toDouble(),
      fechaRegistro: DateTime.parse(map['fechaRegistro'] as String),
    );
  }
}
