import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/gasto.dart';
import '../../../models/usuario.dart';
import '../../../models/vehiculo.dart';
import '../../../providers/gasto_provider.dart';
import '../../../providers/usuario_provider.dart';
import '../../../providers/vehiculo_provider.dart';

class GastoFormDialog extends StatefulWidget {
  final Gasto? gasto;
  const GastoFormDialog({super.key, this.gasto});

  @override
  State<GastoFormDialog> createState() => _GastoFormDialogState();
}

class _GastoFormDialogState extends State<GastoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime _fecha = DateTime.now();
  CategoriaGasto _categoria = CategoriaGasto.combustible;
  final _montoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _comprobanteCtrl = TextEditingController();
  
  String? _empleadoId;
  String? _vehiculoId;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuarioProvider>().cargar();
      context.read<VehiculoProvider>().cargar();
    });

    if (widget.gasto != null) {
      final g = widget.gasto!;
      _fecha = g.fecha;
      _categoria = g.categoria;
      _montoCtrl.text = g.monto.toString();
      _descCtrl.text = g.descripcion;
      _comprobanteCtrl.text = g.comprobanteUrl ?? '';
      _empleadoId = g.empleadoId;
      _vehiculoId = g.vehiculoId;
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descCtrl.dispose();
    _comprobanteCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (seleccion != null) {
      setState(() => _fecha = seleccion);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _guardando = true);
    
    final nuevoGasto = Gasto(
      id: widget.gasto?.id ?? '',
      fecha: _fecha,
      categoria: _categoria,
      monto: double.tryParse(_montoCtrl.text) ?? 0,
      descripcion: _descCtrl.text.trim(),
      comprobanteUrl: _comprobanteCtrl.text.trim().isEmpty ? null : _comprobanteCtrl.text.trim(),
      empleadoId: _empleadoId,
      vehiculoId: _vehiculoId,
    );

    final provider = context.read<GastoProvider>();
    final exito = widget.gasto == null
        ? await provider.crear(nuevoGasto)
        : await provider.actualizar(nuevoGasto);

    setState(() => _guardando = false);

    if (exito && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Error desconocido')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = context.watch<UsuarioProvider>().usuarios;
    final vehiculos = context.watch<VehiculoProvider>().vehiculos;

    return AlertDialog(
      title: Text(widget.gasto == null ? 'Nuevo Gasto' : 'Editar Gasto'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Fecha: ${_fecha.day}/${_fecha.month}/${_fecha.year}'),
                    ),
                    TextButton(onPressed: _seleccionarFecha, child: const Text('Cambiar')),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CategoriaGasto>(
                  decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                  value: _categoria,
                  items: CategoriaGasto.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                  onChanged: (v) => setState(() => _categoria = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _montoCtrl,
                  decoration: const InputDecoration(labelText: 'Monto (\$)', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Monto inválido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                  maxLines: 2,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(labelText: 'Empleado (Opcional)', border: OutlineInputBorder()),
                  value: _empleadoId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Ninguno')),
                    ...usuarios.map((u) => DropdownMenuItem(value: u.id, child: Text(u.nombreCompleto))),
                  ],
                  onChanged: (v) => setState(() => _empleadoId = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(labelText: 'Vehículo (Opcional)', border: OutlineInputBorder()),
                  value: _vehiculoId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Ninguno')),
                    ...vehiculos.map((v) => DropdownMenuItem(value: v.id, child: Text('${v.marca} - ${v.placas}'))),
                  ],
                  onChanged: (v) => setState(() => _vehiculoId = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
        ),
      ],
    );
  }
}
