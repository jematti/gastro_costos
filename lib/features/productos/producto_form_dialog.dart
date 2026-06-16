import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/helpers/image_helper.dart';
import '../../data/models/costo_fijo.dart';
import '../../data/models/producto.dart';
import '../../data/models/producto_costo_fijo.dart';
import '../../data/models/producto_costo_variable.dart';
import '../../data/models/receta.dart';
import '../../shared/widgets/local_image_preview.dart';

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
  final _productoKey = GlobalKey<FormState>();
  final _manoObraKey = GlobalKey<FormState>();
  final _costosFijosKey = GlobalKey<FormState>();
  final _precioKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _minutosController;
  late final TextEditingController _costoHoraController;
  late final TextEditingController _unidadesMesController;
  late final TextEditingController _margenController;
  late final TextEditingController _precioFinalController;
  late final List<_CostoFijoSeleccion> _costosFijos;
  late List<ProductoCostoVariable> _costosVariables;
  Receta? _recetaSeleccionada;
  String? _imagePath;
  bool _actualizandoPrecioFinal = false;
  bool _precioFinalEditado = false;
  int _pasoActual = 0;

  double get _costoReceta => _recetaSeleccionada?.costoPorPorcion ?? 0;
  double get _minutos => _numero(_minutosController.text) ?? 0;
  double get _costoHora => _numero(_costoHoraController.text) ?? 0;
  double get _unidadesMes => _numero(_unidadesMesController.text) ?? 0;
  double get _margen => _numero(_margenController.text) ?? 0;
  double get _costoManoObra => (_minutos / 60) * _costoHora;
  double get _totalMensualCostosFijos => _costosFijos
      .where((item) => item.seleccionado)
      .fold(0, (total, item) => total + item.costo.montoMensual);
  double get _totalCostosFijos => _costosFijos
      .where((item) => item.seleccionado)
      .fold(0, (total, item) => total + item.costoProrrateado);
  bool get _hayCostosFijosSeleccionados =>
      _costosFijos.any((item) => item.seleccionado);
  double get _totalCostosVariables =>
      _costosVariables.fold(0, (total, item) => total + item.costoCalculado);
  double get _otrosCostos =>
      _costoManoObra + _totalCostosFijos + _totalCostosVariables;
  double get _costoTotal => _costoReceta + _otrosCostos;
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
    _unidadesMesController = TextEditingController(
      text: _unidadesInicialesMes(producto),
    );
    _margenController = TextEditingController(
      text: producto?.margenGanancia.toStringAsFixed(0) ?? '0',
    );
    _precioFinalController = TextEditingController(
      text: producto?.precioVentaFinal.toStringAsFixed(2) ?? '0.00',
    );
    _imagePath = _normalizarImagePath(producto?.imagePath);
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
    _unidadesMesController.addListener(_recalcular);
    _margenController.addListener(_recalcular);
    _precioFinalController.addListener(_registrarPrecioFinalEditado);
    _recalcularVariables();
  }

  String? _normalizarImagePath(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return null;
    }

    return imagePath;
  }

  String _unidadesInicialesMes(Producto? producto) {
    final unidadesProducto = producto?.unidadesEstimadasMes ?? 0;
    if (unidadesProducto > 0) {
      return unidadesProducto.toStringAsFixed(0);
    }

    final unidadesGuardadas = widget.costosFijosIniciales
        .where((item) => item.unidadesEstimadasMes > 0)
        .map((item) => item.unidadesEstimadasMes)
        .firstOrNull;
    return unidadesGuardadas == null
        ? ''
        : unidadesGuardadas.toStringAsFixed(0);
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
        unidadesMes: () => _unidadesMes,
      );
      return seleccion;
    }).toList();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _minutosController.dispose();
    _costoHoraController.dispose();
    _unidadesMesController.dispose();
    _margenController.dispose();
    _precioFinalController.dispose();
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
    var subtotal = _costoReceta + _costoManoObra + _totalCostosFijos;
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

  Future<void> _seleccionarImagen() async {
    final imagePath = await ImageHelper.pickAndSaveImage('product_images');

    if (imagePath == null) {
      return;
    }

    setState(() {
      _imagePath = imagePath;
    });
  }

  void _quitarImagen() {
    setState(() {
      _imagePath = null;
    });
  }

  Future<void> _abrirCostoVariable({int? index}) async {
    final costo = index == null ? null : _costosVariables[index];
    final subtotalReferencia =
        _costoReceta +
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
    if (resultado == null) return;

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

  String? _validarUnidadesMes(String? value) {
    if (!_hayCostosFijosSeleccionados) {
      return null;
    }
    final numero = _numero(value ?? '');
    return numero == null || numero <= 0
        ? 'Ingresa una cantidad mayor a 0'
        : null;
  }

  bool _validarPaso(int paso) {
    switch (paso) {
      case 0:
        return (_productoKey.currentState?.validate() ?? false) &&
            _recetaSeleccionada != null;
      case 1:
        return _manoObraKey.currentState?.validate() ?? false;
      case 2:
        if (!(_costosFijosKey.currentState?.validate() ?? true)) {
          return false;
        }
        return !_hayCostosFijosSeleccionados || _unidadesMes > 0;
      case 3:
        return _costosVariables.every((costo) {
          final valor = costo.tipoCalculo == 'porcentaje'
              ? costo.porcentaje
              : costo.monto;
          return valor != null && valor >= 0;
        });
      case 4:
        return _precioKey.currentState?.validate() ?? false;
      default:
        return false;
    }
  }

  void _continuar() {
    if (!_validarPaso(_pasoActual)) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa los datos de este paso.')),
      );
      return;
    }
    if (_pasoActual == 4) {
      _guardar();
    } else {
      setState(() => _pasoActual++);
    }
  }

  void _guardar() {
    for (var paso = 0; paso < 5; paso++) {
      if (!_validarPaso(paso)) {
        setState(() => _pasoActual = paso);
        return;
      }
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
            unidadesEstimadasMes: _unidadesMes,
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
          costoBase: _costoReceta,
          minutosElaboracion: _minutos,
          costoHoraManoObra: _costoHora,
          costoManoObra: _costoManoObra,
          costosVariables: _totalCostosVariables,
          costosFijos: _totalCostosFijos,
          unidadesEstimadasMes: _unidadesMes,
          otrosCostos: _otrosCostos,
          costoTotalProducto: _costoTotal,
          margenGanancia: _margen,
          precioVentaSugerido: _precioSugerido,
          precioVentaFinal: _numero(_precioFinalController.text)!,
          fechaRegistro: productoAnterior?.fechaRegistro ?? DateTime.now(),
          imagePath: _imagePath,
        ),
        costosFijos: costosFijos,
        costosVariables: _costosVariables,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(
        widget.producto == null ? 'Crear producto' : 'Editar producto',
      ),
      content: SizedBox(
        width: 720,
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Stepper(
                  currentStep: _pasoActual,
                  physics: const NeverScrollableScrollPhysics(),
                  onStepTapped: (paso) {
                    if (paso <= _pasoActual || _validarPaso(_pasoActual)) {
                      setState(() => _pasoActual = paso);
                    }
                  },
                  onStepContinue: _continuar,
                  onStepCancel: _pasoActual == 0
                      ? null
                      : () => setState(() => _pasoActual--),
                  controlsBuilder: (context, details) => Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        FilledButton(
                          onPressed: details.onStepContinue,
                          child: Text(
                            _pasoActual == 4 ? 'Guardar producto' : 'Continuar',
                          ),
                        ),
                        if (_pasoActual > 0) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Volver'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  steps: _crearPasos(),
                ),
              ),
            ),
            const Divider(height: 1),
            _ResumenFijo(
              costoTotal: _costoTotal,
              precioSugerido: _precioSugerido,
              precioFinal: _numero(_precioFinalController.text) ?? 0,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  List<Step> _crearPasos() => [
    Step(
      title: const Text('Producto y receta'),
      subtitle: const Text('Define qué vas a vender'),
      isActive: _pasoActual >= 0,
      state: _estadoPaso(0),
      content: Form(
        key: _productoKey,
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
                LocalImagePreview(
                  imagePath: _imagePath,
                  size: 64,
                  fallbackIcon: Icons.restaurant_menu_outlined,
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
            const SizedBox(height: 12),
            DropdownButtonFormField<Receta>(
              initialValue: _recetaSeleccionada,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Seleccionar receta',
              ),
              items: widget.recetas
                  .map(
                    (receta) => DropdownMenuItem(
                      value: receta,
                      child: Text(receta.nombre),
                    ),
                  )
                  .toList(),
              onChanged: _seleccionarReceta,
              validator: (value) =>
                  value == null ? 'Selecciona una receta' : null,
            ),
            if (_recetaSeleccionada case final receta?) ...[
              const SizedBox(height: 12),
              _LineaResumen('Costo total de receta', receta.costoTotal),
              Text('Porciones: ${receta.porciones}'),
              _LineaResumen('Costo por porción', receta.costoPorPorcion),
              const _Ayuda(
                texto:
                    'Este será el costo base del producto. Sale del costo por porción de la receta.',
              ),
              _Resultado(etiqueta: 'Costo base', valor: _costoReceta),
            ],
          ],
        ),
      ),
    ),
    Step(
      title: const Text('Mano de obra'),
      subtitle: const Text('Calcula el valor del tiempo de preparación'),
      isActive: _pasoActual >= 1,
      state: _estadoPaso(1),
      content: Form(
        key: _manoObraKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Ayuda(
              texto:
                  'La mano de obra calcula cuánto vale el tiempo usado para preparar este producto.',
            ),
            _NumberField(
              controller: _minutosController,
              label: '¿Cuánto tiempo toma preparar?',
              suffix: 'min',
              validator: _mayorACero,
            ),
            _NumberField(
              controller: _costoHoraController,
              label: '¿Cuánto vale una hora de trabajo?',
              suffix: 'Bs',
              validator: _mayorACero,
            ),
            const Text('Mano de obra = (minutos / 60) x costo por hora'),
            Text(
              '${_minutos.toStringAsFixed(0)} minutos / 60 x ${_costoHora.toStringAsFixed(2)} Bs = ${_costoManoObra.toStringAsFixed(2)} Bs',
            ),
            _Resultado(
              etiqueta: 'Costo de mano de obra',
              valor: _costoManoObra,
            ),
          ],
        ),
      ),
    ),
    Step(
      title: const Text('Costos que se pagan cada mes'),
      subtitle: const Text('Reparte alquiler, luz, agua y otros pagos'),
      isActive: _pasoActual >= 2,
      state: _estadoPaso(2),
      content: Form(
        key: _costosFijosKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Ayuda(
              texto:
                  'Los costos fijos son pagos mensuales como alquiler, luz, agua o gas. La app reparte ese gasto entre las unidades que esperas vender al mes.',
            ),
            const _Ayuda(
              texto:
                  'Este número se usa para repartir los gastos mensuales entre las unidades que esperas vender.',
            ),
            _NumberField(
              controller: _unidadesMesController,
              label:
                  '¿Cuántas unidades de este producto esperas vender al mes?',
              validator: _validarUnidadesMes,
            ),
            const Text(
              'Costo fijo por producto = monto mensual / unidades estimadas al mes',
            ),
            if (_costosFijos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No hay costos activos para seleccionar.'),
              )
            else
              ..._costosFijos.map(_crearCostoFijo),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              margin: const EdgeInsets.only(top: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total costos fijos seleccionados: ${_totalMensualCostosFijos.toStringAsFixed(2)} Bs/mes',
                    ),
                    Text(
                      'Unidades estimadas al mes: ${_unidadesMes.toStringAsFixed(0)}',
                    ),
                    Text(
                      'Costo fijo por producto: ${_totalCostosFijos.toStringAsFixed(2)} Bs',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    Step(
      title: const Text('Costos que aparecen por cada venta'),
      subtitle: const Text('Envases, bolsas, delivery o comisiones'),
      isActive: _pasoActual >= 3,
      state: _estadoPaso(3),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Ayuda(
            texto:
                'Estos costos aparecen cada vez que vendes un producto. Ejemplo: envase, bolsa, delivery o comisión.',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _abrirCostoVariable,
              icon: const Icon(Icons.add),
              label: const Text('Agregar costo por venta'),
            ),
          ),
          if (_costosVariables.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No agregaste costos por venta.'),
            )
          else
            ...List.generate(_costosVariables.length, _crearCostoVariable),
          const Text(
            'Por unidad: Envase = 1.00 Bs. Porcentaje: Comisión 10% sobre el subtotal actual.',
          ),
          _Resultado(
            etiqueta: 'Subtotal de costos por venta',
            valor: _totalCostosVariables,
          ),
        ],
      ),
    ),
    Step(
      title: const Text('Precio final'),
      subtitle: const Text('Revisa el costo y define tu ganancia'),
      isActive: _pasoActual >= 4,
      state: _estadoPaso(4),
      content: Form(
        key: _precioKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LineaResumen('Costo de receta', _costoReceta),
            _LineaResumen('Mano de obra', _costoManoObra),
            _LineaResumen('Costos mensuales', _totalCostosFijos),
            _LineaResumen('Costos por venta', _totalCostosVariables),
            const Divider(),
            _LineaResumen(
              'Costo total del producto',
              _costoTotal,
              negrita: true,
            ),
            _NumberField(
              controller: _margenController,
              label: 'Margen de ganancia',
              suffix: '%',
              validator: _noNegativo,
            ),
            const Text('Precio sugerido = costo total x (1 + margen / 100)'),
            _Resultado(etiqueta: 'Precio sugerido', valor: _precioSugerido),
            _NumberField(
              controller: _precioFinalController,
              label: 'Precio final de venta',
              suffix: 'Bs',
              validator: _mayorACero,
              onSubmitted: (_) => _guardar(),
            ),
          ],
        ),
      ),
    ),
  ];

  StepState _estadoPaso(int paso) {
    if (_pasoActual > paso) return StepState.complete;
    return _pasoActual == paso ? StepState.editing : StepState.indexed;
  }

  Widget _crearCostoFijo(_CostoFijoSeleccion item) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.costo.nombre),
              subtitle: Text(
                '${item.costo.montoMensual.toStringAsFixed(2)} Bs/mes',
              ),
              value: item.seleccionado,
              onChanged: (value) {
                item.seleccionado = value ?? false;
                _recalcular();
              },
            ),
            if (item.seleccionado)
              Text(
                '${item.costo.montoMensual.toStringAsFixed(2)} Bs / ${_unidadesMes.toStringAsFixed(0)} unidades = ${item.costoProrrateado.toStringAsFixed(2)} Bs por producto',
              ),
          ],
        ),
      ),
    );
  }

  Widget _crearCostoVariable(int index) {
    final costo = _costosVariables[index];
    final detalle = costo.tipoCalculo == 'porcentaje'
        ? '${(costo.porcentaje ?? 0).toStringAsFixed(2)}% sobre subtotal'
        : '${(costo.monto ?? 0).toStringAsFixed(2)} Bs por producto';
    return Card(
      child: ListTile(
        title: Text(costo.nombre),
        subtitle: Text(
          '$detalle\nResultado: ${costo.costoCalculado.toStringAsFixed(2)} Bs',
        ),
        isThreeLine: true,
        trailing: Wrap(
          children: [
            IconButton(
              tooltip: 'Editar',
              onPressed: () => _abrirCostoVariable(index: index),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Eliminar',
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
  }
}

class _CostoFijoSeleccion {
  _CostoFijoSeleccion({
    required this.costo,
    required this.seleccionado,
    required this.unidadesMes,
  });

  final CostoFijo costo;
  final double Function() unidadesMes;
  bool seleccionado;

  double get unidades => unidadesMes();
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
  static const _categorias = {
    'envase': 'Envase',
    'delivery': 'Delivery',
    'comision': 'Comisión',
    'transporte': 'Transporte',
    'empaque': 'Empaque',
    'merma': 'Merma',
    'otro': 'Otro',
  };

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
    if (!_categorias.containsKey(_categoria)) _categoria = 'otro';
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
    if (!_formKey.currentState!.validate()) return;
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
        widget.costo == null ? 'Agregar costo por venta' : 'Editar costo',
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
                  labelText: 'Nombre del costo',
                  hintText: 'Ej. Envase',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Campo obligatorio'
                    : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categorias.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _categoria = value!),
              ),
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                decoration: const InputDecoration(
                  labelText: '¿Cómo se calcula?',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'por_unidad',
                    child: Text('Monto por producto'),
                  ),
                  DropdownMenuItem(
                    value: 'porcentaje',
                    child: Text('Porcentaje sobre subtotal'),
                  ),
                ],
                onChanged: (value) => setState(() => _tipo = value!),
              ),
              _NumberField(
                controller: _valorController,
                label: _tipo == 'porcentaje'
                    ? 'Porcentaje'
                    : 'Monto por producto',
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
              _Resultado(etiqueta: 'Costo calculado', valor: _calculado),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, suffixText: suffix),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        validator: validator,
        onFieldSubmitted: onSubmitted,
      ),
    );
  }
}

class _Ayuda extends StatelessWidget {
  const _Ayuda({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

class _Resultado extends StatelessWidget {
  const _Resultado({required this.etiqueta, required this.valor});

  final String etiqueta;
  final double valor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '$etiqueta: ${valor.toStringAsFixed(2)} Bs',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _LineaResumen extends StatelessWidget {
  const _LineaResumen(this.etiqueta, this.valor, {this.negrita = false});

  final String etiqueta;
  final double valor;
  final bool negrita;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: negrita
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
          ),
          Text(
            '${valor.toStringAsFixed(2)} Bs',
            style: negrita
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
        ],
      ),
    );
  }
}

class _ResumenFijo extends StatelessWidget {
  const _ResumenFijo({
    required this.costoTotal,
    required this.precioSugerido,
    required this.precioFinal,
  });

  final double costoTotal;
  final double precioSugerido;
  final double precioFinal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 20,
        runSpacing: 6,
        children: [
          Text('Costo total: ${costoTotal.toStringAsFixed(2)} Bs'),
          Text('Sugerido: ${precioSugerido.toStringAsFixed(2)} Bs'),
          Text(
            'Precio final: ${precioFinal.toStringAsFixed(2)} Bs',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
