import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../utils/mensajes.dart';
import '../utils/validadores.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _stockCompleto = [];
  bool _isLoading = true;
  String? _error;

  // Controladores para agregar
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _unidadController = TextEditingController();
  final TextEditingController _minimoController = TextEditingController();
  final TextEditingController _stockInicialController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();

  // Tipo de insumo (tela / accesorio)
  String _tipoSeleccionado = 'tela';

  @override
  void initState() {
    super.initState();
    _cargarStock();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _colorController.dispose();
    _unidadController.dispose();
    _minimoController.dispose();
    _stockInicialController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _cargarStock() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _db.getStockCompleto();
      setState(() {
        _stockCompleto = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar stock: $e';
        _isLoading = false;
      });
    }
  }

  // ========== AGREGAR NUEVO INSUMO ==========
  Future<void> _agregarInsumo() async {
    final nombre = _nombreController.text.trim();
    final unidad = _unidadController.text.trim();
    final color = _colorController.text.trim();

    // Validar nombre
    final errorNombre = Validadores.campoRequerido(nombre, nombreCampo: 'Nombre del material');
    if (errorNombre != null) {
      Mensajes.error(context, errorNombre);
      return;
    }

    // Validar unidad
    final errorUnidad = Validadores.campoRequerido(unidad, nombreCampo: 'Unidad de medida');
    if (errorUnidad != null) {
      Mensajes.error(context, errorUnidad);
      return;
    }

    // Validar stock inicial (positivo)
    final stockInicial = double.tryParse(_stockInicialController.text);
    if (stockInicial == null || stockInicial <= 0) {
      Mensajes.error(context, 'La cantidad inicial debe ser mayor a 0');
      return;
    }

    // Validar precio (positivo)
    final precio = double.tryParse(_precioController.text);
    if (precio == null || precio <= 0) {
      Mensajes.error(context, 'El precio debe ser mayor a 0');
      return;
    }

    // Validar stock mínimo (no negativo)
    final minimo = double.tryParse(_minimoController.text) ?? 5;
    if (minimo < 0) {
      Mensajes.error(context, 'El stock mínimo no puede ser negativo');
      return;
    }

    // Si es tela, el color es opcional
    String tipo = _tipoSeleccionado;
    if (tipo == 'tela' && color.isEmpty) {
      final continuar = await Mensajes.confirmarAccion(
        context,
        titulo: 'Color no especificado',
        mensaje: 'No especificó un color para la tela. ¿Desea continuar?',
        botonConfirmacion: 'Continuar',
      );
      if (!continuar) return;
    }

    // Confirmar
    final confirmar = await Mensajes.confirmarAccion(
      context,
      titulo: 'Agregar material',
      mensaje: '¿Agregar "$nombre" al inventario?\n'
               'Tipo: ${tipo == 'tela' ? '🧵 Tela' : '🔧 Accesorio'}\n'
               'Color: ${color.isNotEmpty ? color : 'Sin color'}\n'
               'Stock inicial: $stockInicial $unidad\n'
               'Stock mínimo: $minimo $unidad\n'
               'Precio: Bs ${precio.toStringAsFixed(2)}',
      botonConfirmacion: 'Agregar',
    );

    if (!confirmar) return;

    try {
      final db = await _db.database;

      final idInsumo = await db.insert('insumos', {
        'nombre': nombre,
        'color': color,
        'unidad_medida': unidad,
        'stock_minimo': minimo,
        'precio': precio,
        'tipo': tipo,
      });

      await db.insert('stock', {
        'id_insumo': idInsumo,
        'cantidad_disponible': stockInicial,
      });

      _nombreController.clear();
      _colorController.clear();
      _unidadController.clear();
      _minimoController.clear();
      _stockInicialController.clear();
      _precioController.clear();

      await _cargarStock();
      Navigator.pop(context);

      Mensajes.exito(context, '✅ $nombre agregado al inventario');
    } catch (e) {
      Mensajes.error(context, 'Error al agregar: $e');
    }
  }

  // ========== ACTUALIZAR PRECIO ==========
  Future<void> _actualizarPrecio(int idInsumo, String nombre, double nuevoPrecio) async {
    if (nuevoPrecio <= 0) {
      Mensajes.error(context, 'El precio debe ser mayor a 0');
      return;
    }

    final confirmar = await Mensajes.confirmarAccion(
      context,
      titulo: 'Actualizar precio',
      mensaje: '¿Actualizar precio de "$nombre" a Bs ${nuevoPrecio.toStringAsFixed(2)}?',
      botonConfirmacion: 'Actualizar',
    );

    if (!confirmar) return;

    try {
      final db = await _db.database;
      await db.update(
        'insumos',
        {'precio': nuevoPrecio},
        where: 'id_insumo = ?',
        whereArgs: [idInsumo],
      );
      await _cargarStock();
      Mensajes.exito(context, '✅ Precio de $nombre actualizado');
    } catch (e) {
      Mensajes.error(context, 'Error al actualizar precio: $e');
    }
  }

  // ========== ACTUALIZAR COLOR ==========
  Future<void> _actualizarColor(int idInsumo, String nombre, String nuevoColor) async {
    final confirmar = await Mensajes.confirmarAccion(
      context,
      titulo: 'Actualizar color',
      mensaje: '¿Actualizar color de "$nombre" a "$nuevoColor"?',
      botonConfirmacion: 'Actualizar',
    );

    if (!confirmar) return;

    try {
      final db = await _db.database;
      await db.update(
        'insumos',
        {'color': nuevoColor},
        where: 'id_insumo = ?',
        whereArgs: [idInsumo],
      );
      await _cargarStock();
      Mensajes.exito(context, '✅ Color de $nombre actualizado');
    } catch (e) {
      Mensajes.error(context, 'Error al actualizar color: $e');
    }
  }

  // ========== ACTUALIZAR STOCK ==========
  Future<void> _actualizarStock(int idInsumo, String nombre, double nuevaCantidad) async {
    if (nuevaCantidad < 0) {
      Mensajes.error(context, 'La cantidad no puede ser negativa');
      return;
    }

    final confirmar = await Mensajes.confirmarAccion(
      context,
      titulo: 'Actualizar stock',
      mensaje: '¿Actualizar stock de "$nombre" a $nuevaCantidad?',
      botonConfirmacion: 'Actualizar',
    );

    if (!confirmar) return;

    try {
      await _db.updateStock(idInsumo, nuevaCantidad);
      await _cargarStock();
      Mensajes.exito(context, '✅ Stock de $nombre actualizado');
    } catch (e) {
      Mensajes.error(context, 'Error al actualizar: $e');
    }
  }

  // ========== ELIMINAR INSUMO ==========
  Future<void> _eliminarInsumo(int id, String nombre) async {
    final confirmar = await Mensajes.confirmarEliminar(
      context,
      titulo: 'Eliminar insumo',
      mensaje: '¿Está seguro de eliminar "$nombre" del inventario?',
    );

    if (!confirmar) return;

    try {
      await _db.deleteInsumo(id);
      await _cargarStock();
      Mensajes.exito(context, '🗑️ $nombre eliminado');
    } catch (e) {
      Mensajes.error(context, 'Error al eliminar: $e');
    }
  }

  // ========== DIALOGO PARA AGREGAR ==========
  void _mostrarDialogoAgregar() {
    _nombreController.clear();
    _colorController.clear();
    _unidadController.clear();
    _minimoController.clear();
    _stockInicialController.clear();
    _precioController.clear();
    _tipoSeleccionado = 'tela';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Material'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de material *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'tela', child: Text('🧵 Tela')),
                  DropdownMenuItem(value: 'accesorio', child: Text('🔧 Accesorio')),
                ],
                onChanged: (value) {
                  setState(() {
                    _tipoSeleccionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del material *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Tela Algodón',
                ),
              ),
              const SizedBox(height: 10),
              if (_tipoSeleccionado == 'tela')
                TextField(
                  controller: _colorController,
                  decoration: const InputDecoration(
                    labelText: 'Color (opcional)',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Blanco, Beige, Azul marino',
                    prefixIcon: Icon(Icons.color_lens),
                  ),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: _unidadController,
                decoration: const InputDecoration(
                  labelText: 'Unidad de medida *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: metros, unidades, pares',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _stockInicialController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad inicial *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 50',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio unitario (Bs) *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 45.00',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _minimoController,
                decoration: const InputDecoration(
                  labelText: 'Stock mínimo (alertas)',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 10 (default: 5)',
                  prefixIcon: Icon(Icons.warning_amber),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _agregarInsumo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
            ),
            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========== DIALOGO PARA EDITAR PRECIO ==========
  void _mostrarDialogoEditarPrecio(int idInsumo, String nombre, double precioActual) {
    final controller = TextEditingController(text: precioActual.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actualizar precio de $nombre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Precio actual: Bs ${precioActual.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nuevo precio (Bs)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nuevoPrecio = double.tryParse(controller.text);
              if (nuevoPrecio == null || nuevoPrecio <= 0) {
                Mensajes.error(context, 'Ingrese un precio válido');
                return;
              }
              Navigator.pop(context);
              _actualizarPrecio(idInsumo, nombre, nuevoPrecio);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3A5F),
            ),
            child: const Text('Actualizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========== DIALOGO PARA EDITAR COLOR ==========
  void _mostrarDialogoEditarColor(int idInsumo, String nombre, String colorActual) {
    final controller = TextEditingController(text: colorActual);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actualizar color de $nombre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Color actual: ${colorActual.isNotEmpty ? colorActual : 'Sin color'}'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nuevo color',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.color_lens),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nuevoColor = controller.text.trim();
              Navigator.pop(context);
              _actualizarColor(idInsumo, nombre, nuevoColor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3A5F),
            ),
            child: const Text('Actualizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========== DIALOGO PARA EDITAR STOCK ==========
  void _mostrarDialogoEditarStock(int idInsumo, String nombre, double stockActual) {
    final controller = TextEditingController(text: stockActual.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actualizar stock de $nombre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock actual: $stockActual'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nueva cantidad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nuevaCantidad = double.tryParse(controller.text);
              if (nuevaCantidad == null) {
                Mensajes.error(context, 'Ingrese una cantidad válida');
                return;
              }
              Navigator.pop(context);
              _actualizarStock(idInsumo, nombre, nuevaCantidad);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3A5F),
            ),
            child: const Text('Actualizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Stock'),
        backgroundColor: const Color(0xFF1A3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarStock,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _mostrarDialogoAgregar,
            tooltip: 'Agregar material',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 60, color: Colors.red),
                      const SizedBox(height: 10),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _cargarStock,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _stockCompleto.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory, size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'No hay materiales en el inventario',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Presiona el botón + para agregar',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _stockCompleto.length,
                      itemBuilder: (context, index) {
                        final item = _stockCompleto[index];
                        final idInsumo = item['id_insumo'] as int;
                        final nombre = item['nombre'] as String;
                        final color = item['color'] as String? ?? '';
                        final tipo = item['tipo'] as String? ?? 'tela';
                        final stock = item['cantidad_disponible'] as double;
                        final minimo = item['stock_minimo'] as double;
                        final unidad = item['unidad_medida'] as String;
                        final precio = item['precio'] as double? ?? 0.0;
                        final isCritico = stock <= minimo;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: isCritico ? Colors.red.shade50 : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isCritico
                                ? BorderSide(color: Colors.red.shade300)
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: isCritico
                                  ? Colors.red.shade100
                                  : tipo == 'tela'
                                      ? Colors.blue.shade100
                                      : Colors.orange.shade100,
                              child: Icon(
                                isCritico
                                    ? Icons.warning
                                    : tipo == 'tela'
                                        ? Icons.brush
                                        : Icons.build,
                                color: isCritico ? Colors.red : Colors.blueGrey,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    nombre,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCritico ? Colors.red : Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (tipo == 'tela' && color.isNotEmpty) ...[
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
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Stock: $stock $unidad'),
                                Text('Mínimo: $minimo $unidad'),
                                Text('Precio: Bs ${precio.toStringAsFixed(2)}'),
                                Text(
                                  'Tipo: ${tipo == 'tela' ? '🧵 Tela' : '🔧 Accesorio'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (isCritico)
                                  Text(
                                    '⚠️ Stock crítico',
                                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (tipo == 'tela')
                                  IconButton(
                                    icon: const Icon(Icons.color_lens, color: Colors.purple, size: 20),
                                    onPressed: () => _mostrarDialogoEditarColor(idInsumo, nombre, color),
                                    tooltip: 'Editar color',
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.attach_money, color: Colors.green, size: 20),
                                  onPressed: () => _mostrarDialogoEditarPrecio(idInsumo, nombre, precio),
                                  tooltip: 'Editar precio',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                  onPressed: () => _mostrarDialogoEditarStock(idInsumo, nombre, stock),
                                  tooltip: 'Editar stock',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _eliminarInsumo(idInsumo, nombre),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                            onTap: () => _mostrarDialogoEditarStock(idInsumo, nombre, stock),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAgregar,
        backgroundColor: const Color(0xFF1A3A5F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Helper para convertir nombre de color a color
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