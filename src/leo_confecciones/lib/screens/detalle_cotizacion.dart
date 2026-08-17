import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cotizacion.dart';
import '../providers/cotizacion_provider.dart';
import '../providers/productos_provider.dart';
import '../services/pdf_service.dart';

class DetalleCotizacion extends StatelessWidget {
  final Cotizacion cotizacion;

  const DetalleCotizacion({
    super.key,
    required this.cotizacion,
  });

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'aprobada':
        return Colors.amber;
      case 'en_proceso':
        return Colors.blue;
      case 'finalizado':
        return Colors.green;
      case 'entregado':
        return Colors.purple;
      case 'rechazada':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'aprobada':
        return '✅ Aprobada';
      case 'en_proceso':
        return '🔧 En Proceso';
      case 'finalizado':
        return '✅ Finalizado';
      case 'entregado':
        return '📦 Entregado';
      case 'rechazada':
        return '❌ Rechazada';
      default:
        return '⏳ Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cotización #${cotizacion.id}'),
        backgroundColor: const Color(0xFF1A3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final pdfService = PdfService();
              await pdfService.generarPDF(cotizacion);
            },
            tooltip: 'Generar PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== ESTADO ==========
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getEstadoColor(cotizacion.estado).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getEstadoTexto(cotizacion.estado),
                style: TextStyle(
                  color: _getEstadoColor(cotizacion.estado),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ========== DATOS DEL CLIENTE ==========
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DATOS DEL CLIENTE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5F),
                      ),
                    ),
                    const Divider(),
                    _buildDetalleItem('Cliente', cotizacion.cliente),
                    _buildDetalleItem('Fecha', cotizacion.fecha.toLocal().toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // ========== DATOS DE LA CORTINA ==========
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DATOS DE LA CORTINA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5F),
                      ),
                    ),
                    const Divider(),
                    _buildDetalleItem('Tela', cotizacion.tela),
                    _buildDetalleItem('Medidas', '${cotizacion.ancho}m x ${cotizacion.alto}m'),
                    _buildDetalleItem('Factor de tela', cotizacion.factorTela.toString()),
                    _buildDetalleItem('Precio de tela', '${cotizacion.precioTela.toStringAsFixed(2)} Bs/m'),
                    _buildDetalleItem('Accesorios', cotizacion.accesorios),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // ========== RESUMEN DE COSTOS ==========
            Card(
              color: const Color(0xFFE8F0FE),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RESUMEN DE COSTOS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5F),
                      ),
                    ),
                    const Divider(),
                    _buildDetalleItem('Precio base', '${cotizacion.precioBase.toStringAsFixed(2)} Bs'),
                    _buildDetalleItem('Total accesorios', '+ ${cotizacion.totalAccesorios.toStringAsFixed(2)} Bs'),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${cotizacion.precioFinal.toStringAsFixed(2)} Bs',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3A5F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ========== BOTONES DE ACCIÓN SEGÚN ESTADO ==========
            
            // 1. PENDIENTE → Aprobar o Rechazar
            if (cotizacion.estado == 'pendiente') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _aprobarCotizacion(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        '✅ APROBAR',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _cambiarEstado(context, 'rechazada'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        '❌ RECHAZAR',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // 2. APROBADA → Iniciar Producción
            if (cotizacion.estado == 'aprobada') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _cambiarEstado(context, 'en_proceso'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    '🔧 INICIAR PRODUCCIÓN',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 3. EN PROCESO → Finalizar (CON ACTUALIZACIÓN DE PRODUCTO)
            if (cotizacion.estado == 'en_proceso') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _finalizarCortina(context), // 👈 CAMBIADO
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    '✅ FINALIZAR CORTINA',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 4. FINALIZADO → Entregar
            if (cotizacion.estado == 'finalizado') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _cambiarEstado(context, 'entregado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    '📦 ENTREGAR AL CLIENTE',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ========== BOTÓN ELIMINAR ==========
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('¿Eliminar cotización?'),
                      content: Text(
                        '¿Está seguro de eliminar la cotización de ${cotizacion.cliente}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final provider = Provider.of<CotizacionProvider>(
                      context,
                      listen: false,
                    );
                    final success = await provider.eliminarCotizacion(
                      cotizacion.id!,
                    );
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🗑️ Cotización eliminada'),
                          backgroundColor: Colors.grey,
                        ),
                      );
                      Navigator.pop(context, true);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'ELIMINAR COTIZACIÓN',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ========== BOTÓN PDF ==========
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final pdfService = PdfService();
                  await pdfService.generarPDF(cotizacion);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A5F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text(
                  'GENERAR PDF',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== APROBAR COTIZACIÓN ==========
  void _aprobarCotizacion(BuildContext context) async {
    final cotizacionProvider = Provider.of<CotizacionProvider>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Creando producto...'),
          ],
        ),
      ),
    );

    try {
      final success = await cotizacionProvider.actualizarEstado(
        cotizacion.id!,
        'aprobada',
      );
      
      if (!success) {
        throw Exception('Error al aprobar la cotización');
      }

      final productoCreado = await cotizacionProvider.crearProductoDesdeCotizacion(
        context,
        cotizacion,
      );

      Navigator.pop(context);

      if (productoCreado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cotización aprobada. Producto creado para producción'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(cotizacionProvider.error ?? 'Error al crear producto');
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ========== FINALIZAR CORTINA (ACTUALIZA PRODUCTO) ==========
  void _finalizarCortina(BuildContext context) async {
    final cotizacionProvider = Provider.of<CotizacionProvider>(context, listen: false);
    final productosProvider = Provider.of<ProductosProvider>(context, listen: false);

    // Mostrar carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Finalizando cortina...'),
          ],
        ),
      ),
    );

    try {
      // 1. Cambiar estado de la cotización a "finalizado"
      final success = await cotizacionProvider.actualizarEstado(
        cotizacion.id!,
        'finalizado',
      );

      if (!success) {
        throw Exception('Error al finalizar la cotización');
      }

      // 2. Buscar el producto asociado a esta cotización
      final productos = productosProvider.productos;
      final producto = productos.firstWhere(
        (p) => p.idCotizacion == cotizacion.id,
        orElse: () => throw Exception('Producto no encontrado para esta cotización'),
      );

      // 3. Cambiar estado del producto a "finalizado"
      final productoSync = await productosProvider.actualizarEstado(
        producto.id!,
        'finalizado',
      );

      if (!productoSync) {
        throw Exception('Error al actualizar el producto');
      }

      // 4. Recargar productos
      await productosProvider.cargarProductos();

      // Cerrar diálogo
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cortina finalizada. Ahora está disponible en "Registrar Venta"'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ========== CAMBIAR ESTADO ==========
  void _cambiarEstado(BuildContext context, String nuevoEstado) async {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);
    final success = await provider.actualizarEstado(cotizacion.id!, nuevoEstado);

    if (success) {
      final mensajes = {
        'aprobada': '✅ Cotización aprobada',
        'en_proceso': '🔧 Producción iniciada',
        'finalizado': '✅ Cortina finalizada',
        'entregado': '📦 Cortina entregada al cliente',
        'rechazada': '❌ Cotización rechazada',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajes[nuevoEstado] ?? '✅ Estado actualizado'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error al actualizar el estado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}