import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../providers/productos_provider.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;
  String? _error;

  // Datos de reportes
  Map<String, dynamic> _ventasHoy = {};
  Map<String, dynamic> _ventasMes = {};
  List<Map<String, dynamic>> _topTelas = [];
  List<Map<String, dynamic>> _stockCritico = [];

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _ventasHoy = await _obtenerVentasHoy();
      _ventasMes = await _obtenerVentasMes();
      _topTelas = await _obtenerTopTelas();
      _stockCritico = await _obtenerStockCritico();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar reportes: $e';
        _isLoading = false;
      });
    }
  }

  // ========== CONSULTAS A LA BD ==========

  Future<Map<String, dynamic>> _obtenerVentasHoy() async {
    final db = await _db.database;
    final hoy = DateTime.now().toIso8601String().split('T')[0];

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_ventas,
        COALESCE(SUM(total), 0) as total_ingresos,
        COALESCE(SUM(CASE WHEN estado = 'efectivo' THEN total ELSE 0 END), 0) as efectivo,
        COALESCE(SUM(CASE WHEN estado = 'qr' THEN total ELSE 0 END), 0) as qr,
        COALESCE(SUM(CASE WHEN estado = 'credito' THEN total ELSE 0 END), 0) as credito
      FROM ventas
      WHERE fecha LIKE '$hoy%'
    ''');

    if (result.isNotEmpty) {
      final row = result.first;
      return {
        'total_ventas': (row['total_ventas'] as int?) ?? 0,
        'total_ingresos': (row['total_ingresos'] as num?)?.toDouble() ?? 0.0,
        'efectivo': (row['efectivo'] as num?)?.toDouble() ?? 0.0,
        'qr': (row['qr'] as num?)?.toDouble() ?? 0.0,
        'credito': (row['credito'] as num?)?.toDouble() ?? 0.0,
      };
    }
    return {
      'total_ventas': 0,
      'total_ingresos': 0.0,
      'efectivo': 0.0,
      'qr': 0.0,
      'credito': 0.0,
    };
  }

  Future<Map<String, dynamic>> _obtenerVentasMes() async {
    final db = await _db.database;
    final mes = DateTime.now().month;
    final anio = DateTime.now().year;

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_ventas,
        COALESCE(SUM(total), 0) as total_ingresos,
        COUNT(DISTINCT id_cliente) as clientes_atendidos,
        COALESCE(AVG(total), 0) as promedio_venta
      FROM ventas
      WHERE strftime('%m', fecha) = '${mes.toString().padLeft(2, '0')}'
      AND strftime('%Y', fecha) = '$anio'
    ''');

    if (result.isNotEmpty) {
      final row = result.first;
      return {
        'total_ventas': (row['total_ventas'] as int?) ?? 0,
        'total_ingresos': (row['total_ingresos'] as num?)?.toDouble() ?? 0.0,
        'clientes_atendidos': (row['clientes_atendidos'] as int?) ?? 0,
        'promedio_venta': (row['promedio_venta'] as num?)?.toDouble() ?? 0.0,
      };
    }
    return {
      'total_ventas': 0,
      'total_ingresos': 0.0,
      'clientes_atendidos': 0,
      'promedio_venta': 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> _obtenerTopTelas() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT 
        pi.id_insumo,
        i.nombre as tela,
        COALESCE(SUM(pi.cantidad_requerida), 0) as total_metros
      FROM producto_insumo pi
      INNER JOIN insumos i ON pi.id_insumo = i.id_insumo
      GROUP BY pi.id_insumo
      ORDER BY total_metros DESC
      LIMIT 5
    ''');
    
    return result.map((row) {
      return {
        'id_insumo': row['id_insumo'],
        'tela': row['tela'],
        'total_metros': (row['total_metros'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _obtenerStockCritico() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT 
        i.id_insumo,
        i.nombre,
        i.stock_minimo,
        s.cantidad_disponible,
        (i.stock_minimo - s.cantidad_disponible) as faltante
      FROM insumos i
      INNER JOIN stock s ON i.id_insumo = s.id_insumo
      WHERE s.cantidad_disponible <= i.stock_minimo
      ORDER BY faltante DESC
    ''');
    
    return result.map((row) {
      return {
        'id_insumo': row['id_insumo'],
        'nombre': row['nombre'],
        'stock_minimo': (row['stock_minimo'] as num?)?.toDouble() ?? 0.0,
        'cantidad_disponible': (row['cantidad_disponible'] as num?)?.toDouble() ?? 0.0,
        'faltante': (row['faltante'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();
  }

  // ========== WIDGETS ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: const Color(0xFF1A3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarReportes,
            tooltip: 'Actualizar',
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
                        onPressed: _cargarReportes,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ========== VENTAS DEL DÍA ==========
                      _buildCard(
                        titulo: '📅 Ventas de Hoy',
                        icon: Icons.today,
                        color: Colors.blue,
                        child: Column(
                          children: [
                            _buildInfoRow('Ventas', _ventasHoy['total_ventas']?.toString() ?? '0'),
                            _buildInfoRow('Total', 'Bs ${_ventasHoy['total_ingresos']?.toStringAsFixed(2) ?? '0.00'}'),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetodoPago('💵 Efectivo', _ventasHoy['efectivo'] ?? 0.0),
                                _buildMetodoPago('📱 QR', _ventasHoy['qr'] ?? 0.0),
                                _buildMetodoPago('📝 Crédito', _ventasHoy['credito'] ?? 0.0),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ========== VENTAS DEL MES ==========
                      _buildCard(
                        titulo: '📊 Ventas del Mes',
                        icon: Icons.calendar_month,
                        color: Colors.green,
                        child: Column(
                          children: [
                            _buildInfoRow('Ventas', _ventasMes['total_ventas']?.toString() ?? '0'),
                            _buildInfoRow('Total', 'Bs ${_ventasMes['total_ingresos']?.toStringAsFixed(2) ?? '0.00'}'),
                            _buildInfoRow('Clientes', _ventasMes['clientes_atendidos']?.toString() ?? '0'),
                            _buildInfoRow('Promedio', 'Bs ${_ventasMes['promedio_venta']?.toStringAsFixed(2) ?? '0.00'}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ========== TOP TELAS ==========
                      _buildCard(
                        titulo: '🏆 Telas Más Vendidas',
                        icon: Icons.star,
                        color: Colors.amber,
                        child: _topTelas.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No hay datos aún'),
                              )
                            : Column(
                                children: _topTelas.map((tela) {
                                  final index = _topTelas.indexOf(tela) + 1;
                                  final totalMetros = tela['total_metros'] as double;
                                  return ListTile(
                                    leading: Text(
                                      '#$index',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    title: Text(tela['tela']),
                                    trailing: Text('${totalMetros.toStringAsFixed(1)} m'),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // ========== STOCK CRÍTICO ==========
                      _buildCard(
                        titulo: '⚠️ Stock Crítico',
                        icon: Icons.warning,
                        color: Colors.red,
                        child: _stockCritico.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('✅ Todo en orden'),
                              )
                            : Column(
                                children: _stockCritico.map((item) {
                                  final faltante = item['faltante'] as double;
                                  final stockMinimo = item['stock_minimo'] as double;
                                  final cantidadDisponible = item['cantidad_disponible'] as double;
                                  return ListTile(
                                    leading: const Icon(Icons.warning, color: Colors.red),
                                    title: Text(item['nombre']),
                                    subtitle: Text(
                                      'Stock: ${cantidadDisponible.toStringAsFixed(1)} / Mínimo: ${stockMinimo.toStringAsFixed(1)}',
                                    ),
                                    trailing: Text(
                                      'Faltan ${faltante.toStringAsFixed(1)}',
                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCard({
    required String titulo,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetodoPago(String label, double monto) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          'Bs ${monto.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}