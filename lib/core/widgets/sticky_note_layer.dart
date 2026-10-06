import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/nota.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nota_provider.dart';
import '../../screens/notas/nota_form_fields.dart';

const _stickyBody = Color(0xFFFFF8D6);
const _stickyHeader = Color(0xFFFFEE9A);
const _stickyInk = Color(0xFF4A4222);

/// Capa global que se inyecta con `MaterialApp.router(builder: ...)`.
///
/// Se dibuja POR ENCIMA del Navigator/Router, por lo que el sticky-note
/// flotante sobrevive a cualquier navegación entre pantallas.
///
/// El builder de MaterialApp queda *encima* del Navigator y por eso no hay un
/// `Overlay` disponible (lo necesitan TextField, Tooltip, menús contextuales,
/// etc.). Para resolverlo la capa crea su propio `Overlay` ligero, que además
/// deja pasar los toques a la app en todo lo que no sea la nota.
class StickyNoteLayer extends StatefulWidget {
  final Widget? child;
  const StickyNoteLayer({super.key, this.child});

  @override
  State<StickyNoteLayer> createState() => _StickyNoteLayerState();
}

class _StickyNoteLayerState extends State<StickyNoteLayer> {
  /// Posición actual de la nota. `null` => posición inicial calculada.
  /// Vive aquí (no en el provider) para no reconstruir la lista en cada
  /// movimiento de arrastre.
  final ValueNotifier<Offset?> _offset = ValueNotifier(null);
  late final OverlayEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = OverlayEntry(builder: _buildEntry);
  }

  @override
  void dispose() {
    _entry.remove();
    _entry.dispose();
    _offset.dispose();
    super.dispose();
  }

  Widget _buildEntry(BuildContext context) {
    return Consumer2<NotaProvider, AuthProvider>(
      builder: (context, notas, auth, _) {
        if (!notas.stickyVisible || !auth.estaAutenticado) {
          return const SizedBox.shrink();
        }
        return _DraggableSticky(offset: _offset);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.child != null) widget.child!,
        Positioned.fill(child: Overlay(initialEntries: [_entry])),
      ],
    );
  }
}

class _DraggableSticky extends StatelessWidget {
  final ValueNotifier<Offset?> offset;
  const _DraggableSticky({required this.offset});

  static const double _maxWidth = 340;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = (size.width - 24).clamp(240.0, _maxWidth);

    Offset clamp(Offset o) => Offset(
          o.dx.clamp(0.0, (size.width - width).clamp(0.0, double.infinity)),
          o.dy.clamp(0.0, (size.height - 56).clamp(0.0, double.infinity)),
        );

    return ValueListenableBuilder<Offset?>(
      valueListenable: offset,
      builder: (context, value, _) {
        // Posición inicial: esquina superior derecha, bajo el borde superior.
        final current =
            clamp(value ?? Offset(size.width - width - 24, 72));
        return Stack(
          children: [
            Positioned(
              left: current.dx,
              top: current.dy,
              width: width,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: (size.height - current.dy).clamp(160.0, 640.0)),
                child: _StickyCard(
                  // Se parte del valor más reciente (no del capturado en build)
                  // para acumular bien varios eventos entre frames.
                  onDrag: (delta) =>
                      offset.value = clamp((offset.value ?? current) + delta),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StickyCard extends StatefulWidget {
  final ValueChanged<Offset> onDrag;
  const _StickyCard({required this.onDrag});

  @override
  State<_StickyCard> createState() => _StickyCardState();
}

class _StickyCardState extends State<_StickyCard> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  EstadoNota _estatus = EstadoNota.info;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<NotaProvider>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await provider.crear(
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
      estatus: _estatus,
    );
    if (!mounted) return;
    if (error == null) {
      provider.cerrarSticky(); // desmonta este widget y limpia el borrador
      messenger?.showSnackBar(const SnackBar(
        content: Text('Nota guardada'),
        duration: Duration(seconds: 2),
      ));
    } else {
      setState(() {
        _guardando = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: t, alignment: Alignment.topCenter, child: child),
      ),
      child: Material(
        color: _stickyBody,
        elevation: 14,
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          // Campos translúcidos para que se vea el "papel" amarillo.
          data: theme.copyWith(
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              fillColor: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera = zona de arrastre.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                // `down`: la nota sigue al puntero desde el primer píxel.
                dragStartBehavior: DragStartBehavior.down,
                onPanUpdate: (d) => widget.onDrag(d.delta),
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Container(
                    color: _stickyHeader,
                    padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
                    child: Row(
                      children: [
                        const Icon(Icons.drag_indicator_rounded,
                            size: 18, color: _stickyInk),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text('Nueva nota',
                              style: TextStyle(
                                  color: _stickyInk,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5)),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: _stickyInk),
                          onPressed: () =>
                              context.read<NotaProvider>().cerrarSticky(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      NotaFormFields(
                        formKey: _formKey,
                        tituloCtrl: _tituloCtrl,
                        descripcionCtrl: _descCtrl,
                        estatus: _estatus,
                        onEstatusChanged: (e) => setState(() => _estatus = e),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!,
                            style: TextStyle(
                                color: theme.colorScheme.error, fontSize: 12)),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _guardando
                                ? null
                                : () =>
                                    context.read<NotaProvider>().cerrarSticky(),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _guardando ? null : _guardar,
                            icon: _guardando
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
