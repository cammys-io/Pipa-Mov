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
      responsableId:
          clearResponsable ? null : (responsableId ?? this.responsableId),
      fechaRegistro: fechaRegistro,
    );
  }

  /// Construye un Vehiculo a partir del JSON que retorna el backend NestJS.
  ///
  /// Se manejan dos escenarios distintos de respuesta:
  /// 1. Respuesta completa (create, findOne): incluye todos los campos,
  ///    incluyendo responsableId y createdAt.
  /// 2. Respuesta parcial (findAll con select): no incluye createdAt,
  ///    y en vez de responsableId retorna un objeto anidado 'responsable'
  ///    con el nombre y posiblemente el id del usuario asignado.
  ///
  /// Tambien se maneja que 'capacidad' pueda llegar como string desde
  /// PostgreSQL (columna de tipo decimal), por lo que se usa toString()
  /// antes de parsear a double para cubrir ambos casos.
  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    // El backend retorna responsableId en camelCase cuando devuelve la entidad
    // completa. En findAll (con select y relations), retorna un objeto anidado
    // 'responsable' que puede contener el id del usuario asignado.
    String? resId = json['responsableId']?.toString();
    if (resId == null && json['responsable'] is Map) {
      resId = (json['responsable'] as Map)['id']?.toString();
    }

    return Vehiculo(
      id: json['id']?.toString() ?? '',
      modelo: json['modelo']?.toString() ?? '',
      marca: json['marca']?.toString() ?? '',
      color: json['color']?.toString(),
      tipo: TipoUnidadLabel.fromDbValue(json['tipo']?.toString() ?? ''),
      placas: json['placas']?.toString() ?? '',
      // Se usa toString() antes de parsear porque PostgreSQL decimal
      // puede serializar como string en vez de numero.
      capacidadLitros: double.tryParse(json['capacidad']?.toString() ?? '0') ?? 0.0,
      estado: EstadoVehiculo.values.firstWhere(
        (e) => e.name == json['estatus'],
        orElse: () => EstadoVehiculo.activo,
      ),
      responsableId: resId,
      // createdAt no esta presente en la respuesta de findAll (no se incluye
      // en el select del backend), asi que se usa la fecha actual como fallback.
      fechaRegistro: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Serializa el vehiculo completo a JSON, incluyendo id y fecha de registro.
  /// Se usa para representacion interna y almacenamiento local.
  Map<String, dynamic> toJson() => {
        'id': id,
        'modelo': modelo,
        'marca': marca,
        'color': color,
        'tipo': tipo.dbValue,
        'placas': placas,
        'capacidad': capacidadLitros,
        'estatus': estado.name,
        'responsableId': responsableId,
        'createdAt': fechaRegistro.toIso8601String(),
      };

  /// Serializa solo los campos que acepta el DTO del backend para crear
  /// o actualizar un vehiculo. Excluye 'id' y 'createdAt' porque el backend
  /// los genera automaticamente y rechaza campos no definidos en el DTO
  /// (tiene configurado forbidNonWhitelisted: true en el ValidationPipe).
  ///
  /// Los campos opcionales (color, responsableId) solo se incluyen si
  /// tienen un valor distinto de null, evitando enviar datos innecesarios.
  Map<String, dynamic> toCreateJson() {
    final json = <String, dynamic>{
      'modelo': modelo,
      'marca': marca,
      'tipo': tipo.dbValue,
      'placas': placas,
      'capacidad': capacidadLitros,
      'estatus': estado.name,
    };
    if (color != null) json['color'] = color;
    if (responsableId != null) json['responsableId'] = responsableId;
    return json;
  }
}
