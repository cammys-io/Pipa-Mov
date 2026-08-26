import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/usuario.dart';
import '../../models/vehiculo.dart';
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
      context.read<VehiculoProvider>().cargar();
      context.read<UsuarioProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiculoProvider = context.watch<VehiculoProvider>();
    final usuarioProvider = context.watch<UsuarioProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          await vehiculoProvider.cargar();
          await usuarioProvider.cargar();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatCard(
                  icon: Icons.local_shipping,
                  color: AppColors.primary,
                  label: 'Vehículos registrados',
                  value: '${vehiculoProvider.vehiculos.length}',
                ),
                _StatCard(
                  icon: Icons.verified,
                  color: AppColors.success,
                  label: 'Vehículos activos',
                  value: '${vehiculoProvider.totalActivos}',
                ),
                _StatCard(
                  icon: Icons.build,
                  color: AppColors.warning,
                  label: 'En mantenimiento',
                  value: '${vehiculoProvider.totalMantenimiento}',
                ),
                _StatCard(
                  icon: Icons.groups,
                  color: AppColors.primaryDark,
                  label: 'Personal registrado',
                  value: '${usuarioProvider.usuarios.length}',
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Últimos vehículos registrados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Card(
              child: vehiculoProvider.vehiculos.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Aún no hay vehículos registrados.'),
                    )
                  : Column(
                      children: vehiculoProvider.vehiculos
                          .take(5)
                          .map((v) => _VehiculoTile(
                                vehiculo: v,
                                responsable:
                                    usuarioProvider.porId(v.responsableId),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        return AppColors.success;
      case EstadoVehiculo.mantenimiento:
        return AppColors.warning;
      case EstadoVehiculo.fueraDeServicio:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.local_shipping_outlined),
      title: Text('${vehiculo.marca} ${vehiculo.modelo} · ${vehiculo.placas}'),
      subtitle: Text(
          'Responsable: ${responsable?.nombreCompleto ?? "Sin asignar"}'),
      trailing: EstadoChip(label: vehiculo.estado.label, color: _estadoColor),
    );
  }
}
