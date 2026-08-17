class Validadores {
  // Validar que un campo no esté vacío
  static String? campoRequerido(String? valor, {String nombreCampo = 'Campo'}) {
    if (valor == null || valor.trim().isEmpty) {
      return '$nombreCampo es obligatorio';
    }
    return null;
  }

  // Validar número positivo
  static String? numeroPositivo(String? valor, {String nombreCampo = 'Número'}) {
    if (valor == null || valor.trim().isEmpty) {
      return '$nombreCampo es obligatorio';
    }
    
    final numero = double.tryParse(valor);
    if (numero == null) {
      return '$nombreCampo debe ser un número válido';
    }
    
    if (numero <= 0) {
      return '$nombreCampo debe ser mayor a 0';
    }
    
    return null;
  }

  // Validar número no negativo (puede ser 0)
  static String? numeroNoNegativo(String? valor, {String nombreCampo = 'Número'}) {
    if (valor == null || valor.trim().isEmpty) {
      return '$nombreCampo es obligatorio';
    }
    
    final numero = double.tryParse(valor);
    if (numero == null) {
      return '$nombreCampo debe ser un número válido';
    }
    
    if (numero < 0) {
      return '$nombreCampo no puede ser negativo';
    }
    
    return null;
  }

  // Validar teléfono (básico)
  static String? telefono(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return null; // El teléfono es opcional
    }
    
    final telefono = valor.trim();
    if (!RegExp(r'^[0-9]{7,15}$').hasMatch(telefono)) {
      return 'Ingrese un teléfono válido (7-15 dígitos)';
    }
    return null;
  }

  // Validar email
  static String? email(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Email es obligatorio';
    }
    
    final email = valor.trim();
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      return 'Ingrese un email válido';
    }
    return null;
  }

  // Validar que la cantidad no supere el stock disponible
  static String? cantidadDisponible(String? valor, double stockDisponible) {
    final cantidad = double.tryParse(valor ?? '');
    if (cantidad == null || cantidad <= 0) {
      return 'Cantidad inválida';
    }
    
    if (cantidad > stockDisponible) {
      return 'No hay suficiente stock. Disponible: $stockDisponible';
    }
    
    return null;
  }
}