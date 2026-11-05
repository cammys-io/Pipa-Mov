import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/cliente_especial.dart';
import '../repositories/cliente_especial_repository.dart';
import 'api_config.dart';

class ApiClienteEspecialRepository implements ClienteEspecialRepository {
  final String _url = '${ApiConfig.baseUrl}${ApiConfig.specialClientsPath}';
  final http.Client _client = http.Client();

  @override
  Future<List<ClienteEspecial>> obtenerTodos({bool? activo}) async {
    final uri = activo != null
        ? Uri.parse('$_url?activo=$activo')
        : Uri.parse(_url);

    final res = await _client.get(uri, headers: ApiConfig.authHeaders);
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((j) => ClienteEspecial.fromJson(j)).toList();
    }
    throw Exception('Error al obtener clientes especiales: ${res.statusCode} ${res.body}');
  }

  @override
  Future<ClienteEspecial> obtenerPorId(String id) async {
    final res = await _client.get(
      Uri.parse('$_url/$id'),
      headers: ApiConfig.authHeaders,
    );
    if (res.statusCode == 200) {
      return ClienteEspecial.fromJson(json.decode(res.body));
    }
    throw Exception('Error al obtener cliente: ${res.statusCode} ${res.body}');
  }

  @override
  Future<ClienteEspecial> crear(ClienteEspecial cliente) async {
    final res = await _client.post(
      Uri.parse(_url),
      headers: ApiConfig.authHeaders,
      body: json.encode(cliente.toJson()),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return ClienteEspecial.fromJson(json.decode(res.body));
    }
    throw Exception('Error al crear cliente: ${res.statusCode} ${res.body}');
  }

  @override
  Future<ClienteEspecial> actualizar(ClienteEspecial cliente) async {
    final res = await _client.patch(
      Uri.parse('$_url/${cliente.id}'),
      headers: ApiConfig.authHeaders,
      body: json.encode(cliente.toJson()),
    );
    if (res.statusCode == 200) {
      return ClienteEspecial.fromJson(json.decode(res.body));
    }
    throw Exception('Error al actualizar cliente: ${res.statusCode} ${res.body}');
  }

  @override
  Future<void> eliminar(String id) async {
    final res = await _client.delete(
      Uri.parse('$_url/$id'),
      headers: ApiConfig.authHeaders,
    );
    if (res.statusCode != 200) {
      throw Exception('Error al eliminar cliente: ${res.statusCode} ${res.body}');
    }
  }
}
