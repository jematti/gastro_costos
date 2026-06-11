class Ingrediente {
  const Ingrediente({
    required this.id,
    required this.nombre,
    required this.precioCompra,
    required this.cantidadCompra,
    required this.unidadCompra,
    required this.unidadBase,
    required this.costoPorUnidadBase,
    required this.fechaRegistro,
  });

  final int id;
  final String nombre;
  final double precioCompra;
  final double cantidadCompra;
  final String unidadCompra;
  final String unidadBase;
  final double costoPorUnidadBase;
  final DateTime fechaRegistro;

  Ingrediente copyWith({
    int? id,
    String? nombre,
    double? precioCompra,
    double? cantidadCompra,
    String? unidadCompra,
    String? unidadBase,
    double? costoPorUnidadBase,
    DateTime? fechaRegistro,
  }) {
    return Ingrediente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precioCompra: precioCompra ?? this.precioCompra,
      cantidadCompra: cantidadCompra ?? this.cantidadCompra,
      unidadCompra: unidadCompra ?? this.unidadCompra,
      unidadBase: unidadBase ?? this.unidadBase,
      costoPorUnidadBase: costoPorUnidadBase ?? this.costoPorUnidadBase,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precioCompra': precioCompra,
      'cantidadCompra': cantidadCompra,
      'unidadCompra': unidadCompra,
      'unidadBase': unidadBase,
      'costoPorUnidadBase': costoPorUnidadBase,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  factory Ingrediente.fromMap(Map<String, dynamic> map) {
    return Ingrediente(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      precioCompra: (map['precioCompra'] as num).toDouble(),
      cantidadCompra: (map['cantidadCompra'] as num).toDouble(),
      unidadCompra: map['unidadCompra'] as String,
      unidadBase: map['unidadBase'] as String,
      costoPorUnidadBase: (map['costoPorUnidadBase'] as num).toDouble(),
      fechaRegistro: DateTime.parse(map['fechaRegistro'] as String),
    );
  }
}
