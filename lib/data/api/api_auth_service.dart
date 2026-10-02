import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Servicio que consume el endpoint de autenticación del backend NestJS.
///
/// Realiza la petición POST /api/auth/login enviando email y password.
/// El backend valida las credenciales contra la BD (bcrypt compare) y
/// retorna un JWT firmado con el payload { sub, email, rol }.
///
/// Este servicio es consumido por AuthProvider para manejar el estado
/// de la sesión en la app.
class ApiAuthService {
  final http.Client _client;

  ApiAuthService({http.Client? client}) : _client = client ?? http.Client();

  /// Intenta autenticar al usuario con email y contraseña.
  ///
  /// Retorna un Map con la clave 'access_token' si el login es exitoso.
  /// Lanza una excepción con mensaje descriptivo si falla.
  ///
  /// Posibles errores del backend:
  /// - 401: Correo o contraseña incorrectos
  /// - 400: Campos faltantes o inválidos (ValidationPipe)
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.authPath}/login';

    final response = await _client.post(
      Uri.parse(url),
      headers: ApiConfig.jsonHeaders,
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    // Extraer mensaje de error del backend NestJS
    String errorMsg = 'Error de autenticación';
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map && errorBody['message'] != null) {
        final msg = errorBody['message'];
        errorMsg = msg is List ? msg.join(', ') : msg.toString();
      }
    } catch (_) {}

    throw Exception(errorMsg);
  }
}
