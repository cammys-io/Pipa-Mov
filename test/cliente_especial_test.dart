import 'package:flutter_test/flutter_test.dart';
import 'package:pipa_mov/models/cliente_especial.dart';
import 'package:pipa_mov/providers/cliente_especial_provider.dart';
import 'package:pipa_mov/data/repositories/cliente_especial_repository.dart';

class MockClienteRepository implements ClienteEspecialRepository {
  final List<ClienteEspecial> items = [];

  @override
  Future<List<ClienteEspecial>> obtenerTodos({bool? activo}) async {
    if (activo != null) {
      return items.where((c) => c.activo == activo).toList();
    }
    return List.from(items);
  }

  @override
  Future<ClienteEspecial> obtenerPorId(String id) async {
    return items.firstWhere((c) => c.id == id);
  }

  @override
  Future<ClienteEspecial> crear(ClienteEspecial cliente) async {
    final nuevo = cliente.copyWith(id: 'uuid-${items.length + 1}');
    items.add(nuevo);
    return nuevo;
  }

  @override
  Future<ClienteEspecial> actualizar(ClienteEspecial cliente) async {
    final idx = items.indexWhere((c) => c.id == cliente.id);
    if (idx >= 0) {
      items[idx] = cliente;
    }
    return cliente;
  }

  @override
  Future<void> eliminar(String id) async {
    items.removeWhere((c) => c.id == id);
  }
}

void main() {
  group('ClienteEspecial Modelo', () {
    test('Serialización y deserialización básica (sin factura)', () {
      final json = {
        'id': 'abc-123',
        'nombreEmpresa': 'Agua Pura El Monte',
        'direccion': 'Calle 5 #10',
        'requiereFactura': false,
        'activo': true,
        'telefono': '9511112233',
      };

      final cliente = ClienteEspecial.fromJson(json);
      expect(cliente.id, 'abc-123');
      expect(cliente.nombreEmpresa, 'Agua Pura El Monte');
      expect(cliente.requiereFactura, false);
      expect(cliente.activo, true);
      expect(cliente.etiqueta, 'Agua Pura El Monte');

      final serialized = cliente.toJson();
      expect(serialized['nombreEmpresa'], 'Agua Pura El Monte');
      expect(serialized['requiereFactura'], false);
      expect(serialized.containsKey('rfc'), false);
    });

    test('Serialización y deserialización con facturación SAT CFDI 4.0', () {
      final json = {
        'id': 'uuid-999',
        'nombreEmpresa': 'Constructora Oaxaca SA',
        'requiereFactura': true,
        'activo': true,
        'rfc': 'COX900101XYZ',
        'razonSocial': 'CONSTRUCTORA OAXACA SA DE CV',
        'regimenFiscal': '601',
        'usoCfdi': 'G03',
        'metodoPago': 'PUE',
        'formaPago': '03',
        'codigoPostal': '68000',
      };

      final cliente = ClienteEspecial.fromJson(json);
      expect(cliente.id, 'uuid-999');
      expect(cliente.requiereFactura, true);
      expect(cliente.rfc, 'COX900101XYZ');
      expect(cliente.regimenFiscal, '601');
      expect(cliente.etiqueta, 'Constructora Oaxaca SA · COX900101XYZ');

      final serialized = cliente.toJson();
      expect(serialized['rfc'], 'COX900101XYZ');
      expect(serialized['regimenFiscal'], '601');
      expect(serialized['usoCfdi'], 'G03');
      expect(serialized['codigoPostal'], '68000');
    });

    test('Catálogos SAT parsean correctamente claves', () {
      expect(SatRegimenFiscal.fromClave('601'), SatRegimenFiscal.r601);
      expect(SatRegimenFiscal.fromClave('626'), SatRegimenFiscal.r626);
      expect(SatUsoCfdi.fromClave('G03'), SatUsoCfdi.g03);
      expect(SatMetodoPago.fromClave('PUE'), SatMetodoPago.pue);
      expect(SatFormaPago.fromClave('03'), SatFormaPago.transferencia);
      expect(SatFormaPago.fromClave('99'), SatFormaPago.porDefinir);
    });
  });

  group('ClienteEspecialProvider', () {
    test('Cargar, crear, actualizar y eliminar clientes', () async {
      final mockRepo = MockClienteRepository();
      final provider = ClienteEspecialProvider(repository: mockRepo);

      expect(provider.clientes.isEmpty, true);

      // 1. Crear
      final creado = await provider.crear(
        const ClienteEspecial(
          id: '',
          nombreEmpresa: 'Hotel Central',
          requiereFactura: true,
          rfc: 'HCE800101AAA',
        ),
      );
      expect(creado, true);
      expect(provider.clientes.length, 1);
      expect(provider.clientes.first.nombreEmpresa, 'Hotel Central');

      // 2. Actualizar
      final cliente = provider.clientes.first;
      final actualizado = await provider.actualizar(
        cliente.copyWith(nombreEmpresa: 'Hotel Central Oaxaca'),
      );
      expect(actualizado, true);
      expect(provider.clientes.first.nombreEmpresa, 'Hotel Central Oaxaca');

      // 3. Eliminar
      final eliminado = await provider.eliminar(cliente.id);
      expect(eliminado, true);
      expect(provider.clientes.isEmpty, true);
    });
  });
}
