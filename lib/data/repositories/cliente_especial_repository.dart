import '../../models/cliente_especial.dart';

abstract class ClienteEspecialRepository {
  Future<List<ClienteEspecial>> obtenerTodos({bool? activo});
  Future<ClienteEspecial> obtenerPorId(String id);
  Future<ClienteEspecial> crear(ClienteEspecial cliente);
  Future<ClienteEspecial> actualizar(ClienteEspecial cliente);
  Future<void> eliminar(String id);
}
