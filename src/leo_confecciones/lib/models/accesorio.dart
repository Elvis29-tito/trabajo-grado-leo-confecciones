class Accesorio {
  final String id;
  final String nombre;
  final double precio;
  bool seleccionado;

  Accesorio({
    required this.id,
    required this.nombre,
    required this.precio,
    this.seleccionado = false,
  });

  // Método para crear una copia con valores modificados
  Accesorio copyWith({
    String? id,
    String? nombre,
    double? precio,
    bool? seleccionado,
  }) {
    return Accesorio(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      seleccionado: seleccionado ?? this.seleccionado,
    );
  }

  // Convertir a Map para guardar en BD
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'seleccionado': seleccionado ? 1 : 0,
    };
  }

  // Convertir desde Map (desde BD)
  factory Accesorio.fromMap(Map<String, dynamic> map) {
    return Accesorio(
      id: map['id'],
      nombre: map['nombre'],
      precio: map['precio'],
      seleccionado: map['seleccionado'] == 1,
    );
  }

  // Para convertir a JSON (si usas API)
  Map<String, dynamic> toJson() => toMap();

  // Para crear desde JSON
  factory Accesorio.fromJson(Map<String, dynamic> json) => Accesorio.fromMap(json);
}