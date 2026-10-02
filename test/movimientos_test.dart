import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipa_mov/data/repositories/usuario_repository.dart';
import 'package:pipa_mov/data/repositories/vehiculo_repository.dart';
import 'package:pipa_mov/models/filtro_movimientos.dart';
import 'package:pipa_mov/models/movimiento.dart';
import 'package:pipa_mov/providers/movimiento_provider.dart';
import 'package:pipa_mov/services/reporte_exporter.dart';

Ingreso ingreso({
  String id = '1',
  DateTime? fecha,
  double monto = 150,
  ServicioOperacion servicio = ServicioOperacion.pipa,
}) => Ingreso(
  id: id,
  fecha: fecha ?? DateTime(2026, 9, 30, 23, 59),
  empleadoId: 'u1',
  vehiculoId: 'v1',
  monto: monto,
  servicio: servicio,
  cantidadViajes: servicio == ServicioOperacion.pipa ? 2 : null,
  cantidadGarrafones: servicio == ServicioOperacion.garrafones ? 10 : null,
  capacidadPipa: servicio == ServicioOperacion.pipa ? '5mil' : null,
);
Gasto gasto({String id = '2', double monto = 50}) => Gasto(
  id: id,
  fecha: DateTime(2026, 9, 30),
  empleadoId: 'u1',
  monto: monto,
  categoria: CategoriaGasto.combustible,
  descripcion: 'Carga de combustible',
);

void main() {
  test('Los repositorios arrancan vacíos', () async {
    expect(await MemoryUsuarioRepository().obtenerTodos(), isEmpty);
    expect(await MemoryVehiculoRepository().obtenerTodos(), isEmpty);
    final provider = MovimientoProvider();
    await provider.cargar();
    expect(provider.movimientos, isEmpty);
  });
  test('Cálculo por unidad y redondeo de centavos', () {
    expect(calcularImporte(3, 10.25), 30.75);
    expect(calcularImporte(1.5, 120), 180);
    expect(calcularImporte(3, 0.1), 0.3);
    for (final n in [0.0, -1.0, double.nan, double.infinity]) {
      expect(() => calcularImporte(n, 100), throwsArgumentError);
      expect(() => calcularImporte(1, n), throwsArgumentError);
    }
  });
  test('Serialización usa las columnas y enum de la BD', () {
    for (final servicio in [
      ServicioOperacion.pipa,
      ServicioOperacion.garrafones,
    ]) {
      final m = ingreso(servicio: servicio);
      final json = m.toJson();
      expect(json['tipo_servicio'], 'agua');
      expect(Ingreso.fromJson(json).servicio, servicio);
      expect(Ingreso.fromJson(json).monto, m.monto);
      expect(json['nota_url'], isNull);
    }
    final m = gasto();
    expect(Gasto.fromJson(m.toJson()).categoria, CategoriaGasto.combustible);
    expect(m.toJson()['comprobante_url'], isNull);
  });
  test('El periodo incluye todo el último día y excluye el siguiente', () {
    final rows = [
      ingreso(),
      ingreso(id: '3', fecha: DateTime(2026, 10, 1)),
      gasto(),
    ];
    final result = FiltroMovimientos(
      desde: DateTime(2026, 9, 30),
      hasta: DateTime(2026, 9, 30),
    ).aplicar(rows);
    expect(result.map((m) => m.id), ['1', '2']);
    expect(
      const FiltroMovimientos(
        esGasto: true,
        categoria: 'gasto:combustible',
      ).aplicar(rows),
      hasLength(1),
    );
    expect(
      const FiltroMovimientos(vehiculoId: 'v1', busqueda: 'PIPA').aplicar(rows),
      hasLength(2),
    );
  });
  test('Totales mantienen centavos exactos y balance negativo', () {
    final totals = TotalesMovimientos.de([
      ingreso(monto: 0.1),
      ingreso(id: '3', monto: 0.2),
      gasto(monto: 0.5),
    ]);
    expect(totals.ingresos, 0.3);
    expect(totals.gastos, 0.5);
    expect(totals.balance, -0.2);
  });
  test('Crear, editar y eliminar actualiza el estado compartido', () async {
    final provider = MovimientoProvider();
    expect(await provider.guardar(ingreso()), isTrue);
    expect(await provider.guardar(ingreso(monto: 200)), isTrue);
    expect(provider.movimientos, hasLength(1));
    expect(provider.movimientos.single.monto, 200);
    expect(provider.usaEmpleado('u1'), isTrue);
    expect(provider.usaVehiculo('v1'), isTrue);
    expect(await provider.guardar(ingreso(id: 'invalid', monto: -1)), isFalse);
    expect(provider.movimientos, hasLength(1));
    expect(await provider.eliminar('1'), isTrue);
    expect(provider.movimientos, isEmpty);
  });
  test('Excel contiene filas filtradas e importes numéricos', () {
    final exporter = ReporteExporter(
      movimientos: [ingreso(), gasto()],
      empleados: {'u1': 'Responsable de prueba'},
      vehiculos: {'v1': 'UNIDAD'},
      filtros: 'Septiembre',
    );
    final workbook = Excel.decodeBytes(exporter.excel());
    expect(workbook.tables.keys, containsAll(['Resumen', 'Movimientos']));
    final rows = workbook.tables['Movimientos']!.rows;
    expect(rows, hasLength(3));
    expect(rows[1][6]!.value, isA<IntCellValue>());
    expect(rows[1][6]!.value.toString(), '150');
    expect(rows[2][7]!.value.toString(), '50');
    expect(rows[1][3]!.value.toString(), 'UNIDAD');
  });
  test('PDF genera un documento válido con varias páginas', () async {
    final exporter = ReporteExporter(
      movimientos: List.generate(100, (i) => ingreso(id: '$i')),
      empleados: {'u1': 'José Pérez'},
      vehiculos: {'v1': 'UNIDAD'},
      filtros: 'Todas las fechas',
    );
    final bytes = await exporter.pdf();
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(3000));
  });
}
