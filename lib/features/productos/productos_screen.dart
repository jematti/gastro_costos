import 'package:flutter/material.dart';

import '../../data/models/producto.dart';
import '../../data/models/producto_costo_fijo.dart';
import '../../data/models/producto_costo_variable.dart';
import '../../data/repositories/costo_fijo_repository.dart';
import '../../data/repositories/producto_costo_repository.dart';
import '../../data/repositories/producto_costo_fijo_repository.dart';
import '../../data/repositories/producto_costo_variable_repository.dart';
import '../../data/repositories/producto_repository.dart';
import '../../data/repositories/receta_repository.dart';
import '../../shared/widgets/empty_state.dart';
import 'costos_fijos_screen.dart';
import 'producto_form_dialog.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ProductoRepository _productoRepository = ProductoRepository();
  final ProductoCostoFijoRepository _costoFijoRepository =
      ProductoCostoFijoRepository();
  final ProductoCostoVariableRepository _costoVariableRepository =
      ProductoCostoVariableRepository();
  final ProductoCostoRepository _costoAnteriorRepository =
      ProductoCostoRepository();
  final CostoFijoRepository _costosNegocioRepository = CostoFijoRepository();
  final RecetaRepository _recetaRepository = RecetaRepository();
  late Future<List<Producto>> _productosFuture;

  @override
  void initState() {
    super.initState();
    _productosFuture = _productoRepository.getProductos();
  }

  void _recargarProductos() {
    setState(() {
      _productosFuture = _productoRepository.getProductos();
    });
  }

  Future<void> _abrirFormulario({Producto? producto}) async {
    final recetas = await _recetaRepository.getRecetas();
    final costosNegocio = await _costosNegocioRepository
        .getCostosFijosActivos();
    final costosFijos = producto == null
        ? <ProductoCostoFijo>[]
        : await _costoFijoRepository.getCostosFijosByProducto(producto.id);
    final costosVariables = producto == null
        ? <ProductoCostoVariable>[]
        : await _costoVariableRepository.getCostosVariablesByProducto(
            producto.id,
          );

    if (!mounted) {
      return;
    }

    if (recetas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes crear una receta.')),
      );
      return;
    }

    final resultado = await showDialog<ProductoFormResult>(
      context: context,
      builder: (context) => ProductoFormDialog(
        recetas: recetas,
        producto: producto,
        costosNegocio: costosNegocio,
        costosFijosIniciales: costosFijos,
        costosVariablesIniciales: costosVariables,
      ),
    );

    if (resultado == null) {
      return;
    }

    final productoId = producto == null
        ? await _productoRepository.insertProducto(resultado.producto)
        : producto.id;

    if (producto != null) {
      await _productoRepository.updateProducto(resultado.producto);
      await _costoFijoRepository.deleteCostosFijosByProducto(producto.id);
      await _costoVariableRepository.deleteCostosVariablesByProducto(
        producto.id,
      );
      await _costoAnteriorRepository.deleteCostosByProducto(producto.id);
    }

    for (final costo in resultado.costosFijos) {
      await _costoFijoRepository.insertProductoCostoFijo(
        costo.copyWith(id: 0, productoId: productoId),
      );
    }
    for (final costo in resultado.costosVariables) {
      await _costoVariableRepository.insertProductoCostoVariable(
        costo.copyWith(id: 0, productoId: productoId),
      );
    }

    if (!mounted) {
      return;
    }

    _recargarProductos();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          producto == null ? 'Producto creado' : 'Producto actualizado',
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('Deseas eliminar ${producto.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) {
      return;
    }

    await _costoFijoRepository.deleteCostosFijosByProducto(producto.id);
    await _costoVariableRepository.deleteCostosVariablesByProducto(producto.id);
    await _costoAnteriorRepository.deleteCostosByProducto(producto.id);
    await _productoRepository.deleteProducto(producto.id);

    if (!mounted) {
      return;
    }

    _recargarProductos();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos / Menus'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CostosFijosScreen(),
                ),
              );
            },
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Gestionar costos del negocio'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Producto>>(
        future: _productosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No se pudieron cargar los productos.'),
              ),
            );
          }

          final productos = snapshot.data ?? [];

          if (productos.isEmpty) {
            return const EmptyState(
              icon: Icons.restaurant_menu_outlined,
              message:
                  'No hay productos registrados. Crea tu primer producto o menú.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: productos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final producto = productos[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto.nombre,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text('Receta: ${producto.nombreReceta}'),
                            Text(
                              'Costo total: ${producto.costoTotalProducto.toStringAsFixed(2)} Bs',
                            ),
                            Text(
                              'Sugerido: ${producto.precioVentaSugerido.toStringAsFixed(2)} Bs',
                            ),
                            Text(
                              'Final: ${producto.precioVentaFinal.toStringAsFixed(2)} Bs',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _abrirFormulario(producto: producto),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmarEliminar(producto),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}
