import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/costo_fijo.dart';
import '../../data/repositories/costo_fijo_repository.dart';

class CostosFijosScreen extends StatefulWidget {
  const CostosFijosScreen({super.key});

  @override
  State<CostosFijosScreen> createState() => _CostosFijosScreenState();
}

class _CostosFijosScreenState extends State<CostosFijosScreen> {
  final CostoFijoRepository _repository = CostoFijoRepository();
  final TextEditingController _ventasEstimadasController =
      TextEditingController(text: '300');
  late Future<List<CostoFijo>> _costosFuture;

  @override
  void initState() {
    super.initState();
    _costosFuture = _repository.getCostosFijos();
    _ventasEstimadasController.addListener(_actualizarResumen);
  }

  @override
  void dispose() {
    _ventasEstimadasController.dispose();
    super.dispose();
  }

  void _actualizarResumen() => setState(() {});

  void _recargar() {
    setState(() {
      _costosFuture = _repository.getCostosFijos();
    });
  }

  double? get _ventasEstimadas => double.tryParse(
    _ventasEstimadasController.text.trim().replaceAll(',', '.'),
  );

  Future<void> _abrirFormulario({CostoFijo? costo}) async {
    final resultado = await showDialog<CostoFijo>(
      context: context,
      builder: (context) => _CostoFijoFormDialog(costo: costo),
    );

    if (resultado == null) {
      return;
    }

    if (costo == null) {
      await _repository.insertCostoFijo(resultado);
    } else {
      await _repository.updateCostoFijo(resultado);
    }

    if (!mounted) {
      return;
    }

    _recargar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(costo == null ? 'Costo agregado' : 'Costo actualizado'),
      ),
    );
  }

  Future<void> _cambiarEstado(CostoFijo costo, bool activo) async {
    await _repository.updateCostoFijo(costo.copyWith(activo: activo));

    if (mounted) {
      _recargar();
    }
  }

  Future<void> _confirmarEliminar(CostoFijo costo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar costo'),
        content: Text('¿Deseas eliminar ${costo.nombre}?'),
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

    await _repository.deleteCostoFijo(costo.id);

    if (!mounted) {
      return;
    }

    _recargar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Costo eliminado')));
  }

  Widget _construirResumen(List<CostoFijo> costos) {
    final activos = costos.where((costo) => costo.activo).toList();
    final totalMensual = activos.fold<double>(
      0,
      (total, costo) => total + costo.montoMensual,
    );
    final ventas = _ventasEstimadas;
    final ventasValidas = ventas != null && ventas > 0;
    final estimado = ventasValidas ? totalMensual / ventas : 0.0;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resumen mensual',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                Text('Total mensual: ${totalMensual.toStringAsFixed(2)} Bs'),
                Text('Costos activos: ${activos.length}'),
                Text(
                  'Estimado por producto: ${estimado.toStringAsFixed(2)} Bs',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ventasEstimadasController,
              decoration: InputDecoration(
                labelText: 'Ventas estimadas al mes',
                hintText: 'Ejemplo: 300',
                errorText: ventasValidas
                    ? null
                    : 'Ingresa una cantidad mayor a 0',
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Costos del negocio')),
      body: FutureBuilder<List<CostoFijo>>(
        future: _costosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar los costos del negocio.'),
            );
          }

          final costos = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Registra los pagos mensuales de tu negocio para calcular mejor tus precios.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _construirResumen(costos),
              const SizedBox(height: 16),
              Text(
                'Pagos mensuales',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (costos.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Todavía no registraste pagos mensuales del negocio.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...costos.map(
                  (costo) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Text(
                            _iconoCategoria(costo.categoria),
                            style: const TextStyle(fontSize: 30),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  costo.nombre,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  '${costo.montoMensual.toStringAsFixed(2)} Bs / mes',
                                ),
                                Text(
                                  costo.activo
                                      ? 'Activo'
                                      : 'No se usa en cálculos',
                                  style: TextStyle(
                                    color: costo.activo
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: costo.activo,
                            onChanged: (value) => _cambiarEstado(costo, value),
                          ),
                          IconButton(
                            tooltip: 'Editar',
                            onPressed: () => _abrirFormulario(costo: costo),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            onPressed: () => _confirmarEliminar(costo),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Agregar costo'),
      ),
    );
  }
}

class _CostoFijoFormDialog extends StatefulWidget {
  const _CostoFijoFormDialog({this.costo});

  final CostoFijo? costo;

  @override
  State<_CostoFijoFormDialog> createState() => _CostoFijoFormDialogState();
}

class _CostoFijoFormDialogState extends State<_CostoFijoFormDialog> {
  static const _categorias = [
    'alquiler',
    'luz',
    'agua',
    'gas',
    'internet',
    'sueldo',
    'mantenimiento',
    'otro',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _montoController;
  late String _categoria;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    final costo = widget.costo;
    _nombreController = TextEditingController(text: costo?.nombre ?? '');
    _montoController = TextEditingController(
      text: costo?.montoMensual.toStringAsFixed(2) ?? '',
    );
    _categoria = _normalizarCategoria(costo?.categoria);
    _activo = costo?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  String? _validarNombre(String? value) {
    return value == null || value.trim().isEmpty
        ? 'El nombre es obligatorio'
        : null;
  }

  String? _validarMonto(String? value) {
    final monto = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    return monto == null || monto <= 0 ? 'Ingresa un monto mayor a 0' : null;
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final costo = widget.costo;
    Navigator.of(context).pop(
      CostoFijo(
        id: costo?.id ?? 0,
        nombre: _nombreController.text.trim(),
        categoria: _categoria,
        montoMensual: double.parse(
          _montoController.text.trim().replaceAll(',', '.'),
        ),
        activo: _activo,
        fechaRegistro: costo?.fechaRegistro ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.costo == null ? 'Agregar costo' : 'Editar costo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del costo',
                  hintText: 'Ejemplo: Alquiler',
                ),
                validator: _validarNombre,
              ),
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: '¿Cuánto pagas al mes?',
                  hintText: 'Ejemplo: 1500 Bs',
                  suffixText: 'Bs',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                validator: _validarMonto,
              ),
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categorias
                    .map(
                      (categoria) => DropdownMenuItem(
                        value: categoria,
                        child: Text(
                          '${_iconoCategoria(categoria)} ${_etiquetaCategoria(categoria)}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _categoria = value!),
                validator: (value) =>
                    value == null ? 'Selecciona una categoría' : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Usar este costo para calcular productos'),
                value: _activo,
                onChanged: (value) => setState(() => _activo = value),
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

String _normalizarCategoria(String? categoria) {
  if (categoria == 'sueldo_fijo') {
    return 'sueldo';
  }
  const categoriasValidas = {
    'alquiler',
    'luz',
    'agua',
    'gas',
    'internet',
    'sueldo',
    'mantenimiento',
    'otro',
  };
  return categoriasValidas.contains(categoria) ? categoria! : 'otro';
}

String _etiquetaCategoria(String categoria) {
  return categoria == 'sueldo'
      ? 'Sueldo'
      : '${categoria[0].toUpperCase()}${categoria.substring(1)}';
}

String _iconoCategoria(String categoria) {
  switch (_normalizarCategoria(categoria)) {
    case 'alquiler':
      return '🏠';
    case 'luz':
      return '💡';
    case 'agua':
      return '💧';
    case 'gas':
      return '🔥';
    case 'internet':
      return '🌐';
    case 'sueldo':
      return '👨‍🍳';
    case 'mantenimiento':
      return '🛠️';
    default:
      return '🧾';
  }
}
