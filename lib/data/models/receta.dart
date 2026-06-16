class Receta {
  const Receta({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.procedimiento,
    required this.porciones,
    required this.costoTotal,
    required this.costoPorPorcion,
    required this.fechaRegistro,
    this.imagePath,
  });

  final int id;
  final String nombre;
  final String descripcion;
  final String procedimiento;
  final int porciones;
  final double costoTotal;
  final double costoPorPorcion;
  final DateTime fechaRegistro;
  final String? imagePath;

  Receta copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? procedimiento,
    int? porciones,
    double? costoTotal,
    double? costoPorPorcion,
    DateTime? fechaRegistro,
    String? imagePath,
  }) {
    return Receta(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      procedimiento: procedimiento ?? this.procedimiento,
      porciones: porciones ?? this.porciones,
      costoTotal: costoTotal ?? this.costoTotal,
      costoPorPorcion: costoPorPorcion ?? this.costoPorPorcion,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'procedimiento': procedimiento,
      'porciones': porciones,
      'costoTotal': costoTotal,
      'costoPorPorcion': costoPorPorcion,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory Receta.fromMap(Map<String, dynamic> map) {
    return Receta(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String,
      procedimiento: map['procedimiento'] as String? ?? '',
      porciones: map['porciones'] as int,
      costoTotal: (map['costoTotal'] as num).toDouble(),
      costoPorPorcion: (map['costoPorPorcion'] as num).toDouble(),
      fechaRegistro: DateTime.parse(map['fechaRegistro'] as String),
      imagePath: map['imagePath'] as String?,
    );
  }
}
