import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/movimiento.dart';
import '../repositories/movimiento_repository.dart';
import 'api_config.dart';

class ApiMovimientoRepository implements MovimientoRepository {
  final String _urlIngresos = '${ApiConfig.baseUrl}${ApiConfig.incomesPath}';
  final String _urlGastos = '${ApiConfig.baseUrl}${ApiConfig.expensesPath}';
  final http.Client _client = http.Client();

  @override
  Future<List<Movimiento>> obtenerTodos() async {
    final List<Movimiento> todos = [];

    // 1. Obtener Ingresos
    final resIncomes = await _client.get(Uri.parse(_urlIngresos), headers: ApiConfig.authHeaders);
    if (resIncomes.statusCode == 200) {
      final List<dynamic> data = json.decode(resIncomes.body);
      todos.addAll(data.map((j) => Ingreso.fromJson(j)));
    } else {
      throw Exception('Error al obtener ingresos: ${resIncomes.statusCode}');
    }

    // 2. Obtener Gastos
    final resExpenses = await _client.get(Uri.parse(_urlGastos), headers: ApiConfig.authHeaders);
    if (resExpenses.statusCode == 200) {
      final List<dynamic> data = json.decode(resExpenses.body);
      todos.addAll(data.map((j) => Gasto.fromJson(j)));
    } else {
      throw Exception('Error al obtener gastos: ${resExpenses.statusCode}');
    }

    // Ordenar por fecha desc
    todos.sort((a, b) => b.fecha.compareTo(a.fecha));
    return todos;
  }

  @override
  Future<void> guardar(Movimiento movimiento) async {
    final url = movimiento.esGasto ? _urlGastos : _urlIngresos;
    
    final isUpdate = movimiento.id.contains('-');
    
    final body = movimiento.toJson();
    if (!isUpdate) {
      body.remove('id'); // backend genera el UUID en POST
    }
    body.remove('createdAt');
    body['empleadoId'] = body['empleado_id'];
    body.remove('empleado_id');
    if (body.containsKey('vehiculo_id')) {
      body['vehiculoId'] = body['vehiculo_id'];
      body.remove('vehiculo_id');
    }

    http.Response res;
    if (isUpdate) {
      res = await _client.patch(
        Uri.parse('$url/${movimiento.id}'),
        headers: ApiConfig.authHeaders,
        body: json.encode(body),
      );
    } else {
      res = await _client.post(
        Uri.parse(url),
        headers: ApiConfig.authHeaders,
        body: json.encode(body),
      );
    }

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Error al guardar movimiento: ${res.statusCode} ${res.body}');
    }
  }

  @override
  Future<void> eliminar(String id) async {
    // Para simplificar, intentamos borrar de ambos si no sabemos qué es
    final resGasto = await _client.delete(Uri.parse('$_urlGastos/$id'), headers: ApiConfig.authHeaders);
    if (resGasto.statusCode == 200) return;

    final resIngreso = await _client.delete(Uri.parse('$_urlIngresos/$id'), headers: ApiConfig.authHeaders);
    if (resIngreso.statusCode != 200 && resGasto.statusCode != 200) {
       // ignorar si no existe
    }
  }
}
