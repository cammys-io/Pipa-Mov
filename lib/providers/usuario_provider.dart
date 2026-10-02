import 'package:flutter/foundation.dart';

import '../data/repositories/usuario_repository.dart';
import '../models/usuario.dart';

class UsuarioProvider extends ChangeNotifier {
  // TODO: cuando exista el backend, inyecta aquí ApiUsuarioRepository
  // en lugar de MemoryUsuarioRepository (por ejemplo vía un parámetro
  // en el constructor al registrar el Provider en main.dart).
  final UsuarioRepository _repository;

  UsuarioProvider({UsuarioRepository? repository})
    : _repository = repository ?? MemoryUsuarioRepository();

  List<Usuario> _usuarios = [];
  bool _cargando = false;
  String? _error;

  List<Usuario> get usuarios => _usuarios;
  bool get cargando => _cargando;
  String? get error => _error;

  List<Usuario> get choferesYOperadores => _usuarios
      .where(
        (u) =>
            u.estado == EstadoPersonal.activo &&
            (u.rol == Rol.chofer || u.rol == Rol.operador),
      )
      .toList();

  Usuario? porId(String? id) {
    if (id == null) return null;
    try {
      return _usuarios.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _usuarios = await _repository.obtenerTodos();
    } catch (e) {
      _error = 'No se pudo cargar el personal: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crear(Usuario usuario) async {
    try {
      await _repository.crear(usuario);
      await cargar();
      return true;
    } catch (e) {
      _error = 'No se pudo registrar al empleado: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizar(Usuario usuario) async {
    try {
      await _repository.actualizar(usuario);
      await cargar();
      return true;
    } catch (e) {
      _error = 'No se pudo actualizar al empleado: $e';
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
      _error = 'No se pudo eliminar al empleado: $e';
      notifyListeners();
      return false;
    }
  }
}
