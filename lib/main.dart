import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/sticky_note_layer.dart';
import 'providers/auth_provider.dart';
import 'providers/nota_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/movimiento_provider.dart';
import 'providers/vehiculo_provider.dart';

import 'data/api/api_vehiculo_repository.dart';
import 'data/api/api_usuario_repository.dart';
import 'data/api/api_movimiento_repository.dart';
import 'data/api/api_estadisticas_repository.dart';
import 'providers/estadisticas_provider.dart';

void main() {
  runApp(const PipaMovApp());
}

class PipaMovApp extends StatelessWidget {
  const PipaMovApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VehiculoProvider(repository: ApiVehiculoRepository())),
        ChangeNotifierProvider(create: (_) => UsuarioProvider(repository: ApiUsuarioRepository())),
        ChangeNotifierProvider(create: (_) => MovimientoProvider(repository: ApiMovimientoRepository())),
        ChangeNotifierProvider(create: (_) => EstadisticasProvider(repository: ApiEstadisticasRepository())),
        ChangeNotifierProvider(create: (_) => NotaProvider()),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.read<AuthProvider>();
          final router = buildRouter(authProvider);

          return MaterialApp.router(
            title: 'Pipa Móv',
            locale: const Locale('es', 'MX'),
            supportedLocales: const [Locale('es', 'MX')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            routerConfig: router,
            builder: (context, child) => StickyNoteLayer(child: child),
          );
        },
      ),
    );
  }
}
