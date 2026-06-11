class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.recetaId,
    required this.costoBase,
    required this.otrosCostos,
    required this.margenGanancia,
    required this.precioVentaSugerido,
    required this.precioVentaFinal,
    required this.fechaRegistro,
  });

  final int id;
  final String nombre;
  final int recetaId;
  final double costoBase;
  final double otrosCostos;
  final double margenGanancia;
  final double precioVentaSugerido;
  final double precioVentaFinal;
  final DateTime fechaRegistro;

  Producto copyWith({
    int? id,
    String? nombre,
    int? recetaId,
    double? costoBase,
    double? otrosCostos,
    double? margenGanancia,
    double? precioVentaSugerido,
    double? precioVentaFinal,
    DateTime? fechaRegistro,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      recetaId: recetaId ?? this.recetaId,
      costoBase: costoBase ?? this.costoBase,
      otrosCostos: otrosCostos ?? this.otrosCostos,
      margenGanancia: margenGanancia ?? this.margenGanancia,
      precioVentaSugerido: precioVentaSugerido ?? this.precioVentaSugerido,
      precioVentaFinal: precioVentaFinal ?? this.precioVentaFinal,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'recetaId': recetaId,
      'costoBase': costoBase,
      'otrosCostos': otrosCostos,
      'margenGanancia': margenGanancia,
      'precioVentaSugerido': precioVentaSugerido,
      'precioVentaFinal': precioVentaFinal,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      recetaId: map['recetaId'] as int,
      costoBase: (map['costoBase'] as num).toDouble(),
      otrosCostos: (map['otrosCostos'] as num).toDouble(),
      margenGanancia: (map['margenGanancia'] as num).toDouble(),
      precioVentaSugerido: (map['precioVentaSugerido'] as num).toDouble(),
      precioVentaFinal: (map['precioVentaFinal'] as num).toDouble(),
      fechaRegistro: DateTime.parse(map['fechaRegistro'] as String),
    );
  }
}
