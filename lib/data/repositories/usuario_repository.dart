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

class MockUsuarioRepository implements UsuarioRepository {
  final List<Usuario> _data = [
    Usuario(
      id: '1',
      nombre: 'Juan',
      apellidoPaterno: 'Pérez',
      apellidoMaterno: 'López',
      telefono: '555-101-2020',
      correo: 'juan.perez@pipamov.com',
      puesto: Puesto.chofer,
      numeroLicencia: 'LIC-00123',
      vigenciaLicencia: DateTime(2027, 5, 1),
      estado: EstadoPersonal.activo,
    ),
    Usuario(
      id: '2',
      nombre: 'María',
      apellidoPaterno: 'García',
      apellidoMaterno: 'Torres',
      telefono: '555-202-3030',
      correo: 'maria.garcia@pipamov.com',
      puesto: Puesto.administrador,
      estado: EstadoPersonal.activo,
    ),
  ];

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
      apellidoPaterno: nuevo.apellidoPaterno,
      apellidoMaterno: nuevo.apellidoMaterno,
      telefono: nuevo.telefono,
      correo: nuevo.correo,
      puesto: nuevo.puesto,
      numeroLicencia: nuevo.numeroLicencia,
      vigenciaLicencia: nuevo.vigenciaLicencia,
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
