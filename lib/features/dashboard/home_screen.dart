import 'package:flutter/material.dart';

import '../../data/models/cierre_caja.dart';
import '../../data/repositories/cierre_caja_repository.dart';
import '../../data/repositories/gasto_repository.dart';
import '../../data/repositories/producto_repository.dart';
import '../../data/repositories/receta_repository.dart';
import '../../data/repositories/venta_repository.dart';
import '../cierre_caja/cierre_caja_screen.dart';
import '../gastos/gastos_screen.dart';
import '../ingredientes/ingredientes_screen.dart';
import '../productos/costos_fijos_screen.dart';
import '../productos/productos_screen.dart';
import '../recetas/recetas_screen.dart';
import '../ventas/ventas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_DashboardResumen> _resumenFuture;

  @override
  void initState() {
    super.initState();
    _resumenFuture = _cargarResumen();
  }

  Future<void> _refrescar() async {
    setState(() {
      _resumenFuture = _cargarResumen();
    });
    await _resumenFuture;
  }

  Future<_DashboardResumen> _cargarResumen() async {
    final hoy = DateTime.now();
    final ventas = await _safeList(
      () => VentaRepository().getVentasByFecha(hoy),
    );
    final gastos = await _safeList(
      () => GastoRepository().getGastosByFecha(hoy),
    );
    final productos = await _safeList(
      () => ProductoRepository().getProductos(),
    );
    final recetas = await _safeList(() => RecetaRepository().getRecetas());
    final cierres = await _safeList(() => CierreCajaRepository().getCierres());

    final totalVentasHoy = ventas.fold<double>(
      0,
      (sum, venta) => sum + venta.totalVenta,
    );
    final totalCostosHoy = ventas.fold<double>(
      0,
      (sum, venta) => sum + venta.costoTotal,
    );
    final gananciaBrutaHoy = totalVentasHoy - totalCostosHoy;
    final totalGastosHoy = gastos.fold<double>(
      0,
      (sum, gasto) => sum + gasto.monto,
    );
    final gananciaNetaHoy = gananciaBrutaHoy - totalGastosHoy;
    final cierresOrdenados = [...cierres]..sort(_compararCierresRecientes);

    return _DashboardResumen(
      totalVentasHoy: totalVentasHoy,
      totalGastosHoy: totalGastosHoy,
      gananciaBrutaHoy: gananciaBrutaHoy,
      gananciaNetaHoy: gananciaNetaHoy,
      cantidadProductos: productos.length,
      cantidadRecetas: recetas.length,
      ultimoCierre: cierresOrdenados.isEmpty ? null : cierresOrdenados.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final modules = [
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
      appBar: AppBar(
        title: const Text('GastroCostos'),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: _refrescar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refrescar,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Dashboard', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              FutureBuilder<_DashboardResumen>(
                future: _resumenFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final resumen = snapshot.data ?? _DashboardResumen.vacio();

                  return _ResumenGrid(resumen: resumen);
                },
              ),
              const SizedBox(height: 20),
              Text('Accesos', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumenGrid extends StatelessWidget {
  const _ResumenGrid({required this.resumen});

  final _DashboardResumen resumen;

  @override
  Widget build(BuildContext context) {
    final cierre = resumen.ultimoCierre;
    final estadoGanancia = resumen.gananciaNetaHoy < 0
        ? 'Pérdida estimada del día'
        : 'Ganancia estimada del día';

    final cards = [
      _ResumenCardData(
        icono: '💰',
        titulo: 'Ventas hoy',
        valor: _bs(resumen.totalVentasHoy),
      ),
      _ResumenCardData(
        icono: '🧾',
        titulo: 'Gastos hoy',
        valor: _bs(resumen.totalGastosHoy),
      ),
      _ResumenCardData(
        icono: '📊',
        titulo: 'Ganancia bruta hoy',
        valor: _bs(resumen.gananciaBrutaHoy),
      ),
      _ResumenCardData(
        icono: '📈',
        titulo: 'Ganancia neta',
        valor: _bs(resumen.gananciaNetaHoy),
        detalle: estadoGanancia,
      ),
      _ResumenCardData(
        icono: '🍽️',
        titulo: 'Productos',
        valor: resumen.cantidadProductos.toString(),
      ),
      _ResumenCardData(
        icono: '📖',
        titulo: 'Recetas',
        valor: resumen.cantidadRecetas.toString(),
      ),
      _ResumenCardData(
        icono: '🔒',
        titulo: 'Último cierre',
        valor: cierre == null
            ? 'Sin cierres'
            : '${_formatFecha(cierre.fecha)} - ${cierre.horaCierre}',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => _ResumenCard(data: cards[index]),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({required this.data});

  final _ResumenCardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${data.icono} ${data.titulo}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              data.valor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (data.detalle != null) ...[
              const SizedBox(height: 4),
              Text(
                data.detalle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardResumen {
  const _DashboardResumen({
    required this.totalVentasHoy,
    required this.totalGastosHoy,
    required this.gananciaBrutaHoy,
    required this.gananciaNetaHoy,
    required this.cantidadProductos,
    required this.cantidadRecetas,
    required this.ultimoCierre,
  });

  factory _DashboardResumen.vacio() {
    return const _DashboardResumen(
      totalVentasHoy: 0,
      totalGastosHoy: 0,
      gananciaBrutaHoy: 0,
      gananciaNetaHoy: 0,
      cantidadProductos: 0,
      cantidadRecetas: 0,
      ultimoCierre: null,
    );
  }

  final double totalVentasHoy;
  final double totalGastosHoy;
  final double gananciaBrutaHoy;
  final double gananciaNetaHoy;
  final int cantidadProductos;
  final int cantidadRecetas;
  final CierreCaja? ultimoCierre;
}

class _ResumenCardData {
  const _ResumenCardData({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.detalle,
  });

  final String icono;
  final String titulo;
  final String valor;
  final String? detalle;
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

Future<List<T>> _safeList<T>(Future<List<T>> Function() load) async {
  try {
    return await load();
  } catch (_) {
    return <T>[];
  }
}

int _compararCierresRecientes(CierreCaja a, CierreCaja b) {
  final fechaCompare = b.fecha.compareTo(a.fecha);

  if (fechaCompare != 0) {
    return fechaCompare;
  }

  final horaCompare = b.horaCierre.compareTo(a.horaCierre);

  if (horaCompare != 0) {
    return horaCompare;
  }

  return b.id.compareTo(a.id);
}

String _bs(double value) {
  return '${value.toStringAsFixed(2)} Bs';
}

String _formatFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final anio = fecha.year.toString();

  return '$dia/$mes/$anio';
}
