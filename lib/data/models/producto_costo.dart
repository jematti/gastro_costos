class ProductoCosto {
  const ProductoCosto({
    required this.id,
    required this.productoId,
    required this.nombre,
    required this.tipoCosto,
    required this.categoria,
    required this.tipoCalculo,
    required this.monto,
    required this.unidadesEstimadasMes,
    required this.minutosElaboracion,
    required this.costoHora,
    required this.porcentaje,
    required this.costoCalculado,
    required this.fechaRegistro,
  });

  final int id;
  final int productoId;
  final String nombre;
  final String tipoCosto;
  final String categoria;
  final String tipoCalculo;
  final double monto;
  final double? unidadesEstimadasMes;
  final double? minutosElaboracion;
  final double? costoHora;
  final double? porcentaje;
  final double costoCalculado;
  final DateTime fechaRegistro;

  ProductoCosto copyWith({
    int? id,
    int? productoId,
    String? nombre,
    String? tipoCosto,
    String? categoria,
    String? tipoCalculo,
    double? monto,
    double? unidadesEstimadasMes,
    double? minutosElaboracion,
    double? costoHora,
    double? porcentaje,
    double? costoCalculado,
    DateTime? fechaRegistro,
  }) {
    return ProductoCosto(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      nombre: nombre ?? this.nombre,
      tipoCosto: tipoCosto ?? this.tipoCosto,
      categoria: categoria ?? this.categoria,
      tipoCalculo: tipoCalculo ?? this.tipoCalculo,
      monto: monto ?? this.monto,
      unidadesEstimadasMes: unidadesEstimadasMes ?? this.unidadesEstimadasMes,
      minutosElaboracion: minutosElaboracion ?? this.minutosElaboracion,
      costoHora: costoHora ?? this.costoHora,
      porcentaje: porcentaje ?? this.porcentaje,
      costoCalculado: costoCalculado ?? this.costoCalculado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productoId': productoId,
      'nombre': nombre,
      'tipoCosto': tipoCosto,
      'categoria': categoria,
      'tipoCalculo': tipoCalculo,
      'monto': monto,
      'unidadesEstimadasMes': unidadesEstimadasMes,
      'minutosElaboracion': minutosElaboracion,
      'costoHora': costoHora,
      'porcentaje': porcentaje,
      'costoCalculado': costoCalculado,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  factory ProductoCosto.fromMap(Map<String, dynamic> map) {
    return ProductoCosto(
      id: map['id'] as int,
      productoId: map['productoId'] as int,
      nombre: map['nombre'] as String,
      tipoCosto: map['tipoCosto'] as String,
      categoria: map['categoria'] as String,
      tipoCalculo: map['tipoCalculo'] as String,
      monto: (map['monto'] as num).toDouble(),
      unidadesEstimadasMes: (map['unidadesEstimadasMes'] as num?)?.toDouble(),
      minutosElaboracion: (map['minutosElaboracion'] as num?)?.toDouble(),
      costoHora: (map['costoHora'] as num?)?.toDouble(),
      porcentaje: (map['porcentaje'] as num?)?.toDouble(),
      costoCalculado: (map['costoCalculado'] as num).toDouble(),
      fechaRegistro: DateTime.parse(map['fechaRegistro'] as String),
    );
  }
}
