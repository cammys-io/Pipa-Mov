import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pipa_mov/main.dart';
import 'package:pipa_mov/core/widgets/app_shell.dart';
import 'package:pipa_mov/models/movimiento.dart';
import 'package:pipa_mov/providers/movimiento_provider.dart';
import 'package:pipa_mov/screens/movimientos/movimiento_form_dialog.dart';

Future<void> start(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const PipaMovApp());
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

Future<void> employee(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.inventory_2_outlined));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Personal'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Nuevo empleado'));
  await tester.pumpAndSettle();
  await enter(tester, 'Nombre completo', 'Responsable de prueba');
  await enter(tester, 'Teléfono', '5551234567');
  await enter(tester, 'Número de licencia', 'LIC-TEST');
  await tester.tap(find.text('Guardar'));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets('Todas las pantallas sin datos ni errores a ${size.width}px', (
      tester,
    ) async {
      await start(tester, size);
      expect(find.text('Juan Pérez López'), findsNothing);
      expect(find.text('Resumen general'), findsOneWidget);
      for (final icon in [
        Icons.local_shipping_outlined,
        Icons.receipt_long_outlined,
        Icons.inventory_2_outlined,
        Icons.bar_chart_outlined,
      ]) {
        await tester.tap(find.byIcon(icon).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.scrollUntilVisible(
        find.text('0 registros'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('0 registros'), findsOneWidget);
      final pdf = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Exportar PDF'),
      );
      expect(pdf.onPressed, isNull);
    });
  }
  testWidgets('Personal, ingreso por viaje, edición, gasto y totales', (
    tester,
  ) async {
    await start(tester, const Size(1280, 1000));
    await employee(tester);
    await tester.tap(find.byIcon(Icons.local_shipping_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar operación'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(
        DropdownButtonFormField<String>,
        'Empleado responsable',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Responsable de prueba').last);
    await tester.pumpAndSettle();
    await enter(tester, 'Cantidad de viajes', '3');
    await enter(tester, 'Precio por viaje (MXN)', '250');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final provider = tester
        .element(find.byType(AppShell))
        .read<MovimientoProvider>();
    expect(provider.movimientos, hasLength(1));
    expect(provider.movimientos.single.monto, 750);
    expect((provider.movimientos.single as Ingreso).cantidadViajes, 3);
    // Abrir la edición desde el mismo flujo, incluso en tablas desplazables.
    final row = provider.movimientos.single;
    final context = tester.element(find.byType(AppShell));
    showDialog<void>(
      context: context,
      builder: (_) => MovimientoFormDialog(esGasto: false, movimiento: row),
    );
    await tester.pumpAndSettle();
    await enter(tester, 'Monto total (MXN)', '800');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(provider.movimientos.single.monto, 800);
    await tester.tap(find.byIcon(Icons.receipt_long_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar gasto'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(
        DropdownButtonFormField<String>,
        'Empleado responsable',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Responsable de prueba').last);
    await tester.pumpAndSettle();
    await enter(tester, 'Descripción del gasto', 'Combustible de la jornada');
    await enter(tester, 'Monto total (MXN)', '100');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(provider.movimientos, hasLength(2));
    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();
    expect(find.text(r'$700.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Formulario dinámico y validación en móvil', (tester) async {
    await start(tester, const Size(390, 844));
    await employee(tester);
    await tester.tap(find.byIcon(Icons.local_shipping_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar operación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona un empleado'), findsOneWidget);
    for (final servicio in ServicioOperacion.values) {
      final field = find.byType(DropdownButtonFormField<ServicioOperacion>);
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text(servicio.label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (servicio == ServicioOperacion.retro) {
        expect(find.text('Horas trabajadas'), findsOneWidget);
      }
      if (servicio == ServicioOperacion.garrafones) {
        expect(find.text('Cantidad de garrafones'), findsOneWidget);
      }
    }
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
