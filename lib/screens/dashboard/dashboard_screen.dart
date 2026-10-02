import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/movimientos_table.dart';
import '../../core/widgets/section_widgets.dart';
import '../../models/filtro_movimientos.dart';
import '../../models/vehiculo.dart';
import '../../providers/movimiento_provider.dart';
import '../../providers/usuario_provider.dart';
import '../../providers/vehiculo_provider.dart';

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
    final vehiculos = context.read<VehiculoProvider>();
    final usuarios = context.read<UsuarioProvider>();
    final movimientos = context.read<MovimientoProvider>();
    await Future.wait([
      vehiculos.cargar(),
      usuarios.cargar(),
      movimientos.cargar(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final vehiculos = context.watch<VehiculoProvider>();
    final usuarios = context.watch<UsuarioProvider>();
    final provider = context.watch<MovimientoProvider>();
    final ahora = DateTime.now();
    final movimientos = FiltroMovimientos(
      desde: DateTime(ahora.year, ahora.month),
      hasta: DateTime(ahora.year, ahora.month + 1, 0),
    ).aplicar(provider.movimientos);
    final totales = TotalesMovimientos.de(movimientos);
    final recientes = const FiltroMovimientos()
        .aplicar(provider.movimientos)
        .take(5)
        .toList();
    final unidades = [...vehiculos.vehiculos]
      ..sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen general'),
        actions: [
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
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sin conexión al servidor. Los registros y adjuntos se conservan solo durante esta sesión.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Actividad del mes',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            const SizedBox(height: 12),
            SummaryGrid(
              children: [
                SummaryCard(
                  label: 'Ingresos',
                  value: dinero(totales.ingresos),
                  icon: Icons.south_west,
                  color: AppColors.success,
                ),
                SummaryCard(
                  label: 'Gastos',
                  value: dinero(totales.gastos),
                  icon: Icons.north_east,
                  color: AppColors.warning,
                ),
                SummaryCard(
                  label: 'Balance',
                  value: dinero(totales.balance),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SummaryGrid(
              children: [
                SummaryCard(
                  label: 'Vehículos activos',
                  value:
                      '${vehiculos.totalActivos} / ${vehiculos.vehiculos.length}',
                  icon: Icons.local_shipping_outlined,
                ),
                SummaryCard(
                  label: 'Unidades en taller',
                  value: '${vehiculos.totalTaller}',
                  icon: Icons.build_outlined,
                  color: AppColors.warning,
                ),
                SummaryCard(
                  label: 'Personal registrado',
                  value: '${usuarios.usuarios.length}',
                  icon: Icons.groups_outlined,
                ),
              ],
            ),
            if (vehiculos.cargando || usuarios.cargando || provider.cargando)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
            for (final error in [
              vehiculos.error,
              usuarios.error,
              provider.error,
            ])
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
            const SizedBox(height: 28),
            const Text(
              'Últimos movimientos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            MovimientosTable(movimientos: recientes),
            const SizedBox(height: 28),
            const Text(
              'Flotilla reciente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Card(
              child: unidades.isEmpty
                  ? const EmptyState(
                      title: 'Tu flotilla está vacía',
                      message:
                          'Agrega vehículos y maquinaria desde Catálogos para comenzar.',
                    )
                  : Column(
                      children: [
                        for (final v in unidades.take(5))
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: const Icon(
                              Icons.local_shipping_outlined,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              '${v.marca} ${v.modelo}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${v.placas} · ${usuarios.porId(v.responsableId)?.nombreCompleto ?? 'Sin responsable'}',
                            ),
                            trailing: EstadoChip(
                              label: v.estado.label,
                              color: switch (v.estado) {
                                EstadoVehiculo.activo => AppColors.success,
                                EstadoVehiculo.taller => AppColors.warning,
                                EstadoVehiculo.inactivo =>
                                  AppColors.textSecondary,
                              },
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
