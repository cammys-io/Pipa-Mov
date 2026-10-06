import '../../models/nota.dart';

abstract class NotaRepository {
  Future<List<Nota>> obtenerTodas();
  Future<Nota> crear({
    required String titulo,
    required String descripcion,
    required EstadoNota estatus,
  });

  /// PATCH parcial: solo se envían los campos no nulos.
  Future<Nota> actualizar(
    String id, {
    String? titulo,
    String? descripcion,
    EstadoNota? estatus,
  });
  Future<void> eliminar(String id);
}
