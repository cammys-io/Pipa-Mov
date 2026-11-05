import 'package:flutter/material.dart';
import 'personal/personal_tab.dart';
import 'vehiculos/vehiculos_tab.dart';
import 'clientes/clientes_tab.dart';

class CatalogosScreen extends StatelessWidget {
  const CatalogosScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Catálogos y administración'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'Vehículos y maquinaria'),
            Tab(text: 'Personal'),
            Tab(text: 'Clientes especiales'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          VehiculosTab(),
          PersonalTab(),
          ClientesTab(),
        ],
      ),
    ),
  );
}
