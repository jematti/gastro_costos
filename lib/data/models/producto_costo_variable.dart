class ProductoCostoVariable {
  const ProductoCostoVariable({
    required this.id,
    required this.productoId,
    required this.nombre,
    required this.categoria,
    required this.tipoCalculo,
    required this.monto,
    required this.porcentaje,
    required this.costoCalculado,
    required this.fechaRegistro,
  });

  final int id;
  final int productoId;
  final String nombre;
  final String categoria;
  final String tipoCalculo;
  final double? monto;
  final double? porcentaje;
  final double costoCalculado;
  final DateTime fechaRegistro;

  ProductoCostoVariable copyWith({
    int? id,
    int? productoId,
    String? nombre,
    String? categoria,
    String? tipoCalculo,
    double? monto,
    double? porcentaje,
    double? costoCalculado,
    DateTime? fechaRegistro,
  }) {
    return ProductoCostoVariable(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      tipoCalculo: tipoCalculo ?? this.tipoCalculo,
      monto: monto ?? this.monto,
      porcentaje: porcentaje ?? this.porcentaje,
      costoCalculado: costoCalculado ?? this.costoCalculado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'productoId': productoId,
    'nombre': nombre,
    'categoria': categoria,
    'tipoCalculo': tipoCalculo,
    'monto': monto,
    'porcentaje': porcentaje,
    'costoCalculado': costoCalculado,
    'fechaRegistro': fechaRegistro.toIso8601String(),
  };

  factory ProductoCostoVariable.fromMap(Map<String, dynamic> map) {
    return ProductoCostoVariable(
      id: map['id'] as int,
      productoId: map['productoId'] as int,
      nombre: map['nombre'] as String,
      categoria: map['categoria'] as String,
      tipoCalculo: map['tipoCalculo'] as String,
      monto: (map['monto'] as num?)?.toDouble(),
      porcentaje: (map['porcentaje'] as num?)?.toDouble(),
      costoCalculado: (map['costoCalculado'] as num).toDouble(),
      fechaRegistro: DateTime.parse(map['fechaRegistro'] as String),
    );
  }
}
