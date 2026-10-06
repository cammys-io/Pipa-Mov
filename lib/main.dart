import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/sticky_note_layer.dart';
import 'data/api/api_usuario_repository.dart';
import 'data/api/api_vehiculo_repository.dart';
import 'data/api/api_gasto_repository.dart';
import 'data/api/api_ingreso_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/vehiculo_provider.dart';
import 'providers/gasto_provider.dart';
import 'providers/ingreso_provider.dart';
import 'providers/estadisticas_provider.dart';
import 'providers/nota_provider.dart';

void main() {
  runApp(const PipaMovApp());
}

class PipaMovApp extends StatelessWidget {
  const PipaMovApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthProvider debe ir primero porque los demás providers
        // dependen del token JWT para hacer peticiones autenticadas.
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Repositorios API reales que consumen el backend NestJS.
        ChangeNotifierProvider(
          create: (_) => VehiculoProvider(repository: ApiVehiculoRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => UsuarioProvider(repository: ApiUsuarioRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => GastoProvider(repository: ApiGastoRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => IngresoProvider(repository: ApiIngresoRepository()),
        ),
        ChangeNotifierProvider(create: (_) => EstadisticasProvider()),
        ChangeNotifierProvider(create: (_) => NotaProvider()),
      ],
      // Se usa un Builder para poder acceder al AuthProvider
      // e inyectarlo en la configuración del router.
      child: Builder(
        builder: (context) {
          final authProvider = context.read<AuthProvider>();
          final router = buildRouter(authProvider);

          return MaterialApp.router(
            title: 'Pipa Mov',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            locale: const Locale('es'),
            supportedLocales: const [Locale('es'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
            // El builder envuelve al Navigator: lo que se pinte aquí queda
            // por encima de TODAS las rutas y persiste al navegar.
            builder: (context, child) => StickyNoteLayer(child: child),
          );
        },
      ),
    );
  }
}
