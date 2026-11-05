import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_widgets.dart';
import '../../../models/cliente_especial.dart';
import '../../../providers/cliente_especial_provider.dart';
import 'cliente_form_dialog.dart';

const _panel = AppColors.surface;
const _panelAlt = AppColors.background;
const _border = AppColors.border;

class ClientesTab extends StatefulWidget {
  const ClientesTab({super.key});

  @override
  State<ClientesTab> createState() => _ClientesTabState();
}

class _ClientesTabState extends State<ClientesTab> {
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClienteEspecialProvider>().cargar();
    });
  }

  Future<void> _abrirFormulario({ClienteEspecial? cliente}) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => ClienteFormDialog(cliente: cliente),
    );
    if (!mounted || guardado != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cliente != null
              ? 'Cliente especial actualizado correctamente'
              : 'Cliente especial registrado correctamente',
        ),
      ),
    );
  }

  void _verDetalles(ClienteEspecial c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.business, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                c.nombreEmpresa,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _infoTile('Estatus', c.activo ? 'Activo' : 'Inactivo'),
                _infoTile('¿Requiere factura?', c.requiereFactura ? 'Sí' : 'No'),
                if (c.direccion != null && c.direccion!.isNotEmpty)
                  _infoTile('Dirección general', c.direccion!),
                if (c.telefono != null && c.telefono!.isNotEmpty)
                  _infoTile('Teléfono', c.telefono!),
                if (c.email != null && c.email!.isNotEmpty)
                  _infoTile('Correo electrónico', c.email!),
                if (c.referencia != null && c.referencia!.isNotEmpty)
                  _infoTile('Referencias', c.referencia!),
                if (c.requiereFactura) ...[
                  const Divider(height: 24),
                  const Text(
                    'Información Fiscal (SAT CFDI 4.0)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (c.rfc != null) _infoTile('RFC', c.rfc!),
                  if (c.razonSocial != null) _infoTile('Razón Social', c.razonSocial!),
                  if (c.regimenFiscal != null)
                    _infoTile(
                      'Régimen Fiscal',
                      SatRegimenFiscal.fromClave(c.regimenFiscal)?.label ?? c.regimenFiscal!,
                    ),
                  if (c.usoCfdi != null)
                    _infoTile(
                      'Uso del CFDI',
                      SatUsoCfdi.fromClave(c.usoCfdi)?.label ?? c.usoCfdi!,
                    ),
                  if (c.metodoPago != null)
                    _infoTile(
                      'Método de Pago',
                      SatMetodoPago.fromClave(c.metodoPago)?.label ?? c.metodoPago!,
                    ),
                  if (c.formaPago != null)
                    _infoTile(
                      'Forma de Pago',
                      SatFormaPago.fromClave(c.formaPago)?.label ?? c.formaPago!,
                    ),
                  if (c.codigoPostal != null) _infoTile('Código Postal', c.codigoPostal!),
                  if (c.calle != null)
                    _infoTile(
                      'Domicilio Fiscal',
                      '${c.calle ?? ''} ${c.numeroExterior != null ? '#${c.numeroExterior}' : ''} ${c.numeroInterior != null ? 'Int. ${c.numeroInterior}' : ''}, ${c.colonia ?? ''}, ${c.municipio ?? ''}, ${c.ciudad ?? ''}, ${c.estado ?? ''}, ${c.pais ?? ''}',
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Editar'),
            onPressed: () {
              Navigator.pop(ctx);
              _abrirFormulario(cliente: c);
            },
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(ClienteEspecial cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cliente especial'),
        content: Text(
          '¿Seguro que deseas eliminar a "${cliente.nombreEmpresa}"? Esta acción no se puede deshacer.',
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
      final ok = await context.read<ClienteEspecialProvider>().eliminar(cliente.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'Cliente eliminado correctamente'
                  : 'No se pudo eliminar el cliente',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClienteEspecialProvider>();

    final clientes = provider.clientes.where((c) {
      if (_busqueda.isEmpty) return true;
      final q = _busqueda.toLowerCase();
      final nombre = c.nombreEmpresa.toLowerCase();
      final rfc = c.rfc?.toLowerCase() ?? '';
      final razon = c.razonSocial?.toLowerCase() ?? '';
      return nombre.contains(q) || rfc.contains(q) || razon.contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CatalogToolbar(
            hint: 'Buscar por empresa, RFC o razón social…',
            label: 'Nuevo cliente',
            onChanged: (v) => setState(() => _busqueda = v.trim()),
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
                  : clientes.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay clientes especiales registrados.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dataTableTheme: DataTableThemeData(
                            headingRowColor: WidgetStateProperty.all(_panelAlt),
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                            dataRowColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.hovered)
                                  ? AppColors.primary.withValues(alpha: 0.04)
                                  : null,
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(8),
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Empresa / Cliente')),
                                DataColumn(label: Text('RFC / Razón Social')),
                                DataColumn(label: Text('Facturación')),
                                DataColumn(label: Text('Teléfono')),
                                DataColumn(label: Text('Estado')),
                                DataColumn(label: Text('Acciones')),
                              ],
                              rows: clientes.map((c) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            c.nombreEmpresa,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (c.direccion != null && c.direccion!.isNotEmpty)
                                            Text(
                                              c.direccion!,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        c.rfc != null && c.rfc!.isNotEmpty
                                            ? '${c.rfc}\n${c.razonSocial ?? ''}'
                                            : '—',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DataCell(
                                      _badge(
                                        c.requiereFactura ? 'Factura' : 'Normal',
                                        c.requiereFactura
                                            ? AppColors.primary.withValues(alpha: 0.12)
                                            : _panelAlt,
                                        c.requiereFactura
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    DataCell(Text(c.telefono ?? '—')),
                                    DataCell(
                                      _badge(
                                        c.activo ? 'Activo' : 'Inactivo',
                                        c.activo
                                            ? AppColors.success.withValues(alpha: 0.12)
                                            : _panelAlt,
                                        c.activo
                                            ? AppColors.success
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Ver detalles',
                                            icon: const Icon(
                                              Icons.visibility_outlined,
                                              color: AppColors.primary,
                                              size: 20,
                                            ),
                                            onPressed: () => _verDetalles(c),
                                          ),
                                          IconButton(
                                            tooltip: 'Editar',
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: AppColors.textSecondary,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _abrirFormulario(cliente: c),
                                          ),
                                          IconButton(
                                            tooltip: 'Eliminar',
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: AppColors.danger,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _confirmarEliminar(c),
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

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
