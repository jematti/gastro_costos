class Gasto {
  const Gasto({
    required this.id,
    required this.concepto,
    required this.monto,
    required this.categoria,
    required this.fechaGasto,
    required this.observacion,
  });

  final int id;
  final String concepto;
  final double monto;
  final String categoria;
  final DateTime fechaGasto;
  final String observacion;

  Gasto copyWith({
    int? id,
    String? concepto,
    double? monto,
    String? categoria,
    DateTime? fechaGasto,
    String? observacion,
  }) {
    return Gasto(
      id: id ?? this.id,
      concepto: concepto ?? this.concepto,
      monto: monto ?? this.monto,
      categoria: categoria ?? this.categoria,
      fechaGasto: fechaGasto ?? this.fechaGasto,
      observacion: observacion ?? this.observacion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'concepto': concepto,
      'monto': monto,
      'categoria': categoria,
      'fechaGasto': fechaGasto.toIso8601String(),
      'observacion': observacion,
    };
  }

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'] as int,
      concepto: map['concepto'] as String,
      monto: (map['monto'] as num).toDouble(),
      categoria: map['categoria'] as String,
      fechaGasto: DateTime.parse(map['fechaGasto'] as String),
      observacion: map['observacion'] as String? ?? '',
    );
  }
}
