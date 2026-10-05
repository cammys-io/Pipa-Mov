import 'package:flutter/foundation.dart';

import '../data/api/api_estadisticas_repository.dart';
import '../models/estadisticas.dart';

/// Estado del dashboard. Cada seccion carga y falla de forma independiente.
class EstadisticasProvider extends ChangeNotifier {
  final ApiEstadisticasRepository _repository;

  EstadisticasProvider({ApiEstadisticasRepository? repository})
      : _repository = repository ?? ApiEstadisticasRepository();

  // --- KPIs generales ---
  DashboardResumen? _resumen;
  bool _cargandoResumen = false;
  String? _errorResumen;

  // --- Periodo filtrado ---
  FiltroFecha _filtro = FiltroFecha.hoy();
  double? _ingresoPeriodo;
  double? _gastoPeriodo;
  bool _cargandoPeriodo = false;
  String? _errorPeriodo;
  int _tokenPeriodo = 0; // descarta respuestas de filtros anteriores

  // --- Historicos ---
  double? _ingresoTotal;
  double? _gastoTotal;
  bool _cargandoHistoricos = false;
  String? _errorHistoricos;

  DashboardResumen? get resumen => _resumen;
  bool get cargandoResumen => _cargandoResumen;
  String? get errorResumen => _errorResumen;

  FiltroFecha get filtro => _filtro;
  double? get ingresoPeriodo => _ingresoPeriodo;
  double? get gastoPeriodo => _gastoPeriodo;
  bool get cargandoPeriodo => _cargandoPeriodo;
  String? get errorPeriodo => _errorPeriodo;

  double? get ingresoTotal => _ingresoTotal;
  double? get gastoTotal => _gastoTotal;
  bool get cargandoHistoricos => _cargandoHistoricos;
  String? get errorHistoricos => _errorHistoricos;

  Future<void> cargarTodo() => Future.wait([
        cargarResumen(),
        cargarPeriodo(),
        cargarHistoricos(),
      ]);

  Future<void> cargarResumen() async {
    _cargandoResumen = true;
    _errorResumen = null;
    notifyListeners();
    try {
      _resumen = await _repository.obtenerResumenDashboard();
    } catch (e) {
      _errorResumen = 'No se pudo cargar el resumen: $e';
    } finally {
      _cargandoResumen = false;
      notifyListeners();
    }
  }

  Future<void> cargarHistoricos() async {
    _cargandoHistoricos = true;
    _errorHistoricos = null;
    notifyListeners();
    try {
      final r = await Future.wait([
        _repository.obtenerIngresoTotal(),
        _repository.obtenerGastoTotal(),
      ]);
      _ingresoTotal = r[0];
      _gastoTotal = r[1];
    } catch (e) {
      _errorHistoricos = 'No se pudieron cargar los totales históricos: $e';
    } finally {
      _cargandoHistoricos = false;
      notifyListeners();
    }
  }

  Future<void> cambiarFiltro(FiltroFecha nuevo) {
    _filtro = nuevo;
    return cargarPeriodo();
  }

  Future<void> cargarPeriodo() async {
    final token = ++_tokenPeriodo;
    final filtro = _filtro;
    _cargandoPeriodo = true;
    _errorPeriodo = null;
    notifyListeners();
    try {
      final r = await Future.wait([
        _repository.obtenerIngresoPeriodo(filtro),
        _repository.obtenerGastoPeriodo(filtro),
      ]);
      if (token != _tokenPeriodo) return;
      _ingresoPeriodo = r[0];
      _gastoPeriodo = r[1];
    } catch (e) {
      if (token != _tokenPeriodo) return;
      _errorPeriodo = 'No se pudieron cargar los datos del periodo: $e';
    } finally {
      if (token == _tokenPeriodo) {
        _cargandoPeriodo = false;
        notifyListeners();
      }
    }
  }
}
