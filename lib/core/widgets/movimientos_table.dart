import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/movimiento.dart';
import '../../providers/usuario_provider.dart';
import '../../providers/vehiculo_provider.dart';
import '../theme/app_theme.dart';
import 'section_widgets.dart';

class MovimientosTable extends StatelessWidget {
  final List<Movimiento> movimientos;
  final ValueChanged<Movimiento>? onEdit;
  final ValueChanged<Movimiento>? onDelete;
  const MovimientosTable({
    super.key,
    required this.movimientos,
    this.onEdit,
    this.onDelete,
  });

  Future<void> _archivo(BuildContext context, Movimiento m) async {
    final archivo = m.evidencia;
    if (archivo == null) return;
    if (!archivo.esPdf) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(archivo.nombre),
          content: SizedBox(
            width: 560,
            child: Image.memory(
              archivo.bytes,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Text('No se puede mostrar esta imagen.'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } else {
      try {
        final path = await FileSaver.instance.saveFile(
          name: archivo.nombre,
          includeExtension: false,
          bytes: archivo.bytes,
          mimeType: MimeType.pdf,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('PDF guardado: $path')));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo guardar el PDF.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (movimientos.isEmpty) {
      return const Card(
        child: EmptyState(
          title: 'Sin registros',
          message:
              'Los movimientos que registres aparecerán aquí. Si aplicaste filtros, prueba ampliarlos.',
        ),
      );
    }
    final usuarios = context.watch<UsuarioProvider>();
    final vehiculos = {
      for (final v in context.watch<VehiculoProvider>().vehiculos)
        v.id: v.placas,
    };
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: box.maxWidth),
              child: DataTable(
                columnSpacing: 28,
                columns: [
                  for (final label in [
                    'Fecha',
                    'Tipo',
                    'Concepto / detalle',
                    'Vehículo',
                    'Empleado',
                    'Monto',
                    'Adjunto',
                    if (onEdit != null) 'Acciones',
                  ])
                    DataColumn(label: Text(label)),
                ],
                rows: movimientos
                    .map(
                      (m) => DataRow(
                        cells: [
                          DataCell(Text(fechaCorta(m.fecha))),
                          DataCell(
                            EstadoChip(
                              label: m.esGasto ? 'Gasto' : 'Ingreso',
                              color: m.esGasto
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 210,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.concepto,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    m.detalle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              m.vehiculoId == null
                                  ? 'Sin vehículo'
                                  : vehiculos[m.vehiculoId] ?? 'No disponible',
                            ),
                          ),
                          DataCell(
                            Text(
                              usuarios.porId(m.empleadoId)?.nombreCompleto ??
                                  'No disponible',
                            ),
                          ),
                          DataCell(
                            Text(
                              dinero(m.monto),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            m.evidencia == null
                                ? const Text('—')
                                : IconButton(
                                    tooltip: m.evidencia!.esPdf
                                        ? 'Guardar PDF adjunto'
                                        : 'Ver evidencia',
                                    onPressed: () => _archivo(context, m),
                                    icon: const Icon(
                                      Icons.attach_file,
                                      size: 20,
                                    ),
                                  ),
                          ),
                          if (onEdit != null)
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Editar registro',
                                    onPressed: () => onEdit!(m),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  if (onDelete != null)
                                    IconButton(
                                      tooltip: 'Eliminar registro',
                                      onPressed: () => onDelete!(m),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
