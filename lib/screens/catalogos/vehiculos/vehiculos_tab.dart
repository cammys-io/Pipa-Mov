import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/vehiculo.dart';
import '../../../providers/usuario_provider.dart';
import '../../../providers/vehiculo_provider.dart';
import 'vehiculo_form_dialog.dart';

class VehiculosTab extends StatefulWidget {
  const VehiculosTab({super.key});

  @override
  State<VehiculosTab> createState() => _VehiculosTabState();
}

class _VehiculosTabState extends State<VehiculosTab> {
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: Text(
            '¿Seguro que deseas eliminar el vehículo con placas ${vehiculo.placas}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      final ok = await context.read<VehiculoProvider>().eliminar(vehiculo.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? 'Vehículo eliminado correctamente'
              : 'No se pudo eliminar el vehículo'),
        ));
      }
    }
  }

  Color _estadoColor(EstadoVehiculo estado) {
    switch (estado) {
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
    final provider = context.watch<VehiculoProvider>();
    final usuarioProvider = context.watch<UsuarioProvider>();

    final vehiculos = provider.vehiculos.where((v) {
      if (_busqueda.isEmpty) return true;
      final q = _busqueda.toLowerCase();
      return v.placas.toLowerCase().contains(q) ||
          v.marca.toLowerCase().contains(q) ||
          v.modelo.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por placas, marca o modelo…',
                  ),
                  onChanged: (v) => setState(() => _busqueda = v),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo vehículo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: provider.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : vehiculos.isEmpty
                      ? const Center(
                          child: Text('No hay vehículos registrados.'))
                      : SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Placas')),
                                DataColumn(label: Text('Marca / Modelo')),
                                DataColumn(label: Text('Año')),
                                DataColumn(label: Text('Capacidad (L)')),
                                DataColumn(label: Text('Tipo')),
                                DataColumn(label: Text('Estado')),
                                DataColumn(label: Text('Responsable')),
                                DataColumn(label: Text('Acciones')),
                              ],
                              rows: vehiculos.map((v) {
                                final responsable =
                                    usuarioProvider.porId(v.responsableId);
                                return DataRow(cells: [
                                  DataCell(Text(v.placas)),
                                  DataCell(Text('${v.marca} ${v.modelo}')),
                                  DataCell(Text('${v.anio}')),
                                  DataCell(Text(
                                      v.capacidadLitros.toStringAsFixed(0))),
                                  DataCell(Text(v.tipo.label)),
                                  DataCell(EstadoChip(
                                    label: v.estado.label,
                                    color: _estadoColor(v.estado),
                                  )),
                                  DataCell(
                                      Text(responsable?.nombreCompleto ?? '—')),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Editar',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () =>
                                            _abrirFormulario(vehiculo: v),
                                      ),
                                      IconButton(
                                        tooltip: 'Eliminar',
                                        icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.danger),
                                        onPressed: () =>
                                            _confirmarEliminar(v),
                                      ),
                                    ],
                                  )),
                                ]);
                              }).toList(),
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
