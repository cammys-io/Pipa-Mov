import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pipa_mov/data/api/api_auth_service.dart';
import 'package:pipa_mov/data/api/api_config.dart';
import 'package:pipa_mov/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Genera un JWT mock con el payload dado.
/// El formato es header.payload.signature (signature es dummy).
String _buildMockJwt({
  required String sub,
  required String email,
  required String rol,
}) {
  final header = base64Url.encode(utf8.encode(json.encode({
    'alg': 'HS256',
    'typ': 'JWT',
  })));
  final payload = base64Url.encode(utf8.encode(json.encode({
    'sub': sub,
    'email': email,
    'rol': rol,
    'iat': 1700000000,
    'exp': 1700086400,
  })));
  return '$header.$payload.dummy-signature';
}

void main() {
  tearDown(() => ApiConfig.setToken(null));

  group('AuthProvider', () {
    test('estado inicial: no autenticado', () {
      final provider = AuthProvider();

      expect(provider.estaAutenticado, isFalse);
      expect(provider.token, isNull);
      expect(provider.userId, isNull);
      expect(provider.email, isNull);
      expect(provider.rol, isNull);
      expect(provider.cargando, isFalse);
      expect(provider.error, isNull);
    });

    test('login exitoso actualiza estado y ApiConfig', () async {
      final mockToken = _buildMockJwt(
        sub: 'user-uuid-123',
        email: 'admin@montecito.com',
        rol: 'admin',
      );

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'access_token': mockToken}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = ApiAuthService(client: mockClient);
      final provider = AuthProvider(authService: authService);

      final ok = await provider.login('admin@montecito.com', 'password123');

      expect(ok, isTrue);
      expect(provider.estaAutenticado, isTrue);
      expect(provider.token, mockToken);
      expect(provider.userId, 'user-uuid-123');
      expect(provider.email, 'admin@montecito.com');
      expect(provider.rol, 'admin');
      expect(provider.cargando, isFalse);
      expect(provider.error, isNull);

      // Verificar que ApiConfig tiene el token
      expect(ApiConfig.token, mockToken);
      expect(ApiConfig.authHeaders['Authorization'], 'Bearer $mockToken');
    });

    test('login fallido establece error y no autentica', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'message': 'Correo o contraseña incorrectos',
            'statusCode': 401,
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = ApiAuthService(client: mockClient);
      final provider = AuthProvider(authService: authService);

      final ok = await provider.login('admin@test.com', 'wrongpass');

      expect(ok, isFalse);
      expect(provider.estaAutenticado, isFalse);
      expect(provider.token, isNull);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Correo o contraseña incorrectos'));
      expect(provider.cargando, isFalse);
      expect(ApiConfig.token, isNull);
    });

    test('logout limpia todo el estado y ApiConfig', () async {
      final mockToken = _buildMockJwt(
        sub: 'user-uuid-456',
        email: 'admin@test.com',
        rol: 'admin',
      );

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'access_token': mockToken}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = ApiAuthService(client: mockClient);
      final provider = AuthProvider(authService: authService);

      // Primero login
      await provider.login('admin@test.com', 'pass123');
      expect(provider.estaAutenticado, isTrue);

      // Luego logout
      provider.logout();

      expect(provider.estaAutenticado, isFalse);
      expect(provider.token, isNull);
      expect(provider.userId, isNull);
      expect(provider.email, isNull);
      expect(provider.rol, isNull);
      expect(provider.error, isNull);
      expect(ApiConfig.token, isNull);
    });

    test('limpiarError solo limpia el error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'message': 'Error', 'statusCode': 401}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = ApiAuthService(client: mockClient);
      final provider = AuthProvider(authService: authService);

      await provider.login('a@b.com', '1');
      expect(provider.error, isNotNull);

      provider.limpiarError();
      expect(provider.error, isNull);
      expect(provider.estaAutenticado, isFalse); // sigue sin autenticar
    });

    test('notifica listeners durante el ciclo de login', () async {
      final mockToken = _buildMockJwt(
        sub: 'id', email: 'e@e.com', rol: 'admin');

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'access_token': mockToken}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = ApiAuthService(client: mockClient);
      final provider = AuthProvider(authService: authService);

      int notificationCount = 0;
      provider.addListener(() => notificationCount++);

      await provider.login('e@e.com', 'pass');

      // Debe notificar al menos 2 veces: inicio (cargando=true) y fin (cargando=false)
      expect(notificationCount, greaterThanOrEqualTo(2));
    });
  });
}
