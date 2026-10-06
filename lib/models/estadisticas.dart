// Modelos del modulo de estadisticas (`/api/statics`).

num _num(dynamic v) {
  if (v is num) return v;
  return num.tryParse('$v') ?? 0;
}

/// Respuesta de `GET /api/statics/dashboard-resume`.
class DashboardResumen {
  final int userTotal;
  final int vehiclesTotal;
  final int vehiculosActivos;
  final int vehiculosEnTaller;
  final int vehiculoAsignados;

  const DashboardResumen({
    required this.userTotal,
    required this.vehiclesTotal,
    required this.vehiculosActivos,
    required this.vehiculosEnTaller,
    required this.vehiculoAsignados,
  });

  factory DashboardResumen.fromJson(Map<String, dynamic> json) {
    return DashboardResumen(
      userTotal: _num(json['userTotal']).toInt(),
      vehiclesTotal: _num(json['vehiclesTotal']).toInt(),
      vehiculosActivos: _num(json['vehiculosActivos']).toInt(),
      vehiculosEnTaller: _num(json['vehiculosEnTaller']).toInt(),
      vehiculoAsignados: _num(json['vehiculoAsignados']).toInt(),
    );
  }
}

/// Filtro de fechas del dashboard: un dia o un rango (ambos extremos inclusive).
class FiltroFecha {
  final DateTime? inicio;
  final DateTime? fin;

  FiltroFecha(DateTime? inicio, DateTime? fin)
      : inicio = inicio != null ? _soloFecha(inicio) : null,
        fin = fin != null ? _soloFecha(fin) : null;

  FiltroFecha.dia(DateTime dia) : this(dia, dia);

  factory FiltroFecha.porDefecto() => FiltroFecha(null, null);

  static DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get esDia => inicio != null && fin != null && inicio == fin;
  bool get esVacio => inicio == null && fin == null;

  /// Formato YYYY-MM-DD en hora local (evita desfases por zona horaria).
  static String formatoApi(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Query params esperados por el backend:
  /// `?date=YYYY-MM-DD` o `?fechaInicio=YYYY-MM-DD&fechaFin=YYYY-MM-DD`.
  Map<String, String> toQuery() {
    if (esVacio) return {};
    if (esDia || fin == null) return {'date': formatoApi(inicio!)};
    return {'fechaInicio': formatoApi(inicio!), 'fechaFin': formatoApi(fin!)};
  }

  @override
  bool operator ==(Object other) =>
      other is FiltroFecha && other.inicio == inicio && other.fin == fin;

  @override
  int get hashCode => Object.hash(inicio, fin);
}

/// Extrae el monto de las respuestas de `ingreso-resume` / `gasto-resume`
/// (`montoTotal`) y de los totales historicos (`totalIncomes` / `totalExpenses`).
double montoDeJson(Map<String, dynamic> json, List<String> claves) {
  for (final k in claves) {
    if (json.containsKey(k)) return _num(json[k]).toDouble();
  }
  return 0;
}
