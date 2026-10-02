import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';
import 'providers/usuario_provider.dart';
import 'providers/movimiento_provider.dart';
import 'providers/vehiculo_provider.dart';

void main() {
  runApp(const PipaMovApp());
}

class PipaMovApp extends StatelessWidget {
  const PipaMovApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // TODO: al conectar el backend NestJS, pasa el repositorio real,
        // p.ej. VehiculoProvider(repository: ApiVehiculoRepository(dio)).
        ChangeNotifierProvider(create: (_) => VehiculoProvider()),
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => MovimientoProvider()),
      ],
      child: MaterialApp(
        title: 'Pipa Móv',
        locale: const Locale('es', 'MX'),
        supportedLocales: const [Locale('es', 'MX')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AppShell(),
      ),
    );
  }
}
