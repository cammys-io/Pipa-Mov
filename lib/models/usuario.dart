/// Modelo de Personal / Usuario, alineado al esquema de BD.
enum Rol { admin, chofer, operador }

enum EstadoPersonal { activo, inactivo, suspendido }

extension RolLabel on Rol {
  String get label {
    switch (this) {
      case Rol.admin:
        return 'Administrador';
      case Rol.chofer:
        return 'Chofer';
      case Rol.operador:
        return 'Operador';
    }
  }
}

extension EstadoPersonalLabel on EstadoPersonal {
  String get label {
    switch (this) {
      case EstadoPersonal.activo:
        return 'Activo';
      case EstadoPersonal.inactivo:
        return 'Inactivo';
      case EstadoPersonal.suspendido:
        return 'Suspendido';
    }
  }
}

class Usuario {
  final String id;
  final String nombre;
  final Rol rol;
  final String telefono;
  final String? numeroLicencia;
  final DateTime? vigencia;
  final EstadoPersonal estado;
  final DateTime fechaRegistro;
  final String? email;
  final String? password;

  Usuario({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.telefono,
    this.numeroLicencia,
    this.vigencia,
    this.estado = EstadoPersonal.activo,
    DateTime? fechaRegistro,
    this.email,
    this.password,
  }) : fechaRegistro = fechaRegistro ?? DateTime.now();

  /// Se conserva por compatibilidad con el resto de la app
  /// (tabla, dashboard, dropdown de responsable), que usa
  /// `nombreCompleto` para mostrar al usuario.
  String get nombreCompleto => nombre;

  Usuario copyWith({
    String? nombre,
    Rol? rol,
    String? telefono,
    String? numeroLicencia,
    DateTime? vigencia,
    EstadoPersonal? estado,
    String? email,
    String? password,
  }) {
    return Usuario(
      id: id,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      telefono: telefono ?? this.telefono,
      numeroLicencia: numeroLicencia ?? this.numeroLicencia,
      vigencia: vigencia ?? this.vigencia,
      estado: estado ?? this.estado,
      email: email ?? this.email,
      password: password ?? this.password,
      fechaRegistro: fechaRegistro,
    );
  }

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'].toString(),
    nombre: json['nombre'] as String,
    rol: Rol.values.firstWhere((r) => r.name == json['rol']),
    telefono: json['telefono'] as String,
    numeroLicencia: json['numeroLicencia'] as String?,
    vigencia: json['vigencia'] != null
        ? DateTime.parse(json['vigencia'] as String)
        : null,
    estado: EstadoPersonal.values.firstWhere((e) => e.name == json['estado']),
    fechaRegistro: DateTime.parse(json['createdAt'] as String),
    email: json['email'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'rol': rol.name,
    'telefono': telefono,
    'numeroLicencia': numeroLicencia,
    'vigencia': vigencia?.toIso8601String(),
    'estado': estado.name,
    'createdAt': fechaRegistro.toIso8601String(),
    if (email != null) 'email': email,
    if (password != null) 'password': password,
  };
}
