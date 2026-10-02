import '../../models/ingreso.dart';

abstract class IngresoRepository {
  Future<List<Ingreso>> obtenerTodos();
  Future<Ingreso> crear(Ingreso ingreso);
  Future<Ingreso> actualizar(Ingreso ingreso);
  Future<void> eliminar(String id);
}

class MockIngresoRepository implements IngresoRepository {
  final List<Ingreso> _data = [];

  @override
  Future<List<Ingreso>> obtenerTodos() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_data);
  }

  @override
  Future<Ingreso> crear(Ingreso ingreso) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final nuevo = ingreso.copyWith(id: DateTime.now().microsecondsSinceEpoch.toString());
    _data.add(nuevo);
    return nuevo;
  }

  @override
  Future<Ingreso> actualizar(Ingreso ingreso) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _data.indexWhere((i) => i.id == ingreso.id);
    if (idx != -1) _data[idx] = ingreso;
    return ingreso;
  }

  @override
  Future<void> eliminar(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _data.removeWhere((i) => i.id == id);
  }
}
