import 'package:flutter/material.dart';

import '../../data/models/producto.dart';
import '../../data/models/venta.dart';
import '../../data/repositories/producto_repository.dart';
import '../../data/repositories/venta_repository.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final VentaRepository _ventaRepository = VentaRepository();
  final ProductoRepository _productoRepository = ProductoRepository();
  late Future<List<Producto>> _productosFuture;
  late Future<List<Venta>> _ventasFuture;

  @override
  void initState() {
    super.initState();
    _productosFuture = _productoRepository.getProductos();
    _ventasFuture = _ventaRepository.getVentas();
  }

  void _recargarVentas() {
    setState(() {
      _ventasFuture = _ventaRepository.getVentas();
    });
  }

  Future<void> _abrirFormulario(
    List<Producto> productos, {
    Venta? venta,
  }) async {
    final resultado = await showDialog<Venta>(
      context: context,
      builder: (context) =>
          _VentaFormDialog(productos: productos, venta: venta),
    );

    if (resultado == null) {
      return;
    }

    if (venta == null) {
      await _ventaRepository.insertVenta(resultado);
    } else {
      await _ventaRepository.updateVenta(resultado);
    }

    if (!mounted) {
      return;
    }

    _recargarVentas();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(venta == null ? 'Venta registrada' : 'Venta actualizada'),
      ),
    );
  }

  Future<void> _confirmarEliminar(Venta venta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: Text('Deseas eliminar la venta de ${venta.nombreProducto}?'),
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

    await _ventaRepository.deleteVenta(venta.id);

    if (!mounted) {
      return;
    }

    _recargarVentas();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Venta eliminada')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ventas')),
      body: FutureBuilder<List<Producto>>(
        future: _productosFuture,
        builder: (context, productosSnapshot) {
          if (productosSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productosSnapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No se pudieron cargar los productos.'),
              ),
            );
          }

          final productos = productosSnapshot.data ?? [];

          if (productos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No hay productos creados. Primero crea un producto o menú.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return FutureBuilder<List<Venta>>(
            future: _ventasFuture,
            builder: (context, ventasSnapshot) {
              if (ventasSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (ventasSnapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No se pudieron cargar las ventas.'),
                  ),
                );
              }

              final ventas = ventasSnapshot.data ?? [];

              if (ventas.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No hay ventas registradas.'),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: ventas.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final venta = ventas[index];

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
                                  venta.nombreProducto,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Cantidad: ${_formatCantidad(venta.cantidad)}',
                                ),
                                Text(
                                  'Venta: ${venta.totalVenta.toStringAsFixed(2)} Bs',
                                ),
                                Text(
                                  'Ganancia: ${venta.ganancia.toStringAsFixed(2)} Bs',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Fecha: ${_formatFecha(venta.fechaVenta)}',
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () =>
                                    _abrirFormulario(productos, venta: venta),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmarEliminar(venta),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<List<Producto>>(
        future: _productosFuture,
        builder: (context, snapshot) {
          final productos = snapshot.data ?? [];

          if (productos.isEmpty) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _abrirFormulario(productos),
            icon: const Icon(Icons.add),
            label: const Text('Registrar venta'),
          );
        },
      ),
    );
  }
}

class _VentaFormDialog extends StatefulWidget {
  const _VentaFormDialog({required this.productos, this.venta});

  final List<Producto> productos;
  final Venta? venta;

  @override
  State<_VentaFormDialog> createState() => _VentaFormDialogState();
}

class _VentaFormDialogState extends State<_VentaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cantidadController;
  late final TextEditingController _precioUnitarioController;
  int? _productoId;
  late DateTime _fechaVenta;

  Producto? get _productoSeleccionado {
    for (final producto in widget.productos) {
      if (producto.id == _productoId) {
        return producto;
      }
    }

    return null;
  }

  double get _cantidad => _leerDouble(_cantidadController.text);
  double get _precioUnitario => _leerDouble(_precioUnitarioController.text);
  double get _costoUnitario =>
      _productoSeleccionado?.costoTotalProducto ??
      widget.venta?.costoUnitario ??
      0;
  double get _totalVenta => _cantidad * _precioUnitario;
  double get _costoTotal => _cantidad * _costoUnitario;
  double get _ganancia => _totalVenta - _costoTotal;

  @override
  void initState() {
    super.initState();
    final venta = widget.venta;
    _productoId = venta?.productoId;
    _fechaVenta = venta?.fechaVenta ?? DateTime.now();
    _cantidadController = TextEditingController(
      text: venta == null ? '1' : _formatCantidad(venta.cantidad),
    );
    _precioUnitarioController = TextEditingController(
      text: venta?.precioUnitario.toStringAsFixed(2) ?? '',
    );

    if (venta == null && widget.productos.isNotEmpty) {
      _seleccionarProducto(widget.productos.first, actualizarEstado: false);
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioUnitarioController.dispose();
    super.dispose();
  }

  void _seleccionarProducto(Producto producto, {bool actualizarEstado = true}) {
    void aplicar() {
      _productoId = producto.id;
      _precioUnitarioController.text = producto.precioVentaFinal
          .toStringAsFixed(2);
    }

    if (actualizarEstado) {
      setState(aplicar);
    } else {
      aplicar();
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaVenta,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha == null) {
      return;
    }

    setState(() {
      _fechaVenta = fecha;
    });
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final producto = _productoSeleccionado;

    if (producto == null) {
      return;
    }

    final venta = Venta(
      id: widget.venta?.id ?? 0,
      productoId: producto.id,
      nombreProducto: producto.nombre,
      cantidad: _cantidad,
      precioUnitario: _precioUnitario,
      totalVenta: _totalVenta,
      costoUnitario: _costoUnitario,
      costoTotal: _costoTotal,
      ganancia: _ganancia,
      fechaVenta: _fechaVenta,
    );

    Navigator.of(context).pop(venta);
  }

  @override
  Widget build(BuildContext context) {
    final producto = _productoSeleccionado;

    return AlertDialog(
      title: Text(widget.venta == null ? 'Registrar venta' : 'Editar venta'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: producto?.id,
                  decoration: const InputDecoration(
                    labelText: 'Producto',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.productos
                      .map(
                        (producto) => DropdownMenuItem<int>(
                          value: producto.id,
                          child: Text(producto.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (productoId) {
                    Producto? producto;

                    for (final item in widget.productos) {
                      if (item.id == productoId) {
                        producto = item;
                        break;
                      }
                    }

                    if (producto != null) {
                      _seleccionarProducto(producto);
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Selecciona un producto.' : null,
                ),
                if (producto != null) ...[
                  const SizedBox(height: 8),
                  Text('Nombre: ${producto.nombre}'),
                  Text(
                    'Precio final: ${producto.precioVentaFinal.toStringAsFixed(2)} Bs',
                  ),
                  Text(
                    'Costo total producto: ${producto.costoTotalProducto.toStringAsFixed(2)} Bs',
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cantidadController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad vendida',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final cantidad = _leerDouble(value ?? '');

                    if (cantidad <= 0) {
                      return 'La cantidad debe ser mayor a 0.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _precioUnitarioController,
                  decoration: const InputDecoration(
                    labelText: 'Precio unitario',
                    suffixText: 'Bs',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final precio = _leerDouble(value ?? '');

                    if (precio <= 0) {
                      return 'El precio unitario debe ser mayor a 0.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _seleccionarFecha,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Fecha de venta: ${_formatFecha(_fechaVenta)}'),
                ),
                const SizedBox(height: 16),
                _VentaResumen(
                  nombreProducto: producto?.nombre ?? 'Sin producto',
                  cantidad: _cantidad,
                  precioUnitario: _precioUnitario,
                  totalVenta: _totalVenta,
                  costoTotal: _costoTotal,
                  ganancia: _ganancia,
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

class _VentaResumen extends StatelessWidget {
  const _VentaResumen({
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.totalVenta,
    required this.costoTotal,
    required this.ganancia,
  });

  final String nombreProducto;
  final double cantidad;
  final double precioUnitario;
  final double totalVenta;
  final double costoTotal;
  final double ganancia;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text('Producto: $nombreProducto'),
            Text('Cantidad: ${_formatCantidad(cantidad)}'),
            Text('Precio unitario: ${precioUnitario.toStringAsFixed(2)} Bs'),
            Text('Total venta: ${totalVenta.toStringAsFixed(2)} Bs'),
            Text('Costo total: ${costoTotal.toStringAsFixed(2)} Bs'),
            Text(
              'Ganancia: ${ganancia.toStringAsFixed(2)} Bs',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

double _leerDouble(String value) {
  return double.tryParse(value.replaceAll(',', '.')) ?? 0;
}

String _formatFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final anio = fecha.year.toString();

  return '$dia/$mes/$anio';
}

String _formatCantidad(double cantidad) {
  if (cantidad == cantidad.roundToDouble()) {
    return cantidad.toStringAsFixed(0);
  }

  return cantidad.toStringAsFixed(2);
}
