class Venta {
  const Venta({
    required this.id,
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.totalVenta,
    required this.costoTotal,
    required this.ganancia,
    required this.fechaVenta,
  });

  final int id;
  final int productoId;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;
  final double totalVenta;
  final double costoTotal;
  final double ganancia;
  final DateTime fechaVenta;

  Venta copyWith({
    int? id,
    int? productoId,
    String? nombreProducto,
    int? cantidad,
    double? precioUnitario,
    double? totalVenta,
    double? costoTotal,
    double? ganancia,
    DateTime? fechaVenta,
  }) {
    return Venta(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      totalVenta: totalVenta ?? this.totalVenta,
      costoTotal: costoTotal ?? this.costoTotal,
      ganancia: ganancia ?? this.ganancia,
      fechaVenta: fechaVenta ?? this.fechaVenta,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productoId': productoId,
      'nombreProducto': nombreProducto,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'totalVenta': totalVenta,
      'costoTotal': costoTotal,
      'ganancia': ganancia,
      'fechaVenta': fechaVenta.toIso8601String(),
    };
  }

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'] as int,
      productoId: map['productoId'] as int,
      nombreProducto: map['nombreProducto'] as String,
      cantidad: map['cantidad'] as int,
      precioUnitario: (map['precioUnitario'] as num).toDouble(),
      totalVenta: (map['totalVenta'] as num).toDouble(),
      costoTotal: (map['costoTotal'] as num).toDouble(),
      ganancia: (map['ganancia'] as num).toDouble(),
      fechaVenta: DateTime.parse(map['fechaVenta'] as String),
    );
  }
}
