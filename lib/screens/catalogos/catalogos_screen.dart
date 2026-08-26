import 'package:flutter/material.dart';

import 'personal/personal_tab.dart';
import 'vehiculos/vehiculos_tab.dart';

/// Módulo "Catálogos y Admin".
/// Requisito 1: dos subtabs, uno para Vehículo y otro para Personal.
class CatalogosScreen extends StatelessWidget {
  const CatalogosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catálogos y Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Vehículos', icon: Icon(Icons.local_shipping)),
              Tab(text: 'Personal', icon: Icon(Icons.badge)),
            ],
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
