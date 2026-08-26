import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/usuario.dart';
import '../../../providers/usuario_provider.dart';
import 'personal_form_dialog.dart';

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
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.danger),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsuarioProvider>();

    final usuarios = provider.usuarios.where((u) {
      if (_busqueda.isEmpty) return true;
      final q = _busqueda.toLowerCase();
      return u.nombreCompleto.toLowerCase().contains(q) ||
          u.correo.toLowerCase().contains(q);
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
                    hintText: 'Buscar por nombre o correo…',
                  ),
                  onChanged: (v) => setState(() => _busqueda = v),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Nuevo empleado'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: provider.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : usuarios.isEmpty
                      ? const Center(child: Text('No hay personal registrado.'))
                      : SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Nombre')),
                                DataColumn(label: Text('Puesto')),
                                DataColumn(label: Text('Teléfono')),
                                DataColumn(label: Text('Correo')),
                                DataColumn(label: Text('Licencia')),
                                DataColumn(label: Text('Estado')),
                                DataColumn(label: Text('Acciones')),
                              ],
                              rows: usuarios.map((u) {
                                return DataRow(cells: [
                                  DataCell(Text(u.nombreCompleto)),
                                  DataCell(Text(u.puesto.label)),
                                  DataCell(Text(u.telefono)),
                                  DataCell(Text(u.correo)),
                                  DataCell(Text(u.numeroLicencia ?? '—')),
                                  DataCell(EstadoChip(
                                    label: u.estado.label,
                                    color: u.estado == EstadoPersonal.activo
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                  )),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Editar',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () =>
                                            _abrirFormulario(usuario: u),
                                      ),
                                      IconButton(
                                        tooltip: 'Eliminar',
                                        icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.danger),
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
        ],
      ),
    );
  }
}
