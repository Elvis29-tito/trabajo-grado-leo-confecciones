import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/configuracion.dart';

class ConfiguracionProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  Configuracion? _configuracion;
  bool _isLoading = false;
  String? _error;

  Configuracion? get configuracion => _configuracion;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarConfiguracion() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _db.getConfiguracion();
      if (data != null) {
        _configuracion = Configuracion.fromMap(data);
      }
    } catch (e) {
      _error = 'Error al cargar configuración: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarConfiguracion(Configuracion config) async {
    try {
      final result = await _db.updateConfiguracion(config.toMap());
      if (result > 0) {
        _configuracion = config;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error al guardar configuración: $e';
      return false;
    }
  }
}