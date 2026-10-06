/// Modelo de Vehículo (pipa de agua), alineado al esquema de BD.
enum TipoUnidad { pipa, volteo, retro, carroGarrafon }

enum EstadoVehiculo { activo, taller, inactivo }

extension TipoUnidadLabel on TipoUnidad {
  String get label {
    switch (this) {
      case TipoUnidad.pipa:
        return 'Pipa';
      case TipoUnidad.volteo:
        return 'Volteo';
      case TipoUnidad.retro:
        return 'Retro';
      case TipoUnidad.carroGarrafon:
        return 'Carro garrafón';
    }
  }

  /// Valor tal cual lo espera la BD (snake_case).
  String get dbValue {
    switch (this) {
      case TipoUnidad.pipa:
        return 'pipa';
      case TipoUnidad.volteo:
        return 'volteo';
      case TipoUnidad.retro:
        return 'retro';
      case TipoUnidad.carroGarrafon:
        return 'carro_garrafon';
    }
  }

  static TipoUnidad fromDbValue(String value) {
    return TipoUnidad.values.firstWhere(
      (t) => t.dbValue == value,
      orElse: () => TipoUnidad.pipa,
    );
  }
}

extension EstadoVehiculoLabel on EstadoVehiculo {
  String get label {
    switch (this) {
      case EstadoVehiculo.activo:
        return 'Activo';
      case EstadoVehiculo.taller:
        return 'Taller';
      case EstadoVehiculo.inactivo:
        return 'Inactivo';
    }
  }
}

class Vehiculo {
  final String id;
  final String modelo;
  final String marca;
  final String? color; // nullable, según BD
  final TipoUnidad tipo;
  final String placas;
  final double capacidadLitros; // BD: capacidad (float)
  final EstadoVehiculo estado; // BD: estatus
  final String? responsableId; // FK -> Usuario.id (BD: responsable_id)
  final DateTime fechaRegistro; // BD: createdAt

  Vehiculo({
    required this.id,
    required this.modelo,
    required this.marca,
    this.color,
    required this.tipo,
    required this.placas,
    required this.capacidadLitros,
    this.estado = EstadoVehiculo.activo,
    this.responsableId,
    DateTime? fechaRegistro,
  }) : fechaRegistro = fechaRegistro ?? DateTime.now();

  Vehiculo copyWith({
    String? modelo,
    String? marca,
    String? color,
    bool clearColor = false,
    TipoUnidad? tipo,
    String? placas,
    double? capacidadLitros,
    EstadoVehiculo? estado,
    String? responsableId,
    bool clearResponsable = false,
  }) {
    return Vehiculo(
      id: id,
      modelo: modelo ?? this.modelo,
      marca: marca ?? this.marca,
      color: clearColor ? null : (color ?? this.color),
      tipo: tipo ?? this.tipo,
      placas: placas ?? this.placas,
      capacidadLitros: capacidadLitros ?? this.capacidadLitros,
      estado: estado ?? this.estado,
      responsableId: clearResponsable
          ? null
          : (responsableId ?? this.responsableId),
      fechaRegistro: fechaRegistro,
    );
  }

  factory Vehiculo.fromJson(Map<String, dynamic> json) => Vehiculo(
    id: json['id'].toString(),
    modelo: json['modelo'] as String,
    marca: json['marca'] as String,
    color: json['color'] as String?,
    tipo: TipoUnidadLabel.fromDbValue(json['tipo'] as String),
    placas: json['placas'] as String,
    capacidadLitros: double.tryParse(json['capacidad']?.toString() ?? '0') ?? 0.0,
    estado: EstadoVehiculo.values.firstWhere((e) => e.name == json['estatus']),
    responsableId: (json['responsableId'] ?? json['responsable_id'] ?? json['responsable']?['id'])?.toString(),
    fechaRegistro: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'modelo': modelo,
    'marca': marca,
    'color': color,
    'tipo': tipo.dbValue,
    'placas': placas,
    'capacidad': capacidadLitros,
    'estatus': estado.name,
    'responsable_id': responsableId,
    'createdAt': fechaRegistro.toIso8601String(),
  };
}
