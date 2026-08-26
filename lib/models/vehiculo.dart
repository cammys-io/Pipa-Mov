/// Modelo de Vehículo (pipa de agua).
///
/// NOTA: Campos inferidos mientras se confirma el diagrama de BD real.
/// [responsableId] referencia el id de [Usuario] (FK), igual que
/// probablemente esté modelado en Postgres.
enum TipoUnidad { pipaGrande, pipaChica, camionCisterna }

enum EstadoVehiculo { activo, mantenimiento, fueraDeServicio }

extension TipoUnidadLabel on TipoUnidad {
  String get label {
    switch (this) {
      case TipoUnidad.pipaGrande:
        return 'Pipa grande';
      case TipoUnidad.pipaChica:
        return 'Pipa chica';
      case TipoUnidad.camionCisterna:
        return 'Camión cisterna';
    }
  }
}

extension EstadoVehiculoLabel on EstadoVehiculo {
  String get label {
    switch (this) {
      case EstadoVehiculo.activo:
        return 'Activo';
      case EstadoVehiculo.mantenimiento:
        return 'Mantenimiento';
      case EstadoVehiculo.fueraDeServicio:
        return 'Fuera de servicio';
    }
  }
}

class Vehiculo {
  final String id;
  final String placas;
  final String marca;
  final String modelo;
  final int anio;
  final double capacidadLitros;
  final TipoUnidad tipo;
  final EstadoVehiculo estado;
  final String? responsableId; // FK -> Usuario.id
  final DateTime fechaRegistro;

  Vehiculo({
    required this.id,
    required this.placas,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.capacidadLitros,
    required this.tipo,
    this.estado = EstadoVehiculo.activo,
    this.responsableId,
    DateTime? fechaRegistro,
  }) : fechaRegistro = fechaRegistro ?? DateTime.now();

  Vehiculo copyWith({
    String? placas,
    String? marca,
    String? modelo,
    int? anio,
    double? capacidadLitros,
    TipoUnidad? tipo,
    EstadoVehiculo? estado,
    String? responsableId,
    bool clearResponsable = false,
  }) {
    return Vehiculo(
      id: id,
      placas: placas ?? this.placas,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      anio: anio ?? this.anio,
      capacidadLitros: capacidadLitros ?? this.capacidadLitros,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      responsableId:
          clearResponsable ? null : (responsableId ?? this.responsableId),
      fechaRegistro: fechaRegistro,
    );
  }

  factory Vehiculo.fromJson(Map<String, dynamic> json) => Vehiculo(
        id: json['id'].toString(),
        placas: json['placas'] as String,
        marca: json['marca'] as String,
        modelo: json['modelo'] as String,
        anio: json['anio'] as int,
        capacidadLitros: (json['capacidadLitros'] as num).toDouble(),
        tipo: TipoUnidad.values.firstWhere((t) => t.name == json['tipo']),
        estado: EstadoVehiculo.values
            .firstWhere((e) => e.name == json['estado']),
        responsableId: json['responsableId']?.toString(),
        fechaRegistro: DateTime.parse(json['fechaRegistro'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'placas': placas,
        'marca': marca,
        'modelo': modelo,
        'anio': anio,
        'capacidadLitros': capacidadLitros,
        'tipo': tipo.name,
        'estado': estado.name,
        'responsableId': responsableId,
        'fechaRegistro': fechaRegistro.toIso8601String(),
      };
}
