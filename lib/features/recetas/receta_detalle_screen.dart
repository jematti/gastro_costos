import 'package:flutter/material.dart';

import '../../data/models/receta.dart';
import '../../data/models/receta_ingrediente.dart';
import '../../data/repositories/receta_ingrediente_repository.dart';
import '../../data/repositories/receta_repository.dart';
import 'agregar_ingrediente_receta_screen.dart';

class RecetaDetalleScreen extends StatefulWidget {
  const RecetaDetalleScreen({super.key, required this.receta});

  final Receta receta;

  @override
  State<RecetaDetalleScreen> createState() => _RecetaDetalleScreenState();
}

class _RecetaDetalleScreenState extends State<RecetaDetalleScreen> {
  final RecetaIngredienteRepository _itemsRepository =
      RecetaIngredienteRepository();
  final RecetaRepository _recetaRepository = RecetaRepository();
  late Receta _receta;
  late Future<List<RecetaIngrediente>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _receta = widget.receta;
    _itemsFuture = _itemsRepository.getIngredientesByReceta(_receta.id);
  }

  void _recargarItems() {
    setState(() {
      _itemsFuture = _itemsRepository.getIngredientesByReceta(_receta.id);
    });
  }

  Future<void> _recalcularCostos() async {
    final costoTotal = await _itemsRepository.calcularCostoTotalReceta(
      _receta.id,
    );
    final costoPorPorcion = _receta.porciones > 0
        ? costoTotal / _receta.porciones
        : 0.0;

    await _recetaRepository.updateCostosReceta(
      _receta.id,
      costoTotal,
      costoPorPorcion,
    );

    setState(() {
      _receta = _receta.copyWith(
        costoTotal: costoTotal,
        costoPorPorcion: costoPorPorcion,
      );
    });
  }

  Future<void> _abrirFormulario({RecetaIngrediente? item}) async {
    if (_receta.porciones <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La receta debe tener porciones mayores a 0'),
        ),
      );
      return;
    }

    final resultado = await Navigator.of(context).push<RecetaIngrediente>(
      MaterialPageRoute(
        builder: (context) =>
            AgregarIngredienteRecetaScreen(recetaId: _receta.id, item: item),
      ),
    );

    if (resultado == null) {
      return;
    }

    if (item == null) {
      await _itemsRepository.insertRecetaIngrediente(resultado);
    } else {
      await _itemsRepository.updateRecetaIngrediente(resultado);
    }

    await _recalcularCostos();

    if (!mounted) {
      return;
    }

    _recargarItems();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item == null ? 'Ingrediente agregado' : 'Ingrediente actualizado',
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(RecetaIngrediente item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ingrediente'),
        content: Text('Deseas quitar ${item.nombreIngrediente} de la receta?'),
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

    await _itemsRepository.deleteRecetaIngrediente(item.id);
    await _recalcularCostos();

    if (!mounted) {
      return;
    }

    _recargarItems();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ingrediente eliminado')));
  }

  String _descripcionReceta() {
    final descripcion = _receta.descripcion.trim();
    return descripcion.isEmpty ? 'Sin descripción' : descripcion;
  }

  String _formatearCantidad(double cantidad) {
    if (cantidad == cantidad.roundToDouble()) {
      return cantidad.toStringAsFixed(0);
    }

    return cantidad.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_receta.nombre)),
      body: FutureBuilder<List<RecetaIngrediente>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _receta.nombre,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(_descripcionReceta()),
              const SizedBox(height: 12),
              Text('Porciones: ${_receta.porciones}'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Agregar ingrediente'),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No se pudieron cargar los ingredientes.'),
                )
              else if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay ingredientes agregados a esta receta.'),
                )
              else
                ...items.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.nombreIngrediente),
                      subtitle: Text(
                        '${_formatearCantidad(item.cantidadUsada)} ${item.unidadUsada} '
                        'x ${item.costoUnitario.toStringAsFixed(2)} Bs '
                        '= ${item.costoTotal.toStringAsFixed(2)} Bs',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _abrirFormulario(item: item),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmarEliminar(item),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Costo total receta: ${_receta.costoTotal.toStringAsFixed(2)} Bs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Costo por porción: ${_receta.costoPorPorcion.toStringAsFixed(2)} Bs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          );
        },
      ),
    );
  }
}
