import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/gasto.dart';
import '../../../providers/gasto_provider.dart';
import 'gasto_form_dialog.dart';

const _accent = Color(0xFFCBFF3D);
const _panel = AppColors.surface;
const _panelAlt = Color(0xFFF1F4F7);
const _border = Color(0xFFE3E8ED);

class GastosTab extends StatefulWidget {
  const GastosTab({super.key});

  @override
  State<GastosTab> createState() => _GastosTabState();
}

class _GastosTabState extends State<GastosTab> {
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GastoProvider>().cargar();
    });
  }

  Future<void> _abrirFormulario({Gasto? gasto}) async {
    await showDialog(
      context: context,
      builder: (_) => GastoFormDialog(gasto: gasto),
    );
  }

  Future<void> _confirmarEliminar(Gasto gasto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Seguro que deseas eliminar este gasto de \$${gasto.monto.toStringAsFixed(2)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      final ok = await context.read<GastoProvider>().eliminar(gasto.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Gasto eliminado' : 'Error al eliminar el gasto'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GastoProvider>();
    final gastos = provider.gastos.where((g) {
      if (_busqueda.isEmpty) return true;
      final q = _busqueda.toLowerCase();
      return g.descripcion.toLowerCase().contains(q) || g.categoria.label.toLowerCase().contains(q);
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
                  decoration: BoxDecoration(color: _panelAlt, borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      filled: false, border: OutlineInputBorder(borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                      hintText: 'Buscar por descripción o categoría…',
                    ),
                    onChanged: (v) => setState(() => _busqueda = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent, foregroundColor: Colors.black, elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Registrar Gasto'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _panel, borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: provider.cargando
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : gastos.isEmpty
                      ? const Center(child: Text('No hay gastos registrados.', style: TextStyle(color: AppColors.textSecondary)))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dataTableTheme: DataTableThemeData(
                                headingRowColor: WidgetStateProperty.all(_panelAlt),
                              ),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Fecha')),
                                    DataColumn(label: Text('Categoría')),
                                    DataColumn(label: Text('Descripción')),
                                    DataColumn(label: Text('Monto')),
                                    DataColumn(label: Text('Empleado/Vehículo')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows: gastos.map((g) {
                                    return DataRow(cells: [
                                      DataCell(Text('${g.fecha.day}/${g.fecha.month}/${g.fecha.year}')),
                                      DataCell(Text(g.categoria.label)),
                                      DataCell(Text(g.descripcion)),
                                      DataCell(Text('\$${g.monto.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (g.empleadoNombre != null) Text('👤 ${g.empleadoNombre}'),
                                          if (g.vehiculoPlacas != null) Text('🚚 ${g.vehiculoPlacas}'),
                                          if (g.empleadoNombre == null && g.vehiculoPlacas == null) const Text('—'),
                                        ],
                                      )),
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Editar',
                                            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                                            onPressed: () => _abrirFormulario(gasto: g),
                                          ),
                                          IconButton(
                                            tooltip: 'Eliminar',
                                            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                            onPressed: () => _confirmarEliminar(g),
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
