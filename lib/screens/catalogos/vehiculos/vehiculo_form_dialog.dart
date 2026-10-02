import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/usuario.dart';
import '../../../models/vehiculo.dart';
import '../../../providers/usuario_provider.dart';
import '../../../providers/vehiculo_provider.dart';

/// Formulario de alta/edición de vehículo.
/// Campos alineados al esquema de BD: modelo, marca, color, tipo, placas,
/// capacidad, estatus, responsable_id.
class VehiculoFormDialog extends StatefulWidget {
  final Vehiculo? vehiculo;

  const VehiculoFormDialog({super.key, this.vehiculo});

  bool get esEdicion => vehiculo != null;

  @override
  State<VehiculoFormDialog> createState() => _VehiculoFormDialogState();
}

class _VehiculoFormDialogState extends State<VehiculoFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _marcaCtrl;
  late final TextEditingController _modeloCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _placasCtrl;
  late final TextEditingController _capacidadCtrl;

  late TipoUnidad _tipo;
  late EstadoVehiculo _estado;
  String? _responsableId;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vehiculo;
    _marcaCtrl = TextEditingController(text: v?.marca ?? '');
    _modeloCtrl = TextEditingController(text: v?.modelo ?? '');
    _colorCtrl = TextEditingController(text: v?.color ?? '');
    _placasCtrl = TextEditingController(text: v?.placas ?? '');
    _capacidadCtrl = TextEditingController(
      text: v?.capacidadLitros.toStringAsFixed(0) ?? '',
    );
    _tipo = v?.tipo ?? TipoUnidad.pipa;
    _estado = v?.estado ?? EstadoVehiculo.activo;
    _responsableId = v?.responsableId;
  }

  @override
  void dispose() {
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _colorCtrl.dispose();
    _placasCtrl.dispose();
    _capacidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final provider = context.read<VehiculoProvider>();
    final nuevo = Vehiculo(
      id: widget.vehiculo?.id ?? '',
      modelo: _modeloCtrl.text.trim(),
      marca: _marcaCtrl.text.trim(),
      color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
      placas: _placasCtrl.text.trim().toUpperCase(),
      capacidadLitros: double.parse(_capacidadCtrl.text.trim()),
      tipo: _tipo,
      estado: _estado,
      responsableId: _responsableId,
      fechaRegistro: widget.vehiculo?.fechaRegistro,
    );

    final ok = widget.esEdicion
        ? await provider.actualizar(nuevo)
        : await provider.crear(nuevo);

    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.esEdicion
                ? 'Vehículo actualizado correctamente'
                : 'Vehículo registrado correctamente',
          ),
        ),
      );
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
    final usuarios = context.watch<UsuarioProvider>().usuarios;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        widget.esEdicion ? 'Editar vehículo' : 'Nuevo vehículo',
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
                  controller: _placasCtrl,
                  decoration: const InputDecoration(labelText: 'Placas'),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _marcaCtrl,
                        maxLength: 60,
                        decoration: const InputDecoration(labelText: 'Marca'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _modeloCtrl,
                        maxLength: 60,
                        decoration: const InputDecoration(labelText: 'Modelo'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _colorCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Color (opcional)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _capacidadCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Capacidad',
                          helperText: 'Litros o toneladas',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || !n.isFinite || n <= 0) {
                            return 'Valor inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TipoUnidad>(
                  isExpanded: true,
                  initialValue: _tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de unidad',
                  ),
                  items: TipoUnidad.values
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _tipo = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EstadoVehiculo>(
                  isExpanded: true,
                  initialValue: _estado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: EstadoVehiculo.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.label)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _estado = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  isExpanded: true,

                  initialValue: _responsableId,
                  decoration: const InputDecoration(
                    labelText: 'Responsable asignado',
                    helperText: 'Personal responsable de la unidad',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sin asignar'),
                    ),
                    ...usuarios.map(
                      (Usuario u) => DropdownMenuItem<String?>(
                        value: u.id,
                        child: Text('${u.nombreCompleto} · ${u.rol.label}'),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _responsableId = v),
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
