import 'dart:convert';
import 'package:http/http.dart' as http;

/// ─────────────────────────────────────────────────────────────────────────
/// Referencia: datos de conexión a Postgres según tu docker-compose.yml
/// (servicio "database"). Estos datos NO se usan aquí, son para tu backend
/// (TypeORM/ormconfig) o para conectar TablePlus a la base:
///
///   Host (desde tu máquina): localhost
///   Puerto (desde tu máquina): 5433   <- mapeado desde el 5432 del contenedor
///   Base de datos: pipas_db
///   Usuario: admin
///   Contraseña: postgres
///
/// IMPORTANTE: este docker-compose.yml solo define el contenedor de Postgres,
/// NO el de tu backend (Express/NestJS/etc.). Flutter no habla con Postgres
/// directamente, habla con tu backend — así que el puerto de abajo (_baseUrl)
/// es el de TU SERVIDOR API, no el 5433 de Postgres.
/// ─────────────────────────────────────────────────────────────────────────

/// Excepción personalizada para errores de la API.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Servicio base para comunicarse con el backend.
/// Todos los demás servicios (AuthService, UserService, etc.) deberían
/// usar esta clase para hacer sus peticiones HTTP.
class ApiService {
  // ⚠️ TODO: reemplaza PUERTO por el puerto real donde corre tu backend
  // (el que corre "npm run start" o similar, no el de Postgres).
  // Ajusta también según dónde ejecutes la app Flutter:
  // - Emulador Android:      http://10.0.2.2:PUERTO/api
  // - Simulador iOS:         http://localhost:PUERTO/api
  // - Dispositivo físico:    http://TU_IP_LOCAL:PUERTO/api  (ej. 192.168.1.50)
  // - Flutter Web/Desktop:   http://localhost:PUERTO/api
  static const String _baseUrl = 'http://10.0.2.2:3000/api';

  final http.Client _client;
  String? _authToken;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Guarda el token (por ejemplo tras un login) para enviarlo en cada request.
  void setAuthToken(String token) => _authToken = token;

  void clearAuthToken() => _authToken = null;

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final uri = Uri.parse('$_baseUrl$endpoint');
    if (queryParams == null || queryParams.isEmpty) return uri;
    return uri.replace(
      queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic body;
    try {
      body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      body = response.body;
    }

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    }

    final message = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'Ocurrió un error en la petición';
    throw ApiException(statusCode, message);
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _client
          .get(_buildUri(endpoint, queryParams), headers: _headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on http.ClientException {
      throw ApiException(0, 'No se pudo conectar con el servidor');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await _client
          .post(_buildUri(endpoint), headers: _headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on http.ClientException {
      throw ApiException(0, 'No se pudo conectar con el servidor');
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await _client
          .put(_buildUri(endpoint), headers: _headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on http.ClientException {
      throw ApiException(0, 'No se pudo conectar con el servidor');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _client
          .delete(_buildUri(endpoint), headers: _headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on http.ClientException {
      throw ApiException(0, 'No se pudo conectar con el servidor');
    }
  }

  void dispose() => _client.close();
}