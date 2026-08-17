class Producto {
  final int? id;
  final String nombre;
  final String descripcion;
  final double precioBase; // 👈 CAMBIADO de precioVenta a precioBase
  final String estado; // 'pendiente', 'en_produccion', 'finalizado', 'entregado'
  final int? idCotizacion;
  final DateTime fechaCreacion;

  Producto({
    this.id,
    required this.nombre,
    this.descripcion = '',
    required this.precioBase, // 👈 CAMBIADO
    this.estado = 'pendiente',
    this.idCotizacion,
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  // Convertir a Map para guardar en BD
  Map<String, dynamic> toMap() {
    return {
      'id_producto': id, // 👈 CAMBIADO a id_producto
      'nombre': nombre,
      'descripcion': descripcion,
      'precio_base': precioBase, // 👈 CAMBIADO a precio_base
      'estado': estado,
      'id_cotizacion': idCotizacion,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  // Crear desde Map (desde BD)
  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id_producto'] ?? map['id'], // 👈 Soporta ambos nombres
      nombre: map['nombre'],
      descripcion: map['descripcion'] ?? '',
      precioBase: map['precio_base'] ?? map['precio_venta'] ?? 0.0, // 👈 Soporta ambos
      estado: map['estado'] ?? 'pendiente',
      idCotizacion: map['id_cotizacion'],
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
    );
  }

  // Copiar con cambios
  Producto copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    double? precioBase,
    String? estado,
    int? idCotizacion,
    DateTime? fechaCreacion,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioBase: precioBase ?? this.precioBase,
      estado: estado ?? this.estado,
      idCotizacion: idCotizacion ?? this.idCotizacion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  // Obtener nombre del estado en español
  String get estadoTexto {
    switch (estado) {
      case 'en_produccion':
        return '🔧 En Producción';
      case 'finalizado':
        return '✅ Finalizado';
      case 'entregado':
        return '📦 Entregado';
      default:
        return '⏳ Pendiente';
    }
  }

  // Obtener color del estado (en formato Color)
  String get estadoColorHex {
    switch (estado) {
      case 'en_produccion':
        return '#2196F3'; // Azul
      case 'finalizado':
        return '#4CAF50'; // Verde
      case 'entregado':
        return '#9C27B0'; // Púrpura
      default:
        return '#FF9800'; // Naranja
    }
  }
}