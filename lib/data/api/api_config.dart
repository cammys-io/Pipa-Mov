/// Configuracion central de la conexion al backend NestJS.
///
/// Aqui se define la URL base del servidor y las rutas de cada modulo.
///
/// Para desarrollo local segun la plataforma donde corra Flutter:
/// - En un emulador Android, usar 'http://10.0.2.2:3000' porque
///   localhost dentro del emulador apunta al propio dispositivo virtual,
///   no a la maquina host donde corre el backend.
/// - En el simulador iOS o en Flutter web, usar 'http://localhost:3000'.
/// - En un dispositivo fisico conectado por USB o WiFi, usar la IP local
///   de la maquina donde corre el backend, por ejemplo 'http://192.168.1.100:3000'.
///
/// Si el backend se despliega en produccion, cambiar esta URL por la del servidor.
class ApiConfig {
  /// URL base del backend NestJS. No incluir barra diagonal al final.
  static const String baseUrl = 'http://localhost:3000';

  /// Ruta base para el modulo de vehiculos.
  /// Corresponde al controlador @Controller('api/vehicles') del backend.
  static const String vehiclesPath = '/api/vehicles';

  /// Ruta base para el modulo de usuarios (empleados).
  /// Corresponde al controlador @Controller('api/users') del backend.
  static const String usersPath = '/api/users';
  static const String expensesPath = '/api/expenses';
  static const String incomesPath = '/api/incomes';

  /// Ruta base para el modulo de estadisticas del dashboard.
  /// Corresponde al controlador @Controller('api/statics') del backend.
  static const String staticsPath = '/api/statics';

  /// Ruta base para el modulo de autenticacion.
  /// Corresponde al controlador @Controller('api/auth') del backend.
  static const String authPath = '/api/auth';

  /// Cabeceras comunes para todas las peticiones JSON al backend.
  /// Content-Type indica que el cuerpo de la peticion es JSON.
  /// Accept indica que esperamos una respuesta JSON.
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ---------------------------------------------------------------------------
  // Gestion del token JWT
  // ---------------------------------------------------------------------------

  /// Token JWT almacenado en memoria tras el login exitoso.
  static String? _token;

  /// Guarda el token JWT recibido del backend.
  static void setToken(String? token) => _token = token;

  /// Devuelve el token actual o null si no hay sesion activa.
  static String? get token => _token;

  /// Cabeceras con autenticacion JWT para peticiones protegidas.
  ///
  /// Incluye el encabezado `Authorization: Bearer <token>` cuando existe
  /// una sesion activa. Las peticiones a endpoints protegidos del backend
  /// requieren este encabezado; de lo contrario, el JwtAuthGuard retorna
  /// un 401 Unauthorized.
  static Map<String, String> get authHeaders {
    final headers = Map<String, String>.from(jsonHeaders);
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }
}
