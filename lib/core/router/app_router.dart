
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/catalogos/catalogos_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/movimientos/movimientos_screen.dart';
import '../../screens/reportes/reportes_screen.dart';
import '../../screens/notas/notas_screen.dart';
import '../widgets/app_shell.dart';

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final estaAutenticado = authProvider.estaAutenticado;
      final vaHaciaLogin = state.matchedLocation == '/login';
      if (!estaAutenticado && !vaHaciaLogin) return '/login';
      if (estaAutenticado && vaHaciaLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/operaciones',
                builder: (context, state) =>
                    const MovimientosScreen(esGasto: false),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/gastos',
                builder: (context, state) =>
                    const MovimientosScreen(esGasto: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/catalogos',
                builder: (context, state) => const CatalogosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reportes',
                builder: (context, state) => const ReportesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notas',
                builder: (context, state) => const NotasScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
