import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pipa_mov/core/widgets/sticky_note_layer.dart';
import 'package:pipa_mov/data/repositories/nota_repository.dart';
import 'package:pipa_mov/models/nota.dart';
import 'package:pipa_mov/providers/auth_provider.dart';
import 'package:pipa_mov/providers/nota_provider.dart';
import 'package:pipa_mov/screens/notas/notas_screen.dart';

class _FakeRepo implements NotaRepository {
  final List<Nota> data;
  bool fallar = false;
  final calls = <String>[];
  _FakeRepo(this.data);

  @override
  Future<List<Nota>> obtenerTodas() async => List.of(data);

  @override
  Future<Nota> crear({
    required String titulo,
    required String descripcion,
    required EstadoNota estatus,
  }) async {
    calls.add('POST $titulo/${estatus.api}');
    final n = Nota(
        id: 'n${data.length + 1}',
        titulo: titulo,
        descripcion: descripcion,
        estatus: estatus,
        createdAt: DateTime.now());
    data.add(n);
    return n;
  }

  @override
  Future<Nota> actualizar(String id,
      {String? titulo, String? descripcion, EstadoNota? estatus}) async {
    calls.add('PATCH $id ${estatus?.api}');
    if (fallar) throw Exception('boom');
    final i = data.indexWhere((n) => n.id == id);
    data[i] = data[i]
        .copyWith(titulo: titulo, descripcion: descripcion, estatus: estatus);
    return data[i];
  }

  @override
  Future<void> eliminar(String id) async {
    calls.add('DELETE $id');
    data.removeWhere((n) => n.id == id);
  }
}

class _AuthOk extends AuthProvider {
  @override
  bool get estaAutenticado => true;
}

Nota _nota(String id, EstadoNota e) => Nota(
    id: id,
    titulo: 'T$id',
    descripcion: 'D$id',
    estatus: e,
    createdAt: DateTime(2026, 1, int.parse(id)));

Widget _app(NotaProvider notas, {Widget? home}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => _AuthOk()),
      ChangeNotifierProvider<NotaProvider>.value(value: notas),
    ],
    child: MaterialApp(
      builder: (context, child) => StickyNoteLayer(child: child),
      home: home ??
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const Scaffold(body: Text('Segunda')))),
                  child: const Text('ir'),
                ),
              ),
            ),
          ),
    ),
  );
}

void main() {
  test('Nota.fromJson mapea estatus del backend', () {
    final n = Nota.fromJson({
      'id': 'x',
      'titulo': 'a',
      'descripcion': 'b',
      'estatus': 'pendiente',
      'createdAt': '2026-01-01T10:00:00.000Z',
    });
    expect(n.estatus, EstadoNota.pendiente);
    expect(n.toBodyJson()['estatus'], 'pendiente');
  });

  group('NotaProvider', () {
    test('completar es optimista y revierte si falla', () async {
      final repo = _FakeRepo([_nota('1', EstadoNota.pendiente)]);
      final p = NotaProvider(repository: repo);
      await p.cargar();

      var f = p.completar('1');
      expect(p.notas.first.estatus, EstadoNota.resuelto); // inmediato
      expect(await f, isNull);
      expect(repo.calls.last, 'PATCH 1 resuelto');

      repo.data[0] = _nota('1', EstadoNota.pendiente);
      await p.cargar();
      repo.fallar = true;
      f = p.completar('1');
      expect(await f, isNotNull);
      expect(p.notas.first.estatus, EstadoNota.pendiente); // revertido
    });

    test('crear y eliminar actualizan la lista local', () async {
      final repo = _FakeRepo([]);
      final p = NotaProvider(repository: repo);
      await p.crear(
          titulo: 'Hola', descripcion: 'x', estatus: EstadoNota.info);
      expect(p.notas.length, 1);
      await p.eliminar(p.notas.first.id);
      expect(p.notas, isEmpty);
    });
  });

  testWidgets('sticky: se abre, se arrastra, persiste al navegar y guarda',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _FakeRepo([]);
    final notas = NotaProvider(repository: repo);
    await tester.pumpWidget(_app(notas));

    expect(find.text('Nueva nota'), findsNothing);
    notas.abrirSticky();
    await tester.pumpAndSettle();
    expect(find.text('Nueva nota'), findsOneWidget);

    // Arrastrar por la cabecera.
    final before = tester.getTopLeft(find.text('Nueva nota'));
    await tester.drag(find.text('Nueva nota'), const Offset(-200, 100));
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(find.text('Nueva nota'));
    expect(after.dx, closeTo(before.dx - 200, 1));
    expect(after.dy, closeTo(before.dy + 100, 1));

    // Navegar a otra ruta: la nota sigue visible.
    await tester.tap(find.text('ir'));
    await tester.pumpAndSettle();
    expect(find.text('Segunda'), findsOneWidget);
    expect(find.text('Nueva nota'), findsOneWidget);

    // Validación y guardado (INFO por defecto).
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Escribe un título'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Mi título');
    await tester.enterText(find.byType(TextFormField).at(1), 'Mi desc');
    await tester.tap(find.text('PENDIENTE'));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.calls, ['POST Mi título/pendiente']);
    expect(notas.notas.length, 1);
    expect(find.text('Nueva nota'), findsNothing); // se cerró
  });

  testWidgets('lista: completar, editar y eliminar', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _FakeRepo([
      _nota('2', EstadoNota.pendiente),
      _nota('1', EstadoNota.info),
    ]);
    final notas = NotaProvider(repository: repo);
    await tester.pumpWidget(_app(notas, home: const NotasScreen()));
    await tester.pumpAndSettle();

    expect(find.text('T1'), findsOneWidget);
    expect(find.byTooltip('Marcar como resuelta'), findsOneWidget);

    // Completar
    await tester.tap(find.byTooltip('Marcar como resuelta'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Marcar como resuelta'), findsNothing);
    expect(repo.calls.last, 'PATCH 2 resuelto');

    // Editar
    await tester.tap(find.byTooltip('Editar').first);
    await tester.pumpAndSettle();
    expect(find.text('Editar nota'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Editada');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Editada'), findsOneWidget);

    // Eliminar (con confirmación)
    await tester.tap(find.byTooltip('Eliminar').first);
    await tester.pumpAndSettle();
    expect(find.text('Eliminar nota'), findsOneWidget);
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, startsWith('DELETE'));
    expect(notas.notas.length, 1);
  });
}
