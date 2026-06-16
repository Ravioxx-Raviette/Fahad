import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:my_flutter_app/models/verification_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  Future<void> generateAndPrint(VerificationResult result) async {
    final pdf = pw.Document();

    // 1. Load the font
    final font = await PdfGoogleFonts.nunitoExtraLight();

    // Convert image bytes for PDF
    pw.MemoryImage? pdfImage;
    if (result.imageBytes != null) {
      pdfImage = pw.MemoryImage(result.imageBytes!);
    }

    final bool isManipulated = result.classificationResult.contains('Fake') ||
        result.classificationResult.contains('Manipulated');
    final PdfColor statusColor =
        isManipulated ? PdfColors.red900 : PdfColors.green900;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        // 2. APPLY THE FONT HERE (This fixes the yellow warning)
        theme: pw.ThemeData.withFont(base: font),

        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('FAHAD Deepfake Detector',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text('CONFIDENTIAL REPORT',
                        style: pw.TextStyle(
                            color: PdfColors.red,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // IMAGE & SCORE
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Image Container
                  if (pdfImage != null)
                    pw.Container(
                      width: 150,
                      height: 150,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 8,
                        verticalRadius: 8,
                        child: pw.Image(pdfImage, fit: pw.BoxFit.cover),
                      ),
                    ),
                  pw.SizedBox(width: 20),

                  // Score Details
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Verification Result:',
                            style:
                                const pw.TextStyle(color: PdfColors.grey700)),
                        pw.Text(
                          result.classificationResult.toUpperCase(),
                          style: pw.TextStyle(
                              color: statusColor,
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text('Credibility Score:',
                            style:
                                const pw.TextStyle(color: PdfColors.grey700)),
                        pw.Text(
                          '${result.credibilityScore.toStringAsFixed(2)}%',
                          style: pw.TextStyle(
                              fontSize: 40, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                            'Analyzed on: ${DateFormat('yyyy-MM-dd HH:mm').format(result.verificationDate)}'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // METADATA TABLE
              pw.Text('Technical Analysis',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.SizedBox(height: 10),

              ...result.metadata.entries.map((entry) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(entry.key.toUpperCase(),
                          style: const pw.TextStyle(
                              color: PdfColors.grey700, fontSize: 10)),
                      pw.Text(entry.value.toString(),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),

              pw.Spacer(),

              // FOOTER
              pw.Divider(),
              pw.Center(
                  child: pw.Text(
                      'Generated by FAHAD AI Verification System | Offline Edge-AI',
                      style: const pw.TextStyle(
                          color: PdfColors.grey, fontSize: 10))),
            ],
          );
        },
      ),
    );

    // This opens the printer/share dialog on the phone
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
