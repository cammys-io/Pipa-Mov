import 'package:flutter_test/flutter_test.dart';
import 'package:pipa_mov/data/api/api_config.dart';

void main() {
  group('ApiConfig', () {
    tearDown(() {
      // Limpiar estado global después de cada test
      ApiConfig.setToken(null);
    });

    test('jsonHeaders no incluye Authorization', () {
      expect(ApiConfig.jsonHeaders.containsKey('Authorization'), isFalse);
      expect(ApiConfig.jsonHeaders['Content-Type'], 'application/json');
      expect(ApiConfig.jsonHeaders['Accept'], 'application/json');
    });

    test('authHeaders sin token no incluye Authorization', () {
      ApiConfig.setToken(null);
      final headers = ApiConfig.authHeaders;
      expect(headers.containsKey('Authorization'), isFalse);
      expect(headers['Content-Type'], 'application/json');
    });

    test('authHeaders con token incluye Bearer token', () {
      ApiConfig.setToken('test-jwt-token-123');
      final headers = ApiConfig.authHeaders;
      expect(headers['Authorization'], 'Bearer test-jwt-token-123');
      expect(headers['Content-Type'], 'application/json');
    });

    test('setToken actualiza el token correctamente', () {
      expect(ApiConfig.token, isNull);

      ApiConfig.setToken('token-1');
      expect(ApiConfig.token, 'token-1');

      ApiConfig.setToken('token-2');
      expect(ApiConfig.token, 'token-2');

      ApiConfig.setToken(null);
      expect(ApiConfig.token, isNull);
    });

    test('authHeaders genera una nueva instancia cada vez', () {
      ApiConfig.setToken('abc');
      final h1 = ApiConfig.authHeaders;
      final h2 = ApiConfig.authHeaders;
      // Deben tener el mismo contenido pero ser objetos diferentes
      expect(h1, equals(h2));
      expect(identical(h1, h2), isFalse);
    });

    test('authPath está configurado correctamente', () {
      expect(ApiConfig.authPath, '/api/auth');
    });
  });
}
