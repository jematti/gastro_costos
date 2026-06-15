class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.recetaId,
    required this.nombreReceta,
    required this.costoBase,
    required this.minutosElaboracion,
    required this.costoHoraManoObra,
    required this.costoManoObra,
    required this.costosVariables,
    required this.costosFijos,
    required this.unidadesEstimadasMes,
    required this.otrosCostos,
    required this.costoTotalProducto,
    required this.margenGanancia,
    required this.precioVentaSugerido,
    required this.precioVentaFinal,
    required this.fechaRegistro,
  });

  final int id;
  final String nombre;
  final int recetaId;
  final String nombreReceta;
  final double costoBase;
  final double minutosElaboracion;
  final double costoHoraManoObra;
  final double costoManoObra;
  final double costosVariables;
  final double costosFijos;
  final double unidadesEstimadasMes;
  final double otrosCostos;
  final double costoTotalProducto;
  final double margenGanancia;
  final double precioVentaSugerido;
  final double precioVentaFinal;
  final DateTime fechaRegistro;

  Producto copyWith({
    int? id,
    String? nombre,
    int? recetaId,
    String? nombreReceta,
    double? costoBase,
    double? minutosElaboracion,
    double? costoHoraManoObra,
    double? costoManoObra,
    double? costosVariables,
    double? costosFijos,
    double? unidadesEstimadasMes,
    double? otrosCostos,
    double? costoTotalProducto,
    double? margenGanancia,
    double? precioVentaSugerido,
    double? precioVentaFinal,
    DateTime? fechaRegistro,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      recetaId: recetaId ?? this.recetaId,
      nombreReceta: nombreReceta ?? this.nombreReceta,
      costoBase: costoBase ?? this.costoBase,
      minutosElaboracion: minutosElaboracion ?? this.minutosElaboracion,
      costoHoraManoObra: costoHoraManoObra ?? this.costoHoraManoObra,
      costoManoObra: costoManoObra ?? this.costoManoObra,
      costosVariables: costosVariables ?? this.costosVariables,
      costosFijos: costosFijos ?? this.costosFijos,
      unidadesEstimadasMes: unidadesEstimadasMes ?? this.unidadesEstimadasMes,
      otrosCostos: otrosCostos ?? this.otrosCostos,
      costoTotalProducto: costoTotalProducto ?? this.costoTotalProducto,
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
      'nombreReceta': nombreReceta,
      'costoBase': costoBase,
      'minutosElaboracion': minutosElaboracion,
      'costoHoraManoObra': costoHoraManoObra,
      'costoManoObra': costoManoObra,
      'costosVariables': costosVariables,
      'costosFijos': costosFijos,
      'unidadesEstimadasMes': unidadesEstimadasMes,
      'otrosCostos': otrosCostos,
      'costoTotalProducto': costoTotalProducto,
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
      nombreReceta: map['nombreReceta'] as String? ?? '',
      costoBase: (map['costoBase'] as num).toDouble(),
      minutosElaboracion: (map['minutosElaboracion'] as num?)?.toDouble() ?? 0,
      costoHoraManoObra: (map['costoHoraManoObra'] as num?)?.toDouble() ?? 0,
      costoManoObra: (map['costoManoObra'] as num?)?.toDouble() ?? 0,
      costosVariables: (map['costosVariables'] as num?)?.toDouble() ?? 0,
      costosFijos: (map['costosFijos'] as num?)?.toDouble() ?? 0,
      unidadesEstimadasMes:
          (map['unidadesEstimadasMes'] as num?)?.toDouble() ?? 0,
      otrosCostos: (map['otrosCostos'] as num).toDouble(),
      costoTotalProducto:
          (map['costoTotalProducto'] as num?)?.toDouble() ??
          (map['costoBase'] as num).toDouble() +
              (map['otrosCostos'] as num).toDouble(),
      margenGanancia: (map['margenGanancia'] as num).toDouble(),
      precioVentaSugerido: (map['precioVentaSugerido'] as num).toDouble(),
      precioVentaFinal: (map['precioVentaFinal'] as num).toDouble(),
      fechaRegistro: DateTime.parse(map['fechaRegistro'] as String),
    );
  }
}
