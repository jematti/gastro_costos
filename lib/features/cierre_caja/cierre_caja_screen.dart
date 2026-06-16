import 'package:flutter/material.dart';

import '../../data/models/cierre_caja.dart';
import '../../data/repositories/cierre_caja_repository.dart';
import '../../data/repositories/gasto_repository.dart';
import '../../data/repositories/venta_repository.dart';

class CierreCajaScreen extends StatefulWidget {
  const CierreCajaScreen({super.key});

  @override
  State<CierreCajaScreen> createState() => _CierreCajaScreenState();
}

class _CierreCajaScreenState extends State<CierreCajaScreen> {
  final CierreCajaRepository _cierreRepository = CierreCajaRepository();
  final VentaRepository _ventaRepository = VentaRepository();
  final GastoRepository _gastoRepository = GastoRepository();
  final TextEditingController _observacionesController =
      TextEditingController();

  late Future<List<CierreCaja>> _cierresFuture;
  DateTime _fechaSeleccionada = DateTime.now();
  _CierreCalculado? _cierreCalculado;
  bool _calculando = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cierresFuture = _cierreRepository.getCierres();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  void _recargarCierres() {
    setState(() {
      _cierresFuture = _cierreRepository.getCierres();
    });
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha == null) {
      return;
    }

    setState(() {
      _fechaSeleccionada = fecha;
      _cierreCalculado = null;
    });
  }

  Future<void> _calcularCierre() async {
    setState(() {
      _calculando = true;
    });

    final ventas = await _ventaRepository.getVentasByFecha(_fechaSeleccionada);
    final gastos = await _gastoRepository.getGastosByFecha(_fechaSeleccionada);
    final totalVentas = ventas.fold<double>(
      0,
      (sum, venta) => sum + venta.totalVenta,
    );
    final totalCostos = ventas.fold<double>(
      0,
      (sum, venta) => sum + venta.costoTotal,
    );
    final totalGastos = gastos.fold<double>(
      0,
      (sum, gasto) => sum + gasto.monto,
    );
    final gananciaBruta = totalVentas - totalCostos;
    final gananciaNeta = gananciaBruta - totalGastos;

    if (!mounted) {
      return;
    }

    setState(() {
      _cierreCalculado = _CierreCalculado(
        fecha: _fechaNormalizada(_fechaSeleccionada),
        totalVentas: totalVentas,
        totalCostos: totalCostos,
        gananciaBruta: gananciaBruta,
        totalGastos: totalGastos,
        gananciaNeta: gananciaNeta,
        cantidadVentas: ventas.length,
        cantidadGastos: gastos.length,
      );
      _calculando = false;
    });
  }

  Future<void> _guardarCierre() async {
    final calculado = _cierreCalculado;

    if (calculado == null || calculado.sinMovimientos) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    final cierreExistente = await _cierreRepository.getCierreByFecha(
      calculado.fecha,
    );

    if (!mounted) {
      return;
    }

    var reemplazar = false;

    if (cierreExistente != null) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cierre existente'),
          content: Text(
            'Ya existe un cierre para ${_formatFecha(calculado.fecha)}. Deseas reemplazarlo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reemplazar'),
            ),
          ],
        ),
      );

      if (confirmar != true) {
        setState(() {
          _guardando = false;
        });
        return;
      }

      reemplazar = true;
    }

    final cierre = CierreCaja(
      id: cierreExistente?.id ?? 0,
      fecha: calculado.fecha,
      horaCierre: _horaActual(),
      totalVentas: calculado.totalVentas,
      totalCostos: calculado.totalCostos,
      gananciaBruta: calculado.gananciaBruta,
      totalGastos: calculado.totalGastos,
      gananciaNeta: calculado.gananciaNeta,
      observaciones: _observacionesController.text.trim(),
    );

    if (reemplazar) {
      await _cierreRepository.updateCierreCaja(cierre);
    } else {
      await _cierreRepository.insertCierreCaja(cierre);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _guardando = false;
    });
    _observacionesController.clear();
    _recargarCierres();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cierre guardado correctamente')),
    );
  }

  Future<void> _confirmarEliminar(CierreCaja cierre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cierre'),
        content: Text(
          'Deseas eliminar el cierre de ${_formatFecha(cierre.fecha)}?',
        ),
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

    await _cierreRepository.deleteCierreCaja(cierre.id);

    if (!mounted) {
      return;
    }

    _recargarCierres();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cierre eliminado')));
  }

  @override
  Widget build(BuildContext context) {
    final calculado = _cierreCalculado;

    return Scaffold(
      appBar: AppBar(title: const Text('Cierre de caja')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PanelCalculo(
            fecha: _fechaSeleccionada,
            calculando: _calculando,
            guardando: _guardando,
            cierreCalculado: calculado,
            observacionesController: _observacionesController,
            onSeleccionarFecha: _seleccionarFecha,
            onCalcular: _calcularCierre,
            onGuardar: _guardarCierre,
          ),
          const SizedBox(height: 16),
          Text(
            'Cierres anteriores',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<CierreCaja>>(
            future: _cierresFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No se pudieron cargar los cierres.'),
                  ),
                );
              }

              final cierres = snapshot.data ?? [];

              if (cierres.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No hay cierres guardados.'),
                  ),
                );
              }

              return Column(
                children: cierres
                    .map(
                      (cierre) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CierreCard(
                          cierre: cierre,
                          onEliminar: () => _confirmarEliminar(cierre),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PanelCalculo extends StatelessWidget {
  const _PanelCalculo({
    required this.fecha,
    required this.calculando,
    required this.guardando,
    required this.cierreCalculado,
    required this.observacionesController,
    required this.onSeleccionarFecha,
    required this.onCalcular,
    required this.onGuardar,
  });

  final DateTime fecha;
  final bool calculando;
  final bool guardando;
  final _CierreCalculado? cierreCalculado;
  final TextEditingController observacionesController;
  final VoidCallback onSeleccionarFecha;
  final VoidCallback onCalcular;
  final VoidCallback onGuardar;

  @override
  Widget build(BuildContext context) {
    final calculado = cierreCalculado;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calcular cierre',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onSeleccionarFecha,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text('Fecha: ${_formatFecha(fecha)}'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: calculando ? null : onCalcular,
              icon: calculando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate_outlined),
              label: const Text('Calcular cierre del dia'),
            ),
            if (calculado != null) ...[
              const SizedBox(height: 16),
              if (calculado.sinMovimientos)
                const Text('No hay movimientos para esta fecha.')
              else ...[
                _ResumenCierre(calculado: calculado),
                const SizedBox(height: 12),
                TextField(
                  controller: observacionesController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: guardando ? null : onGuardar,
                  icon: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Guardar cierre'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ResumenCierre extends StatelessWidget {
  const _ResumenCierre({required this.calculado});

  final _CierreCalculado calculado;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fecha: ${_formatFecha(calculado.fecha)}'),
            const SizedBox(height: 12),
            Text('Ventas', style: Theme.of(context).textTheme.titleSmall),
            Text('Total ventas: ${_bs(calculado.totalVentas)}'),
            Text('Costo productos vendidos: ${_bs(calculado.totalCostos)}'),
            Text('Ganancia bruta: ${_bs(calculado.gananciaBruta)}'),
            const SizedBox(height: 12),
            Text('Gastos', style: Theme.of(context).textTheme.titleSmall),
            Text('Total gastos: ${_bs(calculado.totalGastos)}'),
            const SizedBox(height: 12),
            Text('Resultado', style: Theme.of(context).textTheme.titleSmall),
            Text(
              'Ganancia neta: ${_bs(calculado.gananciaNeta)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _CierreCard extends StatelessWidget {
  const _CierreCard({required this.cierre, required this.onEliminar});

  final CierreCaja cierre;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
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
                    '${_formatFecha(cierre.fecha)} - ${cierre.horaCierre}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text('Ventas: ${_bs(cierre.totalVentas)}'),
                  Text('Gastos: ${_bs(cierre.totalGastos)}'),
                  Text(
                    'Ganancia neta: ${_bs(cierre.gananciaNeta)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (cierre.observaciones.trim().isNotEmpty)
                    Text('Nota: ${cierre.observaciones.trim()}'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: onEliminar,
            ),
          ],
        ),
      ),
    );
  }
}

class _CierreCalculado {
  const _CierreCalculado({
    required this.fecha,
    required this.totalVentas,
    required this.totalCostos,
    required this.gananciaBruta,
    required this.totalGastos,
    required this.gananciaNeta,
    required this.cantidadVentas,
    required this.cantidadGastos,
  });

  final DateTime fecha;
  final double totalVentas;
  final double totalCostos;
  final double gananciaBruta;
  final double totalGastos;
  final double gananciaNeta;
  final int cantidadVentas;
  final int cantidadGastos;

  bool get sinMovimientos => cantidadVentas == 0 && cantidadGastos == 0;
}

DateTime _fechaNormalizada(DateTime fecha) {
  return DateTime(fecha.year, fecha.month, fecha.day);
}

String _bs(double value) {
  return '${value.toStringAsFixed(2)} Bs';
}

String _horaActual() {
  final now = DateTime.now();
  final hora = now.hour.toString().padLeft(2, '0');
  final minuto = now.minute.toString().padLeft(2, '0');

  return '$hora:$minuto';
}

String _formatFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final anio = fecha.year.toString();

  return '$dia/$mes/$anio';
}
