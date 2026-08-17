class Cliente {
  final int? id;
  final String nombre;
  final String telefono;
  final String direccion;
  final DateTime fechaRegistro;
  final String estado;

  Cliente({
    this.id,
    required this.nombre,
    this.telefono = '',
    this.direccion = '',
    DateTime? fechaRegistro,
    this.estado = 'activo',
  }) : fechaRegistro = fechaRegistro ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id_cliente': id,
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'estado': estado,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id_cliente'],
      nombre: map['nombre'],
      telefono: map['telefono'] ?? '',
      direccion: map['direccion'] ?? '',
      fechaRegistro: DateTime.parse(map['fecha_registro']),
      estado: map['estado'] ?? 'activo',
    );
  }

  Cliente copyWith({
    int? id,
    String? nombre,
    String? telefono,
    String? direccion,
    DateTime? fechaRegistro,
    String? estado,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      estado: estado ?? this.estado,
    );
  }
}