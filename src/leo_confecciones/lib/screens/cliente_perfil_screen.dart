import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cliente.dart';
import '../providers/clientes_provider.dart';
import '../database/database_helper.dart';
import '../utils/mensajes.dart';
import '../utils/validadores.dart';

class ClientePerfilScreen extends StatefulWidget {
  final Cliente cliente;

  const ClientePerfilScreen({super.key, required this.cliente});

  @override
  State<ClientePerfilScreen> createState() => _ClientePerfilScreenState();
}

class _ClientePerfilScreenState extends State<ClientePerfilScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nombreController.text = widget.cliente.nombre;
    _telefonoController.text = widget.cliente.telefono ?? '';
    _direccionController.text = widget.cliente.direccion ?? '';
    _cargarPedidos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  // ============================================================
  // CARGAR PEDIDOS DEL CLIENTE (CORREGIDO)
  // ============================================================
  Future<void> _cargarPedidos() async {
    setState(() => _isLoading = true);

    try {
      final db = await _db.database;
      
      // 👈 CONSULTA CORREGIDA (sin id_producto)
      final result = await db.rawQuery('''
        SELECT 
          v.id_venta,
          v.fecha,
          v.total,
          v.estado as metodo_pago,
          'Venta' as producto,
          c.nombre as cliente_nombre
        FROM ventas v
        INNER JOIN clientes c ON v.id_cliente = c.id_cliente
        WHERE v.id_cliente = ?
        ORDER BY v.fecha DESC
      ''', [widget.cliente.id]);

      // También obtener cotizaciones del cliente
      final cotizaciones = await db.rawQuery('''
        SELECT 
          id as id_cotizacion,
          fecha,
          precioFinal as total,
          estado,
          'Cotización' as tipo,
          tela
        FROM cotizaciones
        WHERE cliente = ?
        ORDER BY fecha DESC
      ''', [widget.cliente.nombre]);

      setState(() {
        _pedidos = result;
        _pedidos.addAll(cotizaciones);
        _pedidos.sort((a, b) => (b['fecha'] ?? '').compareTo(a['fecha'] ?? ''));
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando pedidos: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        Mensajes.error(context, 'Error al cargar pedidos: $e');
      }
    }
  }

  // ============================================================
  // ACTUALIZAR CLIENTE
  // ============================================================
  Future<void> _actualizarCliente() async {
    final nombre = _nombreController.text.trim();
    final telefono = _telefonoController.text.trim();
    final direccion = _direccionController.text.trim();

    final RegExp soloLetras = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!soloLetras.hasMatch(nombre)) {
      Mensajes.error(context, '⚠️ El nombre solo puede contener letras y espacios');
      return;
    }

    if (nombre.isEmpty) {
      Mensajes.error(context, 'El nombre del cliente es obligatorio');
      return;
    }

    final clienteActualizado = Cliente(
      id: widget.cliente.id,
      nombre: nombre,
      telefono: telefono,
      direccion: direccion,
    );

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<ClientesProvider>(context, listen: false);
      final success = await provider.actualizarCliente(clienteActualizado);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        Mensajes.exito(context, '✅ Cliente actualizado correctamente');
        setState(() => _isEditing = false);
        Navigator.pop(context, true);
      } else {
        Mensajes.error(context, 'Error al actualizar cliente');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Mensajes.error(context, 'Error: $e');
    }
  }

  // ============================================================
  // ELIMINAR CLIENTE
  // ============================================================
  Future<void> _eliminarCliente() async {
    final confirmar = await Mensajes.confirmarEliminar(
      context,
      titulo: 'Eliminar cliente',
      mensaje: '¿Está seguro de eliminar a "${widget.cliente.nombre}"? Esta acción no se puede deshacer.',
    );

    if (!confirmar) return;

    try {
      final provider = Provider.of<ClientesProvider>(context, listen: false);
      final success = await provider.eliminarCliente(widget.cliente.id!);

      if (!mounted) return;

      if (success) {
        Mensajes.exito(context, '🗑️ Cliente eliminado');
        Navigator.pop(context, true);
      } else {
        Mensajes.error(context, 'Error al eliminar cliente');
      }
    } catch (e) {
      Mensajes.error(context, 'Error: $e');
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '✏️ Editar Cliente' : widget.cliente.nombre),
        backgroundColor: const Color(0xFF1A3A5F),
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.save, color: Colors.green),
              onPressed: _actualizarCliente,
              tooltip: 'Guardar cambios',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nombreController.text = widget.cliente.nombre;
                  _telefonoController.text = widget.cliente.telefono ?? '';
                  _direccionController.text = widget.cliente.direccion ?? '';
                });
              },
              tooltip: 'Cancelar edición',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Editar perfil',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _eliminarCliente,
              tooltip: 'Eliminar cliente',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPedidos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // PERFIL DEL CLIENTE
                  // ============================================
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: const Color(0xFF1A3A5F),
                                child: Text(
                                  widget.cliente.nombre[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_isEditing) ...[
                                      TextField(
                                        controller: _nombreController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nombre completo *',
                                          border: OutlineInputBorder(),
                                          hintText: 'Ej: Juan Pérez',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ] else ...[
                                      Text(
                                        widget.cliente.nombre,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'ID: ${widget.cliente.id}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          
                          // Teléfono
                          if (_isEditing) ...[
                            TextField(
                              controller: _telefonoController,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                                hintText: 'Ej: 78945612',
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 8),
                          ] else ...[
                            Row(
                              children: [
                                const Icon(Icons.phone, color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  widget.cliente.telefono?.isNotEmpty == true
                                      ? '📞 ${widget.cliente.telefono}'
                                      : '📞 Sin teléfono',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 8),
                          
                          // Dirección
                          if (_isEditing) ...[
                            TextField(
                              controller: _direccionController,
                              decoration: const InputDecoration(
                                labelText: 'Dirección',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                                hintText: 'Ej: Calle 1 N°123',
                              ),
                            ),
                            const SizedBox(height: 8),
                          ] else ...[
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  widget.cliente.direccion?.isNotEmpty == true
                                      ? '📍 ${widget.cliente.direccion}'
                                      : '📍 Sin dirección',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                          
                          if (_isEditing) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _actualizarCliente,
                                    icon: const Icon(Icons.save, color: Colors.white),
                                    label: const Text('Guardar cambios'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                        _nombreController.text = widget.cliente.nombre;
                                        _telefonoController.text = widget.cliente.telefono ?? '';
                                        _direccionController.text = widget.cliente.direccion ?? '';
                                      });
                                    },
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    label: const Text('Cancelar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ============================================
                  // HISTORIAL DE PEDIDOS
                  // ============================================
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.history, color: Color(0xFF1A3A5F)),
                              SizedBox(width: 8),
                              Text(
                                '📋 Historial de Pedidos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A3A5F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_pedidos.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'No hay pedidos registrados',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _pedidos.length > 10 ? 10 : _pedidos.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final pedido = _pedidos[index];
                                final esCotizacion = pedido.containsKey('id_cotizacion');
                                final id = esCotizacion 
                                    ? pedido['id_cotizacion'] 
                                    : pedido['id_venta'];
                                final fecha = pedido['fecha']?.split('T')[0] ?? 'Sin fecha';
                                final total = pedido['total'] as double? ?? 0.0;
                                final estado = pedido['estado'] ?? 'pendiente';
                                final tipo = esCotizacion ? '📄 Cotización' : '🛒 Venta';
                                final producto = pedido['producto'] ?? pedido['tela'] ?? 'Sin detalle';

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: esCotizacion 
                                        ? Colors.orange.shade100 
                                        : Colors.green.shade100,
                                    child: Icon(
                                      esCotizacion ? Icons.description : Icons.shopping_cart,
                                      color: esCotizacion ? Colors.orange : Colors.green,
                                      size: 20,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$tipo #$id',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: estado == 'pendiente' 
                                              ? Colors.orange.shade100 
                                              : Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          estado,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: estado == 'pendiente' 
                                                ? Colors.orange 
                                                : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(producto),
                                      Text(
                                        fecha,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    'Bs ${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF1A3A5F),
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (_pedidos.length > 10)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Mostrando los 10 últimos pedidos',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}