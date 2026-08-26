import 'package:flutter/material.dart';

import '../../screens/catalogos/catalogos_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../theme/app_theme.dart';

/// Shell principal: sidebar de navegación + contenido.
/// Aquí es donde después colgarías más módulos (Órdenes de servicio,
/// Rutas, Reportes, etc.) según el diagrama de módulos.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = [
    _NavItem('Dashboard', Icons.dashboard_outlined),
    _NavItem('Catálogos y Admin', Icons.inventory_2_outlined),
  ];

  final _pages = const [
    DashboardScreen(),
    CatalogosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              backgroundColor: AppColors.surface,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Icon(Icons.local_shipping,
                    color: AppColors.primary, size: 32),
              ),
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.icon, color: AppColors.primary),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
          if (isWide) const VerticalDivider(width: 1),
          Expanded(child: _pages[_index]),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: _destinations
                  .map((d) => NavigationDestination(
                        icon: Icon(d.icon),
                        label: d.label,
                      ))
                  .toList(),
            ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}
