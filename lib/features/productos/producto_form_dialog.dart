import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/costo_fijo.dart';
import '../../data/models/producto.dart';
import '../../data/models/producto_costo_fijo.dart';
import '../../data/models/producto_costo_variable.dart';
import '../../data/models/receta.dart';

class ProductoFormResult {
  const ProductoFormResult({
    required this.producto,
    required this.costosFijos,
    required this.costosVariables,
  });

  final Producto producto;
  final List<ProductoCostoFijo> costosFijos;
  final List<ProductoCostoVariable> costosVariables;
}

class ProductoFormDialog extends StatefulWidget {
  const ProductoFormDialog({
    required this.recetas,
    required this.costosNegocio,
    required this.costosFijosIniciales,
    required this.costosVariablesIniciales,
    this.producto,
    super.key,
  });

  final List<Receta> recetas;
  final List<CostoFijo> costosNegocio;
  final List<ProductoCostoFijo> costosFijosIniciales;
  final List<ProductoCostoVariable> costosVariablesIniciales;
  final Producto? producto;

  @override
  State<ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<ProductoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _minutosController;
  late final TextEditingController _costoHoraController;
  late final TextEditingController _margenController;
  late final TextEditingController _precioFinalController;
  late final List<_CostoFijoSeleccion> _costosFijos;
  late List<ProductoCostoVariable> _costosVariables;
  Receta? _recetaSeleccionada;
  bool _actualizandoPrecioFinal = false;
  bool _precioFinalEditado = false;

  double get _costoBase => _recetaSeleccionada?.costoPorPorcion ?? 0;
  double get _minutos => _numero(_minutosController.text) ?? 0;
  double get _costoHora => _numero(_costoHoraController.text) ?? 0;
  double get _margen => _numero(_margenController.text) ?? 0;
  double get _costoManoObra => (_minutos / 60) * _costoHora;
  double get _totalCostosFijos => _costosFijos
      .where((item) => item.seleccionado)
      .fold(0, (total, item) => total + item.costoProrrateado);
  double get _totalCostosVariables =>
      _costosVariables.fold(0, (total, item) => total + item.costoCalculado);
  double get _otrosCostos =>
      _costoManoObra + _totalCostosFijos + _totalCostosVariables;
  double get _costoTotal => _costoBase + _otrosCostos;
  double get _precioSugerido => _costoTotal * (1 + _margen / 100);

  @override
  void initState() {
    super.initState();
    final producto = widget.producto;
    _nombreController = TextEditingController(text: producto?.nombre ?? '');
    _minutosController = TextEditingController(
      text: producto == null
          ? ''
          : producto.minutosElaboracion.toStringAsFixed(2),
    );
    _costoHoraController = TextEditingController(
      text: producto == null
          ? ''
          : producto.costoHoraManoObra.toStringAsFixed(2),
    );
    _margenController = TextEditingController(
      text: producto?.margenGanancia.toStringAsFixed(0) ?? '0',
    );
    _precioFinalController = TextEditingController(
      text: producto?.precioVentaFinal.toStringAsFixed(2) ?? '0.00',
    );
    _costosVariables = List.of(widget.costosVariablesIniciales);
    _costosFijos = _crearSeleccionesCostosFijos();

    if (producto != null) {
      _recetaSeleccionada = widget.recetas
          .where((receta) => receta.id == producto.recetaId)
          .firstOrNull;
      _precioFinalEditado =
          (producto.precioVentaFinal - producto.precioVentaSugerido).abs() >
          0.005;
    }

    _minutosController.addListener(_recalcular);
    _costoHoraController.addListener(_recalcular);
    _margenController.addListener(_recalcular);
    _precioFinalController.addListener(_registrarPrecioFinalEditado);
  }

  List<_CostoFijoSeleccion> _crearSeleccionesCostosFijos() {
    final disponibles = [...widget.costosNegocio];
    for (final asociado in widget.costosFijosIniciales) {
      if (!disponibles.any((costo) => costo.id == asociado.costoFijoId)) {
        disponibles.add(
          CostoFijo(
            id: asociado.costoFijoId,
            nombre: asociado.nombreCostoFijo,
            categoria: 'otro',
            montoMensual: asociado.montoMensual,
            activo: false,
            fechaRegistro: asociado.fechaRegistro,
          ),
        );
      }
    }

    return disponibles.map((costo) {
      final asociado = widget.costosFijosIniciales
          .where((item) => item.costoFijoId == costo.id)
          .firstOrNull;
      final seleccion = _CostoFijoSeleccion(
        costo: costo,
        seleccionado: asociado != null,
        unidades: asociado?.unidadesEstimadasMes,
      );
      seleccion.controller.addListener(_recalcular);
      return seleccion;
    }).toList();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _minutosController.dispose();
    _costoHoraController.dispose();
    _margenController.dispose();
    _precioFinalController.dispose();
    for (final item in _costosFijos) {
      item.controller.dispose();
    }
    super.dispose();
  }

  double? _numero(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _registrarPrecioFinalEditado() {
    if (!_actualizandoPrecioFinal) {
      _precioFinalEditado = true;
    }
    setState(() {});
  }

  void _recalcular() {
    _recalcularVariables();
    if (!_precioFinalEditado) {
      _actualizandoPrecioFinal = true;
      _precioFinalController.text = _precioSugerido.toStringAsFixed(2);
      _actualizandoPrecioFinal = false;
    }
    setState(() {});
  }

  void _recalcularVariables() {
    var subtotal = _costoBase + _costoManoObra + _totalCostosFijos;
    _costosVariables = _costosVariables.map((costo) {
      final calculado = costo.tipoCalculo == 'porcentaje'
          ? subtotal * ((costo.porcentaje ?? 0) / 100)
          : costo.monto ?? 0;
      subtotal += calculado;
      return costo.copyWith(costoCalculado: calculado);
    }).toList();
  }

  void _seleccionarReceta(Receta? receta) {
    _recetaSeleccionada = receta;
    _recalcular();
  }

  Future<void> _abrirCostoVariable({int? index}) async {
    final costo = index == null ? null : _costosVariables[index];
    final subtotalReferencia =
        _costoBase +
        _costoManoObra +
        _totalCostosFijos +
        _costosVariables
            .take(index ?? _costosVariables.length)
            .fold<double>(0, (total, item) => total + item.costoCalculado);
    final resultado = await showDialog<ProductoCostoVariable>(
      context: context,
      builder: (context) => _CostoVariableDialog(
        costo: costo,
        subtotalReferencia: subtotalReferencia,
      ),
    );

    if (resultado == null) {
      return;
    }

    if (index == null) {
      _costosVariables.add(resultado);
    } else {
      _costosVariables[index] = resultado;
    }
    _recalcular();
  }

  String? _obligatorio(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obligatorio' : null;
  }

  String? _mayorACero(String? value) {
    final numero = _numero(value ?? '');
    return numero == null || numero <= 0 ? 'Debe ser mayor a 0' : null;
  }

  String? _noNegativo(String? value) {
    final numero = _numero(value ?? '');
    return numero == null || numero < 0 ? 'Debe ser mayor o igual a 0' : null;
  }

  bool _validarCostosFijos() {
    var validos = true;
    for (final item in _costosFijos.where((item) => item.seleccionado)) {
      final unidades = _numero(item.controller.text);
      if (unidades == null || unidades <= 0) {
        validos = false;
      }
    }
    return validos;
  }

  void _guardar() {
    final formularioValido = _formKey.currentState!.validate();
    final costosFijosValidos = _validarCostosFijos();
    if (!formularioValido ||
        !costosFijosValidos ||
        _recetaSeleccionada == null) {
      setState(() {});
      return;
    }

    _recalcularVariables();
    final productoAnterior = widget.producto;
    final receta = _recetaSeleccionada!;
    final costosFijos = _costosFijos
        .where((item) => item.seleccionado)
        .map(
          (item) => ProductoCostoFijo(
            id: 0,
            productoId: productoAnterior?.id ?? 0,
            costoFijoId: item.costo.id,
            nombreCostoFijo: item.costo.nombre,
            montoMensual: item.costo.montoMensual,
            unidadesEstimadasMes: item.unidades,
            costoProrrateado: item.costoProrrateado,
            fechaRegistro: DateTime.now(),
          ),
        )
        .toList();

    Navigator.of(context).pop(
      ProductoFormResult(
        producto: Producto(
          id: productoAnterior?.id ?? 0,
          nombre: _nombreController.text.trim(),
          recetaId: receta.id,
          nombreReceta: receta.nombre,
          costoBase: _costoBase,
          minutosElaboracion: _minutos,
          costoHoraManoObra: _costoHora,
          costoManoObra: _costoManoObra,
          costosVariables: _totalCostosVariables,
          costosFijos: _totalCostosFijos,
          otrosCostos: _otrosCostos,
          costoTotalProducto: _costoTotal,
          margenGanancia: _margen,
          precioVentaSugerido: _precioSugerido,
          precioVentaFinal: _numero(_precioFinalController.text)!,
          fechaRegistro: productoAnterior?.fechaRegistro ?? DateTime.now(),
        ),
        costosFijos: costosFijos,
        costosVariables: _costosVariables,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receta = _recetaSeleccionada;

    return AlertDialog(
      title: Text(
        widget.producto == null ? 'Crear producto' : 'Editar producto',
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del producto',
                  ),
                  validator: _obligatorio,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Receta>(
                  initialValue: receta,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Receta base'),
                  items: widget.recetas
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: _seleccionarReceta,
                  validator: (value) =>
                      value == null ? 'Selecciona una receta' : null,
                ),
                if (receta != null) ...[
                  const SizedBox(height: 8),
                  Text('Nombre receta: ${receta.nombre}'),
                  Text(
                    'Costo total receta: ${receta.costoTotal.toStringAsFixed(2)} Bs',
                  ),
                  Text(
                    'Costo por porción: ${receta.costoPorPorcion.toStringAsFixed(2)} Bs',
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  'Mano de obra',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _NumberField(
                  controller: _minutosController,
                  label: 'Minutos de elaboración',
                  suffix: 'min',
                  validator: _mayorACero,
                ),
                _NumberField(
                  controller: _costoHoraController,
                  label: 'Costo por hora',
                  suffix: 'Bs',
                  validator: _mayorACero,
                ),
                Text(
                  'Costo mano de obra: ${_costoManoObra.toStringAsFixed(2)} Bs',
                ),
                const SizedBox(height: 18),
                Text(
                  'Costos del negocio',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_costosFijos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('No hay costos activos para seleccionar.'),
                  )
                else
                  ..._costosFijos.map(
                    (item) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.costo.nombre),
                              subtitle: Text(
                                '${item.costo.montoMensual.toStringAsFixed(2)} Bs / mes',
                              ),
                              value: item.seleccionado,
                              onChanged: (value) {
                                item.seleccionado = value ?? false;
                                _recalcular();
                              },
                            ),
                            if (item.seleccionado)
                              TextFormField(
                                controller: item.controller,
                                decoration: InputDecoration(
                                  labelText: 'Unidades estimadas al mes',
                                  helperText:
                                      'Prorrateado: ${item.costoProrrateado.toStringAsFixed(2)} Bs',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]'),
                                  ),
                                ],
                                validator: (_) =>
                                    item.seleccionado && item.unidades <= 0
                                    ? 'Debe ser mayor a 0'
                                    : null,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Costos variables',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _abrirCostoVariable,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar costo variable'),
                    ),
                  ],
                ),
                if (_costosVariables.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('No hay costos variables.'),
                  )
                else
                  ...List.generate(_costosVariables.length, (index) {
                    final costo = _costosVariables[index];
                    return Card(
                      child: ListTile(
                        title: Text(costo.nombre),
                        subtitle: Text(
                          '${costo.tipoCalculo == 'porcentaje' ? 'Porcentaje' : 'Por unidad'} | '
                          '${costo.costoCalculado.toStringAsFixed(2)} Bs',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  _abrirCostoVariable(index: index),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () {
                                _costosVariables.removeAt(index);
                                _recalcular();
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                _NumberField(
                  controller: _margenController,
                  label: 'Margen de ganancia',
                  suffix: '%',
                  validator: _noNegativo,
                ),
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Costo receta: ${_costoBase.toStringAsFixed(2)} Bs',
                        ),
                        Text(
                          'Mano de obra: ${_costoManoObra.toStringAsFixed(2)} Bs',
                        ),
                        Text(
                          'Costos fijos: ${_totalCostosFijos.toStringAsFixed(2)} Bs',
                        ),
                        Text(
                          'Costos variables: ${_totalCostosVariables.toStringAsFixed(2)} Bs',
                        ),
                        Text(
                          'Costo total producto: ${_costoTotal.toStringAsFixed(2)} Bs',
                        ),
                        Text('Margen: ${_margen.toStringAsFixed(0)}%'),
                        Text(
                          'Precio sugerido: ${_precioSugerido.toStringAsFixed(2)} Bs',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                _NumberField(
                  controller: _precioFinalController,
                  label: 'Precio final',
                  suffix: 'Bs',
                  validator: _mayorACero,
                  onSubmitted: (_) => _guardar(),
                ),
              ],
            ),
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

class _CostoFijoSeleccion {
  _CostoFijoSeleccion({
    required this.costo,
    required this.seleccionado,
    double? unidades,
  }) : controller = TextEditingController(
         text: unidades == null ? '' : unidades.toStringAsFixed(0),
       );

  final CostoFijo costo;
  final TextEditingController controller;
  bool seleccionado;

  double get unidades =>
      double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
  double get costoProrrateado =>
      unidades > 0 ? costo.montoMensual / unidades : 0;
}

class _CostoVariableDialog extends StatefulWidget {
  const _CostoVariableDialog({this.costo, required this.subtotalReferencia});

  final ProductoCostoVariable? costo;
  final double subtotalReferencia;

  @override
  State<_CostoVariableDialog> createState() => _CostoVariableDialogState();
}

class _CostoVariableDialogState extends State<_CostoVariableDialog> {
  static const _categorias = [
    'envase',
    'delivery',
    'comision',
    'transporte',
    'empaque',
    'merma',
    'otro',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _valorController;
  late String _categoria;
  late String _tipo;

  double get _valor =>
      double.tryParse(_valorController.text.trim().replaceAll(',', '.')) ?? 0;
  double get _calculado => _tipo == 'porcentaje'
      ? widget.subtotalReferencia * (_valor / 100)
      : _valor;

  @override
  void initState() {
    super.initState();
    final costo = widget.costo;
    _nombreController = TextEditingController(text: costo?.nombre ?? '');
    _categoria = costo?.categoria ?? 'otro';
    _tipo = costo?.tipoCalculo ?? 'por_unidad';
    _valorController = TextEditingController(
      text: costo == null
          ? ''
          : (_tipo == 'porcentaje' ? costo.porcentaje : costo.monto)
                    ?.toStringAsFixed(2) ??
                '',
    );
    _valorController.addListener(_actualizar);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  void _actualizar() => setState(() {});

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final anterior = widget.costo;
    Navigator.of(context).pop(
      ProductoCostoVariable(
        id: anterior?.id ?? 0,
        productoId: anterior?.productoId ?? 0,
        nombre: _nombreController.text.trim(),
        categoria: _categoria,
        tipoCalculo: _tipo,
        monto: _tipo == 'por_unidad' ? _valor : null,
        porcentaje: _tipo == 'porcentaje' ? _valor : null,
        costoCalculado: _calculado,
        fechaRegistro: anterior?.fechaRegistro ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.costo == null
            ? 'Agregar costo variable'
            : 'Editar costo variable',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Campo obligatorio'
                  : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: _categorias
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _categoria = value!),
            ),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo de cálculo'),
              items: const [
                DropdownMenuItem(
                  value: 'por_unidad',
                  child: Text('Por unidad'),
                ),
                DropdownMenuItem(
                  value: 'porcentaje',
                  child: Text('Porcentaje'),
                ),
              ],
              onChanged: (value) => setState(() => _tipo = value!),
            ),
            _NumberField(
              controller: _valorController,
              label: _tipo == 'porcentaje' ? 'Porcentaje' : 'Monto',
              suffix: _tipo == 'porcentaje' ? '%' : 'Bs',
              validator: (value) {
                final numero = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                return numero == null || numero < 0
                    ? 'Debe ser mayor o igual a 0'
                    : null;
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Costo calculado: ${_calculado.toStringAsFixed(2)} Bs',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
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

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.validator,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final String? Function(String?) validator;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      validator: validator,
      onFieldSubmitted: onSubmitted,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
