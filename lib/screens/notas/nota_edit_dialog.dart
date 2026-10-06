import 'package:flutter/material.dart';

import '../../models/nota.dart';
import 'nota_form_fields.dart';

/// Diálogo para editar una nota existente (formulario prellenado).
///
/// Devuelve (vía `Navigator.pop`) `true` si la nota se guardó correctamente.
/// El guardado real lo hace [onGuardar], que debe devolver `null` si todo salió
/// bien o un mensaje de error para mostrarlo dentro del diálogo.
class NotaEditDialog extends StatefulWidget {
  final Nota nota;
  final Future<String?> Function(
      String titulo, String descripcion, EstadoNota estatus) onGuardar;

  const NotaEditDialog({super.key, required this.nota, required this.onGuardar});

  @override
  State<NotaEditDialog> createState() => _NotaEditDialogState();
}

class _NotaEditDialogState extends State<NotaEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descCtrl;
  late EstadoNota _estatus;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.nota.titulo);
    _descCtrl = TextEditingController(text: widget.nota.descripcion);
    _estatus = widget.nota.estatus;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await widget.onGuardar(
        _tituloCtrl.text.trim(), _descCtrl.text.trim(), _estatus);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _guardando = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Editar nota',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotaFormFields(
                formKey: _formKey,
                tituloCtrl: _tituloCtrl,
                descripcionCtrl: _descCtrl,
                estatus: _estatus,
                onEstatusChanged: (e) => setState(() => _estatus = e),
                opciones: EstadoNota.values,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
