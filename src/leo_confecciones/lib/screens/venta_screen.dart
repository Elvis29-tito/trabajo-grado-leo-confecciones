import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/productos_provider.dart';
import '../providers/clientes_provider.dart';
import '../models/producto.dart';
import '../models/cliente.dart';
import '../database/database_helper.dart';
import '../utils/mensajes.dart';
import '../utils/validadores.dart';

class VentaScreen extends StatefulWidget {
  const VentaScreen({super.key});

  @override
  State<VentaScreen> createState() => _VentaScreenState();
}

class _VentaScreenState extends State<VentaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  Producto? _productoSeleccionado;
  Cliente? _clienteSeleccionado;
  String _mensaje = '';
  bool _isLoading = false;
  final int _idUsuario = 1;

  // Para venta por metro
  Map<String, dynamic>? _insumoSeleccionado;
  final TextEditingController _cantidadMetrosController = TextEditingController();
  List<Map<String, dynamic>> _insumosDisponibles = [];

  String _metodoPago = 'efectivo';
  int _tabIndex = 0;

  final DatabaseHelper _db = DatabaseHelper();
  bool _datosCargados = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _tabIndex = _tabController.index;
          _mensaje = '';
          _productoSeleccionado = null;
          _insumoSeleccionado = null;
        });
      }
    });
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final productosProvider = Provider.of<ProductosProvider>(context, listen: false);
      final clientesProvider = Provider.of<ClientesProvider>(context, listen: false);
      
      await Future.wait([
        productosProvider.cargarProductos(),
        clientesProvider.cargarClientes(),
        _cargarInsumos(),
      ]);
      
      if (mounted) {
        setState(() {
          _datosCargados = true;
        });
      }
    } catch (e) {
      print('Error cargando datos: $e');
      if (mounted) {
        setState(() {
          _datosCargados = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cantidadMetrosController.dispose();
    super.dispose();
  }

  // ============================================================
  // CARGAR INSUMOS (TELAS) DESDE SQLite
  // ============================================================
  Future<void> _cargarInsumos() async {
    try {
      final telas = await _db.getTelas();
      
      if (mounted) {
        setState(() {
          _insumosDisponibles = telas;
        });
      }
    } catch (e) {
      print('Error al cargar insumos: $e');
    }
  }

  // ============================================================
  // REGISTRAR VENTA DE CORTINA
  // ============================================================
  void _registrarVentaCortina(BuildContext context) async {
    if (_clienteSeleccionado == null) {
      Mensajes.error(context, 'Seleccione un cliente');
      return;
    }

    if (_productoSeleccionado == null) {
      Mensajes.error(context, 'Seleccione una cortina');
      return;
    }

    final resumen = '''
Cliente: ${_clienteSeleccionado!.nombre}
Producto: ${_productoSeleccionado!.nombre}
Precio: ${_productoSeleccionado!.precioBase.toStringAsFixed(2)} Bs
Método de pago: ${_metodoPago.toUpperCase()}
''';

    final confirmar = await Mensajes.confirmarAccion(
      context,
      titulo: 'Confirmar venta',
      mensaje: resumen,
      botonConfirmacion: '✅ Vender',
      colorBoton: Colors.green,
    );

    if (!confirmar) return;

    setState(() {
      _isLoading = true;
      _mensaje = '';
    });

    try {
      final provider = Provider.of<ProductosProvider>(context, listen: false);
      
      final success = await provider.venderProducto(
        _productoSeleccionado!.id!,
        _clienteSeleccionado!.id!,
        _idUsuario,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (success) {
          Mensajes.exito(context, '✅ Venta registrada exitosamente');
          _productoSeleccionado = null;
          _clienteSeleccionado = null;
          provider.cargarProductos();
        } else {
          Mensajes.error(context, provider.error ?? 'Error al registrar venta');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        Mensajes.error(context, 'Error: $e');
      });
    }
  }

  // ============================================================
  // REGISTRAR VENTA POR METRO
  // ============================================================
  void _registrarVentaPorMetro(BuildContext context) async {
    if (_clienteSeleccionado == null) {
      Mensajes.error(context, 'Seleccione un cliente');
      return;
    }

    if (_insumoSeleccionado == null) {
      Mensajes.error(context, 'Seleccione una tela');
      return;
    }

    final cantidad = double.tryParse(_cantidadMetrosController.text);
    if (cantidad == null || cantidad <= 0) {
      Mensajes.error(context, 'Ingrese una cantidad válida mayor a 0');
      return;
    }

    final stockActual = _insumoSeleccionado!['cantidad_disponible'] as double? ?? 0;
    if (cantidad > stockActual) {
      Mensajes.error(
        context,
        'Stock insuficiente. Disponible: $stockActual ${_insumoSeleccionado!['unidad_medida']}',
      );
      return;
    }

    final precio = _insumoSeleccionado!['precio'] as double? ?? 0.0;
    final total = cantidad * precio;

    final resumen = '''
Cliente: ${_clienteSeleccionado!.nombre}
Producto: ${_insumoSeleccionado!['nombre']}
Color: ${_insumoSeleccionado!['color'] ?? 'Sin color'}
Cantidad: ${cantidad.toStringAsFixed(1)} ${_insumoSeleccionado!['unidad_medida']}
Precio unitario: Bs ${precio.toStringAsFixed(2)}
Total: Bs ${total.toStringAsFixed(2)}
Método de pago: ${_metodoPago.toUpperCase()}
''';

    final confirmar = await Mensajes.confirmarAccion(
      context,
      titulo: 'Confirmar venta por metro',
      mensaje: resumen,
      botonConfirmacion: '✅ Vender',
      colorBoton: Colors.green,
    );

    if (!confirmar) return;

    setState(() {
      _isLoading = true;
      _mensaje = '';
    });

    try {
      final idInsumo = _insumoSeleccionado!['id_insumo'] as int;
      final nuevaCantidad = stockActual - cantidad;

      await _db.updateStock(idInsumo, nuevaCantidad);

      await _db.insertMovimientoStock({
        'id_insumo': idInsumo,
        'id_usuario': _idUsuario,
        'tipo': 'salida',
        'cantidad': cantidad,
        'fecha_hora': DateTime.now().toIso8601String(),
        'referencia': 'Venta por metro',
        'responsable': 'Sistema',
      });

      final idVenta = await _db.insertVenta({
        'id_cliente': _clienteSeleccionado!.id!,
        'id_usuario': _idUsuario,
        'fecha': DateTime.now().toIso8601String(),
        'total': total,
        'estado': _metodoPago,
      });

      await _db.insertDetalleVenta({
        'id_venta': idVenta,
        'id_producto': 0,
        'cantidad': cantidad.toInt(),
        'precio_unitario': precio,
        'subtotal': total,
      });

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        Mensajes.exito(context, '✅ Venta por metro registrada: ${cantidad.toStringAsFixed(1)} m');
        _insumoSeleccionado = null;
        _clienteSeleccionado = null;
        _cantidadMetrosController.clear();
        _cargarInsumos();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        Mensajes.error(context, 'Error: $e');
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final productosProvider = Provider.of<ProductosProvider>(context);
    final clientesProvider = Provider.of<ClientesProvider>(context);
    
    final clientes = clientesProvider.clientes;
    final productosFinalizados = productosProvider.productosFinalizados;

    if (productosProvider.isLoading || clientesProvider.isLoading || !_datosCargados) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Registrar Venta'),
          backgroundColor: const Color(0xFF1A3A5F),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Venta'),
        backgroundColor: const Color(0xFF1A3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              productosProvider.cargarProductos();
              clientesProvider.cargarClientes();
              _cargarInsumos();
            },
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cortinas'),
            Tab(text: 'Telas por metro'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CLIENTE
            const Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            DropdownButtonFormField<Cliente>(
              value: _clienteSeleccionado,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Seleccione un cliente',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: clientes.map((cliente) {
                return DropdownMenuItem<Cliente>(
                  value: cliente,
                  child: Text(cliente.nombre),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _clienteSeleccionado = value;
                  _mensaje = '';
                });
              },
            ),
            const SizedBox(height: 15),

            // PESTAÑAS
            Expanded(
              child: _tabIndex == 0 
                  ? _buildCortinasTab(productosProvider)
                  : _buildTelasTab(),
            ),

            const SizedBox(height: 15),

            // MÉTODO DE PAGO
            const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Row(
              children: [
                _buildMetodoPagoChip('Efectivo', 'efectivo', Icons.money, Colors.green),
                const SizedBox(width: 8),
                _buildMetodoPagoChip('QR', 'qr', Icons.qr_code, Colors.blue),
                const SizedBox(width: 8),
                _buildMetodoPagoChip('Crédito', 'credito', Icons.credit_card, Colors.orange),
              ],
            ),
            const SizedBox(height: 15),

            // BOTÓN REGISTRAR
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _tabIndex == 0
                      ? (_productoSeleccionado != null && _clienteSeleccionado != null && !_isLoading)
                          ? () => _registrarVentaCortina(context)
                          : null
                      : (_insumoSeleccionado != null && _clienteSeleccionado != null && !_isLoading)
                          ? () => _registrarVentaPorMetro(context)
                          : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF27AE60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'REGISTRAR VENTA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),

            if (_clienteSeleccionado == null) ...[
              const SizedBox(height: 8),
              const Text('⚠️ Seleccione un cliente', style: TextStyle(color: Colors.orange, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PESTAÑA: CORTINAS
  // ============================================================
  Widget _buildCortinasTab(ProductosProvider provider) {
    final productosFinalizados = provider.productosFinalizados;

    if (productosFinalizados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory, size: 60, color: Colors.grey),
            const SizedBox(height: 10),
            const Text(
              'No hay cortinas finalizadas',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 5),
            const Text(
              'Finaliza una cortina en producción primero',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.separated(
        itemCount: productosFinalizados.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final producto = productosFinalizados[index];
          final isSelected = _productoSeleccionado?.id == producto.id;

          return ListTile(
            tileColor: isSelected ? Colors.green.shade50 : null,
            title: Text(
              producto.nombre,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text('Precio: ${producto.precioBase.toStringAsFixed(2)} Bs'),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() {
                _productoSeleccionado = isSelected ? null : producto;
                _mensaje = '';
              });
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // PESTAÑA: TELAS POR METRO (CORREGIDA)
  // ============================================================
  Widget _buildTelasTab() {
    if (_insumosDisponibles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'No hay telas disponibles',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Seleccionar tela', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView.separated(
              itemCount: _insumosDisponibles.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final insumo = _insumosDisponibles[index];
                final isSelected = _insumoSeleccionado?['id_insumo'] == insumo['id_insumo'];
                final precio = insumo['precio'] as double? ?? 0.0;
                final color = insumo['color'] as String? ?? '';
                final nombre = insumo['nombre'] ?? 'Sin nombre';
                final unidad = insumo['unidad_medida'] ?? 'unidad';
                final stock = insumo['cantidad_disponible'] as double? ?? 0;

                return ListTile(
                  tileColor: isSelected ? Colors.blue.shade50 : null,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (color.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Color: $color',
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getColorFromString(color),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($color)',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    'Stock: $stock $unidad | Precio: Bs ${precio.toStringAsFixed(2)}',
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    setState(() {
                      _insumoSeleccionado = isSelected ? null : insumo;
                      _mensaje = '';
                    });
                  },
                );
              },
            ),
          ),
        ),
        if (_insumoSeleccionado != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('Seleccionado: ${_insumoSeleccionado!['nombre']}'),
                  ],
                ),
                if ((_insumoSeleccionado!['color'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Color: ${_insumoSeleccionado!['color']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Precio: Bs ${(_insumoSeleccionado!['precio'] as double? ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cantidadMetrosController,
                  decoration: InputDecoration(
                    labelText: 'Cantidad (${_insumoSeleccionado!['unidad_medida']})',
                    border: const OutlineInputBorder(),
                    suffixText: _insumoSeleccionado!['unidad_medida'],
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // MÉTODO DE PAGO
  // ============================================================
  Widget _buildMetodoPagoChip(String label, String value, IconData iconData, Color color) {
    final isSelected = _metodoPago == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 16, color: isSelected ? color : Colors.grey),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _metodoPago = value;
        });
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
    );
  }

  // ============================================================
  // HELPER: CONVERTIR NOMBRE DE COLOR A COLOR
  // ============================================================
  Color _getColorFromString(String colorName) {
    final colors = {
      'blanco': Colors.white,
      'negro': Colors.black,
      'rojo': Colors.red,
      'azul': Colors.blue,
      'verde': Colors.green,
      'amarillo': Colors.yellow,
      'naranja': Colors.orange,
      'morado': Colors.purple,
      'rosa': Colors.pink,
      'gris': Colors.grey,
      'beige': Colors.brown.shade100,
      'marron': Colors.brown,
      'celeste': Colors.lightBlue,
      'cafe': Colors.brown,
      'crema': const Color(0xFFFFF8E7),
      'dorado': Colors.amber,
      'plateado': Colors.grey.shade300,
    };
    return colors[colorName.toLowerCase()] ?? Colors.grey.shade300;
  }
}