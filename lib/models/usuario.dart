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

  /// Email del usuario. Solo los usuarios con rol admin requieren email
  /// para poder autenticarse en el sistema.
  final String? email;

  /// Contraseña en texto plano. Se usa SOLO al momento de crear o editar
  /// un usuario admin. El backend la hashea con bcrypt antes de guardarla.
  /// Nunca se recibe del backend (el campo tiene select: false en TypeORM).
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
      fechaRegistro: fechaRegistro,
      email: email ?? this.email,
      password: password ?? this.password,
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
        estado:
            EstadoPersonal.values.firstWhere((e) => e.name == json['estado']),
        fechaRegistro: DateTime.parse(json['createdAt'] as String),
        email: json['email'] as String?,
        // password nunca viene del backend (select: false)
      );

  /// Serializa el usuario completo a JSON, incluyendo id y fecha de registro.
  /// Se usa para representacion interna y almacenamiento local.
  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'rol': rol.name,
        'telefono': telefono,
        'numeroLicencia': numeroLicencia,
        'vigencia': vigencia?.toIso8601String(),
        'estado': estado.name,
        'email': email,
        'createdAt': fechaRegistro.toIso8601String(),
      };

  /// Serializa solo los campos que acepta el DTO del backend para crear
  /// o actualizar un usuario. Excluye 'id' y 'createdAt' porque el backend
  /// los genera automaticamente y rechaza campos no definidos en el DTO
  /// (tiene configurado forbidNonWhitelisted: true en el ValidationPipe).
  ///
  /// Los campos opcionales (numeroLicencia, vigencia, email, password) solo
  /// se incluyen si tienen un valor distinto de null, evitando enviar datos
  /// innecesarios.
  ///
  /// Para usuarios admin, se incluyen email y password (el backend hashea
  /// la contraseña con bcrypt). Para roles no-admin, el backend ignora/limpia
  /// el password aunque se envíe.
  Map<String, dynamic> toCreateJson() {
    final json = <String, dynamic>{
      'nombre': nombre,
      'rol': rol.name,
      'telefono': telefono,
      'estado': estado.name,
    };
    if (numeroLicencia != null) json['numeroLicencia'] = numeroLicencia;
    if (vigencia != null) json['vigencia'] = vigencia!.toIso8601String();
    if (email != null && email!.isNotEmpty) json['email'] = email;
    if (password != null && password!.isNotEmpty) json['password'] = password;
    return json;
  }
}
