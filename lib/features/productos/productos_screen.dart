import 'package:flutter/material.dart';

import '../../data/models/producto.dart';
import '../../data/models/producto_costo.dart';
import '../../data/repositories/producto_costo_repository.dart';
import '../../data/repositories/producto_repository.dart';
import '../../data/repositories/receta_repository.dart';
import 'costos_fijos_screen.dart';
import 'producto_form_dialog.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ProductoRepository _productoRepository = ProductoRepository();
  final ProductoCostoRepository _costoRepository = ProductoCostoRepository();
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
    final costos = producto == null
        ? <ProductoCosto>[]
        : await _costoRepository.getCostosByProducto(producto.id);

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
        costosIniciales: costos,
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
      await _costoRepository.deleteCostosByProducto(producto.id);
    }

    for (final costo in resultado.costos) {
      await _costoRepository.insertProductoCosto(
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

    await _costoRepository.deleteCostosByProducto(producto.id);
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No hay productos registrados.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: productos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final producto = productos[index];
              final costoTotal = producto.costoBase + producto.otrosCostos;

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
                              'Costo base: ${producto.costoBase.toStringAsFixed(2)} Bs',
                            ),
                            Text(
                              'Otros costos: ${producto.otrosCostos.toStringAsFixed(2)} Bs',
                            ),
                            Text(
                              'Costo total: ${costoTotal.toStringAsFixed(2)} Bs',
                            ),
                            Text(
                              'Margen: ${producto.margenGanancia.toStringAsFixed(0)}%',
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
