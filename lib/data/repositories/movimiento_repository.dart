import '../../models/movimiento.dart';

/// Implementar este contrato con los endpoints de ingresos y gastos al conectar NestJS.
abstract class MovimientoRepository {
  Future<List<Movimiento>> obtenerTodos();
  Future<void> guardar(Movimiento movimiento);
  Future<void> eliminar(String id);
}

/// Almacenamiento temporal sin registros iniciales. No persiste al cerrar la app.
class MemoryMovimientoRepository implements MovimientoRepository {
  final List<Movimiento> _data = [];
  @override
  Future<List<Movimiento>> obtenerTodos() async => List.unmodifiable(_data);
  @override
  Future<void> guardar(Movimiento movimiento) async {
    if (!movimiento.monto.isFinite ||
        movimiento.monto <= 0 ||
        movimiento.empleadoId.isEmpty) {
      throw ArgumentError('El empleado y un monto positivo son obligatorios.');
    }
    final index = _data.indexWhere((m) => m.id == movimiento.id);
    if (index < 0) {
      _data.add(movimiento);
    } else {
      _data[index] = movimiento;
    }
  }

  @override
  Future<void> eliminar(String id) async =>
      _data.removeWhere((m) => m.id == id);
}
