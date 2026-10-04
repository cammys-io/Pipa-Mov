import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/ingreso.dart';
import '../../../models/vehiculo.dart';
import '../../../providers/ingreso_provider.dart';
import 'finanza_detalle_dialog.dart';
import 'ingreso_form_dialog.dart';

const _accent = Color(0xFFCBFF3D);
const _panel = AppColors.surface;
const _panelAlt = Color(0xFFF1F4F7);
const _border = Color(0xFFE3E8ED);

class IngresosTab extends StatefulWidget {
  const IngresosTab({super.key});

  @override
  State<IngresosTab> createState() => _IngresosTabState();
}

class _IngresosTabState extends State<IngresosTab> {
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IngresoProvider>().cargar();
    });
  }

  Future<void> _abrirFormulario({Ingreso? ingreso}) async {
    await showDialog(
      context: context,
      builder: (_) => IngresoFormDialog(ingreso: ingreso),
    );
  }

  /// Abre el detalle del ingreso consultando el endpoint findOne.
  void _mostrarDetalles(Ingreso ingreso) {
    final provider = context.read<IngresoProvider>();
    showDialog(
      context: context,
      builder: (_) => FinanzaDetalleDialog(
        titulo: 'Detalle del ingreso',
        detalle: provider.obtenerPorId(ingreso.id).then(_armarDetalle),
      ),
    );
  }

  DetalleFinanza _armarDetalle(Ingreso i) {
    final f = i.fecha;
    return DetalleFinanza(
      generales: [
        DetalleFila('Fecha', '${f.day}/${f.month}/${f.year}', faltante: 'Sin fecha'),
        DetalleFila('Servicio', i.tipoServicio.label, faltante: 'Sin servicio'),
        DetalleFila('Monto', '\$${i.montoTotal.toStringAsFixed(2)}', faltante: 'Sin monto'),
        DetalleFila('Horas', i.cantidadHoras?.toString(), faltante: 'Sin horas registradas'),
        DetalleFila('Viajes', i.cantidadViajes?.toString(), faltante: 'Sin viajes registrados'),
        DetalleFila('Garrafones', i.cantidadGarrafones?.toString(), faltante: 'Sin garrafones registrados'),
        DetalleFila('Capacidad de pipa', i.capacidadPipa?.label, faltante: 'Sin capacidad registrada'),
        DetalleFila('Material', i.tipoMaterial?.label, faltante: 'Sin material registrado'),
      ],
      empleado: i.empleadoId == null && i.empleadoNombre == null
          ? null
          : [DetalleFila('Nombre', i.empleadoNombre, faltante: 'Sin nombre')],
      vehiculo: i.vehiculoId == null && i.vehiculoPlacas == null
          ? null
          : [
              DetalleFila('Marca', i.vehiculoMarca, faltante: 'Sin marca'),
              DetalleFila('Tipo', i.vehiculoTipo == null ? null : TipoUnidadLabel.fromDbValue(i.vehiculoTipo!).label, faltante: 'Sin tipo'),
              DetalleFila('Placas', i.vehiculoPlacas, faltante: 'Sin placas'),
            ],
      comprobanteTitulo: 'Comprobante',
      comprobanteUrl: i.notaUrl,
    );
  }

  Future<void> _confirmarEliminar(Ingreso ingreso) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar ingreso'),
        content: Text('¿Seguro que deseas eliminar este ingreso de \$${ingreso.montoTotal.toStringAsFixed(2)}?'),
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
      final ok = await context.read<IngresoProvider>().eliminar(ingreso.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Ingreso eliminado' : 'Error al eliminar el ingreso'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IngresoProvider>();
    final ingresos = provider.ingresos.where((i) {
      if (_busqueda.isEmpty) return true;
      final q = _busqueda.toLowerCase();
      return i.tipoServicio.label.toLowerCase().contains(q) || (i.empleadoNombre?.toLowerCase().contains(q) ?? false);
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
                      hintText: 'Buscar por tipo de servicio o empleado…',
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
                label: const Text('Registrar Ingreso'),
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
                  : ingresos.isEmpty
                      ? const Center(child: Text('No hay ingresos registrados.', style: TextStyle(color: AppColors.textSecondary)))
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
                                    DataColumn(label: Text('Servicio')),
                                    DataColumn(label: Text('Detalles')),
                                    DataColumn(label: Text('Monto')),
                                    DataColumn(label: Text('Empleado')),
                                    DataColumn(label: Text('Vehículo')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows: ingresos.map((i) {
                                    return DataRow(cells: [
                                      DataCell(Text('${i.fecha.day}/${i.fecha.month}/${i.fecha.year}')),
                                      DataCell(Text(i.tipoServicio.label)),
                                      DataCell(Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (i.cantidadHoras != null) Text('${i.cantidadHoras} hrs'),
                                          if (i.cantidadViajes != null) Text('${i.cantidadViajes} viajes'),
                                          if (i.cantidadGarrafones != null) Text('${i.cantidadGarrafones} garrafones'),
                                          if (i.capacidadPipa != null) Text('Pipa: ${i.capacidadPipa!.label}'),
                                          if (i.tipoMaterial != null) Text('Mat: ${i.tipoMaterial!.label}'),
                                        ],
                                      )),
                                      DataCell(Text('\$${i.montoTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                      DataCell(Text(i.empleadoNombre ?? '—')),
                                      DataCell(Text(i.vehiculoPlacas ?? '—')),
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Detalles',
                                            icon: const Icon(Icons.info_outline, color: AppColors.textPrimary, size: 20),
                                            onPressed: () => _mostrarDetalles(i),
                                          ),
                                          IconButton(
                                            tooltip: 'Editar',
                                            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                                            onPressed: () => _abrirFormulario(ingreso: i),
                                          ),
                                          IconButton(
                                            tooltip: 'Eliminar',
                                            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                            onPressed: () => _confirmarEliminar(i),
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
