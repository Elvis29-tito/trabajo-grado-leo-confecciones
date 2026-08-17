class CalculoService {
  double calcularPrecioCortina({
    required double ancho,
    required double alto,
    required double factorTela,
    required double precioTela,
  }) {
    return ancho * alto * factorTela * precioTela;
  }

  double calcularTotal({
    required double precioBase,
    required double totalAccesorios,
  }) {
    return precioBase + totalAccesorios;
  }
}