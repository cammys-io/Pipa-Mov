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
  Future<Map<String, dynamic>> obtenerConVehiculos(String id);
}

class MockUsuarioRepository implements UsuarioRepository {
  final List<Usuario> _data = [
    Usuario(
      id: '1',
      nombre: 'Juan Pérez López',
      telefono: '555-101-2020',
      rol: Rol.chofer,
      numeroLicencia: 'LIC-00123',
      vigencia: DateTime(2027, 5, 1),
      estado: EstadoPersonal.activo,
    ),
    Usuario(
      id: '2',
      nombre: 'María García Torres',
      telefono: '555-202-3030',
      rol: Rol.admin,
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

  @override
  Future<Map<String, dynamic>> obtenerConVehiculos(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final user = _data.firstWhere((u) => u.id == id);
    return {
      'id': user.id,
      'nombre': user.nombre,
      'numeroLicencia': user.numeroLicencia,
      'vigencia': user.vigencia?.toIso8601String(),
      'estado': user.estado.name,
      'vehiculosAsignados': [],
    };
  }
}
