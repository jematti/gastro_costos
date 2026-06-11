import 'package:flutter/material.dart';

import '../../data/models/receta.dart';
import '../../data/repositories/receta_repository.dart';
import 'receta_detalle_screen.dart';

class RecetasScreen extends StatefulWidget {
  const RecetasScreen({super.key});

  @override
  State<RecetasScreen> createState() => _RecetasScreenState();
}

class _RecetasScreenState extends State<RecetasScreen> {
  final RecetaRepository _repository = RecetaRepository();
  late Future<List<Receta>> _recetasFuture;

  @override
  void initState() {
    super.initState();
    _recetasFuture = _repository.getRecetas();
  }

  void _recargarRecetas() {
    setState(() {
      _recetasFuture = _repository.getRecetas();
    });
  }

  Future<void> _abrirDetalle(Receta receta) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecetaDetalleScreen(receta: receta),
      ),
    );

    if (!mounted) {
      return;
    }

    _recargarRecetas();
  }

  Future<void> _abrirFormulario({Receta? receta}) async {
    final resultado = await showDialog<Receta>(
      context: context,
      builder: (context) => _RecetaFormDialog(receta: receta),
    );

    if (resultado == null) {
      return;
    }

    if (receta == null) {
      await _repository.insertReceta(resultado);
    } else {
      await _repository.updateReceta(resultado);
    }

    if (!mounted) {
      return;
    }

    _recargarRecetas();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(receta == null ? 'Receta creada' : 'Receta actualizada'),
      ),
    );
  }

  Future<void> _confirmarEliminar(Receta receta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar receta'),
        content: Text('Deseas eliminar ${receta.nombre}?'),
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

    await _repository.deleteReceta(receta.id);

    if (!mounted) {
      return;
    }

    _recargarRecetas();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Receta eliminada')));
  }

  String _descripcionCorta(String descripcion) {
    final texto = descripcion.trim();

    if (texto.isEmpty) {
      return 'Sin descripción';
    }

    if (texto.length <= 80) {
      return texto;
    }

    return '${texto.substring(0, 80)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recetas')),
      body: FutureBuilder<List<Receta>>(
        future: _recetasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No se pudieron cargar las recetas.'),
              ),
            );
          }

          final recetas = snapshot.data ?? [];

          if (recetas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No hay recetas registradas.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: recetas.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final receta = recetas[index];

              return Card(
                child: ListTile(
                  onTap: () => _abrirDetalle(receta),
                  title: Text(receta.nombre),
                  subtitle: Text(
                    '${_descripcionCorta(receta.descripcion)}\n'
                    'Porciones: ${receta.porciones}\n'
                    'Costo total: ${receta.costoTotal.toStringAsFixed(2)} Bs\n'
                    'Costo por porción: ${receta.costoPorPorcion.toStringAsFixed(2)} Bs',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _abrirFormulario(receta: receta),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmarEliminar(receta),
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

class _RecetaFormDialog extends StatefulWidget {
  const _RecetaFormDialog({this.receta});

  final Receta? receta;

  @override
  State<_RecetaFormDialog> createState() => _RecetaFormDialogState();
}

class _RecetaFormDialogState extends State<_RecetaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _porcionesController;

  @override
  void initState() {
    super.initState();
    final receta = widget.receta;
    _nombreController = TextEditingController(text: receta?.nombre ?? '');
    _descripcionController = TextEditingController(
      text: receta?.descripcion ?? '',
    );
    _porcionesController = TextEditingController(
      text: receta?.porciones.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _porcionesController.dispose();
    super.dispose();
  }

  String? _validarNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }

    return null;
  }

  String? _validarPorciones(String? value) {
    final porciones = int.tryParse(value?.trim() ?? '');

    if (porciones == null || porciones <= 0) {
      return 'Las porciones deben ser mayores a 0';
    }

    return null;
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final receta = widget.receta;
    final porciones = int.parse(_porcionesController.text.trim());
    final costoTotal = receta?.costoTotal ?? 0.0;

    Navigator.of(context).pop(
      Receta(
        id: receta?.id ?? 0,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        porciones: porciones,
        costoTotal: costoTotal,
        costoPorPorcion: costoTotal / porciones,
        fechaRegistro: receta?.fechaRegistro ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.receta == null ? 'Crear receta' : 'Editar receta'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                textInputAction: TextInputAction.next,
                validator: _validarNombre,
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  helperText: 'Opcional',
                ),
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.next,
              ),
              TextFormField(
                controller: _porcionesController,
                decoration: const InputDecoration(labelText: 'Porciones'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: _validarPorciones,
                onFieldSubmitted: (_) => _guardar(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
