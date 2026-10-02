import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/widgets/section_widgets.dart';
import '../models/filtro_movimientos.dart';
import '../models/movimiento.dart';

/// Generación pura de archivos; no cambia los filtros ni accede a la red.
class ReporteExporter {
  final List<Movimiento> movimientos;
  final Map<String, String> empleados;
  final Map<String, String> vehiculos;
  final String filtros;
  ReporteExporter({
    required this.movimientos,
    required this.empleados,
    required this.vehiculos,
    required this.filtros,
  });
  String empleado(Movimiento m) => empleados[m.empleadoId] ?? 'No disponible';
  String vehiculo(Movimiento m) => m.vehiculoId == null
      ? 'Sin vehículo'
      : vehiculos[m.vehiculoId] ?? 'No disponible';

  Uint8List excel() {
    final book = Excel.createExcel();
    book.rename('Sheet1', 'Resumen');
    final resumen = book['Resumen'];
    final totales = TotalesMovimientos.de(movimientos);
    resumen.appendRow([TextCellValue('Pipa Móv - Reporte de movimientos')]);
    resumen.appendRow([TextCellValue('Filtros'), TextCellValue(filtros)]);
    resumen.appendRow([
      TextCellValue('Registros'),
      IntCellValue(movimientos.length),
    ]);
    resumen.appendRow([
      TextCellValue('Ingresos MXN'),
      DoubleCellValue(totales.ingresos),
    ]);
    resumen.appendRow([
      TextCellValue('Gastos MXN'),
      DoubleCellValue(totales.gastos),
    ]);
    resumen.appendRow([
      TextCellValue('Balance MXN'),
      DoubleCellValue(totales.balance),
    ]);
    resumen.setColumnWidth(0, 38);
    resumen.setColumnWidth(1, 65);
    final sheet = book['Movimientos'];
    const headers = [
      'Fecha',
      'Tipo',
      'Concepto',
      'Vehículo',
      'Empleado',
      'Detalle',
      'Ingresos MXN',
      'Gastos MXN',
      'Horas',
      'Viajes',
      'Garrafones',
      'Capacidad pipa',
      'Material',
      'Adjunto',
      'URL de archivo',
    ];
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (final m in movimientos) {
      final ingreso = m is Ingreso ? m : null;
      sheet.appendRow([
        TextCellValue(fechaCorta(m.fecha)),
        TextCellValue(m.esGasto ? 'Gasto' : 'Ingreso'),
        TextCellValue(m.concepto),
        TextCellValue(vehiculo(m)),
        TextCellValue(empleado(m)),
        TextCellValue(m.detalle),
        DoubleCellValue(m.esGasto ? 0 : m.monto),
        DoubleCellValue(m.esGasto ? m.monto : 0),
        ingreso?.cantidadHoras == null
            ? null
            : DoubleCellValue(ingreso!.cantidadHoras!),
        ingreso?.cantidadViajes == null
            ? null
            : IntCellValue(ingreso!.cantidadViajes!),
        ingreso?.cantidadGarrafones == null
            ? null
            : IntCellValue(ingreso!.cantidadGarrafones!),
        TextCellValue(ingreso?.capacidadPipa ?? ''),
        TextCellValue(ingreso?.tipoMaterial ?? ''),
        TextCellValue(m.evidencia?.nombre ?? ''),
        TextCellValue(m.archivoUrl ?? ''),
      ]);
    }
    for (var col = 0; col < headers.length; col++) {
      sheet.setColumnWidth(col, col == 5 ? 48 : 24);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#334E68'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }
    for (var row = 1; row <= movimientos.length; row++) {
      for (final col in [6, 7]) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
            .cellStyle = CellStyle(
          numberFormat: NumFormat.standard_2,
        );
      }
    }
    return Uint8List.fromList(book.encode()!);
  }

  Future<Uint8List> pdf() async {
    final document = pw.Document();
    final totales = TotalesMovimientos.de(movimientos);
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        maxPages: 1000,
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Pipa Móv | ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (_) => [
          pw.Text(
            'Reporte de movimientos',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#334E68'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(filtros, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 12),
          pw.Text(
            'Ingresos: ${dinero(totales.ingresos)}    Gastos: ${dinero(totales.gastos)}    Balance: ${dinero(totales.balance)}',
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              'Fecha',
              'Tipo',
              'Concepto / detalle',
              'Vehículo',
              'Empleado',
              'Monto MXN',
            ],
            data: movimientos
                .map(
                  (m) => [
                    fechaCorta(m.fecha),
                    m.esGasto ? 'Gasto' : 'Ingreso',
                    '${m.concepto}\n${m.detalle}',
                    vehiculo(m),
                    empleado(m),
                    dinero(m.monto),
                  ],
                )
                .toList(),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#334E68'),
            ),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.all(7),
            oddRowDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F4F6F8'),
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(65),
              1: const pw.FixedColumnWidth(48),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FlexColumnWidth(),
              4: const pw.FlexColumnWidth(2),
              5: const pw.FixedColumnWidth(95),
            },
          ),
        ],
      ),
    );
    return document.save();
  }
}
