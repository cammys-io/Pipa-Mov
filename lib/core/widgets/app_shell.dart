import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  static const _labels = [
    'Inicio',
    'Operaciones',
    'Gastos',
    'Catálogos',
    'Reportes',
    'Notas',
  ];
  static const _icons = [
    Icons.space_dashboard_outlined,
    Icons.local_shipping_outlined,
    Icons.receipt_long_outlined,
    Icons.inventory_2_outlined,
    Icons.bar_chart_outlined,
    Icons.note_alt_outlined,
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final index = navigationShell.currentIndex;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              Container(
                width: 236,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(right: BorderSide(color: AppColors.border)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.water_drop_outlined,
                            color: AppColors.primary,
                            size: 30,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pipa Móv',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 16, 0, 12),
                      child: Text(
                        'ADMINISTRACIÓN',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    for (var i = 0; i < _labels.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            selected: index == i,
                            selectedTileColor: AppColors.subtle,
                            selectedColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            leading: Icon(_icons[i], size: 22),
                            title: Text(_labels[i]),
                            onTap: () => _onTap(i),
                          ),
                        ),
                      ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: const Icon(Icons.logout, size: 22),
                          title: const Text('Cerrar sesión'),
                          onTap: () {
                            context.read<AuthProvider>().logout();
                          },
                        ),
                      ),
                    ),
                    const Text(
                      'Gestión de flotilla y servicios',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              onDestinationSelected: _onTap,
              destinations: [
                for (var i = 0; i < _labels.length; i++)
                  NavigationDestination(
                    icon: Icon(_icons[i]),
                    label: _labels[i],
                  ),
              ],
            ),
    );
  }
}
