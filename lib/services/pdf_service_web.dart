import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

class PdfService {
  // Helper function to format date without locale
  static String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Helper function to download PDF in web
  static void _downloadPdfWeb(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // Generate PDF untuk Konsultasi Anamnesis
  static Future<void> generateAnamnesisPdf({
    required String consultationId,
    required String mainComplaint,
    required String symptomStartDate,
    required List<Map<String, dynamic>> questionsAndAnswers,
    required Map<String, dynamic> diagnosis,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'LAPORAN KONSULTASI ANAMNESIS',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ID Konsultasi: $consultationId',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Tanggal: ${_formatDate(now)}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Keluhan Utama
          _buildSection(title: '📋 KELUHAN UTAMA', content: mainComplaint),

          pw.SizedBox(height: 16),

          // Mulai Gejala
          _buildSection(
            title: '📅 MULAI GEJALA',
            content: symptomStartDate.isNotEmpty
                ? DateFormat(
                    'dd MMMM yyyy',
                  ).format(DateTime.parse(symptomStartDate))
                : 'Tidak dicatat',
          ),

          pw.SizedBox(height: 24),

          // Hasil Anamnesis
          pw.Text(
            '💬 HASIL ANAMNESIS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          ...questionsAndAnswers.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final qa = entry.value;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Pertanyaan $index:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    qa['question'] ?? '',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Jawaban:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    qa['answer'] ?? '',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            );
          }),

          pw.SizedBox(height: 24),

          // Diagnosis
          pw.Text(
            '🏥 DIAGNOSIS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue200),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  diagnosis['diagnosis_name'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                if (diagnosis['probability'] != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Tingkat Keyakinan: ${diagnosis['probability']}',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
                pw.SizedBox(height: 12),
                pw.Text(
                  'Deskripsi:',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  diagnosis['description'] ?? '',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // Recommendations
          if (diagnosis['recommendations'] != null &&
              diagnosis['recommendations'] != '') ...[
            pw.Text(
              '💊 REKOMENDASI',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                diagnosis['recommendations'],
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],

          pw.SizedBox(height: 16),

          // Specialist Recommendation
          if (diagnosis['specialist_recommendation'] != null &&
              diagnosis['specialist_recommendation'] != '') ...[
            pw.Text(
              '👨‍⚕️ REKOMENDASI SPESIALIS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.orange800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                border: pw.Border.all(color: PdfColors.orange200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                diagnosis['specialist_recommendation'],
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],

          pw.SizedBox(height: 32),

          // Disclaimer
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '⚠️ DISCLAIMER',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Laporan ini dibuat oleh AI dan bersifat informatif. Untuk diagnosis dan penanganan yang akurat, silakan konsultasikan dengan dokter atau tenaga medis profesional.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    // Save PDF and download in web
    try {
      final fileName =
          'Konsultasi_Anamnesis_${consultationId.substring(0, 8)}.pdf';
      final bytes = await pdf.save();
      _downloadPdfWeb(bytes, fileName);
    } catch (e) {
      print('Error saving/downloading PDF: $e');
      rethrow;
    }
  }

  // Generate PDF untuk Analisis Gambar Medis
  static Future<void> generateImageAnalysisPdf({
    required String analysisId,
    required String? imageDescription,
    required Map<String, dynamic> analysisResult,
    String? imagePath, // Not used in web version but kept for API compatibility
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'LAPORAN ANALISIS GAMBAR MEDIS',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ID Analisis: $analysisId',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Tanggal: ${_formatDate(now)}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Image Description
          if (imageDescription != null && imageDescription.isNotEmpty) ...[
            _buildSection(
              title: '🖼️ DESKRIPSI GAMBAR',
              content: imageDescription,
            ),
            pw.SizedBox(height: 16),
          ],

          // Analysis Result
          pw.Text(
            '🔬 HASIL ANALISIS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
              analysisResult['analysis_result'] ?? '',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),

          pw.SizedBox(height: 24),

          // Diagnosis
          if (analysisResult['diagnosis'] != null &&
              analysisResult['diagnosis'] != '') ...[
            pw.Text(
              '🏥 DIAGNOSIS',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                border: pw.Border.all(color: PdfColors.blue200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                analysisResult['diagnosis'],
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Recommendations
          if (analysisResult['recommendations'] != null &&
              analysisResult['recommendations'] != '') ...[
            pw.Text(
              '💊 REKOMENDASI',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                analysisResult['recommendations'],
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Specialist Recommendation
          if (analysisResult['specialist_recommendation'] != null &&
              analysisResult['specialist_recommendation'] != '') ...[
            pw.Text(
              '👨‍⚕️ REKOMENDASI SPESIALIS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.orange800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                border: pw.Border.all(color: PdfColors.orange200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                analysisResult['specialist_recommendation'],
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          pw.SizedBox(height: 32),

          // Disclaimer
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '⚠️ DISCLAIMER',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Analisis gambar medis ini dibuat oleh AI dan bersifat informatif. Untuk diagnosis dan penanganan yang akurat, silakan konsultasikan dengan dokter atau tenaga medis profesional.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    // Save PDF and download in web
    try {
      final fileName = 'Analisis_Gambar_${analysisId.substring(0, 8)}.pdf';
      final bytes = await pdf.save();
      _downloadPdfWeb(bytes, fileName);
    } catch (e) {
      print('Error saving/downloading PDF: $e');
      rethrow;
    }
  }

  // Helper method to build section
  static pw.Widget _buildSection({
    required String title,
    required String content,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Text(content, style: const pw.TextStyle(fontSize: 11)),
        ),
      ],
    );
  }
}
