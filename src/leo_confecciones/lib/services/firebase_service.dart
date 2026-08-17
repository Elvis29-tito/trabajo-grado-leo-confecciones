import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cotizacion.dart';
import '../models/cliente.dart';
import '../models/usuario.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // No inicializar FirebaseFirestore aquí como variable final,
  // porque Firebase podría no estar inicializado todavía.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ========== INICIALIZAR ==========
  Future<void> init() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        print('🔥 Firebase ya estaba inicializado');
        return;
      }

      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyABDR8-rFnPdaaEwBZ3ly3rB44nPh31C8M',
          appId: '1:802967363100:android:b3060b6ce429a7691f49d9',
          messagingSenderId: '802967363100',
          projectId: 'leo-confecciones',
          authDomain: 'leo-confecciones.firebaseapp.com',
          storageBucket: 'leo-confecciones.firebasestorage.app',
        ),
      );

      print('🔥 Firebase inicializado correctamente');
    } catch (e) {
      print('❌ Error al inicializar Firebase: $e');
      rethrow;
    }
  }

  // ============================================================
  // 1. COTIZACIONES
  // ============================================================
  Future<void> sincronizarCotizacion(Cotizacion cotizacion) async {
    try {
      await _firestore.collection('cotizaciones').doc(cotizacion.id.toString()).set({
        'id': cotizacion.id,
        'cliente': cotizacion.cliente,
        'tela': cotizacion.tela,
        'ancho': cotizacion.ancho,
        'alto': cotizacion.alto,
        'factorTela': cotizacion.factorTela,
        'precioTela': cotizacion.precioTela,
        'precioBase': cotizacion.precioBase,
        'totalAccesorios': cotizacion.totalAccesorios,
        'precioFinal': cotizacion.precioFinal,
        'accesorios': cotizacion.accesorios,
        'estado': cotizacion.estado,
        'fecha': cotizacion.fecha.toIso8601String(),
        'sincronizado': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al sincronizar cotización: $e');
    }
  }

  // ============================================================
  // 2. CLIENTES
  // ============================================================
  Future<void> sincronizarCliente(Cliente cliente) async {
    try {
      await _firestore.collection('clientes').doc(cliente.id.toString()).set({
        'id_cliente': cliente.id,
        'nombre': cliente.nombre,
        'telefono': cliente.telefono,
        'direccion': cliente.direccion,
        'fecha_registro': cliente.fechaRegistro.toIso8601String(),
        'estado': cliente.estado,
        'sincronizado': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al sincronizar cliente: $e');
    }
  }

  // ============================================================
  // 3. USUARIOS
  // ============================================================
  Future<void> sincronizarUsuario(Usuario usuario) async {
    try {
      await _firestore.collection('usuarios').doc(usuario.id.toString()).set({
        'id_usuario': usuario.id,
        'nombre': usuario.nombre,
        'email': usuario.email,
        'rol': usuario.rol,
        'sincronizado': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al sincronizar usuario: $e');
    }
  }

  // ============================================================
  // 4. INSUMOS (STOCK)
  // ============================================================
  Future<void> sincronizarInsumo(Map<String, dynamic> insumo) async {
    try {
      await _firestore.collection('insumos').doc(insumo['id_insumo'].toString()).set({
        'id_insumo': insumo['id_insumo'],
        'nombre': insumo['nombre'],
        'unidad_medida': insumo['unidad_medida'],
        'stock_minimo': insumo['stock_minimo'],
        'stock_actual': insumo['stock_actual'],
        'precio': insumo['precio'],
        'sincronizado': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al sincronizar insumo: $e');
    }
  }

  // ============================================================
  // 5. PRODUCTOS
  // ============================================================
  Future<void> sincronizarProducto(Map<String, dynamic> producto) async {
    try {
      await _firestore.collection('productos').doc(producto['id_producto'].toString()).set({
        'id_producto': producto['id_producto'],
        'nombre': producto['nombre'],
        'descripcion': producto['descripcion'] ?? '',
        'precio_base': producto['precio_base'],
        'estado': producto['estado'] ?? 'activo',
        'sincronizado': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al sincronizar producto: $e');
    }
  }

  // ============================================================
  // 6. PRODUCTO_INSUMO (relación muchos a muchos)
  // ============================================================
  Future<void> sincronizarProductoInsumo(Map<String, dynamic> relacion) async {
    try {
      final id = '${relacion['id_producto']}_${relacion['id_insumo']}';
      await _firestore.collection('producto_insumo').doc(id).set({
        'id_producto': relacion['id_producto'],
        'id_insumo': relacion['id_insumo'],
        'cantidad_requerida': relacion['cantidad_requerida'],
        'sincronizado': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al sincronizar producto_insumo: $e');
    }
  }

  // ============================================================
  // 7. VENTAS
  // ============================================================
  Future<void> sincronizarVenta(Map<String, dynamic> venta) async {
    try {
      await _firestore.collection('ventas').doc(venta['id_venta'].toString()).set({
        'id_venta': venta['id_venta'],
        'id_cliente': venta['id_cliente'],
        'id_usuario': venta['id_usuario'],
        'fecha': venta['fecha'],
        'total': venta['total'],
        'estado': venta['estado'] ?? 'completada',
        'sincronizado': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al sincronizar venta: $e');
    }
  }

  // ============================================================
  // 8. DETALLE_VENTA
  // ============================================================
  Future<void> sincronizarDetalleVenta(Map<String, dynamic> detalle) async {
    try {
      await _firestore.collection('detalle_venta').doc(detalle['id_detalle'].toString()).set({
        'id_detalle': detalle['id_detalle'],
        'id_venta': detalle['id_venta'],
        'id_producto': detalle['id_producto'],
        'cantidad': detalle['cantidad'],
        'precio_unitario': detalle['precio_unitario'],
        'subtotal': detalle['subtotal'],
        'sincronizado': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al sincronizar detalle_venta: $e');
    }
  }

  // ============================================================
  // 9. MOVIMIENTOS_STOCK
  // ============================================================
  Future<void> sincronizarMovimientoStock(Map<String, dynamic> movimiento) async {
    try {
      await _firestore.collection('movimientos_stock').doc(movimiento['id_movimiento'].toString()).set({
        'id_movimiento': movimiento['id_movimiento'],
        'id_insumo': movimiento['id_insumo'],
        'id_usuario': movimiento['id_usuario'],
        'tipo': movimiento['tipo'],
        'cantidad': movimiento['cantidad'],
        'fecha_hora': movimiento['fecha_hora'],
        'referencia': movimiento['referencia'] ?? '',
        'responsable': movimiento['responsable'] ?? 'Sistema',
        'sincronizado': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al sincronizar movimiento_stock: $e');
    }
  }

  // ============================================================
  // SINCRONIZACIÓN MASIVA (TODAS LAS TABLAS)
  // ============================================================
  Future<void> sincronizarTodos({
    required List<Cotizacion> cotizaciones,
    required List<Cliente> clientes,
    required List<Usuario> usuarios,
    required List<Map<String, dynamic>> insumos,
    required List<Map<String, dynamic>> productos,
    required List<Map<String, dynamic>> productoInsumos,
    required List<Map<String, dynamic>> ventas,
    required List<Map<String, dynamic>> detallesVenta,
    required List<Map<String, dynamic>> movimientosStock,
  }) async {
    try {
      // 1. Cotizaciones
      print('🔄 Sincronizando ${cotizaciones.length} cotizaciones...');
      for (var c in cotizaciones) {
        await sincronizarCotizacion(c);
      }

      // 2. Clientes
      print('🔄 Sincronizando ${clientes.length} clientes...');
      for (var c in clientes) {
        await sincronizarCliente(c);
      }

      // 3. Usuarios
      print('🔄 Sincronizando ${usuarios.length} usuarios...');
      for (var u in usuarios) {
        await sincronizarUsuario(u);
      }

      // 4. Insumos
      print('🔄 Sincronizando ${insumos.length} insumos...');
      for (var i in insumos) {
        await sincronizarInsumo(i);
      }

      // 5. Productos
      print('🔄 Sincronizando ${productos.length} productos...');
      for (var p in productos) {
        await sincronizarProducto(p);
      }

      // 6. Producto_Insumo
      print('🔄 Sincronizando ${productoInsumos.length} relaciones producto-insumo...');
      for (var r in productoInsumos) {
        await sincronizarProductoInsumo(r);
      }

      // 7. Ventas
      print('🔄 Sincronizando ${ventas.length} ventas...');
      for (var v in ventas) {
        await sincronizarVenta(v);
      }

      // 8. Detalle_Venta
      print('🔄 Sincronizando ${detallesVenta.length} detalles de venta...');
      for (var d in detallesVenta) {
        await sincronizarDetalleVenta(d);
      }

      // 9. Movimientos_Stock
      print('🔄 Sincronizando ${movimientosStock.length} movimientos de stock...');
      for (var m in movimientosStock) {
        await sincronizarMovimientoStock(m);
      }

      print('✅ Todos los datos sincronizados con Firebase');
    } catch (e) {
      print('❌ Error en sincronización masiva: $e');
      rethrow;
    }
  }
}