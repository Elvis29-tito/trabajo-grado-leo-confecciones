import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cotizacion_provider.dart';
import '../providers/clientes_provider.dart';
import '../models/cliente.dart';
import '../models/accesorio.dart';
import '../database/database_helper.dart';

class CotizacionScreen extends StatefulWidget {
  const CotizacionScreen({super.key});

  @override
  State<CotizacionScreen> createState() => _CotizacionScreenState();
}

class _CotizacionScreenState extends State<CotizacionScreen> {
  final TextEditingController _anchoController = TextEditingController();
  final TextEditingController _altoController = TextEditingController();
  final TextEditingController _clienteController = TextEditingController();

  // Variables para telas (cargadas desde BD)
  List<Map<String, dynamic>> _telas = [];
  
  // 👈 NUEVO: Variables para el selector de tela con color
  String _telaNombreSeleccionado = '';  // Nombre de la tela (ej. "Gasa nevada")
  String _telaColorSeleccionado = '';   // Color seleccionado (ej. "Beige")
  double _precioTelaSeleccionada = 0.0;
  int _telaIdSeleccionada = 0;

  // Variables para accesorios (cargados desde BD)
  List<Map<String, dynamic>> _accesorios = [];
  Map<int, bool> _accesoriosSeleccionados = {};

  double _factorTela = 3.0;

  // Estado de carga
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _anchoController.dispose();
    _altoController.dispose();
    _clienteController.dispose();
    super.dispose();
  }

  // ============================================================
  // CARGAR TELAS Y ACCESORIOS DESDE SQLite
  // ============================================================
  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper();
      
      final telas = await db.getTelas();
      final accesorios = await db.getAccesorios();

      setState(() {
        _telas = telas;
        _accesorios = accesorios;
        
        if (_telas.isNotEmpty) {
          // 👈 Seleccionar el primer nombre y color por defecto
          _telaNombreSeleccionado = _telas.first['nombre'] ?? '';
          _telaColorSeleccionado = _telas.first['color'] ?? '';
          _telaIdSeleccionada = _telas.first['id_insumo'] as int;
          _precioTelaSeleccionada = _telas.first['precio']?.toDouble() ?? 0.0;
        }

        for (var acc in _accesorios) {
          _accesoriosSeleccionados[acc['id_insumo']] = false;
        }

        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando datos: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // AGRUPAR TELAS POR NOMBRE
  // ============================================================
  Map<String, List<Map<String, dynamic>>> _agruparTelasPorNombre() {
    Map<String, List<Map<String, dynamic>>> grupos = {};
    for (var tela in _telas) {
      final nombre = tela['nombre'] ?? 'Sin nombre';
      if (!grupos.containsKey(nombre)) {
        grupos[nombre] = [];
      }
      grupos[nombre]!.add(tela);
    }
    return grupos;
  }

  // ============================================================
  // CALCULAR COTIZACIÓN
  // ============================================================
  void _calcular(BuildContext context) {
    double ancho = double.tryParse(_anchoController.text) ?? 0;
    double alto = double.tryParse(_altoController.text) ?? 0;

    if (ancho <= 0 || alto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese medidas válidas')),
      );
      return;
    }

    if (_telaIdSeleccionada == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una tela y color')),
      );
      return;
    }

    final provider = Provider.of<CotizacionProvider>(context, listen: false);

    // 👈 Guardar color y nombre en el provider
    provider.setTelaColor(_telaColorSeleccionado);
    provider.setTelaSeleccionada(_telaNombreSeleccionado, _precioTelaSeleccionada);
      
    // Cargar accesorios en el provider si no están cargados
    if (provider.accesorios.isEmpty && _accesorios.isNotEmpty) {
      for (var acc in _accesorios) {
        final id = acc['id_insumo'].toString();
        final nombre = acc['nombre'] ?? 'Sin nombre';
        final precio = acc['precio']?.toDouble() ?? 0.0;
        
        bool existe = false;
        for (var item in provider.accesorios) {
          if (item.id == id) {
            existe = true;
            break;
          }
        }
        if (!existe) {
          provider.agregarAccesorio(
            Accesorio(
              id: id,
              nombre: nombre,
              precio: precio,
              seleccionado: false,
            )
          );
        }
      }
    }

    provider.setAnchoVentana(ancho);
    provider.setAltoVentana(alto);
    provider.setFactorTela(_factorTela);
    provider.setPrecioTela(_precioTelaSeleccionada);
    provider.setNombreCliente(_clienteController.text.trim());

    // Sincronizar accesorios con el provider
    for (var acc in _accesorios) {
      final id = acc['id_insumo'].toString();
      final seleccionado = _accesoriosSeleccionados[acc['id_insumo']] ?? false;
      
      bool existe = false;
      for (var item in provider.accesorios) {
        if (item.id == id) {
          existe = true;
          if (item.seleccionado != seleccionado) {
            provider.toggleAccesorio(id);
          }
          break;
        }
      }
      
      if (!existe && seleccionado) {
        provider.toggleAccesorio(id);
      }
    }

    provider.calcularPrecio();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cálculo realizado correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ============================================================
  // GUARDAR COTIZACIÓN CON CLIENTE
  // ============================================================
  void _guardarCotizacion(BuildContext context) async {
    final nombreCliente = _clienteController.text.trim();

    // 👈 VALIDACIÓN: solo letras y espacios
    final RegExp soloLetras = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!soloLetras.hasMatch(nombreCliente)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ El nombre del cliente solo puede contener letras y espacios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (nombreCliente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese el nombre del cliente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = Provider.of<CotizacionProvider>(context, listen: false);

    if (provider.precioTotal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero calcule el precio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final clientesProvider = Provider.of<ClientesProvider>(context, listen: false);
      
      var cliente = clientesProvider.clientes.firstWhere(
        (c) => c.nombre.toLowerCase() == nombreCliente.toLowerCase(),
        orElse: () => Cliente(nombre: nombreCliente),
      );

      if (cliente.id == null) {
        final nuevoCliente = Cliente(
          nombre: nombreCliente,
          telefono: '',
          direccion: '',
        );
        final id = await clientesProvider.agregarCliente(nuevoCliente);
        if (id != -1) {
          await clientesProvider.cargarClientes();
          cliente = clientesProvider.clientes.firstWhere((c) => c.id == id);
        }
      }

      final id = await provider.guardarCotizacion();

      if (id != -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cotización guardada con éxito (N° $id)'),
            backgroundColor: Colors.green,
          ),
        );
        _limpiar(context);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: ${provider.error ?? "Desconocido"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // LIMPIAR
  // ============================================================
  void _limpiar(BuildContext context) {
    _anchoController.clear();
    _altoController.clear();
    _clienteController.clear();
    
    setState(() {
      if (_telas.isNotEmpty) {
        _telaNombreSeleccionado = _telas.first['nombre'] ?? '';
        _telaColorSeleccionado = _telas.first['color'] ?? '';
        _telaIdSeleccionada = _telas.first['id_insumo'] as int;
        _precioTelaSeleccionada = _telas.first['precio']?.toDouble() ?? 0.0;
      }
      _factorTela = 3.0;
      
      for (var key in _accesoriosSeleccionados.keys) {
        _accesoriosSeleccionados[key] = false;
      }
    });
    
    final provider = Provider.of<CotizacionProvider>(context, listen: false);
    provider.limpiar();
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

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final grupos = _agruparTelasPorNombre();
    final coloresDisponibles = _telaNombreSeleccionado.isNotEmpty 
        ? (grupos[_telaNombreSeleccionado] ?? []) 
        : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Cotización'),
        backgroundColor: const Color(0xFF1A3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/historial');
            },
            tooltip: 'Ver historial',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Recargar telas y accesorios',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<CotizacionProvider>(
              builder: (context, provider, child) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ========== DATOS DEL CLIENTE ==========
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Datos del Cliente',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A3A5F),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _clienteController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre del cliente',
                                  border: OutlineInputBorder(),
                                  hintText: 'Ej: Juan Pérez',
                                ),
                                onChanged: (value) {
                                  provider.setNombreCliente(value.trim());
                                },
                              ),
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
                                'Datos de la Cortina',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A3A5F),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _anchoController,
                                      decoration: const InputDecoration(
                                        labelText: 'Ancho (m)',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _altoController,
                                      decoration: const InputDecoration(
                                        labelText: 'Alto (m)',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              
                              // 👈 PRIMER DROPDOWN: Tipo de tela (nombre)
                              DropdownButtonFormField<String>(
                                value: _telaNombreSeleccionado.isNotEmpty ? _telaNombreSeleccionado : null,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de tela',
                                  border: OutlineInputBorder(),
                                ),
                                hint: const Text('Seleccione una tela'),
                                items: grupos.keys.map((nombre) {
                                  return DropdownMenuItem<String>(
                                    value: nombre,
                                    child: Text(nombre),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _telaNombreSeleccionado = value!;
                                    // Seleccionar el primer color disponible
                                    final colores = grupos[_telaNombreSeleccionado]!;
                                    if (colores.isNotEmpty) {
                                      _telaColorSeleccionado = colores.first['color'] ?? '';
                                      _telaIdSeleccionada = colores.first['id_insumo'] as int;
                                      _precioTelaSeleccionada = colores.first['precio']?.toDouble() ?? 0.0;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              
                              // 👈 SEGUNDO DROPDOWN: Color (solo si hay colores disponibles)
                              if (_telaNombreSeleccionado.isNotEmpty && coloresDisponibles.length > 1)
                                DropdownButtonFormField<String>(
                                  value: _telaColorSeleccionado.isNotEmpty ? _telaColorSeleccionado : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Color',
                                    border: OutlineInputBorder(),
                                  ),
                                  hint: const Text('Seleccione un color'),
                                  items: coloresDisponibles.map((tela) {
                                    final color = tela['color'] ?? 'Sin color';
                                    final precio = tela['precio']?.toDouble() ?? 0.0;
                                    final stock = tela['cantidad_disponible'] as double? ?? 0;
                                    
                                    return DropdownMenuItem<String>(
                                      value: color,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: _getColorFromString(color),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.grey.shade400),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('$color ($precio Bs/m) - Stock: $stock m'),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _telaColorSeleccionado = value!;
                                      // Buscar el ID y precio de la tela con ese color
                                      for (var tela in coloresDisponibles) {
                                        if (tela['color'] == value) {
                                          _telaIdSeleccionada = tela['id_insumo'] as int;
                                          _precioTelaSeleccionada = tela['precio']?.toDouble() ?? 0.0;
                                          break;
                                        }
                                      }
                                    });
                                  },
                                ),
                              
                              // 👈 Mostrar color seleccionado si solo hay uno
                              if (_telaNombreSeleccionado.isNotEmpty && coloresDisponibles.length == 1 && coloresDisponibles.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Text('Color: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: _getColorFromString(coloresDisponibles.first['color'] ?? ''),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.grey.shade400),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(coloresDisponibles.first['color'] ?? 'Sin color'),
                                      Text(
                                        ' (${coloresDisponibles.first['precio']?.toDouble() ?? 0.0} Bs/m)',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              const SizedBox(height: 15),
                              
                              const Text('Factor de tela (pliegues):'),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<double>(
                                      title: const Text('Lisa (2)'),
                                      value: 2.0,
                                      groupValue: _factorTela,
                                      onChanged: (value) {
                                        setState(() => _factorTela = value!);
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<double>(
                                      title: const Text('Normal (3)'),
                                      value: 3.0,
                                      groupValue: _factorTela,
                                      onChanged: (value) {
                                        setState(() => _factorTela = value!);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // ========== ACCESORIOS ==========
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Accesorios (opcionales)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A3A5F),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_accesorios.isEmpty)
                                const Text(
                                  'No hay accesorios disponibles',
                                  style: TextStyle(color: Colors.grey),
                                )
                              else
                                ..._accesorios.map((acc) {
                                  final id = acc['id_insumo'];
                                  final nombre = acc['nombre'] ?? 'Sin nombre';
                                  final precio = acc['precio']?.toDouble() ?? 0.0;
                                  final unidad = acc['unidad_medida'] ?? '';
                                  
                                  return CheckboxListTile(
                                    title: Text('$nombre (+$precio Bs/$unidad)'),
                                    value: _accesoriosSeleccionados[id] ?? false,
                                    onChanged: (value) {
                                      setState(() {
                                        _accesoriosSeleccionados[id] = value ?? false;
                                      });
                                    },
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // ========== BOTONES ==========
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _calcular(context),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: const Color(0xFF1A3A5F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'CALCULAR',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _limpiar(context),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'LIMPIAR',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _guardarCotizacion(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            '💾 GUARDAR COTIZACIÓN',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      // ========== RESULTADO ==========
                      if (provider.precioTotal != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Card(
                            color: const Color(0xFFE8F0FE),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'RESULTADO',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A3A5F),
                                    ),
                                  ),
                                  const Divider(),
                                  // 👈 MOSTRAR TELA CON COLOR
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Tela:'),
                                      Text(
                                        '${provider.telaSeleccionada}${provider.telaColor.isNotEmpty ? ' (${provider.telaColor})' : ''}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Precio base:'),
                                      Text(
                                        '${provider.precioBase?.toStringAsFixed(2) ?? '0.00'} Bs',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Accesorios:'),
                                      Text(
                                        '+ ${provider.totalAccesorios.toStringAsFixed(2)} Bs',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'TOTAL:',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${provider.precioTotal?.toStringAsFixed(2) ?? '0.00'} Bs',
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
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}