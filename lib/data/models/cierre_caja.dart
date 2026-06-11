class CierreCaja {
  const CierreCaja({
    required this.id,
    required this.fecha,
    required this.totalVentas,
    required this.totalGastos,
    required this.gananciaBruta,
    required this.gananciaNeta,
    required this.observaciones,
  });

  final int id;
  final DateTime fecha;
  final double totalVentas;
  final double totalGastos;
  final double gananciaBruta;
  final double gananciaNeta;
  final String observaciones;

  CierreCaja copyWith({
    int? id,
    DateTime? fecha,
    double? totalVentas,
    double? totalGastos,
    double? gananciaBruta,
    double? gananciaNeta,
    String? observaciones,
  }) {
    return CierreCaja(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      totalVentas: totalVentas ?? this.totalVentas,
      totalGastos: totalGastos ?? this.totalGastos,
      gananciaBruta: gananciaBruta ?? this.gananciaBruta,
      gananciaNeta: gananciaNeta ?? this.gananciaNeta,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'totalVentas': totalVentas,
      'totalGastos': totalGastos,
      'gananciaBruta': gananciaBruta,
      'gananciaNeta': gananciaNeta,
      'observaciones': observaciones,
    };
  }

  factory CierreCaja.fromMap(Map<String, dynamic> map) {
    return CierreCaja(
      id: map['id'] as int,
      fecha: DateTime.parse(map['fecha'] as String),
      totalVentas: (map['totalVentas'] as num).toDouble(),
      totalGastos: (map['totalGastos'] as num).toDouble(),
      gananciaBruta: (map['gananciaBruta'] as num).toDouble(),
      gananciaNeta: (map['gananciaNeta'] as num).toDouble(),
      observaciones: map['observaciones'] as String,
    );
  }
}
