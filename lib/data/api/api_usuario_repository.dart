import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/usuario.dart';
import '../repositories/usuario_repository.dart';
import 'api_config.dart';

/// Implementacion real del repositorio de usuarios (empleados) que consume
/// la API REST del backend NestJS.
///
/// Reemplaza a MockUsuarioRepository para que los datos se persistan en la
/// base de datos PostgreSQL a traves del backend. Implementa la misma
/// interfaz abstracta UsuarioRepository, lo que permite intercambiar entre
/// el mock y la API real sin cambiar nada en los providers ni en las pantallas.
///
/// Todas las operaciones son asincronas y lanzan excepciones con mensajes
/// descriptivos cuando el backend retorna un error HTTP, permitiendo que
/// los providers muestren el error al usuario.
class ApiUsuarioRepository implements UsuarioRepository {
  /// Cliente HTTP reutilizable. Se recibe por constructor para facilitar
  /// pruebas unitarias (se puede inyectar un mock de http.Client).
  final http.Client _client;

  /// URL completa del endpoint de usuarios, construida a partir de la
  /// configuracion centralizada en ApiConfig.
  final String _baseUrl;

  /// Constructor que permite inyectar un cliente HTTP personalizado.
  /// Si no se proporciona, se usa el cliente por defecto de la libreria http.
  ApiUsuarioRepository({http.Client? client})
      : _client = client ?? http.Client(),
        _baseUrl = '${ApiConfig.baseUrl}${ApiConfig.usersPath}';

  /// Obtiene todos los usuarios desde el backend.
  ///
  /// Realiza una peticion GET a /api/users.
  /// El backend retorna la lista completa de usuarios sin filtro de select,
  /// por lo que todos los campos estan presentes incluyendo createdAt.
  /// Cada elemento del arreglo se convierte a un objeto Usuario usando fromJson.
  ///
  /// Lanza una excepcion si el servidor retorna un codigo de estado diferente a 200.
  @override
  Future<List<Usuario>> obtenerTodos() async {
    final response = await _client.get(
      Uri.parse(_baseUrl),
      headers: ApiConfig.authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener usuarios: ${response.statusCode} - ${response.body}',
      );
    }

    // El backend retorna un arreglo JSON. Se decodifica y se mapea cada
    // elemento a un objeto Usuario usando el factory constructor fromJson.
    final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;
    return jsonList
        .map((item) => Usuario.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Crea un nuevo usuario (empleado) en el backend.
  ///
  /// Realiza una peticion POST a /api/users con el cuerpo JSON del usuario.
  /// Se usa toCreateJson() en vez de toJson() para excluir los campos 'id' y
  /// 'createdAt' que el backend genera automaticamente. Si se enviaran, el
  /// ValidationPipe del backend los rechazaria con un error 400 porque tiene
  /// configurado forbidNonWhitelisted: true.
  ///
  /// Los campos del DTO CreateUserDto son:
  /// - nombre (requerido): nombre completo del empleado
  /// - rol (requerido): enum con valores admin, chofer, operador
  /// - telefono (requerido): numero de contacto
  /// - numeroLicencia (opcional): folio de licencia de conducir
  /// - vigencia (opcional): fecha de vencimiento de la licencia en formato ISO 8601
  /// - estado (requerido): enum con valores activo, inactivo, suspendido
  ///
  /// Retorna el usuario creado con su id y fecha de registro asignados
  /// por el backend.
  @override
  Future<Usuario> crear(Usuario usuario) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: ApiConfig.authHeaders,
      body: json.encode(usuario.toCreateJson()),
    );

    if (response.statusCode != 201) {
      // Se intenta extraer el mensaje de error del cuerpo de la respuesta.
      // El backend NestJS retorna errores en formato {message: "...", statusCode: N}.
      // El campo 'message' puede ser un string o un arreglo de strings
      // (cuando hay multiples errores de validacion).
      String errorMsg = 'Error al crear usuario: ${response.statusCode}';
      try {
        final errorBody = json.decode(response.body);
        if (errorBody is Map && errorBody['message'] != null) {
          final msg = errorBody['message'];
          errorMsg = msg is List ? msg.join(', ') : msg.toString();
        }
      } catch (_) {
        // Si no se puede parsear el error, se usa el mensaje generico.
      }
      throw Exception(errorMsg);
    }

    return Usuario.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  /// Actualiza un usuario existente en el backend.
  ///
  /// Realiza una peticion PATCH a /api/users/:id con los campos a modificar.
  /// El backend usa PartialType(CreateUserDto), lo que permite enviar solo
  /// los campos que cambiaron. Sin embargo, aqui se envian todos los campos
  /// del DTO para simplificar la logica.
  ///
  /// El backend usa preload() de TypeORM para buscar el usuario por id,
  /// fusionar los datos nuevos con los existentes, y guardar el resultado.
  /// Si el id no existe, retorna un error.
  ///
  /// Retorna el usuario actualizado tal como quedo guardado en la BD.
  @override
  Future<Usuario> actualizar(Usuario usuario) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/${usuario.id}'),
      headers: ApiConfig.authHeaders,
      body: json.encode(usuario.toCreateJson()),
    );

    if (response.statusCode != 200) {
      String errorMsg = 'Error al actualizar usuario: ${response.statusCode}';
      try {
        final errorBody = json.decode(response.body);
        if (errorBody is Map && errorBody['message'] != null) {
          final msg = errorBody['message'];
          errorMsg = msg is List ? msg.join(', ') : msg.toString();
        }
      } catch (_) {
        // Si no se puede parsear el error, se usa el mensaje generico.
      }
      throw Exception(errorMsg);
    }

    return Usuario.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  /// Elimina un usuario del backend por su id (UUID).
  ///
  /// Realiza una peticion DELETE a /api/users/:id.
  /// El backend primero verifica que el usuario exista y luego lo elimina.
  /// Si el usuario no existe, retorna un error con un mensaje descriptivo.
  ///
  /// Nota: si el usuario tiene vehiculos asignados (relacion OneToMany),
  /// la eliminacion puede fallar dependiendo de la configuracion de
  /// cascada de la base de datos.
  @override
  Future<void> eliminar(String id) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: ApiConfig.authHeaders,
    );

    if (response.statusCode != 200) {
      String errorMsg = 'Error al eliminar usuario: ${response.statusCode}';
      try {
        final errorBody = json.decode(response.body);
        if (errorBody is Map && errorBody['message'] != null) {
          errorMsg = errorBody['message'].toString();
        }
      } catch (_) {
        // Si no se puede parsear el error, se usa el mensaje generico.
      }
      throw Exception(errorMsg);
    }
  }

  /// Obtiene un usuario con sus vehículos asignados (relación OneToMany).
  /// Realiza petición GET a /api/users/:id/vehicles
  @override
  Future<Map<String, dynamic>> obtenerConVehiculos(String id) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/$id/vehicles'),
      headers: ApiConfig.authHeaders,
    );

    if (response.statusCode != 200) {
      String errorMsg = 'Error al obtener detalles del usuario: ${response.statusCode}';
      try {
        final errorBody = json.decode(response.body);
        if (errorBody is Map && errorBody['message'] != null) {
          errorMsg = errorBody['message'].toString();
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }
}
