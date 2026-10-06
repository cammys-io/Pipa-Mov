import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/usuario.dart';
import '../../../providers/usuario_provider.dart';

/// Formulario de alta/edición de personal.
/// Campos alineados al esquema de BD: nombre, rol, telefono,
/// numeroLicencia, vigencia, estado.
class PersonalFormDialog extends StatefulWidget {
  final Usuario? usuario;

  const PersonalFormDialog({super.key, this.usuario});

  bool get esEdicion => usuario != null;

  @override
  State<PersonalFormDialog> createState() => _PersonalFormDialogState();
}

class _PersonalFormDialogState extends State<PersonalFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _licenciaCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;

  late Rol _rol;
  late EstadoPersonal _estado;
  DateTime? _vigencia;
  bool _guardando = false;

  bool get _requiereLicencia => _rol == Rol.chofer || _rol == Rol.operador;
  bool get _requiereCuenta => _rol == Rol.admin;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombreCtrl = TextEditingController(text: u?.nombre ?? '');
    _telefonoCtrl = TextEditingController(text: u?.telefono ?? '');
    _licenciaCtrl = TextEditingController(text: u?.numeroLicencia ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _passwordCtrl = TextEditingController(text: '');
    _rol = u?.rol ?? Rol.chofer;
    _estado = u?.estado ?? EstadoPersonal.activo;
    _vigencia = u?.vigencia;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _licenciaCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirVigencia() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _vigencia ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (fecha != null && mounted) setState(() => _vigencia = fecha);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final provider = context.read<UsuarioProvider>();
    final nuevo = Usuario(
      id: widget.usuario?.id ?? '',
      nombre: _nombreCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      rol: _rol,
      numeroLicencia: _requiereLicencia && _licenciaCtrl.text.trim().isNotEmpty
          ? _licenciaCtrl.text.trim()
          : null,
      vigencia: _requiereLicencia ? _vigencia : null,
      estado: _estado,
      fechaRegistro: widget.usuario?.fechaRegistro,
      email: _requiereCuenta && _emailCtrl.text.trim().isNotEmpty
          ? _emailCtrl.text.trim()
          : null,
      password: _requiereCuenta && _passwordCtrl.text.trim().isNotEmpty
          ? _passwordCtrl.text.trim()
          : null,
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
          content: Text(provider.error ?? 'Ocurrió un error al guardar'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        widget.esEdicion ? 'Editar personal' : 'Nuevo personal',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Rol>(
                  isExpanded: true,
                  initialValue: _rol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: Rol.values
                      .map(
                        (r) => DropdownMenuItem(value: r, child: Text(r.label)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _rol = v!),
                ),
                if (_requiereLicencia) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _licenciaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Número de licencia',
                    ),
                    validator: (v) =>
                        (_requiereLicencia && (v == null || v.trim().isEmpty))
                        ? 'Requerido para choferes/operadores'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _elegirVigencia,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Vigencia'),
                      child: Text(
                        _vigencia == null
                            ? 'Seleccionar fecha'
                            : '${_vigencia!.day}/${_vigencia!.month}/${_vigencia!.year}',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
                if (_requiereCuenta) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Correo electrónico'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (_requiereCuenta && (v == null || v.trim().isEmpty))
                        ? 'Requerido para administradores'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: InputDecoration(
                      labelText: widget.esEdicion ? 'Contraseña (opcional)' : 'Contraseña',
                      helperText: widget.esEdicion ? 'Dejar en blanco para no cambiarla' : null,
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (!_requiereCuenta) return null;
                      if (!widget.esEdicion && (v == null || v.trim().isEmpty)) {
                        return 'Requerido para administradores';
                      }
                      if (v != null && v.isNotEmpty && v.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<EstadoPersonal>(
                  isExpanded: true,
                  initialValue: _estado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: EstadoPersonal.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.label)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _estado = v!),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
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
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
