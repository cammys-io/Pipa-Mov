import 'package:flutter/foundation.dart';
import '../data/repositories/movimiento_repository.dart';
import '../models/movimiento.dart';

class MovimientoProvider extends ChangeNotifier {
  final MovimientoRepository _repository;
  MovimientoProvider({MovimientoRepository? repository})
    : _repository = repository ?? MemoryMovimientoRepository();
  List<Movimiento> _movimientos = [];
  bool cargando = false;
  String? error;
  List<Movimiento> get movimientos => List.unmodifiable(_movimientos);
  bool usaEmpleado(String id) => _movimientos.any((m) => m.empleadoId == id);
  bool usaVehiculo(String id) => _movimientos.any((m) => m.vehiculoId == id);
  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      _movimientos = await _repository.obtenerTodos();
    } catch (_) {
      error = 'No se pudieron cargar los movimientos.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<bool> guardar(Movimiento movimiento) async {
    error = null;
    try {
      await _repository.guardar(movimiento);
      await cargar();
      return error == null;
    } catch (_) {
      error = 'No se pudo guardar el registro. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminar(String id) async {
    error = null;
    try {
      await _repository.eliminar(id);
      await cargar();
      return error == null;
    } catch (_) {
      error = 'No se pudo eliminar el registro.';
      notifyListeners();
      return false;
    }
  }
}
