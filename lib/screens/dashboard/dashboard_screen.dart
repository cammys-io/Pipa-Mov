import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/usuario.dart';
import '../../models/vehiculo.dart';
import '../../providers/usuario_provider.dart';
import '../../providers/vehiculo_provider.dart';

/// Acento vibrante solo para este dashboard (estilo panel oscuro).
/// Si te gusta, muévelo a AppColors para reusarlo en otras pantallas.
const _accent = Color(0xFFCBFF3D);
const _darkPanel = Color(0xFF16212B);
const _darkPanelAlt = Color(0xFF1E2C38);

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
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width < 420 ? (width - 52) / 2 : 230.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          await vehiculoProvider.cargar();
          await usuarioProvider.cargar();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const _Header(),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _StatCard(
                  width: cardWidth,
                  icon: Icons.local_shipping_rounded,
                  gradient: const [Color(0xFF0B6E99), Color(0xFF084F70)],
                  label: 'Vehículos registrados',
                  value: '${vehiculoProvider.vehiculos.length}',
                ),
                _StatCard(
                  width: cardWidth,
                  icon: Icons.verified_rounded,
                  gradient: const [Color(0xFF1E8E5A), Color(0xFF146642)],
                  label: 'Vehículos activos',
                  value: '${vehiculoProvider.totalActivos}',
                ),
                _StatCard(
                  width: cardWidth,
                  icon: Icons.build_rounded,
                  gradient: const [Color(0xFFC77700), Color(0xFF8F5600)],
                  label: 'En taller',
                  value: '${vehiculoProvider.totalTaller}',
                ),
                _StatCard(
                  width: cardWidth,
                  icon: Icons.groups_rounded,
                  gradient: const [_darkPanelAlt, _darkPanel],
                  label: 'Personal registrado',
                  value: '${usuarioProvider.usuarios.length}',
                  accentIcon: true,
                ),
              ],
            ),
            const SizedBox(height: 28),
            _VehiculosPanel(
              vehiculos: vehiculoProvider.vehiculos.take(5).toList(),
              usuarioProvider: usuarioProvider,
            ),
          ],
        ),
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
  final String value;
  final bool accentIcon;

  const _StatCard({
    required this.width,
    required this.icon,
    required this.gradient,
    required this.label,
    required this.value,
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
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800)),
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
