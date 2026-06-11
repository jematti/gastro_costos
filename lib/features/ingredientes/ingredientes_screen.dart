import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../core/helpers/ingredient_icon_helper.dart';
import '../../data/models/ingrediente.dart';
import '../../data/repositories/ingrediente_repository.dart';

const List<String> _unidades = [
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

class IngredientesScreen extends StatefulWidget {
  const IngredientesScreen({super.key});

  @override
  State<IngredientesScreen> createState() => _IngredientesScreenState();
}

class _IngredientesScreenState extends State<IngredientesScreen> {
  final IngredienteRepository _repository = IngredienteRepository();
  late Future<List<Ingrediente>> _ingredientesFuture;

  @override
  void initState() {
    super.initState();
    _ingredientesFuture = _repository.getIngredientes();
  }

  void _recargarIngredientes() {
    setState(() {
      _ingredientesFuture = _repository.getIngredientes();
    });
  }

  Future<void> _abrirFormulario({Ingrediente? ingrediente}) async {
    final resultado = await showDialog<Ingrediente>(
      context: context,
      builder: (context) => _IngredienteFormDialog(ingrediente: ingrediente),
    );

    if (resultado == null) {
      return;
    }

    if (ingrediente == null) {
      await _repository.insertIngrediente(resultado);
    } else {
      await _repository.updateIngrediente(resultado);
    }

    if (!mounted) {
      return;
    }

    _recargarIngredientes();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ingrediente == null
              ? 'Ingrediente registrado'
              : 'Ingrediente actualizado',
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(Ingrediente ingrediente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ingrediente'),
        content: Text('Deseas eliminar ${ingrediente.nombre}?'),
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

    await _repository.deleteIngrediente(ingrediente.id);

    if (!mounted) {
      return;
    }

    _recargarIngredientes();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ingrediente eliminado')));
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
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
      appBar: AppBar(title: const Text('Ingredientes')),
      body: FutureBuilder<List<Ingrediente>>(
        future: _ingredientesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No se pudieron cargar los ingredientes.'),
              ),
            );
          }

          final ingredientes = snapshot.data ?? [];

          if (ingredientes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No hay ingredientes registrados.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ingredientes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final ingrediente = ingredientes[index];

              return Card(
                child: ListTile(
                  leading: _IngredientImagePreview(
                    nombre: ingrediente.nombre,
                    imagePath: ingrediente.imagePath,
                    size: 56,
                  ),
                  title: Text(ingrediente.nombre),
                  subtitle: Text(
                    'Compra: ${ingrediente.precioCompra.toStringAsFixed(2)} Bs '
                    'por ${_formatearCantidad(ingrediente.cantidadCompra)} '
                    '${ingrediente.unidadCompra}\n'
                    'Costo unitario: ${ingrediente.costoPorUnidadBase.toStringAsFixed(2)} '
                    'Bs / ${ingrediente.unidadBase}\n'
                    'Fecha de compra: ${_formatearFecha(ingrediente.fechaCompra)}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _abrirFormulario(ingrediente: ingrediente),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmarEliminar(ingrediente),
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

class _IngredienteFormDialog extends StatefulWidget {
  const _IngredienteFormDialog({this.ingrediente});

  final Ingrediente? ingrediente;

  @override
  State<_IngredienteFormDialog> createState() => _IngredienteFormDialogState();
}

class _IngredienteFormDialogState extends State<_IngredienteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nombreController;
  late final TextEditingController _precioCompraController;
  late final TextEditingController _cantidadCompraController;
  late String _unidadCompra;
  late String _unidadBase;
  late DateTime _fechaCompra;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    final ingrediente = widget.ingrediente;
    _nombreController = TextEditingController(text: ingrediente?.nombre ?? '');
    _precioCompraController = TextEditingController(
      text: ingrediente?.precioCompra.toString() ?? '',
    );
    _cantidadCompraController = TextEditingController(
      text: ingrediente?.cantidadCompra.toString() ?? '',
    );
    _unidadCompra = _unidadValida(ingrediente?.unidadCompra) ?? 'libra';
    _unidadBase = _unidadCompra;
    _fechaCompra = ingrediente?.fechaCompra ?? DateTime.now();
    _imagePath = _normalizarImagePath(ingrediente?.imagePath);

    _nombreController.addListener(_actualizarCalculo);
    _precioCompraController.addListener(_actualizarCalculo);
    _cantidadCompraController.addListener(_actualizarCalculo);
  }

  @override
  void dispose() {
    _nombreController.removeListener(_actualizarCalculo);
    _precioCompraController.removeListener(_actualizarCalculo);
    _cantidadCompraController.removeListener(_actualizarCalculo);
    _nombreController.dispose();
    _precioCompraController.dispose();
    _cantidadCompraController.dispose();
    super.dispose();
  }

  String? _unidadValida(String? unidad) {
    if (unidad == null || !_unidades.contains(unidad)) {
      return null;
    }

    return unidad;
  }

  String? _normalizarImagePath(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return null;
    }

    return imagePath;
  }

  void _actualizarCalculo() {
    setState(() {});
  }

  double? _leerDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  double? get _costoPorUnidadBase {
    final precioCompra = _leerDouble(_precioCompraController.text);
    final cantidadCompra = _leerDouble(_cantidadCompraController.text);

    if (precioCompra == null || cantidadCompra == null || cantidadCompra <= 0) {
      return null;
    }

    return precioCompra / cantidadCompra;
  }

  String? _validarTexto(String? value, String campo) {
    if (value == null || value.trim().isEmpty) {
      return '$campo es obligatorio';
    }

    return null;
  }

  String? _validarMonto(String? value, String campo) {
    final numero = _leerDouble(value ?? '');

    if (numero == null || numero <= 0) {
      return '$campo debe ser mayor a 0';
    }

    return null;
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  Future<void> _seleccionarFechaCompra() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaCompra,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha == null) {
      return;
    }

    setState(() {
      _fechaCompra = fecha;
    });
  }

  Future<void> _seleccionarImagen() async {
    final imagen = await _imagePicker.pickImage(source: ImageSource.gallery);

    if (imagen == null) {
      return;
    }

    final appDirectory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory(
      path.join(appDirectory.path, 'ingredient_images'),
    );

    if (!await imagesDirectory.exists()) {
      await imagesDirectory.create(recursive: true);
    }

    final extension = path.extension(imagen.path).isEmpty
        ? '.jpg'
        : path.extension(imagen.path);
    final fileName =
        'ingredient_${DateTime.now().microsecondsSinceEpoch}$extension';
    final localPath = path.join(imagesDirectory.path, fileName);

    await File(imagen.path).copy(localPath);

    setState(() {
      _imagePath = localPath;
    });
  }

  void _quitarImagen() {
    setState(() {
      _imagePath = null;
    });
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final precioCompra = _leerDouble(_precioCompraController.text)!;
    final cantidadCompra = _leerDouble(_cantidadCompraController.text)!;
    final costoPorUnidadBase = precioCompra / cantidadCompra;
    final ingrediente = widget.ingrediente;

    Navigator.of(context).pop(
      Ingrediente(
        id: ingrediente?.id ?? 0,
        nombre: _nombreController.text.trim(),
        precioCompra: precioCompra,
        cantidadCompra: cantidadCompra,
        unidadCompra: _unidadCompra,
        unidadBase: _unidadCompra,
        costoPorUnidadBase: costoPorUnidadBase,
        fechaCompra: _fechaCompra,
        fechaRegistro: ingrediente?.fechaRegistro ?? DateTime.now(),
        imagePath: _imagePath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final costoPorUnidadBase = _costoPorUnidadBase;

    return AlertDialog(
      title: Text(
        widget.ingrediente == null
            ? 'Agregar ingrediente'
            : 'Editar ingrediente',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Ingrediente',
                  helperText: 'Ejemplo: Tomate',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => _validarTexto(value, 'Ingrediente'),
              ),
              TextFormField(
                controller: _precioCompraController,
                decoration: const InputDecoration(
                  labelText: '¿Cuánto pagaste en total?',
                  helperText: 'Ejemplo: 30 Bs',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => _validarMonto(value, 'El precio total'),
              ),
              TextFormField(
                controller: _cantidadCompraController,
                decoration: const InputDecoration(
                  labelText: '¿Cuánto compraste?',
                  helperText: 'Ejemplo: 3',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    _validarMonto(value, 'La cantidad comprada'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _unidadCompra,
                decoration: const InputDecoration(
                  labelText: 'Unidad',
                  helperText: 'Ejemplo: libra',
                ),
                items: _unidades
                    .map(
                      (unidad) =>
                          DropdownMenuItem(value: unidad, child: Text(unidad)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _unidadCompra = value;
                    _unidadBase = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de compra'),
                subtitle: Text(_formatearFecha(_fechaCompra)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _seleccionarFechaCompra,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Imagen opcional',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _IngredientImagePreview(
                    nombre: _nombreController.text,
                    imagePath: _imagePath,
                    size: 56,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _seleccionarImagen,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Seleccionar imagen'),
                        ),
                        if (_imagePath != null)
                          TextButton.icon(
                            onPressed: _quitarImagen,
                            icon: const Icon(Icons.close),
                            label: const Text('Quitar imagen'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  costoPorUnidadBase == null
                      ? 'Resultado: -'
                      : 'Resultado: ${costoPorUnidadBase.toStringAsFixed(2)} Bs por $_unidadBase',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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

class _IngredientImagePreview extends StatelessWidget {
  const _IngredientImagePreview({
    required this.nombre,
    required this.imagePath,
    required this.size,
  });

  final String nombre;
  final String? imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final localPath = imagePath;

    if (localPath != null && localPath.trim().isNotEmpty) {
      final file = File(localPath);

      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                _EmojiFallback(nombre: nombre, size: size),
          ),
        );
      }
    }

    return _EmojiFallback(nombre: nombre, size: size);
  }
}

class _EmojiFallback extends StatelessWidget {
  const _EmojiFallback({required this.nombre, required this.size});

  final String nombre;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircleAvatar(
        child: Text(
          getIngredientEmoji(nombre),
          style: TextStyle(fontSize: size * 0.45),
        ),
      ),
    );
  }
}
