import 'package:flutter_test/flutter_test.dart';
import 'package:pipa_mov/models/usuario.dart';

void main() {
  group('Usuario model - campos de autenticación', () {
    test('fromJson parsea email correctamente', () {
      final json = {
        'id': 'uuid-123',
        'nombre': 'Admin Test',
        'rol': 'admin',
        'telefono': '9511234567',
        'estado': 'activo',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'email': 'admin@test.com',
      };

      final usuario = Usuario.fromJson(json);

      expect(usuario.email, 'admin@test.com');
      expect(usuario.password, isNull); // nunca viene del backend
    });

    test('fromJson sin email tiene email null', () {
      final json = {
        'id': 'uuid-456',
        'nombre': 'Chofer Test',
        'rol': 'chofer',
        'telefono': '9510000000',
        'estado': 'activo',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'email': null,
      };

      final usuario = Usuario.fromJson(json);
      expect(usuario.email, isNull);
    });

    test('toCreateJson incluye email y password para admin', () {
      final admin = Usuario(
        id: '',
        nombre: 'Admin Nuevo',
        rol: Rol.admin,
        telefono: '9511111111',
        email: 'admin@montecito.com',
        password: 'secreto123',
      );

      final jsonCreate = admin.toCreateJson();

      expect(jsonCreate['email'], 'admin@montecito.com');
      expect(jsonCreate['password'], 'secreto123');
      expect(jsonCreate['rol'], 'admin');
      expect(jsonCreate.containsKey('id'), isFalse);
      expect(jsonCreate.containsKey('createdAt'), isFalse);
    });

    test('toCreateJson NO incluye email/password vacíos', () {
      final chofer = Usuario(
        id: '',
        nombre: 'Chofer Nuevo',
        rol: Rol.chofer,
        telefono: '9512222222',
        email: null,
        password: null,
      );

      final jsonCreate = chofer.toCreateJson();

      expect(jsonCreate.containsKey('email'), isFalse);
      expect(jsonCreate.containsKey('password'), isFalse);
    });

    test('toCreateJson NO incluye email/password cuando están vacíos (string vacío)', () {
      final usuario = Usuario(
        id: '',
        nombre: 'Test',
        rol: Rol.operador,
        telefono: '9513333333',
        email: '',
        password: '',
      );

      final jsonCreate = usuario.toCreateJson();

      expect(jsonCreate.containsKey('email'), isFalse);
      expect(jsonCreate.containsKey('password'), isFalse);
    });

    test('copyWith actualiza email y password', () {
      final original = Usuario(
        id: 'uuid-1',
        nombre: 'Admin',
        rol: Rol.admin,
        telefono: '9510000000',
        email: 'old@test.com',
      );

      final actualizado = original.copyWith(
        email: 'new@test.com',
        password: 'newpassword',
      );

      expect(actualizado.email, 'new@test.com');
      expect(actualizado.password, 'newpassword');
      expect(actualizado.nombre, 'Admin'); // no cambió
    });

    test('toJson incluye email pero no password', () {
      final admin = Usuario(
        id: 'uuid-1',
        nombre: 'Admin',
        rol: Rol.admin,
        telefono: '9510000000',
        email: 'admin@test.com',
        password: 'secreto',
      );

      final jsonFull = admin.toJson();

      expect(jsonFull['email'], 'admin@test.com');
      // toJson NO debe incluir password (solo para representación interna)
      expect(jsonFull.containsKey('password'), isFalse);
    });
  });
}
