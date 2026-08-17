import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/usuarios_provider.dart';
import '../models/usuario.dart';
import '../utils/mensajes.dart';
import '../utils/validadores.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  // Controladores para el formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  String _rolSeleccionado = 'vendedor';
  bool _isEditing = false;
  int? _usuarioIdEditando;

  // Controladores para cambiar contraseña
  final TextEditingController _nuevaPasswordController = TextEditingController();
  final TextEditingController _confirmarNuevaPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UsuariosProvider>(context, listen: false);
      provider.cargarUsuarios();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nuevaPasswordController.dispose();
    _confirmarNuevaPasswordController.dispose();
    super.dispose();
  }

  // ========== GUARDAR USUARIO (NUEVO O EDICIÓN) ==========
  void _guardarUsuario(BuildContext context) async {
    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validaciones
    final errorNombre = Validadores.campoRequerido(nombre, nombreCampo: 'Nombre');
    if (errorNombre != null) {
      Mensajes.error(context, errorNombre);
      return;
    }

    final errorEmail = Validadores.email(email);
    if (errorEmail != null) {
      Mensajes.error(context, errorEmail);
      return;
    }

    // Solo validar contraseña si es nuevo usuario o si se está cambiando
    if (!_isEditing || (_isEditing && password.isNotEmpty)) {
      if (password.length < 4) {
        Mensajes.error(context, 'La contraseña debe tener al menos 4 caracteres');
        return;
      }
      if (password != confirmPassword) {
        Mensajes.error(context, 'Las contraseñas no coinciden');
        return;
      }
    }

    final provider = Provider.of<UsuariosProvider>(context, listen: false);

    if (_isEditing) {
      // Editar usuario existente
      final usuarioExistente = provider.getUsuarioById(_usuarioIdEditando!);
      if (usuarioExistente == null) {
        Mensajes.error(context, 'Usuario no encontrado');
        return;
      }

      final usuarioActualizado = usuarioExistente.copyWith(
        nombre: nombre,
        email: email,
        password: password.isNotEmpty ? password : usuarioExistente.password,
        rol: _rolSeleccionado,
      );

      final success = await provider.actualizarUsuario(usuarioActualizado);
      if (success) {
        Mensajes.exito(context, '✅ Usuario actualizado');
        _limpiarFormulario();
        Navigator.pop(context);
      } else {
        Mensajes.error(context, provider.error ?? 'Error al actualizar');
      }
    } else {
      // Nuevo usuario
      final usuario = Usuario(
        nombre: nombre,
        email: email,
        password: password,
        rol: _rolSeleccionado,
      );

      final id = await provider.registrarUsuario(usuario);
      if (id != -1) {
        Mensajes.exito(context, '✅ Usuario registrado correctamente');
        _limpiarFormulario();
        Navigator.pop(context);
      } else {
        Mensajes.error(context, provider.error ?? 'Error al registrar');
      }
    }
  }

  // ========== MOSTRAR DIÁLOGO PARA AGREGAR/EDITAR ==========
  void _mostrarDialogoUsuario({Usuario? usuario}) {
    _isEditing = usuario != null;
    _usuarioIdEditando = usuario?.id;

    if (usuario != null) {
      _nombreController.text = usuario.nombre;
      _emailController.text = usuario.email;
      _passwordController.text = '';
      _confirmPasswordController.text = '';
      _rolSeleccionado = usuario.rol;
    } else {
      _nombreController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _rolSeleccionado = 'vendedor';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_isEditing ? '✏️ Editar Usuario' : '👤 Nuevo Usuario'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: _isEditing ? 'Nueva contraseña (opcional)' : 'Contraseña *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  hintText: _isEditing ? 'Dejar vacío para mantener' : 'Mínimo 4 caracteres',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: _isEditing ? 'Confirmar nueva contraseña' : 'Confirmar contraseña *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _rolSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.admin_panel_settings),
                ),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('👑 Administrador')),
                  DropdownMenuItem(value: 'vendedor', child: Text('👤 Vendedor')),
                ],
                onChanged: (value) {
                  setState(() {
                    _rolSeleccionado = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _limpiarFormulario();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _guardarUsuario(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
            ),
            child: Text(
              _isEditing ? 'Actualizar' : 'Registrar',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ========== MOSTRAR DIÁLOGO PARA CAMBIAR CONTRASEÑA ==========
  void _mostrarDialogoCambiarPassword(Usuario usuario) {
    _nuevaPasswordController.clear();
    _confirmarNuevaPasswordController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔑 Cambiar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Usuario: ${usuario.nombre}'),
            const SizedBox(height: 10),
            TextField(
              controller: _nuevaPasswordController,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmarNuevaPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirmar nueva contraseña *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = _nuevaPasswordController.text.trim();
              final confirmPassword = _confirmarNuevaPasswordController.text.trim();

              if (password.length < 4) {
                Mensajes.error(context, 'La contraseña debe tener al menos 4 caracteres');
                return;
              }
              if (password != confirmPassword) {
                Mensajes.error(context, 'Las contraseñas no coinciden');
                return;
              }

              final provider = Provider.of<UsuariosProvider>(context, listen: false);
              final success = await provider.cambiarPassword(usuario.id!, password);

              if (success) {
                Mensajes.exito(context, '✅ Contraseña actualizada');
                Navigator.pop(context);
              } else {
                Mensajes.error(context, provider.error ?? 'Error al cambiar contraseña');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3A5F),
            ),
            child: const Text('Cambiar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========== ELIMINAR USUARIO ==========
  void _eliminarUsuario(Usuario usuario, UsuariosProvider provider) async {
    final confirmar = await Mensajes.confirmarEliminar(
      context,
      titulo: 'Eliminar usuario',
      mensaje: '¿Está seguro de eliminar a "${usuario.nombre}"? Esta acción no se puede deshacer.',
    );

    if (!confirmar) return;

    final success = await provider.eliminarUsuario(usuario.id!);
    if (success) {
      Mensajes.exito(context, '🗑️ ${usuario.nombre} eliminado');
    } else {
      Mensajes.error(context, provider.error ?? 'Error al eliminar');
    }
  }

  // ========== LIMPIAR FORMULARIO ==========
  void _limpiarFormulario() {
    _nombreController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _rolSeleccionado = 'vendedor';
    _isEditing = false;
    _usuarioIdEditando = null;
  }

  // ========== BUILD ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: const Color(0xFF1A3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<UsuariosProvider>(context, listen: false);
              provider.cargarUsuarios();
            },
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _mostrarDialogoUsuario(),
            tooltip: 'Agregar usuario',
          ),
        ],
      ),
      body: Consumer<UsuariosProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Cargando usuarios...'),
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
                    onPressed: () => provider.cargarUsuarios(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.usuarios.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No hay usuarios registrados'),
                  SizedBox(height: 10),
                  Text(
                    'Presiona el botón + para agregar',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Separar admin y vendedores
          final admins = provider.usuarios.where((u) => u.rol == 'admin').toList();
          final vendedores = provider.usuarios.where((u) => u.rol == 'vendedor').toList();
          final usuarioActual = provider.usuarioActual;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.usuarios.length,
            itemBuilder: (context, index) {
              final usuario = provider.usuarios[index];
              final esAdmin = usuario.rol == 'admin';
              final esUsuarioActual = usuarioActual?.id == usuario.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: esUsuarioActual
                      ? BorderSide(color: Colors.blue.shade300, width: 2)
                      : BorderSide.none,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: esAdmin
                        ? const Color(0xFF1A3A5F)
                        : const Color(0xFF27AE60),
                    child: Text(
                      usuario.nombre[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        usuario.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (esUsuarioActual) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'TÚ',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usuario.email),
                      Text(
                        esAdmin ? '👑 Administrador' : '👤 Vendedor',
                        style: TextStyle(
                          color: esAdmin ? const Color(0xFF1A3A5F) : const Color(0xFF27AE60),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón cambiar contraseña
                      IconButton(
                        icon: const Icon(Icons.key, color: Colors.orange),
                        onPressed: () => _mostrarDialogoCambiarPassword(usuario),
                        tooltip: 'Cambiar contraseña',
                      ),
                      // Botón editar
                      if (usuarioActual?.rol == 'admin' || esUsuarioActual)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _mostrarDialogoUsuario(usuario: usuario),
                          tooltip: 'Editar',
                        ),
                      // Botón eliminar
                      if (usuarioActual?.rol == 'admin' && !esUsuarioActual)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarUsuario(usuario, provider),
                          tooltip: 'Eliminar',
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
        onPressed: () => _mostrarDialogoUsuario(),
        backgroundColor: const Color(0xFF1A3A5F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}