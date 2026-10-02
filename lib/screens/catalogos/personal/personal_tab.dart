import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/usuario.dart';
import '../../../models/vehiculo.dart';
import '../../../providers/usuario_provider.dart';
import 'personal_form_dialog.dart';

const _accent = Color(0xFFCBFF3D);
const _panel = AppColors.surface;
const _panelAlt = Color(0xFFF1F4F7);
const _border = Color(0xFFE3E8ED);

class PersonalTab extends StatefulWidget {
  const PersonalTab({super.key});

  @override
  State<PersonalTab> createState() => _PersonalTabState();
}

class _PersonalTabState extends State<PersonalTab> {
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuarioProvider>().cargar();
    });
  }

  Future<void> _abrirFormulario({Usuario? usuario}) async {
    await showDialog(
      context: context,
      builder: (_) => PersonalFormDialog(usuario: usuario),
    );
  }

  Future<void> _confirmarEliminar(Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar personal'),
        content: Text(
            '¿Seguro que deseas eliminar a ${usuario.nombreCompleto}? Si tiene vehículos asignados quedarán sin responsable.'),
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
      final ok = await context.read<UsuarioProvider>().eliminar(usuario.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? 'Empleado eliminado correctamente'
              : 'No se pudo eliminar al empleado'),
        ));
      }
    }
  }

  Future<void> _mostrarDetalles(Usuario usuario) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      ),
    );

    final details = await context.read<UsuarioProvider>().obtenerDetallesVehiculos(usuario.id);
    if (!mounted) return;
    Navigator.pop(context); // Cerrar loading

    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al obtener detalles del usuario')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        final vehiculos = details['vehiculosAsignados'] as List<dynamic>? ?? [];
        return AlertDialog(
          title: Text('Detalles: ${usuario.nombreCompleto}'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rol: ${usuario.rol.label}', style: const TextStyle(fontSize: 14)),
                  Text('Teléfono: ${usuario.telefono}', style: const TextStyle(fontSize: 14)),
                  Text('Licencia: ${usuario.numeroLicencia ?? '—'}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  const Text('Vehículos asignados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (vehiculos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _panelAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
                          SizedBox(width: 8),
                          Text('Sin vehículo asignado', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    )
                  else
                    ...vehiculos.map((vMap) {
                          final v = Vehiculo.fromJson(vMap as Map<String, dynamic>);
                          return Card(
                            elevation: 0,
                            color: _panelAlt,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.local_shipping, color: AppColors.textSecondary, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${v.marca} ${v.modelo}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                      Text(
                                        v.estado.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: v.estado == EstadoVehiculo.activo ? Colors.green[700] : AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Placas: ${v.placas}', style: const TextStyle(fontSize: 13)),
                                  Text('Tipo: ${v.tipo.label}', style: const TextStyle(fontSize: 13)),
                                  Text('Capacidad: ${v.capacidadLitros.toStringAsFixed(0)} L', style: const TextStyle(fontSize: 13)),
                                  Text('Color: ${v.color ?? '—'}', style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          );
                        }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsuarioProvider>();

    final usuarios = provider.usuarios.where((u) {
      if (_busqueda.isEmpty) return true;
      final q = _busqueda.toLowerCase();
      return u.nombreCompleto.toLowerCase().contains(q);
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
                    color: _panelAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      filled: false,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.textSecondary),
                      hintText: 'Buscar por nombre…',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
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
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Nuevo empleado'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: provider.cargando
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : usuarios.isEmpty
                      ? const Center(
                          child: Text('No hay personal registrado.',
                              style: TextStyle(color: AppColors.textSecondary)))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(18),
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
                                    return DataRow(cells: [
                                      DataCell(Text(u.nombreCompleto)),
                                      DataCell(Text(u.rol.label)),
                                      DataCell(Text(u.telefono)),
                                      DataCell(Text(u.numeroLicencia ?? '—')),
                                      DataCell(Text(u.vigencia == null
                                          ? '—'
                                          : '${u.vigencia!.day}/${u.vigencia!.month}/${u.vigencia!.year}')),
                                      DataCell(
                                          _chip(u.estado.label, c.bg, c.fg)),
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Detalles',
                                            icon: const Icon(
                                                Icons.info_outline,
                                                color: AppColors.textPrimary,
                                                size: 20),
                                            onPressed: () => _mostrarDetalles(u),
                                          ),
                                          IconButton(
                                            tooltip: 'Editar',
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                color: AppColors.textSecondary,
                                                size: 20),
                                            onPressed: () =>
                                                _abrirFormulario(usuario: u),
                                          ),
                                          IconButton(
                                            tooltip: 'Eliminar',
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: AppColors.danger,
                                                size: 20),
                                            onPressed: () =>
                                                _confirmarEliminar(u),
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

({Color bg, Color fg}) _estadoColors(EstadoPersonal estado) {
  switch (estado) {
    case EstadoPersonal.activo:
      return (bg: _accent, fg: Colors.black);
    case EstadoPersonal.inactivo:
      return (bg: _panelAlt, fg: AppColors.textSecondary);
    case EstadoPersonal.suspendido:
      return (
        bg: AppColors.danger.withValues(alpha: 0.14),
        fg: AppColors.danger
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

ThemeData _tableTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(_panelAlt),
      headingTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12),
      dataTextStyle:
          const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      dataRowMinHeight: 54,
      dataRowMaxHeight: 60,
      dividerThickness: 0.6,
    ),
    dividerColor: _border,
  );
}
