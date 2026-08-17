import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/accesorio.dart';
import '../models/cotizacion.dart';
import '../database/database_helper.dart';
import 'productos_provider.dart';

class CotizacionProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  // Datos de la cotización
  String nombreCliente = '';
  String telaSeleccionada = '';
  String telaColor = ''; // 👈 NUEVA: guardar color
  double anchoVentana = 0.0;
  double altoVentana = 0.0;
  double factorTela = 3.0;
  double precioTela = 0.0;
  double manoObra = 12.0;

  // Accesorios (cargados desde SQLite)
  List<Accesorio> accesorios = [];

  // Resultados
  double? precioBase;
  double? precioTotal;
  double totalAccesoriosCalculado = 0.0;

  // Lista de cotizaciones guardadas
  List<Cotizacion> _cotizaciones = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Cotizacion> get cotizaciones => _cotizaciones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========== CALCULAR TOTAL DE ACCESORIOS ==========
  double get totalAccesorios {
    return accesorios
        .where((a) => a.seleccionado)
        .fold(0, (sum, a) => sum + a.precio);
  }

  // ========== CARGAR COTIZACIONES ==========
  Future<void> cargarCotizaciones() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cotizaciones = await _db.getCotizaciones();
    } catch (e) {
      _error = 'Error al cargar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== CARGAR ACCESORIOS DESDE SQLite ==========
  Future<void> cargarAccesorios() async {
    try {
      final data = await _db.getAccesorios();
      accesorios = data.map((item) {
        return Accesorio(
          id: item['id_insumo'].toString(),
          nombre: item['nombre'] ?? 'Sin nombre',
          precio: (item['precio'] as double?) ?? 0.0,
          seleccionado: false,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print('❌ Error cargando accesorios: $e');
    }
  }

  // ========== CALCULAR PRECIO ==========
  void calcularPrecio() {
    if (anchoVentana <= 0 || altoVentana <= 0) {
      _error = 'Ingrese medidas válidas';
      notifyListeners();
      return;
    }

    if (precioTela <= 0) {
      _error = 'Seleccione una tela válida';
      notifyListeners();
      return;
    }

    double area = anchoVentana * altoVentana;
    precioBase = area * factorTela * (precioTela + manoObra);
    
    totalAccesoriosCalculado = 0.0;
    for (var acc in accesorios) {
      if (acc.seleccionado) {
        totalAccesoriosCalculado += acc.precio;
      }
    }
    
    precioTotal = precioBase! + totalAccesoriosCalculado;
    _error = null;
    notifyListeners();
  }

  // ========== GUARDAR COTIZACIÓN ==========
  Future<int> guardarCotizacion() async {
    if (nombreCliente.isEmpty) {
      _error = 'Ingrese el nombre del cliente';
      return -1;
    }

    if (precioTotal == null) {
      _error = 'Primero calcule el precio';
      return -1;
    }

    final accesoriosSeleccionados = accesorios
        .where((a) => a.seleccionado)
        .map((a) => a.nombre)
        .join(', ');

    final cotizacion = Cotizacion(
      cliente: nombreCliente,
      tela: telaSeleccionada,
      telaColor: telaColor, // 👈 NUEVO: guardar color
      ancho: anchoVentana,
      alto: altoVentana,
      factorTela: factorTela,
      precioTela: precioTela,
      precioBase: precioBase!,
      totalAccesorios: totalAccesorios,
      precioFinal: precioTotal!,
      accesorios: accesoriosSeleccionados.isEmpty ? 'Ninguno' : accesoriosSeleccionados,
      estado: 'pendiente',
    );

    try {
      final id = await _db.insertCotizacion(cotizacion);
      await cargarCotizaciones();
      return id;
    } catch (e) {
      _error = 'Error al guardar: $e';
      return -1;
    }
  }

  // ========== ACTUALIZAR ESTADO ==========
  Future<bool> actualizarEstado(int id, String nuevoEstado) async {
    try {
      final result = await _db.updateEstado(id, nuevoEstado);
      await cargarCotizaciones();
      return result > 0;
    } catch (e) {
      _error = 'Error al actualizar: $e';
      return false;
    }
  }

  // ========== ELIMINAR COTIZACIÓN ==========
  Future<bool> eliminarCotizacion(int id) async {
    try {
      final result = await _db.deleteCotizacion(id);
      await cargarCotizaciones();
      return result > 0;
    } catch (e) {
      _error = 'Error al eliminar: $e';
      return false;
    }
  }

  // ========== CONTAR POR ESTADO ==========
  int contarPorEstado(String estado) {
    return _cotizaciones.where((c) => c.estado == estado).length;
  }

  // ========== CREAR PRODUCTO DESDE COTIZACIÓN ==========
  Future<bool> crearProductoDesdeCotizacion(BuildContext context, Cotizacion cotizacion) async {
    try {
      final productosProvider = Provider.of<ProductosProvider>(context, listen: false);
      
      final insumos = _obtenerInsumosParaCotizacion(cotizacion);
      
      final nombreProducto = 'Cortina ${cotizacion.tela} - ${cotizacion.cliente}';
      
      final idProducto = await productosProvider.crearProductoDesdeCotizacion(
        nombre: nombreProducto,
        precio: cotizacion.precioFinal,
        idCotizacion: cotizacion.id!,
        insumos: insumos,
      );
      
      if (idProducto != -1) {
        await actualizarEstado(cotizacion.id!, 'aprobada');
        return true;
      }
      
      return false;
    } catch (e) {
      _error = 'Error al crear producto: $e';
      return false;
    }
  }

  // ========== OBTENER INSUMOS PARA UNA COTIZACIÓN ==========
  List<Map<String, dynamic>> _obtenerInsumosParaCotizacion(Cotizacion cotizacion) {
    final List<Map<String, dynamic>> insumos = [];
    
    final idTela = _getIdInsumoPorTela(cotizacion.tela);
    if (idTela != -1) {
      final cantidadTela = cotizacion.ancho * cotizacion.alto * cotizacion.factorTela;
      insumos.add({
        'id_insumo': idTela,
        'cantidad': cantidadTela,
      });
    }
    
    final accesoriosList = cotizacion.accesorios.split(', ');
    for (var acc in accesoriosList) {
      final idAcc = _getIdAccesorioPorNombre(acc);
      if (idAcc != -1) {
        insumos.add({
          'id_insumo': idAcc,
          'cantidad': 1,
        });
      }
    }
    
    return insumos;
  }

  // ========== OBTENER ID DE INSUMO POR NOMBRE DE TELA ==========
  int _getIdInsumoPorTela(String tela) {
    final mapa = {
      'Tela gruesa': 1,
      'Lino sin diseño': 2,
      'Lino con diseño': 3,
      'Lino bordado': 4,
      'Gasa lisa': 5,
      'Gasa nevada': 6,
      'Gasa bordada': 7,
    };
    for (var entry in mapa.entries) {
      if (tela.contains(entry.key) || entry.key.contains(tela)) {
        return entry.value;
      }
    }
    return -1;
  }

  // ========== OBTENER ID DE ACCESORIO POR NOMBRE ==========
  int _getIdAccesorioPorNombre(String nombre) {
    final mapa = {
      'Riel vacía': 8,
      'Crusetas': 9,
      'Poleas': 10,
      'Finales': 11,
      'Pita': 12,
      'Rodajas': 13,
    };
    return mapa[nombre] ?? -1;
  }

  // ========== SETTERS ==========
  void setNombreCliente(String valor) {
    nombreCliente = valor;
    notifyListeners();
  }

  void setTelaSeleccionada(String tela, double precio) {
    telaSeleccionada = tela;
    precioTela = precio;
    notifyListeners();
  }

  void setTelaColor(String color) { // 👈 NUEVO SETTER
    telaColor = color;
    notifyListeners();
  }

  void setAnchoVentana(double valor) {
    anchoVentana = valor;
    notifyListeners();
  }

  void setAltoVentana(double valor) {
    altoVentana = valor;
    notifyListeners();
  }

  void setFactorTela(double valor) {
    factorTela = valor;
    notifyListeners();
  }

  void setManoObra(double valor) {
    manoObra = valor;
    notifyListeners();
  }

  void setPrecioTela(double valor) {
    precioTela = valor;
    notifyListeners();
  }

  void toggleAccesorio(String id) {
    final index = accesorios.indexWhere((a) => a.id == id);
    if (index != -1) {
      accesorios[index].seleccionado = !accesorios[index].seleccionado;
      if (precioBase != null) {
        calcularPrecio();
      }
      notifyListeners();
    }
  }

  // ========== AGREGAR ACCESORIO DESDE STOCK ==========
  void agregarAccesorio(Accesorio accesorio) {
    final existe = accesorios.any((a) => a.id == accesorio.id);
    if (!existe) {
      accesorios.add(accesorio);
      notifyListeners();
    }
  }

  // ========== LIMPIAR ==========
  void limpiar() {
    nombreCliente = '';
    telaSeleccionada = '';
    telaColor = ''; // 👈 NUEVO: limpiar color
    anchoVentana = 0.0;
    altoVentana = 0.0;
    factorTela = 3.0;
    precioTela = 0.0;
    manoObra = 12.0;
    for (var a in accesorios) {
      a.seleccionado = false;
    }
    precioBase = null;
    precioTotal = null;
    totalAccesoriosCalculado = 0.0;
    notifyListeners();
  }

  // ========== REINICIAR ACCESORIOS ==========
  void reiniciarAccesorios() {
    for (var a in accesorios) {
      a.seleccionado = false;
    }
    notifyListeners();
  }
}