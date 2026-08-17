import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cotizacion.dart';

class PdfService {
  Future<void> generarPDF(Cotizacion cotizacion) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'LEO CONFECCIONES',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'COTIZACIÓN N° ${cotizacion.id}',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Fecha: ${cotizacion.fecha.toLocal()}'),
              pw.Text('Cliente: ${cotizacion.cliente}'),
              pw.SizedBox(height: 20),
              pw.Text('DETALLE DE LA COTIZACIÓN:'),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Concepto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Valor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tela')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(cotizacion.tela)),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Medidas')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${cotizacion.ancho}m x ${cotizacion.alto}m')),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Precio Base')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${cotizacion.precioBase.toStringAsFixed(2)} Bs')),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Accesorios')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${cotizacion.totalAccesorios.toStringAsFixed(2)} Bs')),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${cotizacion.precioFinal.toStringAsFixed(2)} Bs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ]),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text('Estado: ${cotizacion.estado.toUpperCase()}'),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'cotizacion_${cotizacion.id}.pdf',
    );
  }
}