import 'package:flutter/material.dart';

import '../../data/models/gasto.dart';
import '../../data/repositories/gasto_repository.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final GastoRepository _gastoRepository = GastoRepository();
  late Future<List<Gasto>> _gastosFuture;

  @override
  void initState() {
    super.initState();
    _gastosFuture = _gastoRepository.getGastos();
  }

  void _recargarGastos() {
    setState(() {
      _gastosFuture = _gastoRepository.getGastos();
    });
  }

  Future<void> _abrirFormulario({Gasto? gasto}) async {
    final resultado = await showDialog<Gasto>(
      context: context,
      builder: (context) => _GastoFormDialog(gasto: gasto),
    );

    if (resultado == null) {
      return;
    }

    if (gasto == null) {
      await _gastoRepository.insertGasto(resultado);
    } else {
      await _gastoRepository.updateGasto(resultado);
    }

    if (!mounted) {
      return;
    }

    _recargarGastos();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(gasto == null ? 'Gasto registrado' : 'Gasto actualizado'),
      ),
    );
  }

  Future<void> _confirmarEliminar(Gasto gasto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('Deseas eliminar ${gasto.concepto}?'),
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

    await _gastoRepository.deleteGasto(gasto.id);

    if (!mounted) {
      return;
    }

    _recargarGastos();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Gasto eliminado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: FutureBuilder<List<Gasto>>(
        future: _gastosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No se pudieron cargar los gastos.'),
              ),
            );
          }

          final gastos = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _GastosResumen(gastos: gastos),
              const SizedBox(height: 12),
              if (gastos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text('No hay gastos registrados.')),
                )
              else
                ...gastos.map(
                  (gasto) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _GastoCard(
                      gasto: gasto,
                      onEditar: () => _abrirFormulario(gasto: gasto),
                      onEliminar: () => _confirmarEliminar(gasto),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Registrar gasto'),
      ),
    );
  }
}

class _GastosResumen extends StatelessWidget {
  const _GastosResumen({required this.gastos});

  final List<Gasto> gastos;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final total = gastos.fold<double>(0, (sum, gasto) => sum + gasto.monto);
    final totalHoy = gastos
        .where((gasto) => _esMismaFecha(gasto.fechaGasto, hoy))
        .fold<double>(0, (sum, gasto) => sum + gasto.monto);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Total gastos registrados: ${total.toStringAsFixed(2)} Bs'),
            Text('Total gastos de hoy: ${totalHoy.toStringAsFixed(2)} Bs'),
            Text('Cantidad de gastos: ${gastos.length}'),
          ],
        ),
      ),
    );
  }
}

class _GastoCard extends StatelessWidget {
  const _GastoCard({
    required this.gasto,
    required this.onEditar,
    required this.onEliminar,
  });

  final Gasto gasto;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final observacion = gasto.observacion.trim();

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
                    '${_emojiCategoria(gasto.categoria)} ${gasto.concepto}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${gasto.monto.toStringAsFixed(2)} Bs',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Categoría: ${gasto.categoria}'),
                  Text('Fecha: ${_formatFecha(gasto.fechaGasto)}'),
                  if (observacion.isNotEmpty) Text('Obs: $observacion'),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEditar,
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onEliminar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GastoFormDialog extends StatefulWidget {
  const _GastoFormDialog({this.gasto});

  final Gasto? gasto;

  @override
  State<_GastoFormDialog> createState() => _GastoFormDialogState();
}

class _GastoFormDialogState extends State<_GastoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _conceptoController;
  late final TextEditingController _montoController;
  late final TextEditingController _observacionController;
  late DateTime _fechaGasto;
  String? _categoria;

  @override
  void initState() {
    super.initState();
    final gasto = widget.gasto;
    _conceptoController = TextEditingController(text: gasto?.concepto ?? '');
    _montoController = TextEditingController(
      text: gasto?.monto.toStringAsFixed(2) ?? '',
    );
    _observacionController = TextEditingController(
      text: gasto?.observacion ?? '',
    );
    _categoria = gasto?.categoria ?? _categorias.first;
    _fechaGasto = gasto?.fechaGasto ?? DateTime.now();
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaGasto,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha == null) {
      return;
    }

    setState(() {
      _fechaGasto = fecha;
    });
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final categoria = _categoria;

    if (categoria == null) {
      return;
    }

    final gasto = Gasto(
      id: widget.gasto?.id ?? 0,
      concepto: _conceptoController.text.trim(),
      monto: _leerDouble(_montoController.text),
      categoria: categoria,
      fechaGasto: _fechaGasto,
      observacion: _observacionController.text.trim(),
    );

    Navigator.of(context).pop(gasto);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.gasto == null ? 'Registrar gasto' : 'Editar gasto'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _conceptoController,
                  decoration: const InputDecoration(
                    labelText: 'Concepto',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'El concepto es obligatorio.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _montoController,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    suffixText: 'Bs',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final monto = _leerDouble(value ?? '');

                    if (monto <= 0) {
                      return 'El monto debe ser mayor a 0.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoria,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: _categorias
                      .map(
                        (categoria) => DropdownMenuItem<String>(
                          value: categoria,
                          child: Text(
                            '${_emojiCategoria(categoria)} $categoria',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (categoria) {
                    setState(() {
                      _categoria = categoria;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Selecciona una categoría.' : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _seleccionarFecha,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text('Fecha de gasto: ${_formatFecha(_fechaGasto)}'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacionController,
                  decoration: const InputDecoration(
                    labelText: 'Observación',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
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

const List<String> _categorias = [
  'alquiler',
  'luz',
  'agua',
  'gas',
  'internet',
  'transporte',
  'envases',
  'mantenimiento',
  'sueldo',
  'compra_menor',
  'delivery',
  'comision',
  'otro',
];

String _emojiCategoria(String categoria) {
  switch (categoria) {
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
    case 'transporte':
      return '🚕';
    case 'envases':
      return '📦';
    case 'mantenimiento':
      return '🛠️';
    case 'sueldo':
      return '👨‍🍳';
    case 'compra_menor':
      return '🧾';
    case 'delivery':
      return '🛵';
    case 'comision':
      return '💳';
    case 'otro':
      return '🧺';
    default:
      return '🧺';
  }
}

double _leerDouble(String value) {
  return double.tryParse(value.replaceAll(',', '.')) ?? 0;
}

bool _esMismaFecha(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final anio = fecha.year.toString();

  return '$dia/$mes/$anio';
}
