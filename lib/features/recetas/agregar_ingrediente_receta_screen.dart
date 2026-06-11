import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/helpers/ingredient_icon_helper.dart';
import '../../data/models/ingrediente.dart';
import '../../data/models/receta_ingrediente.dart';
import '../../data/repositories/ingrediente_repository.dart';

const List<String> unidadesMedida = [
  'libra',
  'kilo',
  'gramo',
  'arroba',
  'quintal',
  'litro',
  'mililitro',
  'unidad',
  'docena',
  'paquete',
  'bolsa',
  'lata',
  'botella',
  'caja',
  'manojo',
  'amarro',
  'plato',
  'porción',
];

class AgregarIngredienteRecetaScreen extends StatefulWidget {
  const AgregarIngredienteRecetaScreen({
    super.key,
    required this.recetaId,
    this.item,
  });

  final int recetaId;
  final RecetaIngrediente? item;

  @override
  State<AgregarIngredienteRecetaScreen> createState() =>
      _AgregarIngredienteRecetaScreenState();
}

class _AgregarIngredienteRecetaScreenState
    extends State<AgregarIngredienteRecetaScreen> {
  final IngredienteRepository _ingredienteRepository = IngredienteRepository();
  final TextEditingController _buscarController = TextEditingController();
  final TextEditingController _costoController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Ingrediente> _ingredientes = [];
  List<Ingrediente> _ingredientesFiltrados = [];
  Ingrediente? _ingredienteSeleccionado;
  String _unidadUsada = 'unidad';
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscarController.addListener(_filtrarIngredientes);
    _costoController.addListener(_actualizarSubtotal);
    _cantidadController.addListener(_actualizarSubtotal);
    _cantidadController.text = widget.item?.cantidadUsada.toString() ?? '';
    _costoController.text = widget.item?.costoUnitario.toString() ?? '';
    _unidadUsada = _normalizarUnidad(widget.item?.unidadUsada);
    _cargarIngredientes();
  }

  @override
  void dispose() {
    _buscarController.removeListener(_filtrarIngredientes);
    _costoController.removeListener(_actualizarSubtotal);
    _cantidadController.removeListener(_actualizarSubtotal);
    _buscarController.dispose();
    _costoController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _cargarIngredientes() async {
    try {
      final ingredientes = await _ingredienteRepository.getIngredientes();
      final item = widget.item;
      Ingrediente? seleccionado;

      if (item != null && ingredientes.isNotEmpty) {
        for (final ingrediente in ingredientes) {
          if (ingrediente.id == item.ingredienteId) {
            seleccionado = ingrediente;
            break;
          }
        }
      }

      setState(() {
        _ingredientes = ingredientes;
        _ingredientesFiltrados = ingredientes;
        _ingredienteSeleccionado = seleccionado;
        if (seleccionado != null) {
          _unidadUsada = _unidadInicialIngrediente(
            seleccionado,
            unidadGuardada: item?.unidadUsada,
          );
        }
        _cargando = false;
      });
    } catch (_) {
      setState(() {
        _error = 'No se pudieron cargar los ingredientes.';
        _cargando = false;
      });
    }
  }

  void _filtrarIngredientes() {
    final query = _buscarController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _ingredientesFiltrados = _ingredientes;
      } else {
        _ingredientesFiltrados = _ingredientes
            .where(
              (ingrediente) => ingrediente.nombre.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  void _actualizarSubtotal() {
    setState(() {});
  }

  void _seleccionarIngrediente(Ingrediente ingrediente) {
    setState(() {
      _ingredienteSeleccionado = ingrediente;
      _unidadUsada = _unidadInicialIngrediente(ingrediente);
      _costoController.text = ingrediente.costoPorUnidadBase.toString();
    });
  }

  String _normalizarUnidad(String? unidad) {
    final value = unidad?.trim().toLowerCase() ?? '';

    switch (value) {
      case 'kg':
      case 'kgs':
      case 'kilos':
      case 'kilogramo':
      case 'kilogramos':
        return 'kilo';
      case 'gr':
      case 'g':
      case 'gramos':
        return 'gramo';
      case 'l':
      case 'lt':
      case 'lts':
      case 'litros':
        return 'litro';
      case 'ml':
      case 'mililitros':
        return 'mililitro';
      case 'lb':
      case 'lbs':
      case 'libras':
        return 'libra';
      case 'porcion':
      case 'porciÃ³n':
      case 'porciones':
        return 'porción';
      default:
        return unidadesMedida.contains(value) ? value : 'unidad';
    }
  }

  String _unidadInicialIngrediente(
    Ingrediente ingrediente, {
    String? unidadGuardada,
  }) {
    if (unidadGuardada != null) {
      final guardada = _normalizarUnidad(unidadGuardada);
      if (unidadesMedida.contains(guardada)) {
        return guardada;
      }
    }

    final unidadCompra = _normalizarUnidad(ingrediente.unidadCompra);
    if (unidadesMedida.contains(unidadCompra)) {
      return unidadCompra;
    }

    final unidadBase = _normalizarUnidad(ingrediente.unidadBase);
    if (unidadesMedida.contains(unidadBase)) {
      return unidadBase;
    }

    return 'unidad';
  }

  double? _leerDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  double? get _subtotal {
    final costoUnitario = _leerDouble(_costoController.text);
    final cantidadUsada = _leerDouble(_cantidadController.text);

    if (costoUnitario == null || cantidadUsada == null) {
      return null;
    }

    return costoUnitario * cantidadUsada;
  }

  String? _validarCosto(String? value) {
    final costo = _leerDouble(value ?? '');

    if (costo == null || costo <= 0) {
      return 'El costo usado debe ser mayor a 0';
    }

    return null;
  }

  String? _validarCantidad(String? value) {
    final cantidad = _leerDouble(value ?? '');

    if (cantidad == null || cantidad <= 0) {
      return 'La cantidad usada debe ser mayor a 0';
    }

    return null;
  }

  void _guardar() {
    final ingrediente = _ingredienteSeleccionado;

    if (ingrediente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un ingrediente')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final costoUnitario = _leerDouble(_costoController.text)!;
    final cantidadUsada = _leerDouble(_cantidadController.text)!;
    final costoTotal = costoUnitario * cantidadUsada;
    final item = widget.item;

    Navigator.of(context).pop(
      RecetaIngrediente(
        id: item?.id ?? 0,
        recetaId: widget.recetaId,
        ingredienteId: ingrediente.id,
        nombreIngrediente: ingrediente.nombre,
        cantidadUsada: cantidadUsada,
        unidadUsada: _normalizarUnidad(_unidadUsada),
        costoUnitario: costoUnitario,
        costoTotal: costoTotal,
        fechaRegistro: item?.fechaRegistro ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seleccionado = _ingredienteSeleccionado;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Agregar ingrediente' : 'Editar ingrediente',
        ),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(seleccionado),
      ),
      bottomNavigationBar: seleccionado == null || _ingredientes.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _guardar,
                  child: const Text('Guardar'),
                ),
              ),
            ),
    );
  }

  Widget _buildContent(Ingrediente? seleccionado) {
    if (_error != null) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
      );
    }

    if (_ingredientes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No hay ingredientes registrados. Primero agrega ingredientes.',
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _buscarController,
            decoration: const InputDecoration(
              labelText: 'Buscar ingrediente',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _ingredientesFiltrados.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final ingrediente = _ingredientesFiltrados[index];
              final selected = seleccionado?.id == ingrediente.id;

              return Card(
                color: selected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  leading: _IngredientAvatar(ingrediente: ingrediente),
                  title: Text(ingrediente.nombre),
                  subtitle: Text(
                    '${ingrediente.costoPorUnidadBase.toStringAsFixed(2)} Bs / ${_normalizarUnidad(ingrediente.unidadBase)}',
                  ),
                  onTap: () => _seleccionarIngrediente(ingrediente),
                ),
              );
            },
          ),
        ),
        if (_ingredientesFiltrados.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No se encontraron ingredientes.'),
          ),
        if (seleccionado != null)
          _UsoIngredienteForm(
            formKey: _formKey,
            ingrediente: seleccionado,
            costoController: _costoController,
            cantidadController: _cantidadController,
            unidadUsada: _normalizarUnidad(_unidadUsada),
            subtotal: _subtotal,
            normalizarUnidad: _normalizarUnidad,
            onUnidadChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _unidadUsada = _normalizarUnidad(value);
              });
            },
            validarCosto: _validarCosto,
            validarCantidad: _validarCantidad,
          ),
      ],
    );
  }
}

class _UsoIngredienteForm extends StatelessWidget {
  const _UsoIngredienteForm({
    required this.formKey,
    required this.ingrediente,
    required this.costoController,
    required this.cantidadController,
    required this.unidadUsada,
    required this.subtotal,
    required this.normalizarUnidad,
    required this.onUnidadChanged,
    required this.validarCosto,
    required this.validarCantidad,
  });

  final GlobalKey<FormState> formKey;
  final Ingrediente ingrediente;
  final TextEditingController costoController;
  final TextEditingController cantidadController;
  final String unidadUsada;
  final double? subtotal;
  final String Function(String?) normalizarUnidad;
  final ValueChanged<String?> onUnidadChanged;
  final String? Function(String?) validarCosto;
  final String? Function(String?) validarCantidad;

  @override
  Widget build(BuildContext context) {
    final unidadInicial = unidadesMedida.contains(unidadUsada)
        ? unidadUsada
        : 'unidad';

    return Material(
      elevation: 6,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ingrediente.nombre,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Costo registrado: ${ingrediente.costoPorUnidadBase.toStringAsFixed(2)} Bs / ${normalizarUnidad(ingrediente.unidadBase)}',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: costoController,
                      decoration: const InputDecoration(
                        labelText: 'Costo usado en esta receta',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: validarCosto,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: cantidadController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad usada',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: validarCantidad,
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                key: ValueKey('unidad-usada-$unidadInicial'),
                initialValue: unidadInicial,
                decoration: const InputDecoration(labelText: 'Unidad usada'),
                items: unidadesMedida
                    .toSet()
                    .map(
                      (unidad) =>
                          DropdownMenuItem(value: unidad, child: Text(unidad)),
                    )
                    .toList(),
                onChanged: onUnidadChanged,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La unidad usada es obligatoria';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                subtotal == null
                    ? 'Subtotal: -'
                    : 'Subtotal: ${subtotal!.toStringAsFixed(2)} Bs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientAvatar extends StatelessWidget {
  const _IngredientAvatar({required this.ingrediente});

  final Ingrediente ingrediente;

  @override
  Widget build(BuildContext context) {
    final imagePath = ingrediente.imagePath;

    if (imagePath != null && imagePath.trim().isNotEmpty) {
      final file = File(imagePath);

      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _EmojiAvatar(nombre: ingrediente.nombre),
          ),
        );
      }
    }

    return _EmojiAvatar(nombre: ingrediente.nombre);
  }
}

class _EmojiAvatar extends StatelessWidget {
  const _EmojiAvatar({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: CircleAvatar(
        child: Text(
          getIngredientEmoji(nombre),
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
