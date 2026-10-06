import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/movimientos_table.dart';
import '../../core/widgets/section_widgets.dart';
import '../../models/filtro_movimientos.dart';
import '../../models/movimiento.dart';
import '../../providers/movimiento_provider.dart';
import '../../providers/usuario_provider.dart';
import '../../providers/vehiculo_provider.dart';
import 'movimiento_form_dialog.dart';

class MovimientosScreen extends StatefulWidget {
  final bool esGasto;
  const MovimientosScreen({super.key, required this.esGasto});
  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UsuarioProvider>().cargar();
      context.read<VehiculoProvider>().cargar();
      context.read<MovimientoProvider>().cargar();
    });
  }

  Future<void> _formulario([Movimiento? m]) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        MovimientoFormDialog(esGasto: widget.esGasto, movimiento: m),
  );

  Future<void> _eliminar(Movimiento m) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text(
          'Se eliminará ${m.concepto.toLowerCase()} por ${dinero(m.monto)}.',
        ),
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
    if (confirmar != true || !mounted) return;
    final provider = context.read<MovimientoProvider>();
    final ok = await provider.eliminar(m.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Registro eliminado' : provider.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovimientoProvider>();
    final movimientos = provider.movimientos
        .where((m) => m.esGasto == widget.esGasto)
        .toList();
    final totales = TotalesMovimientos.de(movimientos);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esGasto ? 'Gastos' : 'Operaciones e ingresos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.esGasto
                ? 'Controla los egresos de tu flotilla y personal.'
                : 'Registra servicios de agua, maquinaria, volteo y garrafones.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SummaryGrid(
            children: [
              SummaryCard(
                label: widget.esGasto
                    ? 'Gastos registrados'
                    : 'Operaciones registradas',
                value: '${movimientos.length}',
                icon: Icons.receipt_long_outlined,
              ),
              SummaryCard(
                label: widget.esGasto ? 'Total de gastos' : 'Total de ingresos',
                value: dinero(
                  widget.esGasto ? totales.gastos : totales.ingresos,
                ),
                icon: Icons.payments_outlined,
                color: widget.esGasto ? AppColors.warning : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 24),
          CatalogToolbar(
            hint: 'Buscar concepto o detalle…',
            label: widget.esGasto ? 'Registrar gasto' : 'Registrar operación',
            onChanged:
                (
                  v,
                ) {}, // Búsqueda deshabilitada (no soportada por el backend en esta vista)
            onAdd: () => _formulario(),
          ),
          const SizedBox(height: 20),
          if (provider.cargando) const LinearProgressIndicator(),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                provider.error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          MovimientosTable(
            movimientos: movimientos,
            onEdit: _formulario,
            onDelete: _eliminar,
          ),
        ],
      ),
    );
  }
}
