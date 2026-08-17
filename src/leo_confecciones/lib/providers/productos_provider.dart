import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/producto.dart';

class ProductosProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Producto> _productos = [];
  bool _isLoading = false;
  String? _error;

  // ========== GETTERS ==========
  List<Producto> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Productos finalizados (listos para vender)
  List<Producto> get productosFinalizados {
    return _productos.where((p) => p.estado == 'finalizado').toList();
  }

  // Productos en producción
  List<Producto> get productosEnProduccion {
    return _productos.where((p) => p.estado == 'en_produccion').toList();
  }

  // Productos entregados
  List<Producto> get productosEntregados {
    return _productos.where((p) => p.estado == 'entregado').toList();
  }

  // ========== CARGAR TODOS LOS PRODUCTOS ==========
  Future<void> cargarProductos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _db.getProductos();
      _productos = data.map((map) => Producto.fromMap(map)).toList();
    } catch (e) {
      _error = 'Error al cargar productos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== CREAR PRODUCTO DESDE COTIZACIÓN ==========
  Future<int> crearProductoDesdeCotizacion({
    required String nombre,
    required double precio,
    required int idCotizacion,
    required List<Map<String, dynamic>> insumos,
  }) async {
    try {
      // 1. Crear el producto (usando precioBase)
      final producto = Producto(
        nombre: nombre,
        precioBase: precio,
        estado: 'en_produccion',
        idCotizacion: idCotizacion,
      );
      
      final idProducto = await _db.insertProducto(producto.toMap());
      
      if (idProducto == -1) {
        _error = 'Error al insertar producto';
        return -1;
      }
      
      // 2. Guardar los insumos del producto
      await _db.insertProductoInsumos(idProducto, insumos);
      
      // 3. Recargar lista
      await cargarProductos();
      
      return idProducto;
    } catch (e) {
      _error = 'Error al crear producto: $e';
      return -1;
    }
  }

  // ========== ACTUALIZAR ESTADO DE UN PRODUCTO ==========
  Future<bool> actualizarEstado(int id, String nuevoEstado) async {
    try {
      final result = await _db.updateProductoEstado(id, nuevoEstado);
      if (result > 0) {
        await cargarProductos();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error al actualizar estado: $e';
      return false;
    }
  }

  // ============================================================
  // VENDER UN PRODUCTO (INTEGRACIÓN CON STOCK)
  // ============================================================
  Future<bool> venderProducto(int idProducto, int idCliente, int idUsuario) async {
    try {
      // 1. Obtener insumos del producto (incluye stock desde tabla stock)
      final insumos = await _db.getInsumosByProducto(idProducto);
      
      if (insumos.isEmpty) {
        _error = 'El producto no tiene insumos registrados';
        return false;
      }
      
      // ========== 2. VERIFICAR STOCK SUFICIENTE ==========
      for (var insumo in insumos) {
        final cantidadRequerida = insumo['cantidad_requerida'] as double;
        final stockActual = insumo['cantidad_disponible'] as double;
        
        if (stockActual < cantidadRequerida) {
          _error = 'Stock insuficiente de ${insumo['nombre']} '
                   '(Disponible: $stockActual, Requerido: $cantidadRequerida)';
          return false;
        }
      }
      
      // ========== 3. INICIAR TRANSACCIÓN ==========
      final db = await _db.database;
      
      await db.transaction((txn) async {
        // 3.1 Descontar stock de cada insumo
        for (var insumo in insumos) {
          final idInsumo = insumo['id_insumo'] as int;
          final cantidadRequerida = insumo['cantidad_requerida'] as double;
          final stockActual = insumo['cantidad_disponible'] as double;
          final nuevaCantidad = stockActual - cantidadRequerida;
          
          // Actualizar stock
          await txn.update(
            'stock',
            {'cantidad_disponible': nuevaCantidad},
            where: 'id_insumo = ?',
            whereArgs: [idInsumo],
          );
          
          // Registrar movimiento de stock
          await txn.insert('movimientos_stock', {
            'id_insumo': idInsumo,
            'id_usuario': idUsuario,
            'tipo': 'salida',
            'cantidad': cantidadRequerida,
            'fecha_hora': DateTime.now().toIso8601String(),
            'referencia': 'Venta producto #$idProducto',
            'responsable': 'Sistema',
          });
        }
        
        // 3.2 Cambiar estado del producto a 'entregado'
        await txn.update(
          'productos',
          {'estado': 'entregado'},
          where: 'id_producto = ?',
          whereArgs: [idProducto],
        );
        
        // 3.3 Obtener el producto para registrar la venta
        final producto = _productos.firstWhere((p) => p.id == idProducto);
        
        // 3.4 Registrar la venta
        final idVenta = await txn.insert('ventas', {
          'id_cliente': idCliente,
          'id_usuario': idUsuario,
          'fecha': DateTime.now().toIso8601String(),
          'total': producto.precioBase,
          'estado': 'completada',
        });
        
        // 3.5 Registrar detalle de la venta
        await txn.insert('detalle_venta', {
          'id_venta': idVenta,
          'id_producto': idProducto,
          'cantidad': 1,
          'precio_unitario': producto.precioBase,
          'subtotal': producto.precioBase,
        });
      });
      
      // 4. Recargar productos
      await cargarProductos();
      return true;
      
    } catch (e) {
      _error = 'Error al vender producto: $e';
      return false;
    }
  }

  // ============================================================
  // VENDER TELA POR METRO (INTEGRACIÓN CON STOCK)
  // ============================================================
  Future<bool> venderTelaPorMetro({
    required int idInsumo,
    required int idCliente,
    required int idUsuario,
    required double cantidad,
    required double precioUnitario,
  }) async {
    try {
      // 1. Obtener stock actual
      final stockActual = await _db.getStockByInsumo(idInsumo);
      
      if (stockActual < cantidad) {
        _error = 'Stock insuficiente. Disponible: $stockActual, Requerido: $cantidad';
        return false;
      }
      
      // 2. Iniciar transacción
      final db = await _db.database;
      
      await db.transaction((txn) async {
        final nuevaCantidad = stockActual - cantidad;
        
        // 2.1 Actualizar stock
        await txn.update(
          'stock',
          {'cantidad_disponible': nuevaCantidad},
          where: 'id_insumo = ?',
          whereArgs: [idInsumo],
        );
        
        // 2.2 Registrar movimiento
        await txn.insert('movimientos_stock', {
          'id_insumo': idInsumo,
          'id_usuario': idUsuario,
          'tipo': 'salida',
          'cantidad': cantidad,
          'fecha_hora': DateTime.now().toIso8601String(),
          'referencia': 'Venta por metro',
          'responsable': 'Sistema',
        });
        
        // 2.3 Registrar venta
        final total = cantidad * precioUnitario;
        final idVenta = await txn.insert('ventas', {
          'id_cliente': idCliente,
          'id_usuario': idUsuario,
          'fecha': DateTime.now().toIso8601String(),
          'total': total,
          'estado': 'completada',
        });
        
        // 2.4 Registrar detalle (con id_producto = 0 para indicar venta por metro)
        await txn.insert('detalle_venta', {
          'id_venta': idVenta,
          'id_producto': 0,
          'cantidad': cantidad.toInt(),
          'precio_unitario': precioUnitario,
          'subtotal': total,
        });
      });
      
      return true;
      
    } catch (e) {
      _error = 'Error al vender tela por metro: $e';
      return false;
    }
  }

  // ========== ELIMINAR PRODUCTO ==========
  Future<bool> eliminarProducto(int id) async {
    try {
      final result = await _db.deleteProducto(id);
      if (result > 0) {
        await cargarProductos();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error al eliminar producto: $e';
      return false;
    }
  }

  // ========== OBTENER PRODUCTO POR ID ==========
  Producto? getProductoById(int id) {
    try {
      return _productos.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== CONTAR PRODUCTOS POR ESTADO ==========
  int contarPorEstado(String estado) {
    return _productos.where((p) => p.estado == estado).length;
  }

  // ========== LIMPIAR ERROR ==========
  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}