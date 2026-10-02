import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pipa_mov/data/api/api_auth_service.dart';
import 'package:pipa_mov/data/api/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(() => ApiConfig.setToken(null));

  group('ApiAuthService', () {
    test('login exitoso retorna access_token', () async {
      final mockClient = MockClient((request) async {
        // Verificar que la petición es correcta
        expect(request.method, 'POST');
        expect(request.url.toString(),
            '${ApiConfig.baseUrl}${ApiConfig.authPath}/login');
        expect(request.headers['Content-Type'], 'application/json');

        final body = json.decode(request.body);
        expect(body['email'], 'admin@test.com');
        expect(body['password'], 'secreto123');

        return http.Response(
          json.encode({'access_token': 'jwt-token-mock-12345'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ApiAuthService(client: mockClient);
      final result = await service.login('admin@test.com', 'secreto123');

      expect(result['access_token'], 'jwt-token-mock-12345');
    });

    test('login fallido con credenciales incorrectas lanza excepción', () async {
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

      final service = ApiAuthService(client: mockClient);

      expect(
        () => service.login('admin@test.com', 'wrongpassword'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Correo o contraseña incorrectos'),
        )),
      );
    });

    test('login fallido con error de validación (array de mensajes)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'message': ['email must be an email', 'password should not be empty'],
            'statusCode': 400,
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ApiAuthService(client: mockClient);

      expect(
        () => service.login('not-an-email', ''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('email must be an email'),
        )),
      );
    });

    test('login con error de red lanza excepción', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final service = ApiAuthService(client: mockClient);

      expect(
        () => service.login('admin@test.com', 'secreto123'),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
