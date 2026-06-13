import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/producto.dart';
import '../../data/models/producto_costo.dart';
import '../../data/models/receta.dart';

class ProductoFormResult {
  const ProductoFormResult({required this.producto, required this.costos});

  final Producto producto;
  final List<ProductoCosto> costos;
}

class ProductoFormDialog extends StatefulWidget {
  const ProductoFormDialog({
    required this.recetas,
    required this.costosIniciales,
    this.producto,
    super.key,
  });

  final List<Receta> recetas;
  final List<ProductoCosto> costosIniciales;
  final Producto? producto;

  @override
  State<ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<ProductoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _costoBaseController;
  late final TextEditingController _margenController;
  late final TextEditingController _precioFinalController;
  late List<ProductoCosto> _costos;
  Receta? _recetaSeleccionada;
  bool _actualizandoPrecioFinal = false;
  bool _precioFinalEditado = false;

  double get _costoBase => _leerNumero(_costoBaseController.text) ?? 0;
  double get _margen => _leerNumero(_margenController.text) ?? 0;
  double get _costosVariables => _costos
      .where((costo) => costo.tipoCosto == 'variable')
      .fold(0, (total, costo) => total + costo.costoCalculado);
  double get _costosFijos => _costos
      .where((costo) => costo.tipoCosto == 'fijo')
      .fold(0, (total, costo) => total + costo.costoCalculado);
  double get _otrosCostos => _costosVariables + _costosFijos;
  double get _costoTotal => _costoBase + _otrosCostos;
  double get _precioSugerido => _costoTotal * (1 + _margen / 100);

  @override
  void initState() {
    super.initState();
    final producto = widget.producto;
    _nombreController = TextEditingController(text: producto?.nombre ?? '');
    _costoBaseController = TextEditingController(
      text: producto?.costoBase.toStringAsFixed(2) ?? '',
    );
    _margenController = TextEditingController(
      text: producto?.margenGanancia.toStringAsFixed(0) ?? '0',
    );
    _precioFinalController = TextEditingController(
      text: producto?.precioVentaFinal.toStringAsFixed(2) ?? '0.00',
    );
    _costos = List.of(widget.costosIniciales);

    if (producto != null) {
      for (final receta in widget.recetas) {
        if (receta.id == producto.recetaId) {
          _recetaSeleccionada = receta;
          break;
        }
      }
      _precioFinalEditado =
          (producto.precioVentaFinal - producto.precioVentaSugerido).abs() >
          0.005;
    }

    _costoBaseController.addListener(_recalcular);
    _margenController.addListener(_recalcular);
    _precioFinalController.addListener(_registrarEdicionPrecioFinal);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _costoBaseController.dispose();
    _margenController.dispose();
    _precioFinalController.dispose();
    super.dispose();
  }

  double? _leerNumero(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _registrarEdicionPrecioFinal() {
    if (!_actualizandoPrecioFinal) {
      _precioFinalEditado = true;
    }
    setState(() {});
  }

  void _recalcular() {
    _recalcularCostos();
    if (!_precioFinalEditado) {
      _actualizandoPrecioFinal = true;
      _precioFinalController.text = _precioSugerido.toStringAsFixed(2);
      _actualizandoPrecioFinal = false;
    }
    setState(() {});
  }

  void _recalcularCostos() {
    var subtotal = _costoBase;
    _costos = _costos.map((costo) {
      final calculado = _calcularCosto(costo, subtotal);
      subtotal += calculado;
      return costo.copyWith(costoCalculado: calculado);
    }).toList();
  }

  double _calcularCosto(ProductoCosto costo, double subtotal) {
    switch (costo.tipoCalculo) {
      case 'mensual_prorrateado':
        final unidades = costo.unidadesEstimadasMes ?? 0;
        return unidades > 0 ? costo.monto / unidades : 0;
      case 'por_tiempo':
        return ((costo.minutosElaboracion ?? 0) / 60) * (costo.costoHora ?? 0);
      case 'porcentaje':
        return subtotal * ((costo.porcentaje ?? 0) / 100);
      default:
        return costo.monto;
    }
  }

  void _seleccionarReceta(Receta? receta) {
    if (receta != null) {
      _costoBaseController.text = receta.costoPorPorcion.toStringAsFixed(2);
    }
    setState(() {
      _recetaSeleccionada = receta;
    });
  }

  Future<void> _abrirCosto({int? index}) async {
    final costo = index == null ? null : _costos[index];
    final subtotalReferencia = index == null
        ? _costoTotal
        : _costoBase +
              _costos
                  .take(index)
                  .fold<double>(
                    0,
                    (total, item) => total + item.costoCalculado,
                  );
    final resultado = await showDialog<ProductoCosto>(
      context: context,
      builder: (context) => _ProductoCostoDialog(
        costo: costo,
        subtotalReferencia: subtotalReferencia,
      ),
    );

    if (resultado == null) {
      return;
    }

    if (index == null) {
      _costos.add(resultado);
    } else {
      _costos[index] = resultado;
    }
    _recalcular();
  }

  void _eliminarCosto(int index) {
    _costos.removeAt(index);
    _recalcular();
  }

  String? _validarNombre(String? value) {
    return value == null || value.trim().isEmpty
        ? 'El nombre es obligatorio'
        : null;
  }

  String? _validarNoNegativo(String? value, String campo) {
    final numero = _leerNumero(value ?? '');
    if (numero == null) {
      return 'Ingresa un numero valido';
    }
    return numero < 0 ? '$campo debe ser mayor o igual a 0' : null;
  }

  String? _validarPrecioFinal(String? value) {
    final numero = _leerNumero(value ?? '');
    return numero == null || numero <= 0
        ? 'El precio final debe ser mayor a 0'
        : null;
  }

  void _guardar() {
    if (!_formKey.currentState!.validate() || _recetaSeleccionada == null) {
      setState(() {});
      return;
    }

    _recalcularCostos();
    final producto = widget.producto;
    final receta = _recetaSeleccionada!;

    Navigator.of(context).pop(
      ProductoFormResult(
        producto: Producto(
          id: producto?.id ?? 0,
          nombre: _nombreController.text.trim(),
          recetaId: receta.id,
          nombreReceta: receta.nombre,
          costoBase: _costoBase,
          otrosCostos: _otrosCostos,
          margenGanancia: _margen,
          precioVentaSugerido: _precioSugerido,
          precioVentaFinal: _leerNumero(_precioFinalController.text)!,
          fechaRegistro: producto?.fechaRegistro ?? DateTime.now(),
        ),
        costos: _costos,
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
        width: 560,
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
                  validator: _validarNombre,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Receta>(
                  initialValue: receta,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Receta'),
                  items: widget.recetas
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.nombre,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _seleccionarReceta,
                  validator: (value) =>
                      value == null ? 'Selecciona una receta' : null,
                ),
                if (receta != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Costo total receta: ${receta.costoTotal.toStringAsFixed(2)} Bs',
                  ),
                  Text(
                    'Costo por porcion: ${receta.costoPorPorcion.toStringAsFixed(2)} Bs',
                  ),
                ],
                const SizedBox(height: 12),
                _NumberField(
                  controller: _costoBaseController,
                  label: 'Costo base',
                  suffix: 'Bs',
                  validator: (value) =>
                      _validarNoNegativo(value, 'El costo base'),
                ),
                _NumberField(
                  controller: _margenController,
                  label: 'Margen de ganancia',
                  suffix: '%',
                  validator: (value) => _validarNoNegativo(value, 'El margen'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Costos adicionales',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _abrirCosto,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar costo'),
                    ),
                  ],
                ),
                if (_costos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No hay costos adicionales.'),
                  )
                else
                  ...List.generate(_costos.length, (index) {
                    final costo = _costos[index];
                    return Card(
                      child: ListTile(
                        title: Text(costo.nombre),
                        subtitle: Text(
                          '${_etiquetaTipoCosto(costo.tipoCosto)} | '
                          '${_etiquetaTipo(costo.tipoCalculo)} | '
                          '${costo.costoCalculado.toStringAsFixed(2)} Bs',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar costo',
                              onPressed: () => _abrirCosto(index: index),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Eliminar costo',
                              onPressed: () => _eliminarCosto(index),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Costo receta/base: ${_costoBase.toStringAsFixed(2)} Bs',
                        ),
                        Text(
                          'Costos variables: ${_costosVariables.toStringAsFixed(2)} Bs',
                        ),
                        Text(
                          'Costos fijos prorrateados: ${_costosFijos.toStringAsFixed(2)} Bs',
                        ),
                        Text(
                          'Otros costos totales: ${_otrosCostos.toStringAsFixed(2)} Bs',
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
                  label: 'Precio venta final',
                  suffix: 'Bs',
                  validator: _validarPrecioFinal,
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

class _ProductoCostoDialog extends StatefulWidget {
  const _ProductoCostoDialog({this.costo, required this.subtotalReferencia});

  final ProductoCosto? costo;
  final double subtotalReferencia;

  @override
  State<_ProductoCostoDialog> createState() => _ProductoCostoDialogState();
}

class _ProductoCostoDialogState extends State<_ProductoCostoDialog> {
  static const _categorias = [
    'envase',
    'servicio',
    'alquiler',
    'mano_obra',
    'delivery',
    'comision',
    'impuesto',
    'mantenimiento',
    'otro',
  ];
  static const _tiposVariables = ['por_unidad', 'por_tiempo', 'porcentaje'];
  static const _tiposFijos = ['mensual_prorrateado'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _montoController;
  late final TextEditingController _unidadesController;
  late final TextEditingController _minutosController;
  late final TextEditingController _costoHoraController;
  late final TextEditingController _porcentajeController;
  late String _tipoCosto;
  late String _categoria;
  late String _tipo;

  List<String> get _tiposDisponibles =>
      _tipoCosto == 'fijo' ? _tiposFijos : _tiposVariables;

  double? _numero(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.'));
  }

  double get _costoCalculado {
    switch (_tipo) {
      case 'mensual_prorrateado':
        final unidades = _numero(_unidadesController) ?? 0;
        return unidades > 0 ? (_numero(_montoController) ?? 0) / unidades : 0;
      case 'por_tiempo':
        return ((_numero(_minutosController) ?? 0) / 60) *
            (_numero(_costoHoraController) ?? 0);
      case 'porcentaje':
        return widget.subtotalReferencia *
            ((_numero(_porcentajeController) ?? 0) / 100);
      default:
        return _numero(_montoController) ?? 0;
    }
  }

  @override
  void initState() {
    super.initState();
    final costo = widget.costo;
    _nombreController = TextEditingController(text: costo?.nombre ?? '');
    _montoController = TextEditingController(
      text: costo == null ? '' : costo.monto.toStringAsFixed(2),
    );
    _unidadesController = TextEditingController(
      text: costo?.unidadesEstimadasMes?.toStringAsFixed(2) ?? '',
    );
    _minutosController = TextEditingController(
      text: costo?.minutosElaboracion?.toStringAsFixed(2) ?? '',
    );
    _costoHoraController = TextEditingController(
      text: costo?.costoHora?.toStringAsFixed(2) ?? '',
    );
    _porcentajeController = TextEditingController(
      text: costo?.porcentaje?.toStringAsFixed(2) ?? '',
    );
    _tipoCosto = costo?.tipoCosto ?? 'variable';
    _categoria = costo?.categoria ?? 'otro';
    _tipo = costo?.tipoCalculo ?? 'por_unidad';
    if (!_tiposDisponibles.contains(_tipo)) {
      _tipo = _tiposDisponibles.first;
    }

    for (final controller in [
      _montoController,
      _unidadesController,
      _minutosController,
      _costoHoraController,
      _porcentajeController,
    ]) {
      controller.addListener(_actualizar);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    _unidadesController.dispose();
    _minutosController.dispose();
    _costoHoraController.dispose();
    _porcentajeController.dispose();
    super.dispose();
  }

  void _actualizar() => setState(() {});

  String? _requerido(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obligatorio' : null;
  }

  String? _noNegativo(String? value) {
    final numero = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (numero == null) {
      return 'Ingresa un numero valido';
    }
    return numero < 0 ? 'Debe ser mayor o igual a 0' : null;
  }

  String? _mayorACero(String? value) {
    final numero = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    return numero == null || numero <= 0 ? 'Debe ser mayor a 0' : null;
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final costo = widget.costo;
    Navigator.of(context).pop(
      ProductoCosto(
        id: costo?.id ?? 0,
        productoId: costo?.productoId ?? 0,
        nombre: _nombreController.text.trim(),
        tipoCosto: _tipoCosto,
        categoria: _categoria,
        tipoCalculo: _tipo,
        monto: _tipo == 'por_unidad' || _tipo == 'mensual_prorrateado'
            ? _numero(_montoController)!
            : 0,
        unidadesEstimadasMes: _tipo == 'mensual_prorrateado'
            ? _numero(_unidadesController)
            : null,
        minutosElaboracion: _tipo == 'por_tiempo'
            ? _numero(_minutosController)
            : null,
        costoHora: _tipo == 'por_tiempo' ? _numero(_costoHoraController) : null,
        porcentaje: _tipo == 'porcentaje'
            ? _numero(_porcentajeController)
            : null,
        costoCalculado: _costoCalculado,
        fechaRegistro: costo?.fechaRegistro ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.costo == null ? 'Agregar costo' : 'Editar costo'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del costo',
                  ),
                  validator: _requerido,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _tipoCosto,
                  decoration: const InputDecoration(labelText: 'Tipo de costo'),
                  items: const [
                    DropdownMenuItem(value: 'fijo', child: Text('Fijo')),
                    DropdownMenuItem(
                      value: 'variable',
                      child: Text('Variable'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _tipoCosto = value!;
                      if (!_tiposDisponibles.contains(_tipo)) {
                        _tipo = _tiposDisponibles.first;
                      }
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: _categoria,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: _categorias
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.replaceAll('_', ' ')),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _categoria = value!),
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey(_tipoCosto),
                  initialValue: _tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de calculo',
                  ),
                  items: _tiposDisponibles
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_etiquetaTipo(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _tipo = value!),
                ),
                if (_tipo == 'por_unidad')
                  _NumberField(
                    controller: _montoController,
                    label: 'Monto por unidad',
                    suffix: 'Bs',
                    validator: _noNegativo,
                  ),
                if (_tipo == 'mensual_prorrateado') ...[
                  _NumberField(
                    controller: _montoController,
                    label: 'Monto mensual',
                    suffix: 'Bs',
                    validator: _noNegativo,
                  ),
                  _NumberField(
                    controller: _unidadesController,
                    label: 'Unidades estimadas al mes',
                    validator: _mayorACero,
                  ),
                ],
                if (_tipo == 'por_tiempo') ...[
                  _NumberField(
                    controller: _minutosController,
                    label: 'Minutos de elaboracion',
                    suffix: 'min',
                    validator: _mayorACero,
                  ),
                  _NumberField(
                    controller: _costoHoraController,
                    label: 'Costo por hora',
                    suffix: 'Bs',
                    validator: _mayorACero,
                  ),
                ],
                if (_tipo == 'porcentaje') ...[
                  _NumberField(
                    controller: _porcentajeController,
                    label: 'Porcentaje',
                    suffix: '%',
                    validator: _noNegativo,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Referencia actual: ${widget.subtotalReferencia.toStringAsFixed(2)} Bs',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Costo calculado: ${_costoCalculado.toStringAsFixed(2)} Bs',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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

String _etiquetaTipo(String tipo) {
  switch (tipo) {
    case 'mensual_prorrateado':
      return 'Mensual prorrateado';
    case 'por_tiempo':
      return 'Por tiempo';
    case 'porcentaje':
      return 'Porcentaje';
    default:
      return 'Por unidad';
  }
}

String _etiquetaTipoCosto(String tipoCosto) {
  return tipoCosto == 'fijo' ? 'Fijo' : 'Variable';
}
