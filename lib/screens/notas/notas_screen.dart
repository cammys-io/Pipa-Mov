import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/nota.dart';
import '../../providers/nota_provider.dart';
import 'nota_edit_dialog.dart';
import 'nota_form_fields.dart';

/// Vista de gestión de notas: listar, completar, editar y eliminar.
class NotasScreen extends StatefulWidget {
  const NotasScreen({super.key});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  /// `null` = todas.
  EstadoNota? _filtro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotaProvider>().cargar();
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _completar(Nota n) async {
    final error = await context.read<NotaProvider>().completar(n.id);
    if (error != null && mounted) _snack(error);
  }

  Future<void> _editar(Nota n) async {
    final provider = context.read<NotaProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => NotaEditDialog(
        nota: n,
        onGuardar: (titulo, desc, estatus) => provider.actualizar(
          n.id,
          titulo: titulo,
          descripcion: desc,
          estatus: estatus,
        ),
      ),
    );
    if (ok == true && mounted) _snack('Nota actualizada');
  }

  Future<void> _eliminar(Nota n) async {
    final provider = context.read<NotaProvider>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar nota'),
        content: Text('¿Seguro que deseas eliminar "${n.titulo}"? '
            'Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    final error = await provider.eliminar(n.id);
    if (!mounted) return;
    _snack(error ?? 'Nota eliminada');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotaProvider>();
    final visibles = provider.notas
        .where((n) => _filtro == null || n.estatus == _filtro)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Notas y recordatorios',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                      ),
                      IconButton(
                        tooltip: 'Actualizar',
                        onPressed: provider.cargando ? null : provider.cargar,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        onPressed: provider.abrirSticky,
                        icon: const Icon(Icons.note_add_rounded, size: 18),
                        label: const Text('Nueva nota'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ChoiceChip(
                        label: Text('Todas (${provider.notas.length})'),
                        selected: _filtro == null,
                        onSelected: (_) => setState(() => _filtro = null),
                      ),
                      for (final e in EstadoNota.values)
                        ChoiceChip(
                          label: Text(e.label),
                          selected: _filtro == e,
                          selectedColor:
                              colorEstadoNota(e).withValues(alpha: 0.2),
                          onSelected: (_) => setState(() => _filtro = e),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildBody(provider, visibles)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(NotaProvider provider, List<Nota> visibles) {
    if (provider.cargando && provider.notas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.notas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
                onPressed: provider.cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (visibles.isEmpty) {
      return const Center(
        child: Text('No hay notas por mostrar',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: visibles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final n = visibles[i];
        return _NotaTile(
          key: ValueKey(n.id),
          nota: n,
          onCompletar: () => _completar(n),
          onEditar: () => _editar(n),
          onEliminar: () => _eliminar(n),
        );
      },
    );
  }
}

class _NotaTile extends StatelessWidget {
  final Nota nota;
  final VoidCallback onCompletar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _NotaTile({
    super.key,
    required this.nota,
    required this.onCompletar,
    required this.onEditar,
    required this.onEliminar,
  });

  String _fecha(DateTime d) {
    String dos(int v) => v.toString().padLeft(2, '0');
    return '${dos(d.day)}/${dos(d.month)}/${d.year} ${dos(d.hour)}:${dos(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = colorEstadoNota(nota.estatus);
    final resuelta = nota.estatus == EstadoNota.resuelto;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            nota.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              decoration:
                                  resuelta ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        EstadoChip(label: nota.estatus.label, color: color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nota.descripcion,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    if (nota.createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text(_fecha(nota.createdAt!),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (nota.estatus == EstadoNota.pendiente)
                    IconButton(
                      tooltip: 'Marcar como resuelta',
                      icon: const Icon(Icons.check_circle_rounded,
                          color: AppColors.success),
                      onPressed: onCompletar,
                    ),
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    onPressed: onEditar,
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_rounded,
                        size: 20, color: AppColors.danger),
                    onPressed: onEliminar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
