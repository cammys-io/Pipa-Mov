import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/cliente_especial.dart';
import '../../../providers/cliente_especial_provider.dart';

class ClienteFormDialog extends StatefulWidget {
  final ClienteEspecial? cliente;

  const ClienteFormDialog({super.key, this.cliente});

  bool get esEdicion => cliente != null;

  @override
  State<ClienteFormDialog> createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends State<ClienteFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Campos principales
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _referenciaCtrl;

  // Campos de facturación
  late final TextEditingController _rfcCtrl;
  late final TextEditingController _razonSocialCtrl;
  late final TextEditingController _calleCtrl;
  late final TextEditingController _numExtCtrl;
  late final TextEditingController _numIntCtrl;
  late final TextEditingController _coloniaCtrl;
  late final TextEditingController _municipioCtrl;
  late final TextEditingController _ciudadCtrl;
  late final TextEditingController _estadoCtrl;
  late final TextEditingController _paisCtrl;
  late final TextEditingController _cpCtrl;

  late bool _requiereFactura;
  late bool _activo;

  SatRegimenFiscal? _regimenFiscal;
  SatUsoCfdi? _usoCfdi;
  SatMetodoPago? _metodoPago;
  SatFormaPago? _formaPago;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;

    _nombreCtrl = TextEditingController(text: c?.nombreEmpresa ?? '');
    _direccionCtrl = TextEditingController(text: c?.direccion ?? '');
    _telefonoCtrl = TextEditingController(text: c?.telefono ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _referenciaCtrl = TextEditingController(text: c?.referencia ?? '');

    _rfcCtrl = TextEditingController(text: c?.rfc ?? '');
    _razonSocialCtrl = TextEditingController(text: c?.razonSocial ?? '');
    _calleCtrl = TextEditingController(text: c?.calle ?? '');
    _numExtCtrl = TextEditingController(text: c?.numeroExterior ?? '');
    _numIntCtrl = TextEditingController(text: c?.numeroInterior ?? '');
    _coloniaCtrl = TextEditingController(text: c?.colonia ?? '');
    _municipioCtrl = TextEditingController(text: c?.municipio ?? '');
    _ciudadCtrl = TextEditingController(text: c?.ciudad ?? '');
    _estadoCtrl = TextEditingController(text: c?.estado ?? '');
    _paisCtrl = TextEditingController(text: c?.pais ?? 'México');
    _cpCtrl = TextEditingController(text: c?.codigoPostal ?? '');

    _requiereFactura = c?.requiereFactura ?? false;
    _activo = c?.activo ?? true;

    _regimenFiscal = SatRegimenFiscal.fromClave(c?.regimenFiscal);
    _usoCfdi = SatUsoCfdi.fromClave(c?.usoCfdi);
    _metodoPago = SatMetodoPago.fromClave(c?.metodoPago);
    _formaPago = SatFormaPago.fromClave(c?.formaPago);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _referenciaCtrl.dispose();

    _rfcCtrl.dispose();
    _razonSocialCtrl.dispose();
    _calleCtrl.dispose();
    _numExtCtrl.dispose();
    _numIntCtrl.dispose();
    _coloniaCtrl.dispose();
    _municipioCtrl.dispose();
    _ciudadCtrl.dispose();
    _estadoCtrl.dispose();
    _paisCtrl.dispose();
    _cpCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final provider = context.read<ClienteEspecialProvider>();

    final nuevo = ClienteEspecial(
      id: widget.cliente?.id ?? '',
      nombreEmpresa: _nombreCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim().isNotEmpty
          ? _direccionCtrl.text.trim()
          : null,
      requiereFactura: _requiereFactura,
      activo: _activo,
      telefono: _telefonoCtrl.text.trim().isNotEmpty
          ? _telefonoCtrl.text.trim()
          : null,
      email: _emailCtrl.text.trim().isNotEmpty
          ? _emailCtrl.text.trim()
          : null,
      referencia: _referenciaCtrl.text.trim().isNotEmpty
          ? _referenciaCtrl.text.trim()
          : null,

      // Facturación
      rfc: _requiereFactura && _rfcCtrl.text.trim().isNotEmpty
          ? _rfcCtrl.text.trim().toUpperCase()
          : null,
      razonSocial: _requiereFactura && _razonSocialCtrl.text.trim().isNotEmpty
          ? _razonSocialCtrl.text.trim()
          : null,
      regimenFiscal: _requiereFactura ? _regimenFiscal?.clave : null,
      usoCfdi: _requiereFactura ? _usoCfdi?.clave : null,
      metodoPago: _requiereFactura ? _metodoPago?.clave : null,
      formaPago: _requiereFactura ? _formaPago?.clave : null,
      calle: _requiereFactura && _calleCtrl.text.trim().isNotEmpty
          ? _calleCtrl.text.trim()
          : null,
      numeroExterior: _requiereFactura && _numExtCtrl.text.trim().isNotEmpty
          ? _numExtCtrl.text.trim()
          : null,
      numeroInterior: _requiereFactura && _numIntCtrl.text.trim().isNotEmpty
          ? _numIntCtrl.text.trim()
          : null,
      colonia: _requiereFactura && _coloniaCtrl.text.trim().isNotEmpty
          ? _coloniaCtrl.text.trim()
          : null,
      municipio: _requiereFactura && _municipioCtrl.text.trim().isNotEmpty
          ? _municipioCtrl.text.trim()
          : null,
      ciudad: _requiereFactura && _ciudadCtrl.text.trim().isNotEmpty
          ? _ciudadCtrl.text.trim()
          : null,
      estado: _requiereFactura && _estadoCtrl.text.trim().isNotEmpty
          ? _estadoCtrl.text.trim()
          : null,
      pais: _requiereFactura && _paisCtrl.text.trim().isNotEmpty
          ? _paisCtrl.text.trim()
          : 'México',
      codigoPostal: _requiereFactura && _cpCtrl.text.trim().isNotEmpty
          ? _cpCtrl.text.trim()
          : null,
      createdAt: widget.cliente?.createdAt,
    );

    final ok = widget.esEdicion
        ? await provider.actualizar(nuevo)
        : await provider.crear(nuevo);

    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Error al guardar el cliente'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.esEdicion
                        ? 'Editar cliente especial'
                        : 'Nuevo cliente especial',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const Divider(height: 24),

              // Contenido con Scroll
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Switch principal: ¿Requiere Factura?
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _requiereFactura
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _requiereFactura
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              '¿Requiere Facturación Fiscal?',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              _requiereFactura
                                  ? 'Se habilitarán los campos fiscales del SAT (RFC, Razón Social, Régimen, etc.)'
                                  : 'Solo se registrarán los datos básicos de la empresa y contacto.',
                              style: const TextStyle(fontSize: 12),
                            ),
                            value: _requiereFactura,
                            onChanged: (val) =>
                                setState(() => _requiereFactura = val),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Switch Estatus Activo
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Cliente activo'),
                          subtitle: const Text(
                            'Desactívalo si ya no realiza operaciones frecuentes',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _activo,
                          onChanged: (val) => setState(() => _activo = val),
                        ),
                        const SizedBox(height: 12),

                        // SECCIÓN 1: DATOS PRINCIPALES
                        const Text(
                          'DATOS PRINCIPALES DE LA EMPRESA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _nombreCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre comercial / Empresa *',
                            hintText: 'Ej. Constructora El Roble S.A.',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'El nombre de la empresa es obligatorio'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _direccionCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Dirección física general / Entrega',
                            hintText: 'Ej. Av. Universidad #120, Col. Cinco Señores',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _telefonoCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono',
                                  hintText: '9511234567',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  hintText: 'contacto@empresa.com',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _referenciaCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Referencias de ubicación / Notas',
                            hintText: 'Ej. Frente a la gasolinera, zaguán blanco',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                        ),

                        // SECCIÓN 2: DATOS FISCALES (CONDICIONAL DINÁMICO)
                        if (_requiereFactura) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'DATOS DE FACTURACIÓN (SAT CFDI 4.0)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _rfcCtrl,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: const InputDecoration(
                                    labelText: 'RFC *',
                                    hintText: 'ROB901010ABC',
                                  ),
                                  validator: (v) {
                                    if (!_requiereFactura) return null;
                                    if (v == null || v.trim().isEmpty) {
                                      return 'El RFC es obligatorio para facturar';
                                    }
                                    if (v.trim().length < 12 || v.trim().length > 13) {
                                      return 'RFC debe tener 12 o 13 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _razonSocialCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre o Razón Social *',
                                    hintText: 'CONSTRUCTORA EL ROBLE SA DE CV',
                                  ),
                                  validator: (v) {
                                    if (!_requiereFactura) return null;
                                    if (v == null || v.trim().isEmpty) {
                                      return 'La Razón Social es obligatoria';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Régimen Fiscal Dropdown
                          DropdownButtonFormField<SatRegimenFiscal>(
                            isExpanded: true,
                            initialValue: _regimenFiscal,
                            decoration: const InputDecoration(
                              labelText: 'Régimen Fiscal (SAT) *',
                            ),
                            items: SatRegimenFiscal.values.map((r) {
                              return DropdownMenuItem(
                                value: r,
                                child: Text(
                                  r.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _regimenFiscal = val),
                            validator: (v) => _requiereFactura && v == null
                                ? 'Selecciona el régimen fiscal'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Uso del CFDI Dropdown
                          DropdownButtonFormField<SatUsoCfdi>(
                            isExpanded: true,
                            initialValue: _usoCfdi,
                            decoration: const InputDecoration(
                              labelText: 'Uso del CFDI *',
                            ),
                            items: SatUsoCfdi.values.map((u) {
                              return DropdownMenuItem(
                                value: u,
                                child: Text(
                                  u.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _usoCfdi = val),
                            validator: (v) => _requiereFactura && v == null
                                ? 'Selecciona el uso del CFDI'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<SatMetodoPago>(
                                  isExpanded: true,
                                  initialValue: _metodoPago,
                                  decoration: const InputDecoration(
                                    labelText: 'Método de Pago',
                                  ),
                                  items: SatMetodoPago.values.map((m) {
                                    return DropdownMenuItem(
                                      value: m,
                                      child: Text(
                                        m.label,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => _metodoPago = val),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<SatFormaPago>(
                                  isExpanded: true,
                                  initialValue: _formaPago,
                                  decoration: const InputDecoration(
                                    labelText: 'Forma de Pago',
                                  ),
                                  items: SatFormaPago.values.map((f) {
                                    return DropdownMenuItem(
                                      value: f,
                                      child: Text(
                                        f.label,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => _formaPago = val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Domicilio Fiscal
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _calleCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Calle fiscal',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _numExtCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'No. Ext.',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _numIntCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'No. Int.',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _coloniaCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Colonia',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _cpCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'C.P. *',
                                    hintText: '68000',
                                  ),
                                  validator: (v) {
                                    if (!_requiereFactura) return null;
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Requerido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _municipioCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Municipio / Alcaldía',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _ciudadCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Ciudad',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _estadoCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Estado',
                                    hintText: 'Oaxaca',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _paisCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'País',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 24),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.esEdicion ? 'Actualizar' : 'Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
