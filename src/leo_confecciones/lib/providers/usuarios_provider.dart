import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/usuario.dart';
import '../utils/mensajes.dart';

class UsuariosProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Usuario> _usuarios = [];
  bool _isLoading = false;
  String? _error;

  // Usuario actualmente logueado
  Usuario? _usuarioActual;

  // ========== GETTERS ==========
  List<Usuario> get usuarios => _usuarios;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Usuario? get usuarioActual => _usuarioActual;

  // ========== CARGAR TODOS LOS USUARIOS ==========
  Future<void> cargarUsuarios() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _db.getUsuarios();
      _usuarios = data.map((map) => Usuario.fromMap(map)).toList();
    } catch (e) {
      _error = 'Error al cargar usuarios: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== INICIAR SESIÓN ==========
  Future<bool> login(String email, String password) async {
    try {
      final data = await _db.getUsuarioByEmail(email);
      
      if (data == null) {
        _error = 'Usuario no encontrado';
        return false;
      }

      final usuario = Usuario.fromMap(data);
      
      if (usuario.password != password) {
        _error = 'Contraseña incorrecta';
        return false;
      }

      _usuarioActual = usuario;
      notifyListeners();
      return true;

    } catch (e) {
      _error = 'Error al iniciar sesión: $e';
      return false;
    }
  }

  // ========== CERRAR SESIÓN ==========
  void logout() {
    _usuarioActual = null;
    notifyListeners();
  }

  // ========== REGISTRAR NUEVO USUARIO ==========
  Future<int> registrarUsuario(Usuario usuario) async {
    try {
      // Verificar si el email ya existe
      final existente = await _db.getUsuarioByEmail(usuario.email);
      if (existente != null) {
        _error = 'El email ya está registrado';
        return -1;
      }

      final id = await _db.insertUsuario(usuario.toMap());
      if (id != -1) {
        await cargarUsuarios();
      }
      return id;
    } catch (e) {
      _error = 'Error al registrar usuario: $e';
      return -1;
    }
  }

  // ========== ACTUALIZAR USUARIO ==========
  Future<bool> actualizarUsuario(Usuario usuario) async {
    try {
      final result = await _db.updateUsuario(usuario.toMap());
      if (result > 0) {
        await cargarUsuarios();
        // Actualizar usuario actual si es el mismo
        if (_usuarioActual?.id == usuario.id) {
          _usuarioActual = usuario;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error al actualizar usuario: $e';
      return false;
    }
  }

  // ========== ELIMINAR USUARIO ==========
  Future<bool> eliminarUsuario(int id) async {
    try {
      // No permitir eliminar al usuario actual
      if (_usuarioActual?.id == id) {
        _error = 'No puedes eliminar tu propia cuenta';
        return false;
      }

      final result = await _db.deleteUsuario(id);
      if (result > 0) {
        await cargarUsuarios();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error al eliminar usuario: $e';
      return false;
    }
  }

  // ========== CAMBIAR CONTRASEÑA ==========
  Future<bool> cambiarPassword(int id, String nuevaPassword) async {
    try {
      final usuario = _usuarios.firstWhere((u) => u.id == id);
      final usuarioActualizado = usuario.copyWith(password: nuevaPassword);
      return await actualizarUsuario(usuarioActualizado);
    } catch (e) {
      _error = 'Error al cambiar contraseña: $e';
      return false;
    }
  }

  // ========== OBTENER USUARIO POR ID ==========
  Usuario? getUsuarioById(int id) {
    try {
      return _usuarios.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== CONTAR USUARIOS POR ROL ==========
  int contarPorRol(String rol) {
    return _usuarios.where((u) => u.rol == rol).length;
  }

  // ========== LIMPIAR ERROR ==========
  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}