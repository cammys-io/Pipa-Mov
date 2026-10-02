import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/catalogos/catalogos_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/finanzas/finanzas_screen.dart';
import '../widgets/app_shell.dart';

/// Crea y configura la instancia de GoRouter.
///
/// Recibe el [AuthProvider] para escuchar sus cambios y redirigir
/// automáticamente si el usuario inicia sesión o hace logout.
GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/dashboard',
    // refreshListenable le dice al router que se vuelva a evaluar (y ejecute el
    // redirect) cada vez que el AuthProvider notifique un cambio.
    refreshListenable: authProvider,
    
    // El redirect global actúa como nuestro Guard. Se ejecuta antes de navegar
    // a cualquier ruta.
    redirect: (context, state) {
      final estaAutenticado = authProvider.estaAutenticado;
      final vaHaciaLogin = state.matchedLocation == '/login';

      // 1. Si NO está autenticado y NO va a la pantalla de login,
      // forzar redirección al login.
      if (!estaAutenticado && !vaHaciaLogin) {
        return '/login';
      }

      // 2. Si YA está autenticado pero intenta ir al login,
      // enviarlo de vuelta al dashboard.
      if (estaAutenticado && vaHaciaLogin) {
        return '/dashboard';
      }

      // 3. No requiere redirección, dejar pasar a la ruta solicitada.
      return null;
    },
    
    routes: [
      // --- Ruta de Login ---
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // --- Rutas protegidas (dentro del Shell) ---
      // StatefulShellRoute mantiene el estado de cada tab al cambiar entre ellas
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // El AppShell ahora es solo el "cascarón" (layout) y navigationShell
          // es el contenido interior que cambia.
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          
          // Branch 1: Catálogos y Admin
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/catalogos',
                builder: (context, state) => const CatalogosScreen(),
              ),
            ],
          ),

          // Branch 2: Finanzas
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/finanzas',
                builder: (context, state) => const FinanzasScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
