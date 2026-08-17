import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cotizacion_provider.dart';
import '../models/cotizacion.dart';
import 'detalle_cotizacion.dart';

class HistorialCotizaciones extends StatefulWidget {
  const HistorialCotizaciones({super.key});

  @override
  State<HistorialCotizaciones> createState() => _HistorialCotizacionesState();
}

class _HistorialCotizacionesState extends State<HistorialCotizaciones> {
  String _filtroEstado = 'todos';
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CotizacionProvider>(context, listen: false);
      provider.cargarCotizaciones();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  List<Cotizacion> _filtrarCotizaciones(List<Cotizacion> lista) {
    List<Cotizacion> resultado = lista;

    if (_filtroEstado != 'todos') {
      resultado = resultado.where((c) => c.estado == _filtroEstado).toList();
    }

    if (_searchQuery.isNotEmpty) {
      resultado = resultado.where((c) =>
        c.cliente.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return resultado;
  }

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
        title: const Text('Historial de Cotizaciones'),
        backgroundColor: const Color(0xFF1A3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<CotizacionProvider>(context, listen: false);
              provider.cargarCotizaciones();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<CotizacionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Cargando cotizaciones...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 10),
                  Text(
                    'Error: ${provider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => provider.cargarCotizaciones(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final cotizacionesFiltradas = _filtrarCotizaciones(provider.cotizaciones);

          if (cotizacionesFiltradas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isNotEmpty ? Icons.search_off : Icons.history,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    provider.cotizaciones.isEmpty
                        ? 'No hay cotizaciones guardadas'
                        : 'No se encontró "$_searchQuery"',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Intenta con otro nombre',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3A5F),
                    ),
                    child: const Text('Volver', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // ========== BUSCADOR ==========
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por cliente...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      setState(() {
                        _searchQuery = value;
                      });
                    });
                  },
                ),
              ),

              // ========== FILTROS ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Filtrar:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _filtroEstado == 'todos',
                        onSelected: (_) => setState(() => _filtroEstado = 'todos'),
                      ),
                      const SizedBox(width: 5),
                      ChoiceChip(
                        label: const Text('⏳ Pendiente'),
                        selected: _filtroEstado == 'pendiente',
                        onSelected: (_) => setState(() => _filtroEstado = 'pendiente'),
                      ),
                      const SizedBox(width: 5),
                      ChoiceChip(
                        label: const Text('✅ Aprobada'),
                        selected: _filtroEstado == 'aprobada',
                        onSelected: (_) => setState(() => _filtroEstado = 'aprobada'),
                      ),
                      const SizedBox(width: 5),
                      ChoiceChip(
                        label: const Text('🔧 En Proceso'),
                        selected: _filtroEstado == 'en_proceso',
                        onSelected: (_) => setState(() => _filtroEstado = 'en_proceso'),
                      ),
                      const SizedBox(width: 5),
                      ChoiceChip(
                        label: const Text('✅ Finalizado'),
                        selected: _filtroEstado == 'finalizado',
                        onSelected: (_) => setState(() => _filtroEstado = 'finalizado'),
                      ),
                      const SizedBox(width: 5),
                      ChoiceChip(
                        label: const Text('📦 Entregado'),
                        selected: _filtroEstado == 'entregado',
                        onSelected: (_) => setState(() => _filtroEstado = 'entregado'),
                      ),
                    ],
                  ),
                ),
              ),

              // ========== RESUMEN ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResumenItem('Total', provider.cotizaciones.length, Colors.blue),
                    _buildResumenItem('Pendientes', _contarPorEstado(provider, 'pendiente'), Colors.orange),
                    _buildResumenItem('En Proceso', _contarPorEstado(provider, 'en_proceso'), Colors.blue),
                    _buildResumenItem('Finalizados', _contarPorEstado(provider, 'finalizado'), Colors.green),
                    _buildResumenItem('Entregados', _contarPorEstado(provider, 'entregado'), Colors.purple),
                  ],
                ),
              ),

              const Divider(),

              // ========== LISTA ==========
              Expanded(
                child: ListView.builder(
                  itemCount: cotizacionesFiltradas.length,
                  itemBuilder: (context, index) {
                    final c = cotizacionesFiltradas[index];
                    final estadoColor = _getEstadoColor(c.estado);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: estadoColor.withOpacity(0.2),
                          child: Text(
                            c.estado[0].toUpperCase(),
                            style: TextStyle(
                              color: estadoColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          c.cliente,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${c.tela} - ${c.ancho}m x ${c.alto}m'),
                            Text(
                              'Accesorios: ${c.accesorios}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              _getEstadoTexto(c.estado),
                              style: TextStyle(
                                color: estadoColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${c.precioFinal.toStringAsFixed(2)} Bs',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1A3A5F),
                              ),
                            ),
                            Text(
                              '${c.fecha.toLocal().toString().split(' ')[0]}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalleCotizacion(cotizacion: c),
                            ),
                          ).then((_) {
                            final provider = Provider.of<CotizacionProvider>(context, listen: false);
                            provider.cargarCotizaciones();
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: const Color(0xFF1A3A5F),
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }

  int _contarPorEstado(CotizacionProvider provider, String estado) {
    return provider.cotizaciones.where((c) => c.estado == estado).length;
  }

  Widget _buildResumenItem(String label, int cantidad, Color color) {
    return Column(
      children: [
        Text(
          cantidad.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}