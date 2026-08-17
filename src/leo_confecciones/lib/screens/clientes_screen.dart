import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clientes_provider.dart';
import '../models/cliente.dart';
import '../database/database_helper.dart';
import '../utils/mensajes.dart';
import '../utils/validadores.dart';
import 'cliente_perfil_screen.dart'; // 👈 NUEVA IMPORTACIÓN

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ClientesProvider>(context, listen: false);
      provider.cargarClientes();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  // ========== AGREGAR CLIENTE CON VALIDACIONES ==========
  void _agregarCliente() async {
    final nombre = _nombreController.text.trim();
    final telefono = _telefonoController.text.trim();
    final direccion = _direccionController.text.trim();

    final errorNombre = Validadores.campoRequerido(nombre, nombreCampo: 'Nombre del cliente');
    if (errorNombre != null) {
      Mensajes.error(context, errorNombre);
      return;
    }

    final errorTelefono = Validadores.telefono(telefono);
    if (errorTelefono != null) {
      Mensajes.error(context, errorTelefono);
      return;
    }

    final confirmar = await Mensajes.confirmarAccion(
      context,
      titulo: 'Agregar cliente',
      mensaje: '¿Agregar a "$nombre" como cliente?',
      botonConfirmacion: 'Agregar',
    );

    if (!confirmar) return;

    final cliente = Cliente(
      nombre: nombre,
      telefono: telefono,
      direccion: direccion,
    );

    final provider = Provider.of<ClientesProvider>(context, listen: false);
    final id = await provider.agregarCliente(cliente);

    if (id != -1) {
      Navigator.pop(context);
      Mensajes.exito(context, '✅ $nombre agregado como cliente');
    } else {
      Mensajes.error(context, 'Error al agregar cliente');
    }
  }

  // ========== ELIMINAR CLIENTE CON CONFIRMACIÓN ==========
  void _eliminarCliente(Cliente cliente, ClientesProvider provider) async {
    final confirmar = await Mensajes.confirmarEliminar(
      context,
      titulo: 'Eliminar cliente',
      mensaje: '¿Está seguro de eliminar a "${cliente.nombre}" de la lista de clientes? Esta acción no se puede deshacer.',
    );

    if (!confirmar) return;

    final success = await provider.eliminarCliente(cliente.id!);
    if (success) {
      Mensajes.exito(context, '🗑️ ${cliente.nombre} eliminado');
    } else {
      Mensajes.error(context, 'Error al eliminar cliente');
    }
  }

  // ========== DIALOGO PARA AGREGAR CLIENTE ==========
  void _mostrarDialogoAgregar() {
    _nombreController.clear();
    _telefonoController.clear();
    _direccionController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Juan Pérez',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 78945612',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Calle 1 N°123',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _agregarCliente,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
            ),
            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        backgroundColor: const Color(0xFF1A3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _mostrarDialogoAgregar,
            tooltip: 'Agregar cliente',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<ClientesProvider>(context, listen: false);
              provider.cargarClientes();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<ClientesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Cargando clientes...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 60, color: Colors.red),
                  const SizedBox(height: 10),
                  Text(provider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => provider.cargarClientes(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.clientes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No hay clientes registrados'),
                  SizedBox(height: 10),
                  Text(
                    'Presiona el botón + para agregar',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.clientes.length,
            itemBuilder: (context, index) {
              final cliente = provider.clientes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1A3A5F),
                    child: Text(
                      cliente.nombre[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    cliente.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    cliente.telefono.isNotEmpty
                        ? '📞 ${cliente.telefono}'
                        : 'Sin teléfono',
                  ),
                  // 👈 NUEVO: Tap para abrir perfil
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClientePerfilScreen(cliente: cliente),
                      ),
                    );
                    if (result == true) {
                      provider.cargarClientes();
                    }
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarCliente(cliente, provider),
                        tooltip: 'Eliminar cliente',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAgregar,
        backgroundColor: const Color(0xFF1A3A5F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}