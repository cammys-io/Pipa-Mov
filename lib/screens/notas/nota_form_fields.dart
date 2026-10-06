import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/nota.dart';

/// Color asociado a cada estado de nota.
Color colorEstadoNota(EstadoNota e) {
  switch (e) {
    case EstadoNota.info:
      return const Color(0xFF4F6D8A); // gris azulado
    case EstadoNota.pendiente:
      return const Color(0xFFE5532D); // rojo / naranja
    case EstadoNota.resuelto:
      return AppColors.success;
  }
}

/// Campos reutilizables (título, descripción, estatus) usados tanto por el
/// sticky flotante como por el diálogo de edición.
///
/// El [formKey] lo gestiona quien lo use para validar antes de guardar.
class NotaFormFields extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController tituloCtrl;
  final TextEditingController descripcionCtrl;
  final EstadoNota estatus;
  final ValueChanged<EstadoNota> onEstatusChanged;
  final List<EstadoNota> opciones;
  final int descripcionMaxLines;

  const NotaFormFields({
    super.key,
    required this.formKey,
    required this.tituloCtrl,
    required this.descripcionCtrl,
    required this.estatus,
    required this.onEstatusChanged,
    this.opciones = const [EstadoNota.info, EstadoNota.pendiente],
    this.descripcionMaxLines = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: tituloCtrl,
            maxLength: 150,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Título',
              counterText: '',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Escribe un título' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: descripcionCtrl,
            minLines: 3,
            maxLines: descripcionMaxLines,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontSize: 13.5),
            decoration: const InputDecoration(hintText: 'Descripción'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Escribe una descripción'
                : null,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final e in opciones)
                ChoiceChip(
                  label: Text(e.label),
                  selected: estatus == e,
                  showCheckmark: false,
                  selectedColor: colorEstadoNota(e),
                  backgroundColor: colorEstadoNota(e).withValues(alpha: 0.10),
                  side: BorderSide(
                      color: colorEstadoNota(e).withValues(alpha: 0.4)),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: estatus == e ? Colors.white : colorEstadoNota(e),
                  ),
                  onSelected: (_) => onEstatusChanged(e),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
