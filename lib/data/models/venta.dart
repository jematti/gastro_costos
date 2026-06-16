class Venta {
  const Venta({
    required this.id,
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.totalVenta,
    required this.costoUnitario,
    required this.costoTotal,
    required this.ganancia,
    required this.fechaVenta,
  });

  final int id;
  final int productoId;
  final String nombreProducto;
  final double cantidad;
  final double precioUnitario;
  final double totalVenta;
  final double costoUnitario;
  final double costoTotal;
  final double ganancia;
  final DateTime fechaVenta;

  Venta copyWith({
    int? id,
    int? productoId,
    String? nombreProducto,
    double? cantidad,
    double? precioUnitario,
    double? totalVenta,
    double? costoUnitario,
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
      costoUnitario: costoUnitario ?? this.costoUnitario,
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
      'costoUnitario': costoUnitario,
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
      cantidad: (map['cantidad'] as num).toDouble(),
      precioUnitario: (map['precioUnitario'] as num).toDouble(),
      totalVenta: (map['totalVenta'] as num).toDouble(),
      costoUnitario: (map['costoUnitario'] as num?)?.toDouble() ?? 0,
      costoTotal: (map['costoTotal'] as num).toDouble(),
      ganancia: (map['ganancia'] as num).toDouble(),
      fechaVenta: DateTime.parse(map['fechaVenta'] as String),
    );
  }
}
