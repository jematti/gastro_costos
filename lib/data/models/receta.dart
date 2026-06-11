class Receta {
  const Receta({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.porciones,
    required this.costoTotal,
    required this.costoPorPorcion,
    required this.fechaRegistro,
  });

  final int id;
  final String nombre;
  final String descripcion;
  final int porciones;
  final double costoTotal;
  final double costoPorPorcion;
  final DateTime fechaRegistro;

  Receta copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    int? porciones,
    double? costoTotal,
    double? costoPorPorcion,
    DateTime? fechaRegistro,
  }) {
    return Receta(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      porciones: porciones ?? this.porciones,
      costoTotal: costoTotal ?? this.costoTotal,
      costoPorPorcion: costoPorPorcion ?? this.costoPorPorcion,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'porciones': porciones,
      'costoTotal': costoTotal,
      'costoPorPorcion': costoPorPorcion,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  factory Receta.fromMap(Map<String, dynamic> map) {
    return Receta(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String,
      porciones: map['porciones'] as int,
      costoTotal: (map['costoTotal'] as num).toDouble(),
      costoPorPorcion: (map['costoPorPorcion'] as num).toDouble(),
      fechaRegistro: DateTime.parse(map['fechaRegistro'] as String),
    );
  }
}
