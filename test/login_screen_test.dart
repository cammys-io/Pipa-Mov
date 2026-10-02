import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pipa_mov/providers/auth_provider.dart';
import 'package:pipa_mov/screens/auth/login_screen.dart';
import 'package:pipa_mov/data/api/api_auth_service.dart';
import 'package:pipa_mov/data/api/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Helper que genera un JWT mock válido para testing.
String _buildMockJwt() {
  final header = base64Url.encode(utf8.encode(json.encode({
    'alg': 'HS256',
    'typ': 'JWT',
  })));
  final payload = base64Url.encode(utf8.encode(json.encode({
    'sub': 'test-uuid',
    'email': 'admin@test.com',
    'rol': 'admin',
    'iat': 1700000000,
    'exp': 1700086400,
  })));
  return '$header.$payload.dummy-sig';
}

/// Envuelve el LoginScreen con MaterialApp y AuthProvider para testing.
Widget _buildTestApp({ApiAuthService? authService}) {
  return MaterialApp(
    home: ChangeNotifierProvider(
      create: (_) => AuthProvider(authService: authService),
      child: const LoginScreen(),
    ),
  );
}

void main() {
  tearDown(() => ApiConfig.setToken(null));

  group('LoginScreen Widget Tests', () {
    testWidgets('muestra campos de email, password y botón entrar',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('muestra branding de Agua El Montecito', (tester) async {
      // Usar un tamaño ancho para ver el panel decorativo
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp());

      expect(find.textContaining('Montecito'), findsOneWidget);
    });

    testWidgets('validación: campos vacíos muestran errores', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      // Tap en Entrar sin llenar campos
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa tu correo'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    });

    testWidgets('validación: email sin @ muestra error', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Correo electrónico'),
          'notanemail');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Contraseña'), 'pass123');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Correo no válido'), findsOneWidget);
    });

    testWidgets('toggle de visibilidad de contraseña funciona',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());

      // Inicialmente el password está oculto
      final passwordField = find.widgetWithText(TextFormField, 'Contraseña');
      expect(passwordField, findsOneWidget);

      // Buscar el botón de toggle (icono de ojo)
      final visibilityToggle = find.byIcon(Icons.visibility_off);
      expect(visibilityToggle, findsOneWidget);

      // Tap para mostrar
      await tester.tap(visibilityToggle);
      await tester.pump();

      // Ahora debe mostrar el icono de visibility (ojo abierto)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('login exitoso no muestra error', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'access_token': _buildMockJwt()}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = ApiAuthService(client: mockClient);
      await tester.pumpWidget(_buildTestApp(authService: authService));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Correo electrónico'),
          'admin@test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Contraseña'), 'password123');

      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      // No debe haber error snackbar visible
      expect(find.text('Error al iniciar sesión'), findsNothing);
    });

    testWidgets('login fallido muestra snackbar con error', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'message': 'Correo o contraseña incorrectos',
            'statusCode': 401,
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = ApiAuthService(client: mockClient);
      await tester.pumpWidget(_buildTestApp(authService: authService));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Correo electrónico'),
          'admin@test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Contraseña'), 'wrongpass');

      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      // Debe mostrar el snackbar con el mensaje de error
      expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    });
  });
}
