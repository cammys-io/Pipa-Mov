enum TipoServicio {
  aguaGarrafon,
  pipaAgua,
  maquinaria,
  volteo
}

extension TipoServicioExtension on TipoServicio {
  String get dbValue {
    switch (this) {
      case TipoServicio.aguaGarrafon: return 'garrafon de agua';
      case TipoServicio.pipaAgua: return 'pipa de agua';
      case TipoServicio.maquinaria: return 'maquinaria';
      case TipoServicio.volteo: return 'volteo';
    }
  }

  String get label {
    switch (this) {
      case TipoServicio.aguaGarrafon: return 'Garrafón de Agua';
      case TipoServicio.pipaAgua: return 'Pipa de Agua';
      case TipoServicio.maquinaria: return 'Maquinaria';
      case TipoServicio.volteo: return 'Volteo';
    }
  }

  static TipoServicio fromDbValue(String value) {
    if (value == 'garrafon de agua') return TipoServicio.aguaGarrafon;
    if (value == 'pipa de agua') return TipoServicio.pipaAgua;
    if (value == 'maquinaria') return TipoServicio.maquinaria;
    if (value == 'volteo') return TipoServicio.volteo;
    return TipoServicio.pipaAgua; // Fallback
  }
}

enum CapacidadPipa {
  cincoMil,
  diezMil,
  milQuinientos
}

extension CapacidadPipaExtension on CapacidadPipa {
  String get dbValue {
    switch (this) {
      case CapacidadPipa.cincoMil: return '5000 '; // Backend tiene un espacio!
      case CapacidadPipa.diezMil: return '10000';
      case CapacidadPipa.milQuinientos: return '1500';
    }
  }

  String get label {
    switch (this) {
      case CapacidadPipa.cincoMil: return '5,000 L';
      case CapacidadPipa.diezMil: return '10,000 L';
      case CapacidadPipa.milQuinientos: return '1,500 L';
    }
  }

  static CapacidadPipa? fromDbValue(String? value) {
    if (value == null) return null;
    if (value.trim() == '5000') return CapacidadPipa.cincoMil;
    if (value == '10000') return CapacidadPipa.diezMil;
    if (value == '1500') return CapacidadPipa.milQuinientos;
    return null;
  }
}

enum TipoMaterial {
  arena,
  grava,
  tierra,
  escombro,
  otro
}

extension TipoMaterialExtension on TipoMaterial {
  String get label {
    return name[0].toUpperCase() + name.substring(1);
  }

  static TipoMaterial? fromString(String? value) {
    if (value == null) return null;
    try {
      return TipoMaterial.values.firstWhere((e) => e.name == value.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}

class Ingreso {
  final String id;
  final DateTime fecha;
  final TipoServicio tipoServicio;
  final double? cantidadHoras;
  final int? cantidadViajes;
  final int? cantidadGarrafones;
  final CapacidadPipa? capacidadPipa;
  final TipoMaterial? tipoMaterial;
  final double montoTotal;
  final String? notaUrl;
  final String? empleadoId;
  final String? vehiculoId;

  // Extra relations info
  final String? empleadoNombre;
  final String? vehiculoPlacas;

  Ingreso({
    required this.id,
    required this.fecha,
    required this.tipoServicio,
    this.cantidadHoras,
    this.cantidadViajes,
    this.cantidadGarrafones,
    this.capacidadPipa,
    this.tipoMaterial,
    required this.montoTotal,
    this.notaUrl,
    this.empleadoId,
    this.vehiculoId,
    this.empleadoNombre,
    this.vehiculoPlacas,
  });

  factory Ingreso.fromJson(Map<String, dynamic> json) {
    String? vId = json['vehiculoId']?.toString();
    String? eId = json['empleadoId']?.toString();
    String? eNombre;
    String? vPlacas;

    if (json['vehiculo'] is Map) {
      final vMap = json['vehiculo'] as Map;
      vId ??= vMap['id']?.toString();
      vPlacas = vMap['placas']?.toString();
    }
    
    if (json['responsable'] is Map) {
      final eMap = json['responsable'] as Map; // Backend returns 'responsable' in incomes
      eId ??= eMap['id']?.toString();
      eNombre = eMap['nombre']?.toString();
    }

    return Ingreso(
      id: json['id']?.toString() ?? '',
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha'].toString()) : DateTime.now(),
      tipoServicio: TipoServicioExtension.fromDbValue(json['tipo_servicio'].toString()),
      cantidadHoras: json['cantidad_horas'] != null ? double.parse(json['cantidad_horas'].toString()) : null,
      cantidadViajes: json['cantidad_viajes'] != null ? int.parse(json['cantidad_viajes'].toString()) : null,
      cantidadGarrafones: json['cantidad_garrafones'] != null ? int.parse(json['cantidad_garrafones'].toString()) : null,
      capacidadPipa: CapacidadPipaExtension.fromDbValue(json['capacidad_pipa']?.toString()),
      tipoMaterial: TipoMaterialExtension.fromString(json['tipo_material']?.toString()),
      montoTotal: json['monto_total'] != null ? double.parse(json['monto_total'].toString()) : 0.0,
      notaUrl: json['nota_url']?.toString(),
      empleadoId: eId,
      vehiculoId: vId,
      empleadoNombre: eNombre,
      vehiculoPlacas: vPlacas,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'fecha': fecha.toIso8601String(),
      'tipo_servicio': tipoServicio.dbValue,
      if (cantidadHoras != null) 'cantidad_horas': cantidadHoras,
      if (cantidadViajes != null) 'cantidad_viajes': cantidadViajes,
      if (cantidadGarrafones != null) 'cantidad_garrafones': cantidadGarrafones,
      if (capacidadPipa != null) 'capacidad_pipa': capacidadPipa!.dbValue,
      if (tipoMaterial != null) 'tipo_material': tipoMaterial!.name,
      'monto_total': montoTotal,
      if (notaUrl != null && notaUrl!.isNotEmpty) 'nota_url': notaUrl,
      if (empleadoId != null && empleadoId!.isNotEmpty) 'empleadoId': empleadoId,
      if (vehiculoId != null && vehiculoId!.isNotEmpty) 'vehiculoId': vehiculoId,
    };
  }

  Ingreso copyWith({
    String? id,
    DateTime? fecha,
    TipoServicio? tipoServicio,
    double? cantidadHoras,
    int? cantidadViajes,
    int? cantidadGarrafones,
    CapacidadPipa? capacidadPipa,
    TipoMaterial? tipoMaterial,
    double? montoTotal,
    String? notaUrl,
    String? empleadoId,
    String? vehiculoId,
  }) {
    return Ingreso(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      tipoServicio: tipoServicio ?? this.tipoServicio,
      cantidadHoras: cantidadHoras ?? this.cantidadHoras,
      cantidadViajes: cantidadViajes ?? this.cantidadViajes,
      cantidadGarrafones: cantidadGarrafones ?? this.cantidadGarrafones,
      capacidadPipa: capacidadPipa ?? this.capacidadPipa,
      tipoMaterial: tipoMaterial ?? this.tipoMaterial,
      montoTotal: montoTotal ?? this.montoTotal,
      notaUrl: notaUrl ?? this.notaUrl,
      empleadoId: empleadoId ?? this.empleadoId,
      vehiculoId: vehiculoId ?? this.vehiculoId,
      empleadoNombre: empleadoNombre,
      vehiculoPlacas: vehiculoPlacas,
    );
  }
}
