import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/vehiculo.dart';
import '../repositories/vehiculo_repository.dart';
import 'api_config.dart';

/// Implementacion real del repositorio de vehiculos que consume la API REST
/// del backend NestJS.
///
/// Reemplaza a MockVehiculoRepository para que los datos se persistan en la
/// base de datos PostgreSQL a traves del backend. Implementa la misma
/// interfaz abstracta VehiculoRepository, lo que permite intercambiar entre
/// el mock y la API real sin cambiar nada en los providers ni en las pantallas.
///
/// Todas las operaciones son asincronas y lanzan excepciones con mensajes
/// descriptivos cuando el backend retorna un error HTTP, permitiendo que
/// los providers muestren el error al usuario.
class ApiVehiculoRepository implements VehiculoRepository {
  /// Cliente HTTP reutilizable. Se recibe por constructor para facilitar
  /// pruebas unitarias (se puede inyectar un mock de http.Client).
  final http.Client _client;

  /// URL completa del endpoint de vehiculos, construida a partir de la
  /// configuracion centralizada en ApiConfig.
  final String _baseUrl;

  /// Constructor que permite inyectar un cliente HTTP personalizado.
  /// Si no se proporciona, se usa el cliente por defecto de la libreria http.
  ApiVehiculoRepository({http.Client? client})
      : _client = client ?? http.Client(),
        _baseUrl = '${ApiConfig.baseUrl}${ApiConfig.vehiclesPath}';

  /// Obtiene todos los vehiculos desde el backend.
  ///
  /// Realiza una peticion GET a /api/vehicles.
  /// El backend retorna una lista JSON con los vehiculos, incluyendo la
  /// relacion 'responsable' como objeto anidado (solo con el campo 'nombre').
  /// Cada elemento del arreglo se convierte a un objeto Vehiculo usando fromJson.
  ///
  /// Lanza una excepcion si el servidor retorna un codigo de estado diferente a 200.
  @override
  Future<List<Vehiculo>> obtenerTodos() async {
    final response = await _client.get(
      Uri.parse(_baseUrl),
      headers: ApiConfig.authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener vehiculos: ${response.statusCode} - ${response.body}',
      );
    }

    // El backend retorna un arreglo JSON. Se decodifica y se mapea cada
    // elemento a un objeto Vehiculo usando el factory constructor fromJson.
    final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;
    return jsonList
        .map((item) => Vehiculo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Crea un nuevo vehiculo en el backend.
  ///
  /// Realiza una peticion POST a /api/vehicles con el cuerpo JSON del vehiculo.
  /// Se usa toCreateJson() en vez de toJson() para excluir los campos 'id' y
  /// 'createdAt' que el backend genera automaticamente. Si se enviaran, el
  /// ValidationPipe del backend los rechazaria con un error 400 porque tiene
  /// configurado forbidNonWhitelisted: true.
  ///
  /// Retorna el vehiculo creado con su id y fecha de registro asignados
  /// por el backend.
  @override
  Future<Vehiculo> crear(Vehiculo vehiculo) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: ApiConfig.authHeaders,
      body: json.encode(vehiculo.toCreateJson()),
    );

    if (response.statusCode != 201) {
      // Se intenta extraer el mensaje de error del cuerpo de la respuesta.
      // El backend NestJS retorna errores en formato {message: "...", statusCode: N}.
      String errorMsg = 'Error al crear vehiculo: ${response.statusCode}';
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

    return Vehiculo.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  /// Actualiza un vehiculo existente en el backend.
  ///
  /// Realiza una peticion PATCH a /api/vehicles/:id con los campos a modificar.
  /// El backend usa PartialType(CreateVehicleDto), lo que permite enviar solo
  /// los campos que cambiaron. Sin embargo, aqui se envian todos los campos
  /// del DTO para simplificar la logica.
  ///
  /// Retorna el vehiculo actualizado tal como quedo guardado en la BD.
  @override
  Future<Vehiculo> actualizar(Vehiculo vehiculo) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/${vehiculo.id}'),
      headers: ApiConfig.authHeaders,
      body: json.encode(vehiculo.toCreateJson()),
    );

    if (response.statusCode != 200) {
      String errorMsg = 'Error al actualizar vehiculo: ${response.statusCode}';
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

    return Vehiculo.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  /// Elimina un vehiculo del backend por su id (UUID).
  ///
  /// Realiza una peticion DELETE a /api/vehicles/:id.
  /// El backend primero verifica que el vehiculo exista y luego lo elimina.
  /// Si el vehiculo no existe, retorna un error 404 con un mensaje descriptivo.
  @override
  Future<void> eliminar(String id) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: ApiConfig.authHeaders,
    );

    if (response.statusCode != 200) {
      String errorMsg = 'Error al eliminar vehiculo: ${response.statusCode}';
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
}
