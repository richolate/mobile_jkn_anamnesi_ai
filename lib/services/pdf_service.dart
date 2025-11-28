import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class PdfService {
  // Data dummy pasien
  static const Map<String, String> _patientData = {
    'nama': 'Azel',
    'umur': '21 Tahun',
    'pekerjaan': 'Mahasiswa',
    'noBpjs': '000001234',
  };

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

  // Build patient header section
  static pw.Widget _buildPatientHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DATA PASIEN',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Nama: ${_patientData['nama']}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Umur: ${_patientData['umur']}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Pekerjaan: ${_patientData['pekerjaan']}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'No BPJS: ${_patientData['noBpjs']}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Generate PDF bytes untuk Konsultasi Anamnesis (untuk preview)
  static Future<Uint8List> generateAnamnesisPdfBytes({
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

          pw.SizedBox(height: 16),

          // Data Pasien
          _buildPatientHeader(),

          pw.SizedBox(height: 8),

          // Keluhan Utama
          _buildSection(title: 'KELUHAN UTAMA', content: mainComplaint),

          pw.SizedBox(height: 16),

          // Mulai Gejala
          _buildSection(
            title: 'MULAI GEJALA',
            content: symptomStartDate.isNotEmpty
                ? DateFormat(
                    'dd MMMM yyyy',
                  ).format(DateTime.parse(symptomStartDate))
                : 'Tidak dicatat',
          ),

          pw.SizedBox(height: 24),

          // Hasil Anamnesis
          pw.Text(
            'HASIL ANAMNESIS',
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
            'DIAGNOSIS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red800,
            ),
          ),
          pw.SizedBox(height: 12),

          if (diagnosis['primaryDiagnosis'] != null) ...[
            _buildDiagnosisSection(
              'Diagnosis Utama',
              diagnosis['primaryDiagnosis'],
            ),
            pw.SizedBox(height: 12),
          ],

          if (diagnosis['differentialDiagnoses'] != null) ...[
            pw.Text(
              'Diagnosis Diferensial:',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            ...(diagnosis['differentialDiagnoses'] as List).asMap().entries.map(
              (entry) {
                final index = entry.key + 1;
                final diff = entry.value;
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 16, bottom: 6),
                  child: pw.Text(
                    '$index. ${diff['name'] ?? diff['diagnosis'] ?? 'N/A'}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
            pw.SizedBox(height: 12),
          ],

          if (diagnosis['recommendations'] != null) ...[
            pw.Text(
              'REKOMENDASI',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildRecommendations(diagnosis['recommendations']),
          ],

          pw.SizedBox(height: 24),

          // Disclaimer
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              border: pw.Border.all(color: PdfColors.orange300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DISCLAIMER',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Hasil analisis ini bukan diagnosis final. Segera konsultasikan dengan dokter untuk pemeriksaan dan penanganan lebih lanjut.',
                  style: const pw.TextStyle(
                    fontSize: 10,
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

    // Return PDF bytes for preview
    return pdf.save();
  }

  // Generate PDF untuk Konsultasi Anamnesis (dan langsung share)
  static Future<void> generateAnamnesisPdf({
    required String consultationId,
    required String mainComplaint,
    required String symptomStartDate,
    required List<Map<String, dynamic>> questionsAndAnswers,
    required Map<String, dynamic> diagnosis,
  }) async {
    final pdfBytes = await generateAnamnesisPdfBytes(
      consultationId: consultationId,
      mainComplaint: mainComplaint,
      symptomStartDate: symptomStartDate,
      questionsAndAnswers: questionsAndAnswers,
      diagnosis: diagnosis,
    );

    final output = await getTemporaryDirectory();
    final fileName =
        'Konsultasi_Anamnesis_${consultationId.substring(0, 8)}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Laporan Konsultasi Anamnesis',
      text: 'Laporan konsultasi anamnesis dari Mobile JKN',
    );
  }

  // Generate PDF untuk Analisis Gambar Medis
  static Future<void> generateImageAnalysisPdf({
    required String analysisId,
    required String? imageDescription,
    required Map<String, dynamic> analysisResult,
    String? imagePath,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // Load image if path provided
    pw.MemoryImage? pdfImage;
    if (imagePath != null) {
      try {
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          pdfImage = pw.MemoryImage(imageBytes);
        }
      } catch (e) {
        print('Error loading image for PDF: $e');
      }
    }

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
                    color: PdfColors.green900,
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

          pw.SizedBox(height: 16),

          // Data Pasien
          _buildPatientHeader(),

          pw.SizedBox(height: 8),

          // Gambar yang dianalisis
          if (pdfImage != null) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'GAMBAR MEDIS YANG DIANALISIS',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Center(
                    child: pw.Container(
                      constraints: const pw.BoxConstraints(
                        maxWidth: 400,
                        maxHeight: 300,
                      ),
                      child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Gambar di atas adalah foto yang Anda upload untuk dianalisis',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Deskripsi Gambar
          if (imageDescription != null && imageDescription.isNotEmpty) ...[
            _buildSection(title: 'DESKRIPSI GAMBAR', content: imageDescription),
            pw.SizedBox(height: 16),
          ],

          // Jenis Gambar
          if (analysisResult['imageType'] != null) ...[
            _buildSection(
              title: 'JENIS GAMBAR',
              content: analysisResult['imageType'].toString(),
            ),
            pw.SizedBox(height: 16),
          ],

          // Area Anatomi
          if (analysisResult['anatomicalArea'] != null) ...[
            _buildSection(
              title: 'AREA ANATOMI',
              content: analysisResult['anatomicalArea'].toString(),
            ),
            pw.SizedBox(height: 16),
          ],

          pw.SizedBox(height: 12),

          // Diagnosis
          pw.Text(
            'DIAGNOSIS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red800,
            ),
          ),
          pw.SizedBox(height: 12),

          if (analysisResult['primaryDiagnosis'] != null) ...[
            _buildDiagnosisSection(
              'Diagnosis Utama',
              analysisResult['primaryDiagnosis'],
            ),
            pw.SizedBox(height: 12),
          ],

          // Temuan
          if (analysisResult['findings'] != null) ...[
            pw.Text(
              'TEMUAN',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildFindings(analysisResult['findings']),
            pw.SizedBox(height: 16),
          ],

          // Differential Diagnoses
          if (analysisResult['differentialDiagnoses'] != null &&
              (analysisResult['differentialDiagnoses'] as List).isNotEmpty) ...[
            pw.Text(
              'Diagnosis Diferensial:',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            ...(analysisResult['differentialDiagnoses'] as List)
                .asMap()
                .entries
                .map((entry) {
                  final index = entry.key + 1;
                  final diff = entry.value;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 16, bottom: 6),
                    child: pw.Text(
                      '$index. ${diff['name'] ?? diff['diagnosis'] ?? 'N/A'}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  );
                }),
            pw.SizedBox(height: 12),
          ],

          // Rekomendasi
          if (analysisResult['recommendations'] != null) ...[
            pw.Text(
              'REKOMENDASI',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildRecommendations(analysisResult['recommendations']),
            pw.SizedBox(height: 16),
          ],

          // Red Flags
          if (analysisResult['redFlags'] != null &&
              (analysisResult['redFlags'] as List).isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                border: pw.Border.all(color: PdfColors.red300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TANDA BAHAYA',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red900,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...(analysisResult['redFlags'] as List).map(
                    (flag) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
                      child: pw.Text(
                        '• ${flag.toString()}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Disclaimer
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              border: pw.Border.all(color: PdfColors.orange300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DISCLAIMER',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  analysisResult['disclaimer']?.toString() ??
                      'Hasil analisis ini bukan diagnosis final. Segera konsultasikan dengan dokter untuk pemeriksaan lebih lanjut.',
                  style: const pw.TextStyle(
                    fontSize: 10,
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

    // Save PDF to file and share
    try {
      final output = await getTemporaryDirectory();
      final fileName = 'Analisis_Gambar_${analysisId.substring(0, 8)}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Share the PDF file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Laporan Analisis Gambar Medis',
        text: 'Laporan analisis gambar medis dari Mobile JKN',
      );
    } catch (e) {
      print('Error saving/sharing PDF: $e');
      rethrow;
    }
  }

  // Generate PDF bytes untuk Analisis Gambar Medis (untuk preview)
  static Future<Uint8List> generateImageAnalysisPdfBytes({
    required String analysisId,
    required String? imageDescription,
    required Map<String, dynamic> analysisResult,
    Uint8List? imageBytes,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // Load image from bytes
    pw.MemoryImage? pdfImage;
    if (imageBytes != null) {
      try {
        pdfImage = pw.MemoryImage(imageBytes);
      } catch (e) {
        print('Error loading image for PDF: $e');
      }
    }

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
                    color: PdfColors.green900,
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

          pw.SizedBox(height: 16),

          // Data Pasien
          _buildPatientHeader(),

          pw.SizedBox(height: 8),

          // Gambar yang dianalisis
          if (pdfImage != null) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'GAMBAR MEDIS YANG DIANALISIS',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Center(
                    child: pw.Container(
                      constraints: const pw.BoxConstraints(
                        maxWidth: 400,
                        maxHeight: 300,
                      ),
                      child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Deskripsi Gambar
          if (imageDescription != null && imageDescription.isNotEmpty) ...[
            _buildSection(title: 'DESKRIPSI GAMBAR', content: imageDescription),
            pw.SizedBox(height: 16),
          ],

          // Jenis Gambar
          if (analysisResult['imageType'] != null) ...[
            _buildSection(
              title: 'JENIS GAMBAR',
              content: analysisResult['imageType'].toString(),
            ),
            pw.SizedBox(height: 16),
          ],

          // Area Anatomi
          if (analysisResult['anatomicalArea'] != null) ...[
            _buildSection(
              title: 'AREA ANATOMI',
              content: analysisResult['anatomicalArea'].toString(),
            ),
            pw.SizedBox(height: 16),
          ],

          pw.SizedBox(height: 12),

          // Diagnosis
          pw.Text(
            'DIAGNOSIS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red800,
            ),
          ),
          pw.SizedBox(height: 12),

          if (analysisResult['primaryDiagnosis'] != null) ...[
            _buildDiagnosisSection(
              'Diagnosis Utama',
              analysisResult['primaryDiagnosis'],
            ),
            pw.SizedBox(height: 12),
          ],

          // Temuan
          if (analysisResult['findings'] != null) ...[
            pw.Text(
              'TEMUAN',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildFindings(analysisResult['findings']),
            pw.SizedBox(height: 16),
          ],

          // Differential Diagnoses
          if (analysisResult['differentialDiagnoses'] != null &&
              (analysisResult['differentialDiagnoses'] as List).isNotEmpty) ...[
            pw.Text(
              'KEMUNGKINAN DIAGNOSIS LAIN',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.purple800,
              ),
            ),
            pw.SizedBox(height: 8),
            ...(analysisResult['differentialDiagnoses'] as List)
                .asMap()
                .entries
                .map((entry) {
                  final index = entry.key + 1;
                  final diff = entry.value;
                  final diagnosis = diff['diagnosis'] ?? diff['name'] ?? 'N/A';
                  final probability =
                      diff['probability'] ?? diff['confidence'] ?? '';
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 20,
                          height: 20,
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.purple,
                            shape: pw.BoxShape.circle,
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              '$index',
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                diagnosis.toString(),
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              if (probability.toString().isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'Probabilitas: $probability%',
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ],
                              if (diff['reasoning'] != null) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  diff['reasoning'].toString(),
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            pw.SizedBox(height: 12),
          ],

          // Rekomendasi
          if (analysisResult['recommendations'] != null) ...[
            pw.Text(
              'REKOMENDASI',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildRecommendations(analysisResult['recommendations']),
            pw.SizedBox(height: 16),
          ],

          // Red Flags
          if (analysisResult['redFlags'] != null &&
              (analysisResult['redFlags'] as List).isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                border: pw.Border.all(color: PdfColors.red300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TANDA BAHAYA',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red900,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...(analysisResult['redFlags'] as List).map(
                    (flag) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '! ',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red700,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              flag.toString(),
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Patient Education
          if (analysisResult['patientEducation'] != null &&
              (analysisResult['patientEducation'] as List).isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo50,
                border: pw.Border.all(color: PdfColors.indigo200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'EDUKASI PASIEN',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...(analysisResult['patientEducation'] as List).map(
                    (edu) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '- ',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              edu.toString(),
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Disclaimer
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              border: pw.Border.all(color: PdfColors.orange300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DISCLAIMER',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  analysisResult['disclaimer']?.toString() ??
                      'Hasil analisis ini bukan diagnosis final. Segera konsultasikan dengan dokter untuk pemeriksaan lebih lanjut.',
                  style: const pw.TextStyle(
                    fontSize: 10,
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

    // Return PDF bytes for preview
    return pdf.save();
  }

  // Helper widgets
  static pw.Widget _buildSection({
    required String title,
    required String content,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(content, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildDiagnosisSection(
    String title,
    Map<String, dynamic> diagnosis,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        border: pw.Border.all(color: PdfColors.red200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red900,
                ),
              ),
              if (diagnosis['confidence'] != null)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Text(
                    'Confidence: ${diagnosis['confidence']}%',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            diagnosis['diagnosis']?.toString() ??
                diagnosis['name']?.toString() ??
                'N/A',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          if (diagnosis['reasoning'] != null) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              diagnosis['reasoning'].toString(),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildRecommendations(dynamic recommendations) {
    // Handle both Map and List formats
    if (recommendations is Map<String, dynamic>) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (recommendations['immediateActions'] != null) ...[
            pw.Text(
              'Tindakan Segera:',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            ..._buildListItems(recommendations['immediateActions']),
            pw.SizedBox(height: 8),
          ],
          if (recommendations['immediate'] != null) ...[
            pw.Text(
              'Tindakan Segera:',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            ..._buildListItems(recommendations['immediate']),
            pw.SizedBox(height: 8),
          ],
          if (recommendations['furtherTests'] != null) ...[
            pw.Text(
              'Pemeriksaan Lanjutan:',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            ..._buildListItems(recommendations['furtherTests']),
            pw.SizedBox(height: 8),
          ],
          if (recommendations['followUp'] != null) ...[
            pw.Text(
              'Tindakan Lanjutan:',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            ..._buildListItems(recommendations['followUp']),
            pw.SizedBox(height: 8),
          ],
          if (recommendations['specialistReferral'] != null) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.purple50,
                border: pw.Border.all(color: PdfColors.purple200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'Rujukan Spesialis: ',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      recommendations['specialistReferral'].toString(),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    } else if (recommendations is List) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: recommendations
            .map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('- ', style: const pw.TextStyle(fontSize: 10)),
                    pw.Expanded(
                      child: pw.Text(
                        item.toString(),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );
    }
    return pw.SizedBox.shrink();
  }

  // Helper to build list items
  static List<pw.Widget> _buildListItems(dynamic items) {
    if (items == null) return [];
    final itemList = items is List ? items : [items];
    return itemList
        .map(
          (item) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('- ', style: const pw.TextStyle(fontSize: 10)),
                pw.Expanded(
                  child: pw.Text(
                    item.toString(),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  static pw.Widget _buildFindings(Map<String, dynamic> findings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (findings['normal'] != null &&
            (findings['normal'] as List).isNotEmpty) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              border: pw.Border.all(color: PdfColors.green200),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Temuan Normal:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
                pw.SizedBox(height: 4),
                ...(findings['normal'] as List).map(
                  (item) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('- ', style: const pw.TextStyle(fontSize: 9)),
                        pw.Expanded(
                          child: pw.Text(
                            item.toString(),
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
        ],
        if (findings['abnormal'] != null &&
            (findings['abnormal'] as List).isNotEmpty) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              border: pw.Border.all(color: PdfColors.orange200),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Temuan Abnormal:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange900,
                  ),
                ),
                pw.SizedBox(height: 4),
                ...(findings['abnormal'] as List).map(
                  (item) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('- ', style: const pw.TextStyle(fontSize: 9)),
                        pw.Expanded(
                          child: pw.Text(
                            item.toString(),
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
