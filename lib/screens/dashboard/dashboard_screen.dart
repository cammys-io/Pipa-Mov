import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_widgets.dart';
import '../../models/estadisticas.dart';
import '../../providers/estadisticas_provider.dart';

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
      if (mounted) _cargar();
    });
  }

  Future<void> _cargar() async {
    final estadisticas = context.read<EstadisticasProvider>();
    await Future.wait([
      estadisticas.cargarTodo(),
    ]);
  }

  Future<void> _seleccionarFiltro() async {
    final provider = context.read<EstadisticasProvider>();
    final actual = provider.filtro;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today, color: AppColors.primary),
              title: const Text('Hoy (Por defecto)', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                provider.cambiarFiltro(FiltroFecha.porDefecto());
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: AppColors.primary),
              title: const Text('Seleccionar día específico', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () async {
                Navigator.pop(ctx);
                final d = await showDatePicker(
                  context: context,
                  initialDate: actual.inicio ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) provider.cambiarFiltro(FiltroFecha.dia(d));
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range, color: AppColors.primary),
              title: const Text('Seleccionar rango de fechas', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () async {
                Navigator.pop(ctx);
                final r = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: actual.inicio != null && actual.fin != null
                      ? DateTimeRange(start: actual.inicio!, end: actual.fin!)
                      : null,
                );
                if (r != null) {
                  provider.cambiarFiltro(FiltroFecha(r.start, r.end));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final est = context.watch<EstadisticasProvider>();

    final ingPeriodo = est.ingresoPeriodo ?? 0;
    final gasPeriodo = est.gastoPeriodo ?? 0;
    
    final ingTotal = est.ingresoTotal ?? 0;
    final gasTotal = est.gastoTotal ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen general'),
        actions: [
          IconButton(
            tooltip: 'Filtrar periodo',
            onPressed: _seleccionarFiltro,
            icon: const Icon(Icons.date_range),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargar,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Tu operación, en un solo lugar.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  est.filtro.esVacio
                    ? 'Actividad de hoy (Por defecto)'
                    : est.filtro.esDia 
                      ? 'Actividad del ${FiltroFecha.formatoApi(est.filtro.inicio!)}'
                      : 'Actividad (${FiltroFecha.formatoApi(est.filtro.inicio!)} - ${FiltroFecha.formatoApi(est.filtro.fin!)})',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                if (est.cargandoPeriodo) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 12),
            SummaryGrid(
              children: [
                SummaryCard(
                  label: 'Ingresos',
                  value: dinero(ingPeriodo),
                  icon: Icons.south_west,
                  color: AppColors.success,
                ),
                SummaryCard(
                  label: 'Gastos',
                  value: dinero(gasPeriodo),
                  icon: Icons.north_east,
                  color: AppColors.warning,
                ),
              ],
            ),
            if (est.errorPeriodo != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(est.errorPeriodo!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Totales Históricos',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                const SizedBox(width: 12),
                if (est.cargandoHistoricos) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 12),
            SummaryGrid(
              children: [
                SummaryCard(
                  label: 'Ingresos Globales',
                  value: dinero(ingTotal),
                  icon: Icons.account_balance,
                  color: AppColors.success,
                ),
                SummaryCard(
                  label: 'Gastos Globales',
                  value: dinero(gasTotal),
                  icon: Icons.money_off,
                  color: AppColors.warning,
                ),
              ],
            ),
            if (est.errorHistoricos != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(est.errorHistoricos!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ),

            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Catálogos (API Statics)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                const SizedBox(width: 12),
                if (est.cargandoResumen) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 12),
            SummaryGrid(
              children: [
                SummaryCard(
                  label: 'Vehículos activos',
                  value: '${est.resumen?.vehiculosActivos ?? 0} / ${est.resumen?.vehiclesTotal ?? 0}',
                  icon: Icons.local_shipping_outlined,
                ),
                SummaryCard(
                  label: 'Unidades en taller',
                  value: '${est.resumen?.vehiculosEnTaller ?? 0}',
                  icon: Icons.build_outlined,
                  color: AppColors.warning,
                ),
                SummaryCard(
                  label: 'Personal registrado',
                  value: '${est.resumen?.userTotal ?? 0}',
                  icon: Icons.groups_outlined,
                ),
              ],
            ),
            if (est.errorResumen != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(est.errorResumen!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
