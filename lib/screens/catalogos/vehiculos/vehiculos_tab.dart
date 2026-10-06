import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_widgets.dart';
import '../../../models/vehiculo.dart';
import '../../../providers/usuario_provider.dart';
import '../../../providers/movimiento_provider.dart';
import '../../../providers/vehiculo_provider.dart';
import 'vehiculo_form_dialog.dart';

const _panel = AppColors.surface;
const _panelAlt = AppColors.background;
const _border = AppColors.border;

class VehiculosTab extends StatefulWidget {
  const VehiculosTab({super.key});

  @override
  State<VehiculosTab> createState() => _VehiculosTabState();
}

class _VehiculosTabState extends State<VehiculosTab> {


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VehiculoProvider>().cargar();
      context.read<UsuarioProvider>().cargar();
    });
  }

  Future<void> _abrirFormulario({Vehiculo? vehiculo}) async {
    await showDialog(
      context: context,
      builder: (_) => VehiculoFormDialog(vehiculo: vehiculo),
    );
  }

  Future<void> _confirmarEliminar(Vehiculo vehiculo) async {
    if (context.read<MovimientoProvider>().usaVehiculo(vehiculo.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este registro tiene movimientos o asignaciones. Puedes cambiar su estado a inactivo para conservar el historial.',
          ),
        ),
      );
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: Text(
          '¿Seguro que deseas eliminar el vehículo con placas ${vehiculo.placas}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      final ok = await context.read<VehiculoProvider>().eliminar(vehiculo.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'Vehículo eliminado correctamente'
                  : 'No se pudo eliminar el vehículo',
            ),
          ),
        );
      }
    }
  }

  ({Color bg, Color fg}) _estadoColors(EstadoVehiculo estado) {
    switch (estado) {
      case EstadoVehiculo.activo:
        return (
          bg: AppColors.success.withValues(alpha: 0.10),
          fg: AppColors.success,
        );
      case EstadoVehiculo.taller:
        return (
          bg: AppColors.warning.withValues(alpha: 0.14),
          fg: AppColors.warning,
        );
      case EstadoVehiculo.inactivo:
        return (
          bg: AppColors.danger.withValues(alpha: 0.14),
          fg: AppColors.danger,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VehiculoProvider>();
    final usuarioProvider = context.watch<UsuarioProvider>();

    final vehiculos = provider.vehiculos;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CatalogToolbar(
            hint: 'Buscar placas, marca o modelo…',
            label: 'Nuevo vehículo',
            onChanged: (v) {}, // Búsqueda deshabilitada por backend
            onAdd: () => _abrirFormulario(),
          ),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                provider.error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: provider.cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : vehiculos.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay vehículos registrados.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Theme(
                        data: _tableTheme(context),
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(8),
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Placas')),
                                DataColumn(label: Text('Marca / Modelo')),
                                DataColumn(label: Text('Color')),
                                DataColumn(label: Text('Capacidad')),
                                DataColumn(label: Text('Tipo')),
                                DataColumn(label: Text('Estado')),
                                DataColumn(label: Text('Responsable')),
                                DataColumn(label: Text('Acciones')),
                              ],
                              rows: vehiculos.map((v) {
                                final responsable = usuarioProvider.porId(
                                  v.responsableId,
                                );
                                final c = _estadoColors(v.estado);
                                return DataRow(
                                  cells: [
                                    DataCell(Text(v.placas)),
                                    DataCell(Text('${v.marca} ${v.modelo}')),
                                    DataCell(Text(v.color ?? '—')),
                                    DataCell(
                                      Text(
                                        v.capacidadLitros.toStringAsFixed(0),
                                      ),
                                    ),
                                    DataCell(Text(v.tipo.label)),
                                    DataCell(_chip(v.estado.label, c.bg, c.fg)),
                                    DataCell(
                                      Text(responsable?.nombreCompleto ?? '—'),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Editar',
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: AppColors.textSecondary,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _abrirFormulario(vehiculo: v),
                                          ),
                                          IconButton(
                                            tooltip: 'Eliminar',
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: AppColors.danger,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _confirmarEliminar(v),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _chip(String label, Color bg, Color fg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
    ),
  );
}

ThemeData _tableTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(_panelAlt),
      headingTextStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      dataTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
      ),
      dataRowMinHeight: 54,
      dataRowMaxHeight: 60,
      dividerThickness: 0.6,
    ),
    dividerColor: _border,
  );
}
