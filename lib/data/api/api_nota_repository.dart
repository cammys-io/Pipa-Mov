import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/nota.dart';
import '../repositories/nota_repository.dart';
import 'api_config.dart';

/// Consume el módulo `api/notes` del backend NestJS.
class ApiNotaRepository implements NotaRepository {
  final String _baseUrl = '${ApiConfig.baseUrl}${ApiConfig.notesPath}';
  final http.Client _client;

  ApiNotaRepository({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<List<Nota>> obtenerTodas() async {
    final response =
        await _client.get(Uri.parse(_baseUrl), headers: ApiConfig.authHeaders);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((e) => Nota.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throwError(response);
  }

  @override
  Future<Nota> crear({
    required String titulo,
    required String descripcion,
    required EstadoNota estatus,
  }) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: ApiConfig.authHeaders,
      body: json.encode({
        'titulo': titulo,
        'descripcion': descripcion,
        'estatus': estatus.api,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Nota.fromJson(json.decode(response.body));
    }
    _throwError(response);
  }

  @override
  Future<Nota> actualizar(
    String id, {
    String? titulo,
    String? descripcion,
    EstadoNota? estatus,
  }) async {
    final body = <String, dynamic>{
      if (titulo != null) 'titulo': titulo,
      if (descripcion != null) 'descripcion': descripcion,
      if (estatus != null) 'estatus': estatus.api,
    };
    final response = await _client.patch(
      Uri.parse('$_baseUrl/$id'),
      headers: ApiConfig.authHeaders,
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return Nota.fromJson(json.decode(response.body));
    }
    _throwError(response);
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

  Never _throwError(http.Response response) {
    String errorMsg = 'Error en el backend: ${response.statusCode}';
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map && errorBody['message'] != null) {
        final msgs = errorBody['message'];
        errorMsg = msgs is List ? msgs.join(', ') : msgs.toString();
      }
    } catch (_) {}
    throw Exception(errorMsg);
  }
}
