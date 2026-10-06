import 'package:flutter/material.dart';
import '../data/api/api_nota_repository.dart';
import '../data/repositories/nota_repository.dart';
import '../models/nota.dart';

/// Estado global de notas: lista (CRUD) + estado del sticky-note flotante.
///
/// Los métodos de escritura devuelven `null` si salieron bien, o el mensaje de
/// error en caso contrario, para que la UI decida cómo mostrarlo.
class NotaProvider extends ChangeNotifier {
  final NotaRepository _repository;

  NotaProvider({NotaRepository? repository})
      : _repository = repository ?? ApiNotaRepository();

  // ---------------------------------------------------------------------------
  // Lista de notas
  // ---------------------------------------------------------------------------
  List<Nota> _notas = [];
  bool _cargando = false;
  String? _error;

  List<Nota> get notas => _notas;
  bool get cargando => _cargando;
  String? get error => _error;
  int get pendientes =>
      _notas.where((n) => n.estatus == EstadoNota.pendiente).length;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _notas = _ordenar(await _repository.obtenerTodas());
    } catch (e) {
      _error = 'No se pudieron cargar las notas: ${_limpiar(e)}';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<String?> crear({
    required String titulo,
    required String descripcion,
    required EstadoNota estatus,
  }) async {
    try {
      final nueva = await _repository.crear(
        titulo: titulo,
        descripcion: descripcion,
        estatus: estatus,
      );
      _notas = _ordenar([nueva, ..._notas]);
      notifyListeners();
      return null;
    } catch (e) {
      return 'No se pudo guardar la nota: ${_limpiar(e)}';
    }
  }

  Future<String?> actualizar(
    String id, {
    String? titulo,
    String? descripcion,
    EstadoNota? estatus,
  }) async {
    try {
      final actualizada = await _repository.actualizar(
        id,
        titulo: titulo,
        descripcion: descripcion,
        estatus: estatus,
      );
      _reemplazar(actualizada);
      return null;
    } catch (e) {
      return 'No se pudo actualizar la nota: ${_limpiar(e)}';
    }
  }

  /// Marca la nota como RESUELTO de forma "silenciosa": la UI cambia al
  /// instante (optimista) y se revierte solo si el PATCH falla.
  Future<String?> completar(String id) async {
    final idx = _notas.indexWhere((n) => n.id == id);
    if (idx == -1) return null;
    final original = _notas[idx];
    _reemplazar(original.copyWith(estatus: EstadoNota.resuelto));
    try {
      final actualizada =
          await _repository.actualizar(id, estatus: EstadoNota.resuelto);
      _reemplazar(actualizada);
      return null;
    } catch (e) {
      _reemplazar(original);
      return 'No se pudo completar la nota: ${_limpiar(e)}';
    }
  }

  Future<String?> eliminar(String id) async {
    try {
      await _repository.eliminar(id);
      _notas = _notas.where((n) => n.id != id).toList();
      notifyListeners();
      return null;
    } catch (e) {
      return 'No se pudo eliminar la nota: ${_limpiar(e)}';
    }
  }

  void _reemplazar(Nota nota) {
    _notas = _notas.map((n) => n.id == nota.id ? nota : n).toList();
    notifyListeners();
  }

  List<Nota> _ordenar(List<Nota> lista) {
    final copia = [...lista];
    copia.sort((a, b) {
      final da = a.createdAt, db = b.createdAt;
      if (da == null || db == null) return 0;
      return db.compareTo(da); // más recientes primero
    });
    return copia;
  }

  String _limpiar(Object e) => e.toString().replaceFirst('Exception: ', '');

  // ---------------------------------------------------------------------------
  // Sticky-note flotante (overlay global)
  // ---------------------------------------------------------------------------
  bool _stickyVisible = false;

  bool get stickyVisible => _stickyVisible;

  void abrirSticky() {
    if (_stickyVisible) return;
    _stickyVisible = true;
    notifyListeners();
  }

  void cerrarSticky() {
    if (!_stickyVisible) return;
    _stickyVisible = false;
    notifyListeners();
  }
}
