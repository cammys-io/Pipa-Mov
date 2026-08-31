import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/usuario.dart';
import '../../../models/vehiculo.dart';
import '../../../providers/usuario_provider.dart';
import '../../../providers/vehiculo_provider.dart';

const _accent = Color(0xFFCBFF3D);
const _darkPanel = Color(0xFF16212B);
const _darkField = Color(0xFF1E2C38);

/// Formulario de alta/edición de vehículo.
/// Requisitos 2 y 5: alta de vehículo + asignación de responsable (usuario).
class VehiculoFormDialog extends StatefulWidget {
  final Vehiculo? vehiculo;

  const VehiculoFormDialog({super.key, this.vehiculo});

  bool get esEdicion => vehiculo != null;

  @override
  State<VehiculoFormDialog> createState() => _VehiculoFormDialogState();
}

class _VehiculoFormDialogState extends State<VehiculoFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _placasCtrl;
  late final TextEditingController _marcaCtrl;
  late final TextEditingController _modeloCtrl;
  late final TextEditingController _anioCtrl;
  late final TextEditingController _capacidadCtrl;

  late TipoUnidad _tipo;
  late EstadoVehiculo _estado;
  String? _responsableId;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vehiculo;
    _placasCtrl = TextEditingController(text: v?.placas ?? '');
    _marcaCtrl = TextEditingController(text: v?.marca ?? '');
    _modeloCtrl = TextEditingController(text: v?.modelo ?? '');
    _anioCtrl = TextEditingController(text: v?.anio.toString() ?? '');
    _capacidadCtrl = TextEditingController(
        text: v?.capacidadLitros.toStringAsFixed(0) ?? '');
    _tipo = v?.tipo ?? TipoUnidad.pipaGrande;
    _estado = v?.estado ?? EstadoVehiculo.activo;
    _responsableId = v?.responsableId;
  }

  @override
  void dispose() {
    _placasCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _anioCtrl.dispose();
    _capacidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final provider = context.read<VehiculoProvider>();
    final nuevo = Vehiculo(
      id: widget.vehiculo?.id ?? '',
      placas: _placasCtrl.text.trim().toUpperCase(),
      marca: _marcaCtrl.text.trim(),
      modelo: _modeloCtrl.text.trim(),
      anio: int.parse(_anioCtrl.text.trim()),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.esEdicion
            ? 'Vehículo actualizado correctamente'
            : 'Vehículo registrado correctamente'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'Ocurrió un error al guardar'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = context.watch<UsuarioProvider>().usuarios;

    return Theme(
      data: _darkDialogTheme(context),
      child: AlertDialog(
        backgroundColor: _darkPanel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          widget.esEdicion ? 'Editar vehículo' : 'Nuevo vehículo',
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
                          decoration:
                              const InputDecoration(labelText: 'Modelo'),
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
                          controller: _anioCtrl,
                          decoration: const InputDecoration(labelText: 'Año'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 1980 || n > 2100) {
                              return 'Año inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _capacidadCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Capacidad (litros)'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            if (n == null || n <= 0) return 'Valor inválido';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TipoUnidad>(
                    initialValue: _tipo,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de unidad'),
                    items: TipoUnidad.values
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _tipo = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EstadoVehiculo>(
                    initialValue: _estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: EstadoVehiculo.values
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _estado = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
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
                      ...usuarios.map((Usuario u) => DropdownMenuItem<String?>(
                            value: u.id,
                            child:
                                Text('${u.nombreCompleto} · ${u.puesto.label}'),
                          )),
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

ThemeData _darkDialogTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    textTheme: base.textTheme.apply(
        bodyColor: const Color.fromARGB(255, 65, 156, 144),
        displayColor: const Color.fromARGB(255, 43, 112, 117)),
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
    popupMenuTheme: const PopupMenuThemeData(color: _darkField),
  );
}
