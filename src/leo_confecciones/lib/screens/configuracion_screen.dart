import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/configuracion_provider.dart';
import '../models/configuracion.dart';
import '../utils/mensajes.dart';
import '../utils/validadores.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _manoObraController = TextEditingController();
  final TextEditingController _factorTelaController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ConfiguracionProvider>(context, listen: false);
      provider.cargarConfiguracion();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _manoObraController.dispose();
    _factorTelaController.dispose();
    super.dispose();
  }

  void _cargarDatos(Configuracion config) {
    _nombreController.text = config.nombreTaller;
    _telefonoController.text = config.telefono;
    _emailController.text = config.email;
    _direccionController.text = config.direccion;
    _manoObraController.text = config.manoObraPorMetro.toString();
    _factorTelaController.text = config.factorTelaDefecto.toString();
  }

  void _guardarConfiguracion(BuildContext context) async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      Mensajes.error(context, 'El nombre del taller es obligatorio');
      return;
    }

    final manoObra = double.tryParse(_manoObraController.text) ?? 12.0;
    if (manoObra <= 0) {
      Mensajes.error(context, 'La mano de obra debe ser mayor a 0');
      return;
    }

    final factorTela = double.tryParse(_factorTelaController.text) ?? 3.0;
    if (factorTela < 2 || factorTela > 3) {
      Mensajes.error(context, 'El factor de tela debe ser 2 o 3');
      return;
    }

    final config = Configuracion(
      nombreTaller: nombre,
      telefono: _telefonoController.text.trim(),
      email: _emailController.text.trim(),
      direccion: _direccionController.text.trim(),
      manoObraPorMetro: manoObra,
      factorTelaDefecto: factorTela,
    );

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<ConfiguracionProvider>(context, listen: false);
    final success = await provider.guardarConfiguracion(config);

    setState(() {
      _isSaving = false;
    });

    if (success) {
      Mensajes.exito(context, '✅ Configuración guardada');
      Navigator.pop(context);
    } else {
      Mensajes.error(context, 'Error al guardar configuración');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: const Color(0xFF1A3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _guardarConfiguracion(context),
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: Consumer<ConfiguracionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Cargando configuración...'),
                ],
              ),
            );
          }

          if (provider.configuracion != null) {
            _cargarDatos(provider.configuracion!);
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========== DATOS DEL TALLER ==========
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🏪 Datos del Taller',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3A5F),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del taller *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.store),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _telefonoController,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _direccionController,
                            decoration: const InputDecoration(
                              labelText: 'Dirección',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ========== CONFIGURACIÓN DE PRECIOS ==========
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '💰 Precios por Defecto',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3A5F),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _manoObraController,
                            decoration: const InputDecoration(
                              labelText: 'Mano de obra (Bs/m)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money),
                              hintText: 'Ej: 12.00',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _factorTelaController,
                            decoration: const InputDecoration(
                              labelText: 'Factor de tela (2 o 3)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calculate),
                              hintText: 'Ej: 3.0',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '💡 El factor de tela determina la cantidad de tela necesaria según los pliegues. 2 = Lisa, 3 = Normal',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ========== BOTÓN GUARDAR ==========
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _guardarConfiguracion(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '💾 GUARDAR CONFIGURACIÓN',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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