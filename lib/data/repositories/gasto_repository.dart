import '../../models/gasto.dart';

abstract class GastoRepository {
  Future<List<Gasto>> obtenerTodos();
  Future<Gasto> crear(Gasto gasto);
  Future<Gasto> actualizar(Gasto gasto);
  Future<void> eliminar(String id);
}

class MockGastoRepository implements GastoRepository {
  final List<Gasto> _data = [];

  @override
  Future<List<Gasto>> obtenerTodos() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_data);
  }

  @override
  Future<Gasto> crear(Gasto gasto) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final nuevo = gasto.copyWith(id: DateTime.now().microsecondsSinceEpoch.toString());
    _data.add(nuevo);
    return nuevo;
  }

  @override
  Future<Gasto> actualizar(Gasto gasto) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _data.indexWhere((g) => g.id == gasto.id);
    if (idx != -1) _data[idx] = gasto;
    return gasto;
  }

  @override
  Future<void> eliminar(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _data.removeWhere((g) => g.id == id);
  }
}
