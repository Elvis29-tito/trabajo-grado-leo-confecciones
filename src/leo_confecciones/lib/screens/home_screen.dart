import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/menu_card.dart';
import '../providers/usuarios_provider.dart';
import '../providers/cotizacion_provider.dart';
import '../providers/clientes_provider.dart';
import '../database/database_helper.dart';
import '../services/firebase_service.dart';
import '../utils/mensajes.dart';
import 'login_screen.dart';
import 'cotizacion_screen.dart';
import 'historial_cotizaciones.dart';
import 'stock_screen.dart';
import 'venta_screen.dart';
import 'reportes_screen.dart';
import 'clientes_screen.dart';
import 'usuarios_screen.dart';
import 'configuracion_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ========== SINCRONIZAR CON FIREBASE (TODAS LAS TABLAS) ==========
  void _sincronizarDatos(BuildContext context) async {
    try {
      final firebaseService = FirebaseService();
      
      // Diálogo mejorado
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Icon(
                Icons.cloud_upload,
                size: 60,
                color: Color(0xFF1A3A5F),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3A5F)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sincronizando datos...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Subiendo todas las tablas a la nube',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );

      // Obtener datos de los providers
      final cotizaciones = Provider.of<CotizacionProvider>(context, listen: false).cotizaciones;
      final clientes = Provider.of<ClientesProvider>(context, listen: false).clientes;
      final usuarios = Provider.of<UsuariosProvider>(context, listen: false).usuarios;
      
      // Obtener datos de la base de datos SQLite
      final db = DatabaseHelper();
      
      // 1. Insumos (stock)
      final insumos = await db.getInsumos();
      
      // 2. Productos
      final productos = await db.getProductos();
      
      // 3. Producto_Insumo (relaciones)
      final productoInsumos = await db.getProductoInsumos();
      
      // 4. Ventas
      final ventas = await db.getVentasCompletas();
      
      // 5. Detalle_Venta
      final detallesVenta = await db.getDetallesVenta();
      
      // 6. Movimientos_Stock
      final movimientosStock = await db.getMovimientosStock();

      // Sincronizar con Firebase (todas las tablas)
      await firebaseService.sincronizarTodos(
        cotizaciones: cotizaciones,
        clientes: clientes,
        usuarios: usuarios,
        insumos: insumos,
        productos: productos,
        productoInsumos: productoInsumos,
        ventas: ventas,
        detallesVenta: detallesVenta,
        movimientosStock: movimientosStock,
      );

      // Cerrar diálogo
      if (context.mounted) {
        Navigator.pop(context);
        Mensajes.exito(context, '✅ Todos los datos sincronizados con la nube');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        Mensajes.error(context, '❌ Error al sincronizar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<UsuariosProvider>(
          builder: (context, provider, child) {
            final usuario = provider.usuarioActual;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LEO CONFECCIONES'),
                if (usuario != null)
                  Text(
                    '👤 ${usuario.nombre} (${usuario.rol})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
              ],
            );
          },
        ),
        backgroundColor: const Color(0xFF1A3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: () => _sincronizarDatos(context),
            tooltip: 'Sincronizar con Firebase',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              final provider = Provider.of<UsuariosProvider>(context, listen: false);
              provider.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<UsuariosProvider>(
        builder: (context, provider, child) {
          final usuario = provider.usuarioActual;
          final bool esAdmin = usuario?.rol == 'admin';

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF5F7FA), Colors.white],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'SISTEMA DE GESTIÓN',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5F),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Seleccione una opción para continuar',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        // 1. COTIZACIÓN (todos)
                        MenuCard(
                          titulo: 'Cotización',
                          icono: Icons.calculate,
                          color: const Color(0xFF2C5F8A),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CotizacionScreen(),
                              ),
                            );
                          },
                        ),
                        // 2. HISTORIAL (todos)
                        MenuCard(
                          titulo: 'Historial',
                          icono: Icons.history,
                          color: const Color(0xFF6C63FF),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HistorialCotizaciones(),
                              ),
                            );
                          },
                        ),
                        // 3. STOCK (solo admin)
                        if (esAdmin)
                          MenuCard(
                            titulo: 'Stock',
                            icono: Icons.inventory,
                            color: const Color(0xFFE67E22),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StockScreen(),
                                ),
                              );
                            },
                          ),
                        // 4. REGISTRAR VENTA (todos)
                        MenuCard(
                          titulo: 'Registrar Venta',
                          icono: Icons.shopping_cart,
                          color: const Color(0xFF27AE60),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VentaScreen(),
                              ),
                            );
                          },
                        ),
                        // 5. REPORTES (solo admin)
                        if (esAdmin)
                          MenuCard(
                            titulo: 'Reportes',
                            icono: Icons.bar_chart,
                            color: const Color(0xFF8E44AD),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReportesScreen(),
                                ),
                              );
                            },
                          ),
                        // 6. CLIENTES (todos)
                        MenuCard(
                          titulo: 'Clientes',
                          icono: Icons.people,
                          color: const Color(0xFF00BCD4),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ClientesScreen(),
                              ),
                            );
                          },
                        ),
                        // 7. USUARIOS (solo admin)
                        if (esAdmin)
                          MenuCard(
                            titulo: 'Usuarios',
                            icono: Icons.admin_panel_settings,
                            color: const Color(0xFF9C27B0),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UsuariosScreen(),
                                ),
                              );
                            },
                          ),
                        // 8. CONFIGURACIÓN (solo admin)
                        if (esAdmin)
                          MenuCard(
                            titulo: 'Configuración',
                            icono: Icons.settings,
                            color: const Color(0xFF607D8B),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ConfiguracionScreen(),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}