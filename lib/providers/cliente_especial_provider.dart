import 'package:flutter/foundation.dart';
import '../data/api/api_cliente_especial_repository.dart';
import '../data/repositories/cliente_especial_repository.dart';
import '../models/cliente_especial.dart';

class ClienteEspecialProvider extends ChangeNotifier {
  final ClienteEspecialRepository _repository;

  ClienteEspecialProvider({ClienteEspecialRepository? repository})
      : _repository = repository ?? ApiClienteEspecialRepository();

  List<ClienteEspecial> _clientes = [];
  bool _cargando = false;
  String? _error;

  List<ClienteEspecial> get clientes => _clientes;
  bool get cargando => _cargando;
  String? get error => _error;

  List<ClienteEspecial> get clientesActivos =>
      _clientes.where((c) => c.activo).toList();

  ClienteEspecial? porId(String? id) {
    if (id == null) return null;
    try {
      return _clientes.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> cargar({bool? activo}) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _clientes = await _repository.obtenerTodos(activo: activo);
    } catch (e) {
      _error = 'No se pudieron cargar los clientes: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crear(ClienteEspecial cliente) async {
    _error = null;
    try {
      await _repository.crear(cliente);
      await cargar();
      return true;
    } catch (e) {
      _error = 'No se pudo registrar el cliente: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizar(ClienteEspecial cliente) async {
    _error = null;
    try {
      await _repository.actualizar(cliente);
      await cargar();
      return true;
    } catch (e) {
      _error = 'No se pudo actualizar el cliente: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminar(String id) async {
    _error = null;
    try {
      await _repository.eliminar(id);
      _clientes.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'No se pudo eliminar el cliente: $e';
      notifyListeners();
      return false;
    }
  }
}
