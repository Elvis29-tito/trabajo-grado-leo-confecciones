class Usuario {
  final int? id;
  final String nombre;
  final String email;
  final String password;
  final String rol; // 'admin' o 'vendedor'

  Usuario({
    this.id,
    required this.nombre,
    required this.email,
    required this.password,
    this.rol = 'vendedor',
  });

  // Convertir a Map para guardar en BD
  Map<String, dynamic> toMap() {
    return {
      'id_usuario': id,
      'nombre': nombre,
      'email': email,
      'password': password,
      'rol': rol,
    };
  }

  // Crear desde Map (desde BD)
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id_usuario'],
      nombre: map['nombre'],
      email: map['email'],
      password: map['password'],
      rol: map['rol'] ?? 'vendedor',
    );
  }

  // Copiar con cambios
  Usuario copyWith({
    int? id,
    String? nombre,
    String? email,
    String? password,
    String? rol,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      password: password ?? this.password,
      rol: rol ?? this.rol,
    );
  }

  // Verificar si es admin
  bool get isAdmin => rol == 'admin';

  // Verificar si es vendedor
  bool get isVendedor => rol == 'vendedor';

  // Obtener nombre del rol
  String get rolTexto {
    switch (rol) {
      case 'admin':
        return '👑 Administrador';
      case 'vendedor':
        return '👤 Vendedor';
      default:
        return '👤 Usuario';
    }
  }

  // Obtener color del rol
  String get rolColor {
    switch (rol) {
      case 'admin':
        return '#1A3A5F'; // Azul oscuro
      case 'vendedor':
        return '#27AE60'; // Verde
      default:
        return '#607D8B'; // Gris
    }
  }
}