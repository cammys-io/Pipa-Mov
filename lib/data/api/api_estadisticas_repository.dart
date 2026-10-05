import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/estadisticas.dart';
import 'api_config.dart';

/// Consume el modulo de estadisticas del backend (`/api/statics`).
class ApiEstadisticasRepository {
  final String _baseUrl = '${ApiConfig.baseUrl}${ApiConfig.staticsPath}';
  final http.Client _client;

  ApiEstadisticasRepository({http.Client? client})
      : _client = client ?? http.Client();

  Future<DashboardResumen> obtenerResumenDashboard() async {
    final json = await _get('dashboard-resume');
    return DashboardResumen.fromJson(json);
  }

  Future<double> obtenerIngresoPeriodo(FiltroFecha filtro) async {
    final json = await _get('ingreso-resume', filtro.toQuery());
    return montoDeJson(json, const ['montoTotal']);
  }

  Future<double> obtenerGastoPeriodo(FiltroFecha filtro) async {
    final json = await _get('gasto-resume', filtro.toQuery());
    return montoDeJson(json, const ['montoTotal']);
  }

  Future<double> obtenerIngresoTotal() async {
    final json = await _get('ingreso-total');
    return montoDeJson(json, const ['totalIncomes']);
  }

  Future<double> obtenerGastoTotal() async {
    final json = await _get('gasto-total');
    return montoDeJson(json, const ['totalExpenses']);
  }

  Future<Map<String, dynamic>> _get(String path,
      [Map<String, String>? query]) async {
    final uri = Uri.parse('$_baseUrl/$path')
        .replace(queryParameters: query?.isEmpty ?? true ? null : query);
    final response = await _client.get(uri, headers: ApiConfig.authHeaders);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Respuesta inesperada del servidor');
    }
    throw Exception(_mensajeError(response));
  }

  String _mensajeError(http.Response response) {
    var msg = 'Error en el backend: ${response.statusCode}';
    try {
      final body = json.decode(response.body);
      if (body is Map && body['message'] != null) {
        final m = body['message'];
        msg = m is List ? m.join(', ') : m.toString();
      }
    } catch (_) {}
    return msg;
  }
}
