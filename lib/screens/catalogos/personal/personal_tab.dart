import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/usuario.dart';
import '../../../providers/usuario_provider.dart';
import 'personal_form_dialog.dart';

const _accent = Color(0xFFCBFF3D);
const _darkPanel = Color(0xFF16212B);
const _darkPanelAlt = Color(0xFF1E2C38);

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
                      hintText: 'Buscar por nombre o correo…',
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
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Nuevo empleado'),
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
                  : usuarios.isEmpty
                      ? const Center(
                          child: Text('No hay personal registrado.',
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
                                    DataColumn(label: Text('Nombre')),
                                    DataColumn(label: Text('Puesto')),
                                    DataColumn(label: Text('Teléfono')),
                                    DataColumn(label: Text('Correo')),
                                    DataColumn(label: Text('Licencia')),
                                    DataColumn(label: Text('Estado')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows: usuarios.map((u) {
                                    final activo =
                                        u.estado == EstadoPersonal.activo;
                                    return DataRow(cells: [
                                      DataCell(Text(u.nombreCompleto)),
                                      DataCell(Text(u.puesto.label)),
                                      DataCell(Text(u.telefono)),
                                      DataCell(Text(u.correo)),
                                      DataCell(Text(u.numeroLicencia ?? '—')),
                                      DataCell(_chip(
                                        u.estado.label,
                                        activo ? _accent : Colors.white24,
                                        activo ? Colors.black : Colors.white70,
                                      )),
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

/// Chip de estado con relleno sólido (activo) o translúcido (resto).
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

/// Theme local solo para que el DataTable se vea oscuro dentro del panel.
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
