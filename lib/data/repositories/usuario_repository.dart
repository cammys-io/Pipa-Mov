import '../../models/usuario.dart';

/// Contrato del repositorio de Personal.
///
/// Cuando el backend NestJS esté listo, crea `ApiUsuarioRepository`
/// implementando esta misma interfaz usando Dio/http, y cambia una sola
/// línea en el `Provider` (ver providers/usuario_provider.dart).
abstract class UsuarioRepository {
  Future<List<Usuario>> obtenerTodos();
  Future<Usuario> crear(Usuario usuario);
  Future<Usuario> actualizar(Usuario usuario);
  Future<void> eliminar(String id);
}

class MemoryUsuarioRepository implements UsuarioRepository {
  final List<Usuario> _data = [];

  @override
  Future<List<Usuario>> obtenerTodos() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_data);
  }

  @override
  Future<Usuario> crear(Usuario usuario) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final nuevo = usuario.copyWith();
    final conId = Usuario(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      nombre: nuevo.nombre,
      telefono: nuevo.telefono,
      rol: nuevo.rol,
      numeroLicencia: nuevo.numeroLicencia,
      vigencia: nuevo.vigencia,
      estado: nuevo.estado,
    );
    _data.add(conId);
    return conId;
  }

  @override
  Future<Usuario> actualizar(Usuario usuario) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _data.indexWhere((u) => u.id == usuario.id);
    if (idx == -1) {
      throw Exception('Usuario no encontrado');
    }
    _data[idx] = usuario;
    return usuario;
  }

  @override
  Future<void> eliminar(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _data.removeWhere((u) => u.id == id);
  }
}
