import 'package:flutter/foundation.dart';
import '../data/repositories/gasto_repository.dart';
import '../models/gasto.dart';

class GastoProvider extends ChangeNotifier {
  final GastoRepository _repository;

  GastoProvider({GastoRepository? repository}) : _repository = repository ?? MockGastoRepository();

  List<Gasto> _gastos = [];
  bool _cargando = false;
  String? _error;

  List<Gasto> get gastos => _gastos;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _gastos = await _repository.obtenerTodos();
    } catch (e) {
      _error = 'No se pudieron cargar los gastos: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crear(Gasto gasto) async {
    try {
      await _repository.crear(gasto);
      await cargar();
      return true;
    } catch (e) {
      _error = 'No se pudo registrar el gasto: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizar(Gasto gasto) async {
    try {
      await _repository.actualizar(gasto);
      await cargar();
      return true;
    } catch (e) {
      _error = 'No se pudo actualizar el gasto: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminar(String id) async {
    try {
      await _repository.eliminar(id);
      await cargar();
      return true;
    } catch (e) {
      _error = 'No se pudo eliminar el gasto: $e';
      notifyListeners();
      return false;
    }
  }
}
