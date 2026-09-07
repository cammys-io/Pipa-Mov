import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';


// Ajusta este import a la ruta real donde guardaste api_service.dart
import 'package:pipa_mov/services/api.service.dart';

void main() {
  group('ApiService', () {
    test('GET exitoso devuelve el JSON decodificado', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/users');
        return http.Response(
          jsonEncode([
            {'id': 1, 'name': 'Ana'}
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiService(client: mockClient);
      final result = await api.get('/users');

      expect(result, isA<List>());
      expect(result[0]['name'], 'Ana');
    });

    test('POST exitoso envía el body correcto y devuelve 201', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        final sentBody = jsonDecode(request.body);
        expect(sentBody['name'], 'Carlos');
        return http.Response(
          jsonEncode({'id': 2, 'name': 'Carlos'}),
          201,
        );
      });

      final api = ApiService(client: mockClient);
      final result = await api.post('/users', body: {'name': 'Carlos'});

      expect(result['id'], 2);
    });

    test('Respuesta 404 lanza ApiException con el statusCode correcto', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Usuario no encontrado'}),
          404,
        );
      });

      final api = ApiService(client: mockClient);

      expect(
        () => api.get('/users/999'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('El token de autenticación se envía en el header Authorization', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer mi-token-123');
        return http.Response('{}', 200);
      });

      final api = ApiService(client: mockClient)..setAuthToken('mi-token-123');
      await api.get('/perfil');
    });

    test('Error de conexión (backend caído/URL mal) lanza ApiException', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final api = ApiService(client: mockClient);

      expect(() => api.get('/users'), throwsA(isA<ApiException>()));
    });
  });
}