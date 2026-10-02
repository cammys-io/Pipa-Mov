import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_widgets.dart';
import '../../models/movimiento.dart';
import '../../providers/movimiento_provider.dart';
import '../../providers/usuario_provider.dart';
import '../../providers/vehiculo_provider.dart';

class MovimientoFormDialog extends StatefulWidget {
  final bool esGasto;
  final Movimiento? movimiento;
  const MovimientoFormDialog({
    super.key,
    required this.esGasto,
    this.movimiento,
  });
  @override
  State<MovimientoFormDialog> createState() => _MovimientoFormDialogState();
}

class _MovimientoFormDialogState extends State<MovimientoFormDialog> {
  final _form = GlobalKey<FormState>();
  final _viajes = TextEditingController();
  final _horas = TextEditingController();
  final _garrafones = TextEditingController();
  final _precio = TextEditingController();
  final _monto = TextEditingController();
  final _descripcion = TextEditingController();
  final _material = TextEditingController();
  late DateTime _fecha;
  ServicioOperacion _servicio = ServicioOperacion.pipa;
  CategoriaGasto _categoria = CategoriaGasto.combustible;
  String? _empleadoId;
  String? _vehiculoId;
  String _capacidad = '5mil';
  bool _manual = false;
  bool _porHoras = false;
  bool _guardando = false;
  bool _adjuntando = false;
  String? _error;
  Evidencia? _evidencia;
  String? _archivoUrl;

  @override
  void initState() {
    super.initState();
    final m = widget.movimiento;
    _fecha = m?.fecha ?? DateTime.now();
    _empleadoId = m?.empleadoId;
    _vehiculoId = m?.vehiculoId;
    _evidencia = m?.evidencia;
    _archivoUrl = m?.archivoUrl;
    _manual = widget.esGasto || m != null;
    _monto.text = m?.monto.toStringAsFixed(2) ?? '';
    if (m is Ingreso) {
      _servicio = m.servicio;
      _viajes.text = m.cantidadViajes?.toString() ?? '';
      _horas.text = m.cantidadHoras?.toString() ?? '';
      _garrafones.text = m.cantidadGarrafones?.toString() ?? '';
      _capacidad = m.capacidadPipa ?? '5mil';
      _material.text = m.tipoMaterial ?? '';
    } else if (m is Gasto) {
      _categoria = m.categoria;
      _descripcion.text = m.descripcion;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _viajes,
      _horas,
      _garrafones,
      _precio,
      _monto,
      _descripcion,
      _material,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _numero(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));
  bool get _usaViajes =>
      _servicio == ServicioOperacion.pipa ||
      _servicio == ServicioOperacion.volteo;
  bool get _usaHoras =>
      _servicio == ServicioOperacion.retro ||
      _servicio == ServicioOperacion.volteo;
  String get _unidad => _servicio == ServicioOperacion.garrafones
      ? 'garrafón'
      : _servicio == ServicioOperacion.retro ||
            (_servicio == ServicioOperacion.volteo && _porHoras)
      ? 'hora'
      : 'viaje';

  void _calcular() {
    if (_manual || widget.esGasto) return;
    final cantidad = _numero(
      _unidad == 'garrafón'
          ? _garrafones.text
          : _unidad == 'hora'
          ? _horas.text
          : _viajes.text,
    );
    final precio = _numero(_precio.text);
    try {
      _monto.text = cantidad == null || precio == null
          ? ''
          : calcularImporte(cantidad, precio).toStringAsFixed(2);
    } on ArgumentError {
      _monto.clear();
    }
  }

  String? _positivo(
    String? value, {
    bool entero = false,
    bool opcional = false,
  }) {
    if (opcional && (value == null || value.trim().isEmpty)) return null;
    final n = _numero(value ?? '');
    if (n == null || !n.isFinite || n <= 0 || n > 999999999999.99) {
      return 'Ingresa un valor positivo válido';
    }
    if (entero && n != n.truncateToDouble()) {
      return 'Ingresa una cantidad entera';
    }
    return null;
  }

  Widget _cantidad(
    TextEditingController controller,
    String label, {
    bool entero = false,
    bool opcional = false,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: TextInputType.numberWithOptions(decimal: !entero),
    validator: (v) => _positivo(v, entero: entero, opcional: opcional),
    onChanged: (_) => setState(_calcular),
  );

  Future<void> _elegirFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (fecha != null && mounted) setState(() => _fecha = fecha);
  }

  Future<void> _adjuntar() async {
    setState(() {
      _adjuntando = true;
      _error = null;
    });
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (file == null) return;
      if ((await file.length() ?? 0) > 10 * 1024 * 1024) {
        throw const FormatException('El archivo debe pesar menos de 10 MB.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        throw const FormatException('El archivo debe pesar menos de 10 MB.');
      }
      if (bytes.isEmpty) throw const FormatException('El archivo está vacío.');
      if (mounted) {
        setState(() {
          _evidencia = Evidencia(nombre: file.name, bytes: bytes);
          _archivoUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is FormatException
              ? e.message
              : 'No se pudo adjuntar el archivo. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _adjuntando = false);
    }
  }

  Future<void> _guardar() async {
    _calcular();
    if (!_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final id =
        widget.movimiento?.id ??
        DateTime.now().microsecondsSinceEpoch.toString();
    final monto = (_numero(_monto.text)! * 100).round() / 100;
    final Movimiento movimiento = widget.esGasto
        ? Gasto(
            id: id,
            fecha: _fecha,
            empleadoId: _empleadoId!,
            vehiculoId: _vehiculoId,
            monto: monto,
            categoria: _categoria,
            descripcion: _descripcion.text.trim(),
            evidencia: _evidencia,
            archivoUrl: _archivoUrl,
          )
        : Ingreso(
            id: id,
            fecha: _fecha,
            empleadoId: _empleadoId!,
            vehiculoId: _vehiculoId,
            monto: monto,
            servicio: _servicio,
            evidencia: _evidencia,
            archivoUrl: _archivoUrl,
            cantidadViajes: _usaViajes && _viajes.text.trim().isNotEmpty
                ? _numero(_viajes.text)!.toInt()
                : null,
            cantidadHoras: _usaHoras && _horas.text.trim().isNotEmpty
                ? _numero(_horas.text)
                : null,
            cantidadGarrafones: _servicio == ServicioOperacion.garrafones
                ? _numero(_garrafones.text)!.toInt()
                : null,
            capacidadPipa: _servicio == ServicioOperacion.pipa
                ? _capacidad
                : null,
            tipoMaterial: _servicio == ServicioOperacion.volteo
                ? _material.text.trim()
                : null,
          );
    final provider = context.read<MovimientoProvider>();
    final ok = await provider.guardar(movimiento);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro guardado en esta sesión')),
      );
    } else {
      setState(() {
        _guardando = false;
        _error = provider.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = context.watch<UsuarioProvider>().usuarios;
    final vehiculos = context
        .watch<VehiculoProvider>()
        .vehiculos
        .where((v) => widget.esGasto || v.tipo == _servicio.tipoUnidad)
        .toList();
    final fields = <Widget>[
      OutlinedButton.icon(
        onPressed: _elegirFecha,
        icon: const Icon(Icons.calendar_today_outlined, size: 18),
        label: Text('Fecha: ${fechaCorta(_fecha)}'),
      ),
      if (!widget.esGasto)
        DropdownButtonFormField<ServicioOperacion>(
          isExpanded: true,
          initialValue: _servicio,

          decoration: const InputDecoration(labelText: 'Tipo de operación'),
          items: ServicioOperacion.values
              .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
              .toList(),
          onChanged: (s) => setState(() {
            _servicio = s!;
            _vehiculoId = null;
            _porHoras = false;
            _calcular();
          }),
        ),
      if (widget.esGasto)
        DropdownButtonFormField<CategoriaGasto>(
          isExpanded: true,
          initialValue: _categoria,
          decoration: const InputDecoration(labelText: 'Categoría'),
          items: CategoriaGasto.values
              .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
              .toList(),
          onChanged: (c) => setState(() => _categoria = c!),
        ),
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _empleadoId,

        decoration: const InputDecoration(labelText: 'Empleado responsable'),
        items: usuarios
            .map(
              (u) => DropdownMenuItem(
                value: u.id,
                child: Text(u.nombreCompleto, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (id) => setState(() => _empleadoId = id),
        validator: (id) => id == null ? 'Selecciona un empleado' : null,
      ),
      if (usuarios.isEmpty)
        const Text(
          'Primero registra al personal en Catálogos.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      DropdownButtonFormField<String>(
        isExpanded: true,
        key: ValueKey('${_servicio.name}:$_vehiculoId'),
        initialValue: _vehiculoId ?? '',

        decoration: const InputDecoration(labelText: 'Vehículo (opcional)'),
        items: [
          const DropdownMenuItem(value: '', child: Text('Sin vehículo')),
          ...vehiculos.map(
            (v) => DropdownMenuItem(
              value: v.id,
              child: Text(
                '${v.placas} · ${v.marca}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: (id) => setState(() => _vehiculoId = id == '' ? null : id),
      ),
      if (!widget.esGasto) ...[
        if (_usaViajes)
          _cantidad(
            _viajes,
            _servicio == ServicioOperacion.volteo
                ? 'Viajes (opcional si capturas horas)'
                : 'Cantidad de viajes',
            entero: true,
            opcional:
                _servicio == ServicioOperacion.volteo &&
                (_numero(_horas.text) ?? 0) > 0 &&
                (_manual || _porHoras),
          ),
        if (_usaHoras)
          _cantidad(
            _horas,
            _servicio == ServicioOperacion.volteo
                ? 'Horas (opcional si capturas viajes)'
                : 'Horas trabajadas',
            opcional:
                _servicio == ServicioOperacion.volteo &&
                (_numero(_viajes.text) ?? 0) > 0 &&
                (_manual || !_porHoras),
          ),
        if (_servicio == ServicioOperacion.garrafones)
          _cantidad(_garrafones, 'Cantidad de garrafones', entero: true),
        if (_servicio == ServicioOperacion.pipa)
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _capacidad,
            decoration: const InputDecoration(
              labelText: 'Capacidad de la pipa',
            ),
            items: const [
              DropdownMenuItem(value: '5mil', child: Text('5,000 litros')),
              DropdownMenuItem(value: '10mil', child: Text('10,000 litros')),
            ],
            onChanged: (v) => setState(() => _capacidad = v!),
          ),
        if (_servicio == ServicioOperacion.volteo)
          TextFormField(
            controller: _material,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Material',
              hintText: 'Arena, grava, base…',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Indica el material' : null,
          ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Capturar monto manual'),
          subtitle: const Text(
            'Desactiva para calcular cantidad × precio unitario',
          ),
          value: _manual,
          onChanged: (v) => setState(() {
            _manual = v;
            _calcular();
          }),
        ),
        if (!_manual) ...[
          if (_servicio == ServicioOperacion.volteo)
            DropdownButtonFormField<bool>(
              isExpanded: true,
              initialValue: _porHoras,
              decoration: const InputDecoration(labelText: 'Cobrar por'),
              items: const [
                DropdownMenuItem(value: false, child: Text('Viaje')),
                DropdownMenuItem(value: true, child: Text('Hora')),
              ],
              onChanged: (v) => setState(() {
                _porHoras = v!;
                _calcular();
              }),
            ),
          _cantidad(_precio, 'Precio por $_unidad (MXN)'),
        ],
      ],
      if (widget.esGasto)
        TextFormField(
          controller: _descripcion,
          maxLength: 300,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Descripción del gasto'),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Describe el gasto' : null,
        ),
      TextFormField(
        controller: _monto,
        readOnly: !widget.esGasto && !_manual,
        decoration: const InputDecoration(
          labelText: 'Monto total (MXN)',
          prefixText: r'$ ',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: _positivo,
      ),
      const Divider(),
      Text(
        widget.esGasto ? 'Comprobante' : 'Evidencia del servicio',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      OutlinedButton.icon(
        onPressed: _adjuntando ? null : _adjuntar,
        icon: const Icon(Icons.attach_file),
        label: Text(_adjuntando ? 'Leyendo archivo…' : 'Adjuntar foto o PDF'),
      ),
      const Text(
        'JPG, PNG o PDF · Hasta 10 MB',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      if (_evidencia != null || _archivoUrl != null)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined),
          title: Text(
            _evidencia?.nombre ?? 'Archivo existente',
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            tooltip: 'Quitar adjunto',
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
              _evidencia = null;
              _archivoUrl = null;
            }),
          ),
        ),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: AppColors.danger)),
    ];
    return PopScope(
      canPop: !_guardando,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Text(
          '${widget.movimiento == null ? 'Registrar' : 'Editar'} ${widget.esGasto ? 'gasto' : 'operación'}',
        ),
        content: SizedBox(
          width: 520,
          child: AbsorbPointer(
            absorbing: _guardando,
            child: Form(
              key: _form,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final field in fields)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: field,
                      ),
                  ],
                ),
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
            onPressed: _guardando || _adjuntando || usuarios.isEmpty
                ? null
                : _guardar,
            child: Text(_guardando ? 'Guardando…' : 'Guardar'),
          ),
        ],
      ),
    );
  }
}
