import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/ingreso.dart';
import '../repositories/ingreso_repository.dart';
import 'api_config.dart';

class ApiIngresoRepository implements IngresoRepository {
  final String _baseUrl = '${ApiConfig.baseUrl}${ApiConfig.incomesPath}';
  final http.Client _client;

  ApiIngresoRepository({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<List<Ingreso>> obtenerTodos() async {
    final response = await _client.get(Uri.parse(_baseUrl), headers: ApiConfig.authHeaders);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Ingreso.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener ingresos: ${response.statusCode}');
    }
  }

  @override
  Future<Ingreso> crear(Ingreso ingreso) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: ApiConfig.authHeaders,
      body: json.encode(ingreso.toCreateJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Ingreso.fromJson(json.decode(response.body));
    } else {
      _throwError(response);
    }
    throw Exception('Unreachable');
  }

  @override
  Future<Ingreso> actualizar(Ingreso ingreso) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/${ingreso.id}'),
      headers: ApiConfig.authHeaders,
      body: json.encode(ingreso.toCreateJson()),
    );

    if (response.statusCode == 200) {
      return Ingreso.fromJson(json.decode(response.body));
    } else {
      _throwError(response);
    }
    throw Exception('Unreachable');
  }

  @override
  Future<void> eliminar(String id) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: ApiConfig.authHeaders,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      _throwError(response);
    }
  }

  void _throwError(http.Response response) {
    String errorMsg = 'Error en el backend: ${response.statusCode}';
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map && errorBody['message'] != null) {
        final msgs = errorBody['message'];
        if (msgs is List) {
          errorMsg = msgs.join(', ');
        } else {
          errorMsg = msgs.toString();
        }
      }
    } catch (_) {}
    throw Exception(errorMsg);
  }
}
