import 'package:flutter/foundation.dart';

import '../data/repositories/vehiculo_repository.dart';
import '../models/vehiculo.dart';

class VehiculoProvider extends ChangeNotifier {
  // TODO: cuando exista el backend, inyecta aquí ApiVehiculoRepository
  // en lugar de MockVehiculoRepository.
  final VehiculoRepository _repository;

  VehiculoProvider({VehiculoRepository? repository})
      : _repository = repository ?? MockVehiculoRepository();

  List<Vehiculo> _vehiculos = [];
  bool _cargando = false;
  String? _error;

  List<Vehiculo> get vehiculos => _vehiculos;
  bool get cargando => _cargando;
  String? get error => _error;

  int get totalActivos =>
      _vehiculos.where((v) => v.estado == EstadoVehiculo.activo).length;
  int get totalMantenimiento => _vehiculos
      .where((v) => v.estado == EstadoVehiculo.mantenimiento)
      .length;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _vehiculos = await _repository.obtenerTodos();
    } catch (e) {
      _error = 'No se pudo cargar la flotilla: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crear(Vehiculo vehiculo) async {
    try {
      await _repository.crear(vehiculo);
      await cargar();
      return true;
    } catch (e) {
      _error = 'No se pudo registrar el vehículo: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizar(Vehiculo vehiculo) async {
    try {
      await _repository.actualizar(vehiculo);
      await cargar();
      return true;
    } catch (e) {
      _error = 'No se pudo actualizar el vehículo: $e';
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
      _error = 'No se pudo eliminar el vehículo: $e';
      notifyListeners();
      return false;
    }
  }
}
