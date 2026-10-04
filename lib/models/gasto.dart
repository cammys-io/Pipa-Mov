enum CategoriaGasto {
  combustible,
  insumos,
  sueldos,
  refacciones,
  taller,
  otro
}

extension CategoriaGastoExtension on CategoriaGasto {
  String get label {
    switch (this) {
      case CategoriaGasto.combustible:
        return 'Combustible';
      case CategoriaGasto.insumos:
        return 'Insumos';
      case CategoriaGasto.sueldos:
        return 'Sueldos';
      case CategoriaGasto.refacciones:
        return 'Refacciones';
      case CategoriaGasto.taller:
        return 'Taller';
      case CategoriaGasto.otro:
        return 'Otro';
    }
  }

  static CategoriaGasto fromString(String value) {
    return CategoriaGasto.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => CategoriaGasto.otro,
    );
  }
}

class Gasto {
  final String id;
  final DateTime fecha;
  final CategoriaGasto categoria;
  final double monto;
  final String descripcion;
  final String? comprobanteUrl;
  final String? vehiculoId;
  final String? empleadoId;

  // Additional data mapped from nested relation
  final String? empleadoNombre;
  final String? vehiculoPlacas;
  final String? vehiculoMarca;
  final String? vehiculoTipo;

  Gasto({
    required this.id,
    required this.fecha,
    required this.categoria,
    required this.monto,
    required this.descripcion,
    this.comprobanteUrl,
    this.vehiculoId,
    this.empleadoId,
    this.empleadoNombre,
    this.vehiculoPlacas,
    this.vehiculoMarca,
    this.vehiculoTipo,
  });

  factory Gasto.fromJson(Map<String, dynamic> json) {
    String? vId = json['vehiculoId']?.toString();
    String? eId = json['empleadoId']?.toString();
    String? eNombre;
    String? vPlacas;
    String? vMarca;
    String? vTipo;

    if (json['vehiculo'] is Map) {
      final vMap = json['vehiculo'] as Map;
      vId ??= vMap['id']?.toString();
      vPlacas = vMap['placas']?.toString();
      vMarca = vMap['marca']?.toString();
      vTipo = vMap['tipo']?.toString();
    }
    
    if (json['empleado'] is Map) {
      final eMap = json['empleado'] as Map;
      eId ??= eMap['id']?.toString();
      eNombre = eMap['nombre']?.toString();
    }

    return Gasto(
      id: json['id']?.toString() ?? '',
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha'].toString()) : DateTime.now(),
      categoria: CategoriaGastoExtension.fromString(json['categoria'].toString()),
      monto: json['monto'] != null ? double.parse(json['monto'].toString()) : 0.0,
      descripcion: json['descripcion']?.toString() ?? '',
      comprobanteUrl: json['comprobante_url']?.toString(),
      vehiculoId: vId,
      empleadoId: eId,
      empleadoNombre: eNombre,
      vehiculoPlacas: vPlacas,
      vehiculoMarca: vMarca,
      vehiculoTipo: vTipo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'categoria': categoria.name,
      'monto': monto,
      'descripcion': descripcion,
      'comprobante_url': comprobanteUrl,
      'vehiculoId': vehiculoId,
      'empleadoId': empleadoId,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'fecha': fecha.toIso8601String(),
      'categoria': categoria.name,
      'monto': monto,
      'descripcion': descripcion,
      if (comprobanteUrl != null && comprobanteUrl!.isNotEmpty) 'comprobante_url': comprobanteUrl,
      if (vehiculoId != null && vehiculoId!.isNotEmpty) 'vehiculoId': vehiculoId,
      if (empleadoId != null && empleadoId!.isNotEmpty) 'empleadoId': empleadoId,
    };
  }

  Gasto copyWith({
    String? id,
    DateTime? fecha,
    CategoriaGasto? categoria,
    double? monto,
    String? descripcion,
    String? comprobanteUrl,
    String? vehiculoId,
    String? empleadoId,
  }) {
    return Gasto(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      categoria: categoria ?? this.categoria,
      monto: monto ?? this.monto,
      descripcion: descripcion ?? this.descripcion,
      comprobanteUrl: comprobanteUrl ?? this.comprobanteUrl,
      vehiculoId: vehiculoId ?? this.vehiculoId,
      empleadoId: empleadoId ?? this.empleadoId,
      empleadoNombre: empleadoNombre,
      vehiculoPlacas: vehiculoPlacas,
    );
  }
}
