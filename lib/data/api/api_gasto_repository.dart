import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/gasto.dart';
import '../repositories/gasto_repository.dart';
import 'api_config.dart';

class ApiGastoRepository implements GastoRepository {
  final String _baseUrl = '${ApiConfig.baseUrl}${ApiConfig.expensesPath}';
  final http.Client _client;

  ApiGastoRepository({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<List<Gasto>> obtenerTodos() async {
    final response = await _client.get(Uri.parse(_baseUrl), headers: ApiConfig.authHeaders);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Gasto.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener gastos: ${response.statusCode}');
    }
  }

  @override
  Future<Gasto> crear(Gasto gasto) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: ApiConfig.authHeaders,
      body: json.encode(gasto.toCreateJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Gasto.fromJson(json.decode(response.body));
    } else {
      _throwError(response);
    }
    throw Exception('Unreachable');
  }

  @override
  Future<Gasto> actualizar(Gasto gasto) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/${gasto.id}'),
      headers: ApiConfig.authHeaders,
      body: json.encode(gasto.toCreateJson()),
    );

    if (response.statusCode == 200) {
      return Gasto.fromJson(json.decode(response.body));
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
