import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'gastos_tab.dart';
import 'ingresos_tab.dart';

class FinanzasScreen extends StatelessWidget {
  const FinanzasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Finanzas',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                SizedBox(height: 4),
                Text('Gestión de ingresos y gastos',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                SizedBox(height: 20),
                TabBar(
                  indicatorColor: Color(0xFFCBFF3D),
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  tabs: [
                    Tab(text: 'INGRESOS'),
                    Tab(text: 'GASTOS'),
                  ],
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                IngresosTab(),
                GastosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
