import 'package:flutter/material.dart';
import 'personal/personal_tab.dart';
import 'vehiculos/vehiculos_tab.dart';

class CatalogosScreen extends StatelessWidget {
  const CatalogosScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Catálogos y administración'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Vehículos y maquinaria'),
            Tab(text: 'Personal'),
          ],
        ),
      ),
      body: const TabBarView(children: [VehiculosTab(), PersonalTab()]),
    ),
  );
}
