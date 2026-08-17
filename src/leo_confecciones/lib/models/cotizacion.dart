class Cotizacion {
  final int? id;
  final String cliente;
  final String tela;
  final String telaColor; 
  final double ancho;
  final double alto;
  final double factorTela;
  final double precioTela;
  final double precioBase;
  final double totalAccesorios;
  final double precioFinal;
  final String accesorios;
  final String estado; // 'pendiente', 'aprobada', 'rechazada'
  final DateTime fecha;

  Cotizacion({
    this.id,
    required this.cliente,
    required this.tela,
    this.telaColor = '',
    required this.ancho,
    required this.alto,
    required this.factorTela,
    required this.precioTela,
    required this.precioBase,
    required this.totalAccesorios,
    required this.precioFinal,
    required this.accesorios,
    this.estado = 'pendiente',
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente': cliente,
      'tela': tela,
      'telaColor': telaColor, 
      'ancho': ancho,
      'alto': alto,
      'factorTela': factorTela,
      'precioTela': precioTela,
      'precioBase': precioBase,
      'totalAccesorios': totalAccesorios,
      'precioFinal': precioFinal,
      'accesorios': accesorios,
      'estado': estado,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Cotizacion.fromMap(Map<String, dynamic> map) {
    return Cotizacion(
      id: map['id'],
      cliente: map['cliente'],
      tela: map['tela'],
      telaColor: map['telaColor'] ?? '', 
      ancho: map['ancho'],
      alto: map['alto'],
      factorTela: map['factorTela'],
      precioTela: map['precioTela'],
      precioBase: map['precioBase'],
      totalAccesorios: map['totalAccesorios'],
      precioFinal: map['precioFinal'],
      accesorios: map['accesorios'],
      estado: map['estado'] ?? 'pendiente',
      fecha: DateTime.parse(map['fecha']),
    );
  }
}