import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  Future<String> savePdf(String fileName, String content) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Deskripsi Gambar',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                font: font,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              content,
              style: pw.TextStyle(fontSize: 16, font: font),
            ),
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final outputFile = File('${directory.path}/$fileName');
    await outputFile.writeAsBytes(pdfBytes);
    return outputFile.path;
  }

  Future<String?> extractTextFromPdf(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String filePath = '${directory.path}/$fileName';
      File pdfFile = File(filePath);

      if (!await pdfFile.exists()) {
        final externalDir = Directory('/sdcard/Download');
        filePath = '${externalDir.path}/$fileName';
        pdfFile = File(filePath);
        if (!await pdfFile.exists()) {
          return null;
        }
      }

      final PdfDocument pdfDoc = PdfDocument(
        inputBytes: await pdfFile.readAsBytes(),
      );
      final PdfTextExtractor extractor = PdfTextExtractor(pdfDoc);
      String extractedText = '';
      for (var i = 0; i < pdfDoc.pages.count; i++) {
        final pageText = extractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        extractedText += pageText + '\n';
      }
      pdfDoc.dispose();
      return extractedText.trim();
    } catch (e) {
      print("Error extracting PDF text: $e");
      throw e;
    }
  }
}
