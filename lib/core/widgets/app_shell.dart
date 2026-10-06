import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/nota_provider.dart';
import '../theme/app_theme.dart';

const _accent = Color(0xFFCBFF3D);
const _darkPanel = Color(0xFF16212B);

const _destinationsList = [
  _NavItem('Dashboard', Icons.dashboard_rounded),
  _NavItem('Catálogos y Admin', Icons.inventory_2_rounded),
  _NavItem('Finanzas', Icons.attach_money_rounded),
  _NavItem('Notas', Icons.sticky_note_2_rounded),
];

/// Shell principal: sidebar de navegación + contenido.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _onNavigate(int index) {
    navigationShell.goBranch(
      index,
      // Soporta "volver al inicio" del tab si tocas el mismo ícono de nuevo
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isWide)
            _Sidebar(
                index: navigationShell.currentIndex,
                onSelect: _onNavigate),
          Expanded(
            child: Column(
              children: [
                // AppBar compacto con logout solo en pantallas angostas
                if (!isWide)
                  Container(
                    color: _darkPanel,
                    padding: const EdgeInsets.only(
                        left: 16, right: 4, top: 8, bottom: 8),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_rounded,
                              color: _accent, size: 20),
                          const SizedBox(width: 8),
                          const Text('Pipas',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.note_add_rounded,
                                color: _accent, size: 20),
                            tooltip: 'Crear nota',
                            onPressed: () =>
                                context.read<NotaProvider>().abrirSticky(),
                          ),
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) => IconButton(
                              icon: const Icon(Icons.logout_rounded,
                                  color: Colors.white54, size: 20),
                              tooltip: 'Cerrar sesión',
                              onPressed: () => auth.logout(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : Container(
              decoration: BoxDecoration(
                color: _darkPanel,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: Colors.transparent,
                  indicatorColor: _accent,
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : Colors.white54,
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return IconThemeData(
                        color: selected ? Colors.black : Colors.white54);
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onNavigate,
                  destinations: _destinationsList
                      .map((d) => NavigationDestination(
                            icon: Icon(d.icon),
                            label: d.label,
                          ))
                      .toList(),
                ),
              ),
            ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _Sidebar({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: _darkPanel,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Pipas',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          for (var i = 0; i < _destinationsList.length; i++) ...[
            _RailItem(
              item: _destinationsList[i],
              selected: i == index,
              onTap: () => onSelect(i),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.read<NotaProvider>().abrirSticky(),
            icon: const Icon(Icons.note_add_rounded, size: 18),
            label: const Text('Nueva nota'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: BorderSide(color: _accent.withValues(alpha: 0.5)),
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const Spacer(),
          // Sección de logout
          Consumer<AuthProvider>(
            builder: (context, auth, _) => Column(
              children: [
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: _accent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        auth.email ?? 'Admin',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.white54, size: 20),
                      tooltip: 'Cerrar sesión',
                      onPressed: () => _confirmarLogout(context, auth),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _darkPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('¿Estás seguro de que deseas salir?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.white60),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _RailItem(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(item.icon,
                  size: 20, color: selected ? Colors.black : Colors.white60),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white70,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}
