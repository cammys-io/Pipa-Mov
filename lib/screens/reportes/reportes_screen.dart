import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
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
import '../../services/reporte_exporter.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});
  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  DateTimeRange? _fechas;
  String _tipo = 'todos';
  String _categoria = '';
  String _vehiculo = '';
  bool _exportando = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MovimientoProvider>().cargar();
      context.read<UsuarioProvider>().cargar();
      context.read<VehiculoProvider>().cargar();
    });
  }

  Future<void> _rango() async {
    final rango = await showDateRangePicker(
      context: context,
      initialDateRange: _fechas,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
      helpText: 'Periodo del reporte',
      saveText: 'Aplicar',
    );
    if (rango != null && mounted) setState(() => _fechas = rango);
  }

  String get _periodo => _fechas == null
      ? 'Todas las fechas'
      : '${fechaCorta(_fechas!.start)} - ${fechaCorta(_fechas!.end)}';

  Future<void> _exportar(
    List<Movimiento> movimientos,
    bool pdf,
    String filtros,
  ) async {
    setState(() => _exportando = true);
    final exporter = ReporteExporter(
      movimientos: movimientos,
      filtros: filtros,
      empleados: {
        for (final u in context.read<UsuarioProvider>().usuarios)
          u.id: u.nombreCompleto,
      },
      vehiculos: {
        for (final v in context.read<VehiculoProvider>().vehiculos)
          v.id: v.placas,
      },
    );
    try {
      final bytes = pdf ? await exporter.pdf() : exporter.excel();
      final path = await FileSaver.instance.saveFile(
        name: 'reporte_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        fileExtension: pdf ? 'pdf' : 'xlsx',
        mimeType: pdf ? MimeType.pdf : MimeType.microsoftExcel,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'Descarga del reporte iniciada'
                  : 'Reporte guardado: $path',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo exportar el reporte. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovimientoProvider>();
    final vehiculos = context.watch<VehiculoProvider>().vehiculos;
    final categorias = <String, String>{
      '': 'Todas las categorías',
      if (_tipo != 'gastos')
        for (final s in ServicioOperacion.values) 'ingreso:${s.name}': s.label,
      if (_tipo != 'ingresos')
        for (final c in CategoriaGasto.values) 'gasto:${c.name}': c.label,
    };
    final movimientos = FiltroMovimientos(
      desde: _fechas?.start,
      hasta: _fechas?.end,
      esGasto: _tipo == 'todos' ? null : _tipo == 'gastos',
      categoria: _categoria.isEmpty ? null : _categoria,
      vehiculoId: _vehiculo.isEmpty ? null : _vehiculo,
    ).aplicar(provider.movimientos);
    final totales = TotalesMovimientos.de(movimientos);
    final placas = {for (final v in vehiculos) v.id: v.placas};
    final filtros =
        '$_periodo | ${_tipo == 'todos' ? 'Ingresos y gastos' : _tipo} | ${categorias[_categoria]} | ${placas[_vehiculo] ?? 'Todos los vehículos'}';
    return Scaffold(
      appBar: AppBar(title: const Text('Filtros y reportes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Consulta el detalle de ingresos y gastos y exporta el periodo que necesitas.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, box) {
                  final width = box.maxWidth < 600
                      ? box.maxWidth
                      : (box.maxWidth - 16) / 2;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: width,
                        child: OutlinedButton.icon(
                          onPressed: _rango,
                          icon: const Icon(Icons.date_range_outlined),
                          label: Text(_periodo),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('tipo:$_tipo'),
                          initialValue: _tipo,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de movimiento',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'todos',
                              child: Text('Ingresos y gastos'),
                            ),
                            DropdownMenuItem(
                              value: 'ingresos',
                              child: Text('Ingresos'),
                            ),
                            DropdownMenuItem(
                              value: 'gastos',
                              child: Text('Gastos'),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _tipo = v!;
                            _categoria = '';
                          }),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('categoria:$_tipo:$_categoria'),
                          initialValue: _categoria,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Categoría / servicio',
                          ),
                          items: categorias.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _categoria = v!),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('vehiculo:$_vehiculo'),
                          initialValue: _vehiculo,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Vehículo',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Todos los vehículos'),
                            ),
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
                          onChanged: (v) => setState(() => _vehiculo = v!),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _fechas = null;
                          _tipo = 'todos';
                          _categoria = '';
                          _vehiculo = '';
                        }),
                        icon: const Icon(Icons.filter_alt_off_outlined),
                        label: const Text('Limpiar filtros'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          SummaryGrid(
            children: [
              SummaryCard(
                label: 'Ingresos del periodo',
                value: dinero(totales.ingresos),
                icon: Icons.south_west,
                color: AppColors.success,
              ),
              SummaryCard(
                label: 'Gastos del periodo',
                value: dinero(totales.gastos),
                icon: Icons.north_east,
                color: AppColors.warning,
              ),
              SummaryCard(
                label: 'Balance del periodo',
                value: dinero(totales.balance),
                icon: Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${movimientos.length} registros',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              FilledButton.icon(
                onPressed: _exportando || movimientos.isEmpty
                    ? null
                    : () => _exportar(movimientos, true, filtros),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Exportar PDF'),
              ),
              OutlinedButton.icon(
                onPressed: _exportando || movimientos.isEmpty
                    ? null
                    : () => _exportar(movimientos, false, filtros),
                icon: const Icon(Icons.table_view_outlined),
                label: const Text('Exportar Excel'),
              ),
            ],
          ),
          if (_exportando || provider.cargando)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(),
            ),
          if (provider.error != null)
            Text(
              provider.error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          const SizedBox(height: 16),
          MovimientosTable(movimientos: movimientos),
        ],
      ),
    );
  }
}
