class RecetaIngrediente {
  const RecetaIngrediente({
    required this.id,
    required this.recetaId,
    required this.ingredienteId,
    required this.nombreIngrediente,
    required this.cantidadUsada,
    required this.unidadUsada,
    required this.costoUnitario,
    required this.costoTotal,
    required this.fechaRegistro,
  });

  final int id;
  final int recetaId;
  final int ingredienteId;
  final String nombreIngrediente;
  final double cantidadUsada;
  final String unidadUsada;
  final double costoUnitario;
  final double costoTotal;
  final DateTime fechaRegistro;

  RecetaIngrediente copyWith({
    int? id,
    int? recetaId,
    int? ingredienteId,
    String? nombreIngrediente,
    double? cantidadUsada,
    String? unidadUsada,
    double? costoUnitario,
    double? costoTotal,
    DateTime? fechaRegistro,
  }) {
    return RecetaIngrediente(
      id: id ?? this.id,
      recetaId: recetaId ?? this.recetaId,
      ingredienteId: ingredienteId ?? this.ingredienteId,
      nombreIngrediente: nombreIngrediente ?? this.nombreIngrediente,
      cantidadUsada: cantidadUsada ?? this.cantidadUsada,
      unidadUsada: unidadUsada ?? this.unidadUsada,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      costoTotal: costoTotal ?? this.costoTotal,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recetaId': recetaId,
      'ingredienteId': ingredienteId,
      'nombreIngrediente': nombreIngrediente,
      'cantidadUsada': cantidadUsada,
      'unidadUsada': unidadUsada,
      'costoUnitario': costoUnitario,
      'costoTotal': costoTotal,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  factory RecetaIngrediente.fromMap(Map<String, dynamic> map) {
    return RecetaIngrediente(
      id: map['id'] as int,
      recetaId: map['recetaId'] as int,
      ingredienteId: map['ingredienteId'] as int,
      nombreIngrediente: map['nombreIngrediente'] as String,
      cantidadUsada: (map['cantidadUsada'] as num).toDouble(),
      unidadUsada: map['unidadUsada'] as String,
      costoUnitario: (map['costoUnitario'] as num).toDouble(),
      costoTotal: (map['costoTotal'] as num).toDouble(),
      fechaRegistro: DateTime.parse(map['fechaRegistro'] as String),
    );
  }
}
