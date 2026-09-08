import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/usuario.dart';
import '../../../providers/usuario_provider.dart';

const _accent = Color(0xFFCBFF3D);
const _darkPanel = Color(0xFF16212B);
const _darkField = Color(0xFF1E2C38);

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

  late Rol _rol;
  late EstadoPersonal _estado;
  DateTime? _vigencia;
  bool _guardando = false;

  bool get _requiereLicencia => _rol == Rol.chofer || _rol == Rol.operador;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombreCtrl = TextEditingController(text: u?.nombre ?? '');
    _telefonoCtrl = TextEditingController(text: u?.telefono ?? '');
    _licenciaCtrl = TextEditingController(text: u?.numeroLicencia ?? '');
    _rol = u?.rol ?? Rol.chofer;
    _estado = u?.estado ?? EstadoPersonal.activo;
    _vigencia = u?.vigencia;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _licenciaCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirVigencia() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _vigencia ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (fecha != null) setState(() => _vigencia = fecha);
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
    );

    final ok = widget.esEdicion
        ? await provider.actualizar(nuevo)
        : await provider.crear(nuevo);

    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.esEdicion
            ? 'Empleado actualizado correctamente'
            : 'Empleado registrado correctamente'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'Ocurrió un error al guardar'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _darkDialogTheme(context),
      child: AlertDialog(
        backgroundColor: _darkPanel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          widget.esEdicion ? 'Editar personal' : 'Nuevo personal',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
                    decoration:
                        const InputDecoration(labelText: 'Nombre completo'),
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
                    initialValue: _rol,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: Rol.values
                        .map((r) =>
                            DropdownMenuItem(value: r, child: Text(r.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _rol = v!),
                  ),
                  if (_requiereLicencia) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _licenciaCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Número de licencia'),
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
                        decoration:
                            const InputDecoration(labelText: 'Vigencia'),
                        child: Text(
                          _vigencia == null
                              ? 'Seleccionar fecha'
                              : '${_vigencia!.day}/${_vigencia!.month}/${_vigencia!.year}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EstadoPersonal>(
                    initialValue: _estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: EstadoPersonal.values
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e.label)))
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
            style: TextButton.styleFrom(foregroundColor: Colors.white60),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

/// Theme local: inputs y dropdowns oscuros solo dentro de este diálogo.
ThemeData _darkDialogTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: Colors.white, displayColor: Colors.white),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkField,
      labelStyle: const TextStyle(color: Colors.white54),
      helperStyle: const TextStyle(color: Colors.white38),
      hintStyle: const TextStyle(color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle:
          MenuStyle(backgroundColor: WidgetStateProperty.all(_darkField)),
    ),
    popupMenuTheme: const PopupMenuThemeData(color: _darkField),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: _darkPanel,
      headerBackgroundColor: _accent,
      headerForegroundColor: Colors.black,
    ),
  );
}
