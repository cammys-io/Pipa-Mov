import 'movimiento.dart';

class FiltroMovimientos {
  final DateTime? desde;
  final DateTime? hasta;
  final bool? esGasto;
  final String? categoria;
  final String? vehiculoId;
  final String busqueda;
  const FiltroMovimientos({
    this.desde,
    this.hasta,
    this.esGasto,
    this.categoria,
    this.vehiculoId,
    this.busqueda = '',
  });
  List<Movimiento> aplicar(Iterable<Movimiento> movimientos) {
    final inicio = desde == null
        ? null
        : DateTime(desde!.year, desde!.month, desde!.day);
    final fin = hasta == null
        ? null
        : DateTime(hasta!.year, hasta!.month, hasta!.day + 1);
    final q = busqueda.trim().toLowerCase();
    return movimientos
        .where(
          (m) =>
              (esGasto == null || m.esGasto == esGasto) &&
              (inicio == null || !m.fecha.isBefore(inicio)) &&
              (fin == null || m.fecha.isBefore(fin)) &&
              (categoria == null || claveCategoria(m) == categoria) &&
              (vehiculoId == null || m.vehiculoId == vehiculoId) &&
              (q.isEmpty ||
                  '${m.concepto} ${m.detalle}'.toLowerCase().contains(q)),
        )
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  static String claveCategoria(Movimiento m) => switch (m) {
    Ingreso() => 'ingreso:${m.servicio.name}',
    Gasto() => 'gasto:${m.categoria.name}',
  };
}

class TotalesMovimientos {
  final int ingresosCentavos;
  final int gastosCentavos;
  const TotalesMovimientos(this.ingresosCentavos, this.gastosCentavos);
  factory TotalesMovimientos.de(Iterable<Movimiento> movimientos) {
    var ingresos = 0;
    var gastos = 0;
    for (final m in movimientos) {
      if (m.esGasto) {
        gastos += (m.monto * 100).round();
      } else {
        ingresos += (m.monto * 100).round();
      }
    }
    return TotalesMovimientos(ingresos, gastos);
  }
  double get ingresos => ingresosCentavos / 100;
  double get gastos => gastosCentavos / 100;
  double get balance => (ingresosCentavos - gastosCentavos) / 100;
}
