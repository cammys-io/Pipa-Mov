import '../../models/vehiculo.dart';

/// Contrato del repositorio de Vehículos.
///
/// Cuando el backend NestJS esté listo, crea `ApiVehiculoRepository`
/// implementando esta misma interfaz usando Dio/http, y cambia una sola
/// línea en el `Provider` (ver providers/vehiculo_provider.dart).
abstract class VehiculoRepository {
  Future<List<Vehiculo>> obtenerTodos();
  Future<Vehiculo> crear(Vehiculo vehiculo);
  Future<Vehiculo> actualizar(Vehiculo vehiculo);
  Future<void> eliminar(String id);
}

class MemoryVehiculoRepository implements VehiculoRepository {
  final List<Vehiculo> _data = [];

  @override
  Future<List<Vehiculo>> obtenerTodos() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_data);
  }

  @override
  Future<Vehiculo> crear(Vehiculo vehiculo) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final conId = Vehiculo(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      placas: vehiculo.placas,
      marca: vehiculo.marca,
      modelo: vehiculo.modelo,
      color: vehiculo.color,
      capacidadLitros: vehiculo.capacidadLitros,
      tipo: vehiculo.tipo,
      estado: vehiculo.estado,
      responsableId: vehiculo.responsableId,
    );
    _data.add(conId);
    return conId;
  }

  @override
  Future<Vehiculo> actualizar(Vehiculo vehiculo) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _data.indexWhere((v) => v.id == vehiculo.id);
    if (idx == -1) {
      throw Exception('Vehículo no encontrado');
    }
    _data[idx] = vehiculo;
    return vehiculo;
  }

  @override
  Future<void> eliminar(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _data.removeWhere((v) => v.id == id);
  }
}
