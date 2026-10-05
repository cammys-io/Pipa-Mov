import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/estadisticas.dart';
import '../../models/usuario.dart';
import '../../models/vehiculo.dart';
import '../../providers/estadisticas_provider.dart';
import '../../providers/usuario_provider.dart';
import '../../providers/vehiculo_provider.dart';

/// Acento vibrante solo para este dashboard (estilo panel oscuro).
/// Si te gusta, muévelo a AppColors para reusarlo en otras pantallas.
const _accent = Color(0xFFCBFF3D);
const _darkPanel = Color(0xFF16212B);
const _darkPanelAlt = Color(0xFF1E2C38);

const _gradAzul = [Color(0xFF0B6E99), Color(0xFF084F70)];
const _gradVerde = [Color(0xFF1E8E5A), Color(0xFF146642)];
const _gradNaranja = [Color(0xFFC77700), Color(0xFF8F5600)];
const _gradRojo = [Color(0xFFC0392B), Color(0xFF8A261C)];
const _gradTeal = [Color(0xFF127C86), Color(0xFF0C565D)];
const _gradOscuro = [_darkPanelAlt, _darkPanel];

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic', //
];

String _fecha(DateTime d) => '${d.day} ${_meses[d.month - 1]} ${d.year}';

String _etiquetaFiltro(FiltroFecha f) {
  final hoy = FiltroFecha.hoy();
  if (f == hoy) return 'Hoy · ${_fecha(f.inicio)}';
  if (f.esDia) return _fecha(f.inicio);
  if (f.inicio.year == f.fin.year) {
    return '${f.inicio.day} ${_meses[f.inicio.month - 1]} – ${_fecha(f.fin)}';
  }
  return '${_fecha(f.inicio)} – ${_fecha(f.fin)}';
}

/// $1,234.56 (con separador de miles, sin depender de `intl`).
String _dinero(double v) {
  final negativo = v < 0;
  final partes = v.abs().toStringAsFixed(2).split('.');
  final entero = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${negativo ? '-' : ''}\$$entero.${partes[1]}';
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stats = context.read<EstadisticasProvider>();
      // Al entrar siempre se muestran los datos del día de hoy.
      stats.cambiarFiltro(FiltroFecha.hoy());
      stats.cargarResumen();
      stats.cargarHistoricos();
      // Solo para el listado de últimos vehículos (no para totales).
      context.read<VehiculoProvider>().cargar();
      context.read<UsuarioProvider>().cargar();
    });
  }

  Future<void> _refrescar() {
    final stats = context.read<EstadisticasProvider>();
    return Future.wait([
      stats.cargarTodo(),
      context.read<VehiculoProvider>().cargar(),
      context.read<UsuarioProvider>().cargar(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final vehiculoProvider = context.watch<VehiculoProvider>();
    final usuarioProvider = context.watch<UsuarioProvider>();
    final stats = context.watch<EstadisticasProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const padding = 20.0;
            final disponible = constraints.maxWidth - padding * 2;
            return ListView(
              padding: const EdgeInsets.fromLTRB(padding, 12, padding, 24),
              children: [
                const _Header(),
                const SizedBox(height: 20),
                const _SectionTitle('Flotilla y personal'),
                _KpiSection(stats: stats, ancho: disponible),
                const SizedBox(height: 28),
                const _SectionTitle('Ingresos y gastos por periodo'),
                _PeriodoSection(stats: stats, ancho: disponible),
                const SizedBox(height: 28),
                const _SectionTitle('Totales históricos'),
                _HistoricosSection(stats: stats, ancho: disponible),
                const SizedBox(height: 28),
                _VehiculosPanel(
                  vehiculos: vehiculoProvider.vehiculos.take(5).toList(),
                  usuarioProvider: usuarioProvider,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Reparte [children] en [columnas] columnas de igual ancho.
Widget _grid({
  required double ancho,
  required int columnas,
  required List<Widget Function(double width)> children,
  double spacing = 14,
}) {
  final w = (ancho - spacing * (columnas - 1)) / columnas;
  return Wrap(
    spacing: spacing,
    runSpacing: spacing,
    children: [for (final c in children) c(w)],
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
    );
  }
}

// ---------------------------------------------------------------------------
// TOP: KPIs generales (GET /api/statics/dashboard-resume)
// ---------------------------------------------------------------------------

class _KpiSection extends StatelessWidget {
  final EstadisticasProvider stats;
  final double ancho;
  const _KpiSection({required this.stats, required this.ancho});

  @override
  Widget build(BuildContext context) {
    final r = stats.resumen;
    final cargando = stats.cargandoResumen && r == null;
    final columnas = ancho >= 900 ? 5 : (ancho >= 600 ? 3 : 2);

    String? v(int? n) => n?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stats.errorResumen != null)
          _ErrorBanner(
              mensaje: stats.errorResumen!, onRetry: stats.cargarResumen),
        _grid(
          ancho: ancho,
          columnas: columnas,
          children: [
            (w) => _StatCard(
                  width: w,
                  icon: Icons.local_shipping_rounded,
                  gradient: _gradAzul,
                  label: 'Vehículos registrados',
                  value: v(r?.vehiclesTotal),
                  loading: cargando,
                ),
            (w) => _StatCard(
                  width: w,
                  icon: Icons.verified_rounded,
                  gradient: _gradVerde,
                  label: 'Vehículos activos',
                  value: v(r?.vehiculosActivos),
                  loading: cargando,
                ),
            (w) => _StatCard(
                  width: w,
                  icon: Icons.build_rounded,
                  gradient: _gradNaranja,
                  label: 'En taller',
                  value: v(r?.vehiculosEnTaller),
                  loading: cargando,
                ),
            (w) => _StatCard(
                  width: w,
                  icon: Icons.assignment_ind_rounded,
                  gradient: _gradTeal,
                  label: 'Vehículos asignados',
                  value: v(r?.vehiculoAsignados),
                  loading: cargando,
                ),
            (w) => _StatCard(
                  width: w,
                  icon: Icons.groups_rounded,
                  gradient: _gradOscuro,
                  label: 'Personal registrado',
                  value: v(r?.userTotal),
                  loading: cargando,
                  accentIcon: true,
                ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// MEDIO: Ingresos / gastos filtrados por fecha
// (GET /api/statics/ingreso-resume y /gasto-resume)
// ---------------------------------------------------------------------------

class _PeriodoSection extends StatelessWidget {
  final EstadisticasProvider stats;
  final double ancho;
  const _PeriodoSection({required this.stats, required this.ancho});

  @override
  Widget build(BuildContext context) {
    final ingreso = stats.ingresoPeriodo;
    final gasto = stats.gastoPeriodo;
    final cargando = stats.cargandoPeriodo;
    final etiqueta = _etiquetaFiltro(stats.filtro);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FiltroFechaCard(
          filtro: stats.filtro,
          onChanged: stats.cambiarFiltro,
        ),
        const SizedBox(height: 14),
        if (stats.errorPeriodo != null)
          _ErrorBanner(
              mensaje: stats.errorPeriodo!, onRetry: stats.cargarPeriodo),
        _grid(
          ancho: ancho,
          columnas: ancho >= 420 ? 2 : 1,
          children: [
            (w) => _MontoCard(
                  width: w,
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                  label: 'Ingresos',
                  periodo: etiqueta,
                  monto: ingreso,
                  loading: cargando,
                ),
            (w) => _MontoCard(
                  width: w,
                  icon: Icons.trending_down_rounded,
                  color: AppColors.danger,
                  label: 'Gastos',
                  periodo: etiqueta,
                  monto: gasto,
                  loading: cargando,
                ),
          ],
        ),
      ],
    );
  }
}

/// Selector de fecha: atajos rápidos + día específico + rango.
class _FiltroFechaCard extends StatelessWidget {
  final FiltroFecha filtro;
  final ValueChanged<FiltroFecha> onChanged;

  const _FiltroFechaCard({required this.filtro, required this.onChanged});

  static final _primera = DateTime(2020);

  DateTime get _ultima => DateTime(DateTime.now().year + 1, 12, 31);

  List<(String, FiltroFecha)> get _atajos {
    final hoy = DateTime.now();
    return [
      ('Hoy', FiltroFecha.hoy()),
      ('Ayer', FiltroFecha.dia(hoy.subtract(const Duration(days: 1)))),
      ('7 días', FiltroFecha(hoy.subtract(const Duration(days: 6)), hoy)),
      ('Este mes', FiltroFecha(DateTime(hoy.year, hoy.month, 1), hoy)),
    ];
  }

  Future<void> _elegirDia(BuildContext context) async {
    final inicial = filtro.esDia ? filtro.inicio : DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: _primera,
      lastDate: _ultima,
      helpText: 'Selecciona un día',
      confirmText: 'Aplicar',
      cancelText: 'Cancelar',
    );
    if (d != null) onChanged(FiltroFecha.dia(d));
  }

  Future<void> _elegirRango(BuildContext context) async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: _primera,
      lastDate: _ultima,
      initialDateRange: DateTimeRange(start: filtro.inicio, end: filtro.fin),
      helpText: 'Selecciona un rango',
      saveText: 'Aplicar',
    );
    if (r != null) onChanged(FiltroFecha(r.start, r.end));
  }

  @override
  Widget build(BuildContext context) {
    final atajos = _atajos;
    final esAtajo = atajos.any((a) => a.$2 == filtro);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Periodo seleccionado',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(_etiquetaFiltro(filtro),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final a in atajos)
                  ChoiceChip(
                    label: Text(a.$1),
                    selected: a.$2 == filtro,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: a.$2 == filtro
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    onSelected: (_) => onChanged(a.$2),
                  ),
                ChoiceChip(
                  avatar: Icon(Icons.today_rounded,
                      size: 16,
                      color: !esAtajo && filtro.esDia
                          ? Colors.white
                          : AppColors.primary),
                  label: const Text('Día…'),
                  selected: !esAtajo && filtro.esDia,
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: !esAtajo && filtro.esDia
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  onSelected: (_) => _elegirDia(context),
                ),
                ChoiceChip(
                  avatar: Icon(Icons.date_range_rounded,
                      size: 16,
                      color: !esAtajo && !filtro.esDia
                          ? Colors.white
                          : AppColors.primary),
                  label: const Text('Rango…'),
                  selected: !esAtajo && !filtro.esDia,
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: !esAtajo && !filtro.esDia
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  onSelected: (_) => _elegirRango(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MontoCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color color;
  final String label;
  final String periodo;
  final double? monto;
  final bool loading;

  const _MontoCard({
    required this.width,
    required this.icon,
    required this.color,
    required this.label,
    required this.periodo,
    required this.monto,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ValorMonto(
                  monto: monto,
                  loading: loading,
                  color: monto != null && monto! < 0
                      ? AppColors.danger
                      : AppColors.textPrimary),
              const SizedBox(height: 2),
              Text(periodo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValorMonto extends StatelessWidget {
  final double? monto;
  final bool loading;
  final Color color;
  final double size;

  const _ValorMonto({
    required this.monto,
    required this.loading,
    required this.color,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size * 1.3,
      child: Align(
        alignment: Alignment.centerLeft,
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  monto == null ? '—' : _dinero(monto!),
                  style: TextStyle(
                      color: color,
                      fontSize: size,
                      fontWeight: FontWeight.w800),
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// INFERIOR: Totales históricos
// (GET /api/statics/ingreso-total y /gasto-total)
// ---------------------------------------------------------------------------

class _HistoricosSection extends StatelessWidget {
  final EstadisticasProvider stats;
  final double ancho;
  const _HistoricosSection({required this.stats, required this.ancho});

  @override
  Widget build(BuildContext context) {
    final cargando = stats.cargandoHistoricos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stats.errorHistoricos != null)
          _ErrorBanner(
              mensaje: stats.errorHistoricos!, onRetry: stats.cargarHistoricos),
        _grid(
          ancho: ancho,
          columnas: ancho >= 520 ? 2 : 1,
          children: [
            (w) => _HistoricoCard(
                  width: w,
                  icon: Icons.savings_rounded,
                  gradient: _gradVerde,
                  label: 'Ingreso total histórico',
                  monto: stats.ingresoTotal,
                  loading: cargando,
                ),
            (w) => _HistoricoCard(
                  width: w,
                  icon: Icons.receipt_long_rounded,
                  gradient: _gradRojo,
                  label: 'Gasto total histórico',
                  monto: stats.gastoTotal,
                  loading: cargando,
                ),
          ],
        ),
      ],
    );
  }
}

class _HistoricoCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final List<Color> gradient;
  final String label;
  final double? monto;
  final bool loading;

  const _HistoricoCard({
    required this.width,
    required this.icon,
    required this.gradient,
    required this.label,
    required this.monto,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13)),
                const SizedBox(height: 8),
                _ValorMonto(
                    monto: monto,
                    loading: loading,
                    color: Colors.white,
                    size: 30),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Componentes compartidos
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensaje,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.danger, fontSize: 12)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final hora = DateTime.now().hour;
    final saludo = hora < 12
        ? 'Buenos días'
        : hora < 19
            ? 'Buenas tardes'
            : 'Buenas noches';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(saludo,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 2),
              const Text('Resumen de la flotilla',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.water_drop_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final List<Color> gradient;
  final String label;
  final String? value;
  final bool loading;
  final bool accentIcon;

  const _StatCard({
    required this.width,
    required this.icon,
    required this.gradient,
    required this.label,
    required this.value,
    this.loading = false,
    this.accentIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accentIcon
                  ? _accent.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: accentIcon ? _accent : Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 34,
            child: Align(
              alignment: Alignment.centerLeft,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(value ?? '—',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
        ],
      ),
    );
  }
}

class _VehiculosPanel extends StatelessWidget {
  final List<Vehiculo> vehiculos;
  final UsuarioProvider usuarioProvider;

  const _VehiculosPanel(
      {required this.vehiculos, required this.usuarioProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _darkPanel,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Últimos vehículos registrados',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${vehiculos.length}',
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (vehiculos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text('Aún no hay vehículos registrados',
                    style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            ...vehiculos.map((v) => _VehiculoTile(
                  vehiculo: v,
                  responsable: usuarioProvider.porId(v.responsableId),
                )),
        ],
      ),
    );
  }
}

class _VehiculoTile extends StatelessWidget {
  final Vehiculo vehiculo;
  final Usuario? responsable;

  const _VehiculoTile({required this.vehiculo, required this.responsable});

  Color get _estadoColor {
    switch (vehiculo.estado) {
      case EstadoVehiculo.activo:
        return _accent;
      case EstadoVehiculo.taller:
        return AppColors.warning;
      case EstadoVehiculo.inactivo:
        return AppColors.danger;
    }
  }

  bool get _esActivo => vehiculo.estado == EstadoVehiculo.activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _darkPanelAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _estadoColor.withValues(alpha: 0.16),
            child: Icon(Icons.local_shipping_outlined,
                color: _estadoColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehiculo.marca} ${vehiculo.modelo} · ${vehiculo.placas}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Responsable: ${responsable?.nombreCompleto ?? "Sin asignar"}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _esActivo
                  ? _estadoColor
                  : _estadoColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              vehiculo.estado.label,
              style: TextStyle(
                color: _esActivo ? Colors.black : _estadoColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
