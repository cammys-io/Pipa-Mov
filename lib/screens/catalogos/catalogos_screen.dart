import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'personal/personal_tab.dart';
import 'vehiculos/vehiculos_tab.dart';

const _accent = Color.fromARGB(255, 61, 168, 255);
const _darkPanel = Color(0xFF16212B);

/// Módulo "Catálogos y Admin".
/// Requisito 1: dos subtabs, uno para Vehículo y otro para Personal.
class CatalogosScreen extends StatelessWidget {
  const CatalogosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Catálogos y Admin'),
          toolbarHeight: 64,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _darkPanel,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  splashBorderRadius: BorderRadius.all(Radius.circular(10)),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white70,
                  labelStyle:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: [
                    Tab(
                      height: 42,
                      icon: Icon(Icons.local_shipping_rounded, size: 18),
                      iconMargin: EdgeInsets.only(bottom: 2),
                      text: 'Vehículos',
                    ),
                    Tab(
                      height: 42,
                      icon: Icon(Icons.badge_rounded, size: 18),
                      iconMargin: EdgeInsets.only(bottom: 2),
                      text: 'Personal',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            VehiculosTab(),
            PersonalTab(),
          ],
        ),
      ),
    );
  }
}
