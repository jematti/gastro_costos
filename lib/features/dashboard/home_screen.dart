import 'package:flutter/material.dart';

import '../cierre_caja/cierre_caja_screen.dart';
import '../gastos/gastos_screen.dart';
import '../ingredientes/ingredientes_screen.dart';
import '../productos/productos_screen.dart';
import '../productos/costos_fijos_screen.dart';
import '../recetas/recetas_screen.dart';
import '../ventas/ventas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      _ModuleItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        builder: (_) => const _DashboardPlaceholderScreen(),
      ),
      _ModuleItem(
        title: 'Ingredientes',
        icon: Icons.inventory_2_outlined,
        builder: (_) => const IngredientesScreen(),
      ),
      _ModuleItem(
        title: 'Recetas',
        icon: Icons.menu_book_outlined,
        builder: (_) => const RecetasScreen(),
      ),
      _ModuleItem(
        title: 'Productos / Menus',
        icon: Icons.restaurant_menu_outlined,
        builder: (_) => const ProductosScreen(),
      ),
      _ModuleItem(
        title: 'Costos del negocio',
        icon: Icons.account_balance_wallet_outlined,
        builder: (_) => const CostosFijosScreen(),
      ),
      _ModuleItem(
        title: 'Ventas',
        icon: Icons.point_of_sale_outlined,
        builder: (_) => const VentasScreen(),
      ),
      _ModuleItem(
        title: 'Gastos',
        icon: Icons.receipt_long_outlined,
        builder: (_) => const GastosScreen(),
      ),
      _ModuleItem(
        title: 'Cierre de caja',
        icon: Icons.fact_check_outlined,
        builder: (_) => const CierreCajaScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('GastroCostos')),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];

            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: module.builder));
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        module.icon,
                        size: 36,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        module.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModuleItem {
  const _ModuleItem({
    required this.title,
    required this.icon,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;
}

class _DashboardPlaceholderScreen extends StatelessWidget {
  const _DashboardPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(child: Text('Modulo Dashboard')),
    );
  }
}
