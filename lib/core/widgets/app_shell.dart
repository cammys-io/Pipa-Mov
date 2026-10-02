import 'package:flutter/material.dart';
import '../../screens/catalogos/catalogos_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/movimientos/movimientos_screen.dart';
import '../../screens/reportes/reportes_screen.dart';
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  static const _labels = [
    'Inicio',
    'Operaciones',
    'Gastos',
    'Catálogos',
    'Reportes',
  ];
  static const _icons = [
    Icons.space_dashboard_outlined,
    Icons.local_shipping_outlined,
    Icons.receipt_long_outlined,
    Icons.inventory_2_outlined,
    Icons.bar_chart_outlined,
  ];
  Widget get _page => switch (_index) {
    0 => const DashboardScreen(),
    1 => const MovimientosScreen(esGasto: false),
    2 => const MovimientosScreen(esGasto: true),
    3 => const CatalogosScreen(),
    _ => const ReportesScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
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
                            selected: _index == i,
                            selectedTileColor: AppColors.subtle,
                            selectedColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            leading: Icon(_icons[i], size: 22),
                            title: Text(_labels[i]),
                            onTap: () => setState(() => _index = i),
                          ),
                        ),
                      ),
                    const Spacer(),
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
            Expanded(
              child: KeyedSubtree(key: ValueKey(_index), child: _page),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              onDestinationSelected: (i) => setState(() => _index = i),
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
