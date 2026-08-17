class Configuracion {
  final int? id;
  final String nombreTaller;
  final String telefono;
  final String email;
  final String direccion;
  final double manoObraPorMetro;
  final double factorTelaDefecto;
  final double iva;

  Configuracion({
    this.id,
    required this.nombreTaller,
    this.telefono = '',
    this.email = '',
    this.direccion = '',
    this.manoObraPorMetro = 12.0,
    this.factorTelaDefecto = 3.0,
    this.iva = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_taller': nombreTaller,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'mano_obra_por_metro': manoObraPorMetro,
      'factor_tela_defecto': factorTelaDefecto,
      'iva': iva,
    };
  }

  factory Configuracion.fromMap(Map<String, dynamic> map) {
    return Configuracion(
      id: map['id'],
      nombreTaller: map['nombre_taller'],
      telefono: map['telefono'] ?? '',
      email: map['email'] ?? '',
      direccion: map['direccion'] ?? '',
      manoObraPorMetro: map['mano_obra_por_metro'] ?? 12.0,
      factorTelaDefecto: map['factor_tela_defecto'] ?? 3.0,
      iva: map['iva'] ?? 0.0,
    );
  }
}