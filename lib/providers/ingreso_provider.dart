import 'package:flutter/foundation.dart';
import '../data/repositories/ingreso_repository.dart';
import '../models/ingreso.dart';

class IngresoProvider extends ChangeNotifier {
  final IngresoRepository _repository;

  IngresoProvider({IngresoRepository? repository}) : _repository = repository ?? MockIngresoRepository();

  List<Ingreso> _ingresos = [];
  bool _cargando = false;
  String? _error;

  List<Ingreso> get ingresos => _ingresos;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _ingresos = await _repository.obtenerTodos();
    } catch (e) {
      _error = 'No se pudieron cargar los ingresos: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Consulta el detalle completo (endpoint findOne) de un registro.
  /// Lanza excepcion si el backend responde con error.
  Future<Ingreso> obtenerPorId(String id) => _repository.obtenerPorId(id);

  Future<bool> crear(Ingreso ingreso) async {
    try {
      await _repository.crear(ingreso);
      await cargar();
      return true;
    } catch (e) {
      _error = 'No se pudo registrar el ingreso: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizar(Ingreso ingreso) async {
    try {
      await _repository.actualizar(ingreso);
      await cargar();
      return true;
    } catch (e) {
      _error = 'No se pudo actualizar el ingreso: $e';
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
      _error = 'No se pudo eliminar el ingreso: $e';
      notifyListeners();
      return false;
    }
  }
}
