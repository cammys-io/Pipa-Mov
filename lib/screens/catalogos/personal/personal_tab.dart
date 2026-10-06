import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_widgets.dart';
import '../../../models/usuario.dart';
import '../../../providers/usuario_provider.dart';
import '../../../providers/movimiento_provider.dart';
import '../../../providers/vehiculo_provider.dart';
import 'personal_form_dialog.dart';

const _panel = AppColors.surface;
const _panelAlt = AppColors.background;
const _border = AppColors.border;

class PersonalTab extends StatefulWidget {
  const PersonalTab({super.key});

  @override
  State<PersonalTab> createState() => _PersonalTabState();
}

class _PersonalTabState extends State<PersonalTab> {


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UsuarioProvider>().cargar();
    });
  }

  Future<void> _abrirFormulario({Usuario? usuario}) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => PersonalFormDialog(usuario: usuario),
    );
    if (!mounted || guardado != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          usuario != null
              ? 'Empleado actualizado correctamente'
              : 'Empleado registrado correctamente',
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(Usuario usuario) async {
    if (context.read<MovimientoProvider>().usaEmpleado(usuario.id) ||
        context.read<VehiculoProvider>().vehiculos.any(
          (v) => v.responsableId == usuario.id,
        )) {
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
        title: const Text('Eliminar personal'),
        content: Text(
          '¿Seguro que deseas eliminar a ${usuario.nombreCompleto}? Esta acción no se puede deshacer.',
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
      final ok = await context.read<UsuarioProvider>().eliminar(usuario.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'Empleado eliminado correctamente'
                  : 'No se pudo eliminar al empleado',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsuarioProvider>();

    final usuarios = provider.usuarios;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CatalogToolbar(
            hint: 'Buscar por nombre…',
            label: 'Nuevo empleado',
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
                  : usuarios.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay personal registrado.',
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
                                DataColumn(label: Text('Nombre')),
                                DataColumn(label: Text('Rol')),
                                DataColumn(label: Text('Teléfono')),
                                DataColumn(label: Text('Licencia')),
                                DataColumn(label: Text('Vigencia')),
                                DataColumn(label: Text('Estado')),
                                DataColumn(label: Text('Acciones')),
                              ],
                              rows: usuarios.map((u) {
                                final c = _estadoColors(u.estado);
                                return DataRow(
                                  cells: [
                                    DataCell(Text(u.nombreCompleto)),
                                    DataCell(Text(u.rol.label)),
                                    DataCell(Text(u.telefono)),
                                    DataCell(Text(u.numeroLicencia ?? '—')),
                                    DataCell(
                                      Text(
                                        u.vigencia == null
                                            ? '—'
                                            : '${u.vigencia!.day}/${u.vigencia!.month}/${u.vigencia!.year}',
                                      ),
                                    ),
                                    DataCell(_chip(u.estado.label, c.bg, c.fg)),
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
                                                _abrirFormulario(usuario: u),
                                          ),
                                          IconButton(
                                            tooltip: 'Eliminar',
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: AppColors.danger,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _confirmarEliminar(u),
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

({Color bg, Color fg}) _estadoColors(EstadoPersonal estado) {
  switch (estado) {
    case EstadoPersonal.activo:
      return (
        bg: AppColors.success.withValues(alpha: 0.10),
        fg: AppColors.success,
      );
    case EstadoPersonal.inactivo:
      return (bg: _panelAlt, fg: AppColors.textSecondary);
    case EstadoPersonal.suspendido:
      return (
        bg: AppColors.danger.withValues(alpha: 0.14),
        fg: AppColors.danger,
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
