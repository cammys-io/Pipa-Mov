/// Modelo de Personal / Usuario.
///
/// NOTA: Campos inferidos mientras se confirma el diagrama de BD real.
/// Cuando tengas el diagrama definitivo, ajusta solo este archivo y
/// [UsuarioRepository] — el resto de la app (formularios, tablas,
/// providers) consume estos campos por nombre y no debería requerir
/// cambios grandes.
enum Puesto { chofer, operador, supervisor, administrador }

enum EstadoPersonal { activo, inactivo }

extension PuestoLabel on Puesto {
  String get label {
    switch (this) {
      case Puesto.chofer:
        return 'Chofer';
      case Puesto.operador:
        return 'Operador';
      case Puesto.supervisor:
        return 'Supervisor';
      case Puesto.administrador:
        return 'Administrador';
    }
  }
}

extension EstadoPersonalLabel on EstadoPersonal {
  String get label => this == EstadoPersonal.activo ? 'Activo' : 'Inactivo';
}

class Usuario {
  final String id;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String telefono;
  final String correo;
  final Puesto puesto;
  final String? numeroLicencia;
  final DateTime? vigenciaLicencia;
  final EstadoPersonal estado;
  final DateTime fechaRegistro;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.telefono,
    required this.correo,
    required this.puesto,
    this.numeroLicencia,
    this.vigenciaLicencia,
    this.estado = EstadoPersonal.activo,
    DateTime? fechaRegistro,
  }) : fechaRegistro = fechaRegistro ?? DateTime.now();

  String get nombreCompleto => '$nombre $apellidoPaterno $apellidoMaterno';

  Usuario copyWith({
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? telefono,
    String? correo,
    Puesto? puesto,
    String? numeroLicencia,
    DateTime? vigenciaLicencia,
    EstadoPersonal? estado,
  }) {
    return Usuario(
      id: id,
      nombre: nombre ?? this.nombre,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      puesto: puesto ?? this.puesto,
      numeroLicencia: numeroLicencia ?? this.numeroLicencia,
      vigenciaLicencia: vigenciaLicencia ?? this.vigenciaLicencia,
      estado: estado ?? this.estado,
      fechaRegistro: fechaRegistro,
    );
  }

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'].toString(),
        nombre: json['nombre'] as String,
        apellidoPaterno: json['apellidoPaterno'] as String,
        apellidoMaterno: json['apellidoMaterno'] as String,
        telefono: json['telefono'] as String,
        correo: json['correo'] as String,
        puesto: Puesto.values.firstWhere((p) => p.name == json['puesto']),
        numeroLicencia: json['numeroLicencia'] as String?,
        vigenciaLicencia: json['vigenciaLicencia'] != null
            ? DateTime.parse(json['vigenciaLicencia'] as String)
            : null,
        estado: EstadoPersonal.values
            .firstWhere((e) => e.name == json['estado']),
        fechaRegistro: DateTime.parse(json['fechaRegistro'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'apellidoPaterno': apellidoPaterno,
        'apellidoMaterno': apellidoMaterno,
        'telefono': telefono,
        'correo': correo,
        'puesto': puesto.name,
        'numeroLicencia': numeroLicencia,
        'vigenciaLicencia': vigenciaLicencia?.toIso8601String(),
        'estado': estado.name,
        'fechaRegistro': fechaRegistro.toIso8601String(),
      };
}
