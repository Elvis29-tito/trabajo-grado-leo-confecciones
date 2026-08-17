import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/cliente.dart';

class ClientesProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Cliente> _clientes = [];
  bool _isLoading = false;
  String? _error;

  // ========== GETTERS ==========
  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========== CARGAR CLIENTES ==========
  Future<void> cargarClientes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _db.getClientes();
      _clientes = data.map((map) => Cliente.fromMap(map)).toList();
    } catch (e) {
      _error = 'Error al cargar clientes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== AGREGAR CLIENTE ==========
  Future<int> agregarCliente(Cliente cliente) async {
    try {
      final id = await _db.insertCliente(cliente.toMap());
      await cargarClientes();
      return id;
    } catch (e) {
      _error = 'Error al agregar cliente: $e';
      return -1;
    }
  }

  // ========== ACTUALIZAR CLIENTE ========== 
  Future<bool> actualizarCliente(Cliente cliente) async {
    try {
      final result = await _db.updateCliente(cliente.toMap());
      await cargarClientes(); // Recargar lista después de actualizar
      return result > 0;
    } catch (e) {
      _error = 'Error al actualizar cliente: $e';
      return false;
    }
  }

  // ========== ELIMINAR CLIENTE ==========
  Future<bool> eliminarCliente(int id) async {
    try {
      final db = await _db.database;
      final result = await db.delete(
        'clientes',
        where: 'id_cliente = ?',
        whereArgs: [id],
      );
      await cargarClientes();
      return result > 0;
    } catch (e) {
      _error = 'Error al eliminar cliente: $e';
      return false;
    }
  }

  // ========== OBTENER CLIENTE POR ID ==========
  Cliente? getClienteById(int id) {
    try {
      return _clientes.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== LIMPIAR ERROR ==========
  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}