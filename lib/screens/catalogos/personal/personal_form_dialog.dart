import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/usuario.dart';
import '../../../providers/usuario_provider.dart';

/// Formulario de alta/edición de personal.
/// Requisitos 6 y 8: alta de personal + edición.
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
  late final TextEditingController _apPaternoCtrl;
  late final TextEditingController _apMaternoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _licenciaCtrl;

  late Puesto _puesto;
  late EstadoPersonal _estado;
  DateTime? _vigenciaLicencia;
  bool _guardando = false;

  bool get _requiereLicencia =>
      _puesto == Puesto.chofer || _puesto == Puesto.operador;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombreCtrl = TextEditingController(text: u?.nombre ?? '');
    _apPaternoCtrl = TextEditingController(text: u?.apellidoPaterno ?? '');
    _apMaternoCtrl = TextEditingController(text: u?.apellidoMaterno ?? '');
    _telefonoCtrl = TextEditingController(text: u?.telefono ?? '');
    _correoCtrl = TextEditingController(text: u?.correo ?? '');
    _licenciaCtrl = TextEditingController(text: u?.numeroLicencia ?? '');
    _puesto = u?.puesto ?? Puesto.chofer;
    _estado = u?.estado ?? EstadoPersonal.activo;
    _vigenciaLicencia = u?.vigenciaLicencia;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apPaternoCtrl.dispose();
    _apMaternoCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _licenciaCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirVigencia() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _vigenciaLicencia ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (fecha != null) setState(() => _vigenciaLicencia = fecha);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final provider = context.read<UsuarioProvider>();
    final nuevo = Usuario(
      id: widget.usuario?.id ?? '',
      nombre: _nombreCtrl.text.trim(),
      apellidoPaterno: _apPaternoCtrl.text.trim(),
      apellidoMaterno: _apMaternoCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      correo: _correoCtrl.text.trim(),
      puesto: _puesto,
      numeroLicencia:
          _requiereLicencia && _licenciaCtrl.text.trim().isNotEmpty
              ? _licenciaCtrl.text.trim()
              : null,
      vigenciaLicencia: _requiereLicencia ? _vigenciaLicencia : null,
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
    return AlertDialog(
      title: Text(widget.esEdicion ? 'Editar personal' : 'Nuevo personal'),
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
                  decoration: const InputDecoration(labelText: 'Nombre(s)'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _apPaternoCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Apellido paterno'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _apMaternoCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Apellido materno'),
                      ),
                    ),
                  ],
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
                TextFormField(
                  controller: _correoCtrl,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Puesto>(
                  initialValue: _puesto,
                  decoration: const InputDecoration(labelText: 'Puesto'),
                  items: Puesto.values
                      .map((p) =>
                          DropdownMenuItem(value: p, child: Text(p.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _puesto = v!),
                ),
                if (_requiereLicencia) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _licenciaCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Número de licencia'),
                    validator: (v) => (_requiereLicencia &&
                            (v == null || v.trim().isEmpty))
                        ? 'Requerido para choferes/operadores'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _elegirVigencia,
                    child: InputDecorator(
                      decoration:
                          const InputDecoration(labelText: 'Vigencia licencia'),
                      child: Text(
                        _vigenciaLicencia == null
                            ? 'Seleccionar fecha'
                            : '${_vigenciaLicencia!.day}/${_vigenciaLicencia!.month}/${_vigenciaLicencia!.year}',
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
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
