import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/ingreso.dart';
import '../../../models/usuario.dart';
import '../../../models/vehiculo.dart';
import '../../../providers/ingreso_provider.dart';
import '../../../providers/usuario_provider.dart';
import '../../../providers/vehiculo_provider.dart';

class IngresoFormDialog extends StatefulWidget {
  final Ingreso? ingreso;
  const IngresoFormDialog({super.key, this.ingreso});

  @override
  State<IngresoFormDialog> createState() => _IngresoFormDialogState();
}

class _IngresoFormDialogState extends State<IngresoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime _fecha = DateTime.now();
  TipoServicio _tipoServicio = TipoServicio.pipaAgua;
  final _montoCtrl = TextEditingController();
  
  final _horasCtrl = TextEditingController();
  final _viajesCtrl = TextEditingController();
  final _garrafonesCtrl = TextEditingController();
  
  CapacidadPipa? _capacidadPipa;
  TipoMaterial? _tipoMaterial;
  
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

    if (widget.ingreso != null) {
      final i = widget.ingreso!;
      _fecha = i.fecha;
      _tipoServicio = i.tipoServicio;
      _montoCtrl.text = i.montoTotal.toString();
      _horasCtrl.text = i.cantidadHoras?.toString() ?? '';
      _viajesCtrl.text = i.cantidadViajes?.toString() ?? '';
      _garrafonesCtrl.text = i.cantidadGarrafones?.toString() ?? '';
      _capacidadPipa = i.capacidadPipa;
      _tipoMaterial = i.tipoMaterial;
      _empleadoId = i.empleadoId;
      _vehiculoId = i.vehiculoId;
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _horasCtrl.dispose();
    _viajesCtrl.dispose();
    _garrafonesCtrl.dispose();
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
    
    final nuevoIngreso = Ingreso(
      id: widget.ingreso?.id ?? '',
      fecha: _fecha,
      tipoServicio: _tipoServicio,
      montoTotal: double.tryParse(_montoCtrl.text) ?? 0,
      cantidadHoras: double.tryParse(_horasCtrl.text),
      cantidadViajes: int.tryParse(_viajesCtrl.text),
      cantidadGarrafones: int.tryParse(_garrafonesCtrl.text),
      capacidadPipa: _capacidadPipa,
      tipoMaterial: _tipoMaterial,
      empleadoId: _empleadoId,
      vehiculoId: _vehiculoId,
    );

    final provider = context.read<IngresoProvider>();
    final exito = widget.ingreso == null
        ? await provider.crear(nuevoIngreso)
        : await provider.actualizar(nuevoIngreso);

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
      title: Text(widget.ingreso == null ? 'Nuevo Ingreso' : 'Editar Ingreso'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Fecha: ${_fecha.day}/${_fecha.month}/${_fecha.year}')),
                    TextButton(onPressed: _seleccionarFecha, child: const Text('Cambiar')),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TipoServicio>(
                  decoration: const InputDecoration(labelText: 'Tipo de Servicio', border: OutlineInputBorder()),
                  value: _tipoServicio,
                  items: TipoServicio.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _tipoServicio = v!;
                      // Resetear opcionales al cambiar servicio
                      _horasCtrl.clear();
                      _viajesCtrl.clear();
                      _garrafonesCtrl.clear();
                      _capacidadPipa = null;
                      _tipoMaterial = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _montoCtrl,
                  decoration: const InputDecoration(labelText: 'Monto Total (\$)', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Monto inválido' : null,
                ),
                
                // Mostrar campos extra dependiendo del servicio
                if (_tipoServicio == TipoServicio.maquinaria) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _horasCtrl,
                    decoration: const InputDecoration(labelText: 'Cantidad de Horas', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],

                if (_tipoServicio == TipoServicio.pipaAgua) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _viajesCtrl,
                    decoration: const InputDecoration(labelText: 'Cantidad de Viajes', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CapacidadPipa?>(
                    decoration: const InputDecoration(labelText: 'Capacidad Pipa', border: OutlineInputBorder()),
                    value: _capacidadPipa,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No aplica')),
                      ...CapacidadPipa.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))),
                    ],
                    onChanged: (v) => setState(() => _capacidadPipa = v),
                  ),
                ],

                if (_tipoServicio == TipoServicio.aguaGarrafon) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _garrafonesCtrl,
                    decoration: const InputDecoration(labelText: 'Cantidad de Garrafones', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ],

                if (_tipoServicio == TipoServicio.volteo) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _viajesCtrl,
                    decoration: const InputDecoration(labelText: 'Cantidad de Viajes', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TipoMaterial?>(
                    decoration: const InputDecoration(labelText: 'Tipo de Material', border: OutlineInputBorder()),
                    value: _tipoMaterial,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No aplica')),
                      ...TipoMaterial.values.map((m) => DropdownMenuItem(value: m, child: Text(m.label))),
                    ],
                    onChanged: (v) => setState(() => _tipoMaterial = v),
                  ),
                ],

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
