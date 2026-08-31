import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/vehiculo.dart';
import '../../../providers/usuario_provider.dart';
import '../../../providers/vehiculo_provider.dart';
import 'vehiculo_form_dialog.dart';

const _accent = Color(0xFFCBFF3D);
const _darkPanel = Color(0xFF16212B);
const _darkPanelAlt = Color(0xFF1E2C38);

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? 'Vehículo eliminado correctamente'
              : 'No se pudo eliminar el vehículo'),
        ));
      }
    }
  }

  ({Color bg, Color fg}) _estadoColors(EstadoVehiculo estado) {
    switch (estado) {
      case EstadoVehiculo.activo:
        return (bg: _accent, fg: Colors.black);
      case EstadoVehiculo.mantenimiento:
        return (
          bg: AppColors.warning.withValues(alpha: 0.2),
          fg: AppColors.warning
        );
      case EstadoVehiculo.fueraDeServicio:
        return (
          bg: AppColors.danger.withValues(alpha: 0.2),
          fg: AppColors.danger
        );
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
                child: Container(
                  decoration: BoxDecoration(
                    color: _darkPanelAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      filled: false,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.white54),
                      hintText: 'Buscar por placas, marca o modelo…',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                    onChanged: (v) => setState(() => _busqueda = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo vehículo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _darkPanel,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: provider.cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: _accent))
                  : vehiculos.isEmpty
                      ? const Center(
                          child: Text('No hay vehículos registrados.',
                              style: TextStyle(color: Colors.white54)))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Theme(
                            data: _darkTableTheme(context),
                            child: SingleChildScrollView(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(8),
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
                                    final c = _estadoColors(v.estado);
                                    return DataRow(cells: [
                                      DataCell(Text(v.placas)),
                                      DataCell(Text('${v.marca} ${v.modelo}')),
                                      DataCell(Text('${v.anio}')),
                                      DataCell(Text(v.capacidadLitros
                                          .toStringAsFixed(0))),
                                      DataCell(Text(v.tipo.label)),
                                      DataCell(
                                          _chip(v.estado.label, c.bg, c.fg)),
                                      DataCell(Text(
                                          responsable?.nombreCompleto ?? '—')),
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Editar',
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                color: Colors.white70,
                                                size: 20),
                                            onPressed: () =>
                                                _abrirFormulario(vehiculo: v),
                                          ),
                                          IconButton(
                                            tooltip: 'Eliminar',
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: AppColors.danger,
                                                size: 20),
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
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11)),
  );
}

ThemeData _darkTableTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(_darkPanelAlt),
      headingTextStyle: const TextStyle(
          color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12),
      dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      dataRowMinHeight: 54,
      dataRowMaxHeight: 60,
      dividerThickness: 0.4,
    ),
    dividerColor: Colors.white12,
  );
}
