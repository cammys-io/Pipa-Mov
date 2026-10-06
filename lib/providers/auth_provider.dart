import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/api/api_auth_service.dart';
import '../data/api/api_config.dart';

/// Provider que gestiona el estado de autenticación de la app.
///
/// Maneja el ciclo completo de sesión:
/// 1. Login: envía credenciales al backend, recibe JWT, decodifica payload.
/// 2. Sesión activa: almacena token en memoria y en ApiConfig para que
///    todos los repositorios API incluyan el header Authorization.
/// 3. Logout: limpia token y datos de usuario.
///
/// El JWT del backend contiene el payload { sub (userId), email, rol }
/// que se decodifica localmente sin necesidad de otra petición al servidor.
class AuthProvider extends ChangeNotifier {
  final ApiAuthService _authService;

  String? _token;
  String? _userId;
  String? _email;
  String? _rol;
  String? _nombre;
  bool _cargando = false;
  String? _error;

  AuthProvider({ApiAuthService? authService})
    : _authService = authService ?? ApiAuthService();

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// true si existe un token JWT válido en memoria.
  bool get estaAutenticado => _token != null;

  String? get token => _token;
  String? get userId => _userId;
  String? get email => _email;
  String? get rol => _rol;
  String? get nombre => _nombre;
  bool get cargando => _cargando;
  String? get error => _error;

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  /// Intenta iniciar sesión con email y contraseña.
  ///
  /// Retorna true si el login fue exitoso, false si falló.
  /// En caso de error, el mensaje queda disponible en [error].
  Future<bool> login(String email, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.login(email, password);
      _token = data['access_token'] as String;

      // Guardar el token en ApiConfig para que todos los repositorios
      // lo incluyan automáticamente en sus peticiones.
      ApiConfig.setToken(_token);

      // Decodificar el payload del JWT para obtener datos del usuario.
      _decodeToken(_token!);

      _cargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  /// Cierra la sesión actual: limpia el token y los datos del usuario.
  void logout() {
    _token = null;
    _userId = null;
    _email = null;
    _rol = null;
    _nombre = null;
    _error = null;
    ApiConfig.setToken(null);
    notifyListeners();
  }

  /// Limpia solo el mensaje de error (util al navegar de vuelta al login).
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Decodificación del JWT
  // ---------------------------------------------------------------------------

  /// Decodifica el payload de un JWT (la segunda parte separada por '.').
  ///
  /// El payload del backend contiene:
  /// - sub: UUID del usuario
  /// - email: correo electrónico
  /// - rol: admin | chofer | operador
  /// - iat: issued at (timestamp)
  /// - exp: expiration (timestamp)
  void _decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return;

      // El payload es base64url-encoded
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = json.decode(decoded) as Map<String, dynamic>;

      _userId = data['sub'] as String?;
      _email = data['email'] as String?;
      _rol = data['rol'] as String?;
    } catch (e) {
      // Si no se puede decodificar el token, no es crítico.
      // El token sigue siendo válido para las peticiones HTTP.
      debugPrint('Error decodificando JWT: $e');
    }
  }
}
