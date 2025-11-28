import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../utils/app_theme.dart';
import '../services/gemini_service.dart';
import '../services/database_service.dart';
import '../services/pdf_export.dart';
import 'pdf_preview_export.dart';

class AnalisisGambarMedisScreen extends StatefulWidget {
  const AnalisisGambarMedisScreen({super.key});

  @override
  State<AnalisisGambarMedisScreen> createState() =>
      _AnalisisGambarMedisScreenState();
}

class _AnalisisGambarMedisScreenState extends State<AnalisisGambarMedisScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  final DatabaseHelper _db = DatabaseHelper.instance;

  // For web, we use XFile and Uint8List instead of File
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  String _analysisStep = '';
  Map<String, dynamic>? _analysisResult;
  String? _currentAnalysisId;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        // Read bytes for web compatibility
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageFile = image;
          _selectedImageBytes = bytes;
          _analysisResult = null;
        });
        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      _showErrorSnackbar('Error memilih gambar: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pilih Sumber Gambar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeImage() async {
    if (_selectedImageBytes == null) {
      _showErrorSnackbar('Pilih gambar terlebih dahulu');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisProgress = 0.0;
      _analysisStep = 'Memproses gambar...';
    });

    try {
      await _updateProgress(0.2, 'Membaca gambar...');
      // Use already loaded bytes
      final Uint8List imageBytes = _selectedImageBytes!;

      await _updateProgress(0.4, 'Mengirim ke AI...');

      // Convert bytes to base64
      final base64Image = base64Encode(imageBytes);

      await _updateProgress(0.6, 'Menganalisis gambar medis...');
      final result = await _geminiService.analyzeImage(
        base64Image: base64Image,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      await _updateProgress(0.8, 'Menyimpan hasil...');

      // Save to database (include base64 image for web display in history)
      _currentAnalysisId = const Uuid().v4();
      await _db.insertImageAnalysis({
        'id': _currentAnalysisId,
        'image_path': _selectedImageFile?.name ?? 'web_upload',
        'image_base64': base64Image, // Store base64 for web history display
        'image_description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'analysis_result': json.encode(result),
        'diagnosis': result['primaryDiagnosis']?['diagnosis'],
        'recommendations': json.encode(result['recommendations']),
        'specialist_recommendation':
            result['recommendations']?['specialistReferral'],
        'created_at': DateTime.now().toIso8601String(),
      });

      await _updateProgress(1.0, 'Selesai!');

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      _animationController.forward(from: 0.0);

      _showSuccessSnackbar('Analisis selesai!');
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      _showErrorSnackbar('Error: ${e.toString()}');
    }
  }

  Future<void> _updateProgress(double progress, String step) async {
    setState(() {
      _analysisProgress = progress;
      _analysisStep = step;
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _launchMaps(String specialistType) async {
    try {
      final primaryDiagnosis =
          _analysisResult?['primaryDiagnosis']?['diagnosis'] ?? '';
      final imageType = _analysisResult?['imageType'] ?? '';

      String query;
      if (primaryDiagnosis.isNotEmpty) {
        query = Uri.encodeComponent(
          'Dokter spesialis $specialistType untuk kasus $primaryDiagnosis terdekat dari saya',
        );
      } else if (imageType.isNotEmpty) {
        query = Uri.encodeComponent(
          'Dokter spesialis $specialistType untuk analisis $imageType terdekat dari saya',
        );
      } else {
        query = Uri.encodeComponent(
          'Dokter spesialis $specialistType terdekat dari saya',
        );
      }

      final webUrl = Uri.parse('https://www.google.com/maps/search/$query');

      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka Maps: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analisis Gambar Medis',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryBlue,
                    AppTheme.primaryBlue.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.image_search_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Analisis Gambar Medis AI',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload foto kondisi medis untuk analisis otomatis',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Important Notes Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber[800],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Hasil analisis hanya sebagai referensi awal. Konsultasikan dengan dokter untuk diagnosis akurat.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber[900],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Image Selection Section
                  if (_selectedImageBytes == null) ...[
                    _buildEmptyImageState(),
                  ] else ...[
                    _buildSelectedImageState(),
                  ],

                  if (_selectedImageBytes != null) ...[
                    const SizedBox(height: 24),

                    // Description Input
                    const Text(
                      'Deskripsi Kondisi (Opsional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Contoh: Luka di kaki kiri, sudah 3 hari, terasa nyeri dan sedikit bengkak...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Analyze Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isAnalyzing ? null : _analyzeImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: _isAnalyzing ? 0 : 2,
                        ),
                        child: _isAnalyzing
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _analysisStep,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.psychology, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Analisis dengan AI',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // Progress Indicator
                    if (_isAnalyzing) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _analysisProgress,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ],

                  // Analysis Result
                  if (_analysisResult != null) ...[
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildAnalysisResult(_analysisResult!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyImageState() {
    return InkWell(
      onTap: _showImageSourceDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate,
                size: 56,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Upload Gambar Medis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap untuk memilih dari kamera atau galeri',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                const SizedBox(width: 6),
                Text(
                  'JPG, PNG, WebP',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                const SizedBox(width: 6),
                Text(
                  'Max 10MB',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImageState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Use Image.memory for web compatibility
                Image.memory(
                  _selectedImageBytes!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedImageFile = null;
                          _selectedImageBytes = null;
                          _analysisResult = null;
                          _descriptionController.clear();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showImageSourceDialog,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Ganti Gambar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult(Map<String, dynamic> result) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hasil Analisis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Analisis selesai dengan AI',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResultSection(
                  icon: Icons.category,
                  title: 'Jenis Gambar',
                  content:
                      result['imageType']?.toString() ?? 'Tidak terdeteksi',
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),

                if (result['anatomicalArea'] != null) ...[
                  _buildResultSection(
                    icon: Icons.accessibility_new,
                    title: 'Area Anatomi',
                    content: result['anatomicalArea'].toString(),
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 20),
                ],

                _buildResultSection(
                  icon: Icons.medical_services,
                  title: 'Diagnosis Utama',
                  content:
                      result['primaryDiagnosis']?['diagnosis']?.toString() ??
                      'Tidak dapat ditentukan',
                  color: Colors.red,
                  badge: _formatConfidenceBadge(
                    result['primaryDiagnosis']?['confidence'],
                  ),
                  badgeColor: _getConfidenceColor(
                    result['primaryDiagnosis']?['confidence']?.toString(),
                  ),
                ),

                if (result['primaryDiagnosis']?['reasoning'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Text(
                      result['primaryDiagnosis']['reasoning'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                if (result['findings'] != null) ...[
                  _buildFindings(result['findings']),
                  const SizedBox(height: 20),
                ],

                if (result['differentialDiagnoses'] != null &&
                    result['differentialDiagnoses'] is List &&
                    (result['differentialDiagnoses'] as List).isNotEmpty) ...[
                  _buildDifferentialDiagnoses(result['differentialDiagnoses']),
                  const SizedBox(height: 20),
                ],

                if (result['recommendations'] != null) ...[
                  _buildRecommendations(result['recommendations']),
                  const SizedBox(height: 20),
                ],

                if (result['redFlags'] != null &&
                    result['redFlags'] is List &&
                    (result['redFlags'] as List).isNotEmpty) ...[
                  _buildRedFlags(result['redFlags']),
                  const SizedBox(height: 20),
                ],

                if (result['patientEducation'] != null &&
                    result['patientEducation'] is List &&
                    (result['patientEducation'] as List).isNotEmpty) ...[
                  _buildPatientEducation(result['patientEducation']),
                  const SizedBox(height: 20),
                ],

                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange[800],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          result['disclaimer']?.toString() ??
                              'Hasil ini bukan diagnosis final. Segera konsultasikan dengan dokter untuk pemeriksaan lebih lanjut.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[900],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Download PDF Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadPdf(result),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Download Laporan PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(Map<String, dynamic> result) async {
    try {
      setState(() {
        _isAnalyzing = true;
        _analysisStep = 'Membuat laporan PDF...';
      });

      // Generate PDF bytes for preview
      final pdfBytes = await PdfService.generateImageAnalysisPdfBytes(
        analysisId: _currentAnalysisId ?? 'unknown',
        imageDescription: _descriptionController.text.isEmpty
            ? 'Tidak ada deskripsi'
            : _descriptionController.text,
        analysisResult: result,
        imageBytes: _selectedImageBytes,
      );

      setState(() {
        _isAnalyzing = false;
      });

      // Navigate to preview screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              title: 'Laporan Analisis Gambar Medis',
              pdfBytes: pdfBytes,
              fileName:
                  'Analisis_Gambar_${(_currentAnalysisId ?? 'unknown').substring(0, 8)}.pdf',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error membuat PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Widget _buildResultSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    String? badge,
    Color? badgeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (badge != null) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor ?? color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDifferentialDiagnoses(List diagnoses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.compare_arrows,
                size: 20,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Kemungkinan Diagnosis Lain',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...diagnoses.asMap().entries.map((entry) {
          final index = entry.key;
          final diagnosis = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          diagnosis['diagnosis'] ?? diagnosis['name'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getProbabilityColor(
                            diagnosis['probability']?.toString(),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatProbabilityBadge(diagnosis['probability']),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (diagnosis['reasoning'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      diagnosis['reasoning'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecommendations(Map recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.recommend, size: 20, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Text(
              'Rekomendasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (recommendations['immediateActions'] != null)
          _buildRecommendationItem(
            'Tindakan Segera',
            recommendations['immediateActions'],
            Icons.emergency,
            Colors.red,
          ),

        if (recommendations['furtherTests'] != null)
          _buildRecommendationItem(
            'Pemeriksaan Lanjutan',
            recommendations['furtherTests'],
            Icons.science,
            Colors.blue,
          ),

        if (recommendations['specialistReferral'] != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_hospital,
                      color: Colors.purple[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Rujukan Spesialis',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  recommendations['specialistReferral'],
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _launchMaps(recommendations['specialistReferral']),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Cari Dokter Terdekat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildRecommendationItem(
    String title,
    dynamic items,
    IconData icon,
    Color color,
  ) {
    if (items == null) return const SizedBox.shrink();

    final itemList = items is List ? items : [items];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...itemList.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.toString(),
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFindings(Map findings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.search, size: 20, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            const Text(
              'Temuan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (findings['normal'] != null && findings['normal'] is List) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Temuan Normal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...(findings['normal'] as List).map(
                  (finding) => Padding(
                    padding: const EdgeInsets.only(left: 26, top: 4),
                    child: Text(
                      '• $finding',
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (findings['abnormal'] != null &&
            findings['abnormal'] is List &&
            (findings['abnormal'] as List).isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Temuan Abnormal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...(findings['abnormal'] as List).map(
                  (finding) => Padding(
                    padding: const EdgeInsets.only(left: 26, top: 4),
                    child: Text(
                      '• $finding',
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
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

  Widget _buildPatientEducation(List education) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, size: 20, color: Colors.indigo),
            ),
            const SizedBox(width: 12),
            const Text(
              'Edukasi Pasien',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.indigo[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: education.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.indigo[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRedFlags(List flags) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red[700], size: 24),
              const SizedBox(width: 12),
              Text(
                'Tanda Bahaya',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...flags.map(
            (flag) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error, color: Colors.red[700], size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      flag.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[900],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatConfidenceBadge(dynamic confidence) {
    if (confidence == null) return 'N/A';
    final str = confidence.toString();
    final numValue = int.tryParse(str);
    if (numValue != null) {
      return '$numValue%';
    }
    return str.toUpperCase();
  }

  String _formatProbabilityBadge(dynamic probability) {
    if (probability == null) return 'N/A';
    final str = probability.toString();
    final numValue = int.tryParse(str);
    if (numValue != null) {
      return '$numValue%';
    }
    return str.toUpperCase();
  }

  Color _getConfidenceColor(String? confidence) {
    if (confidence == null) return Colors.grey;
    final lower = confidence.toLowerCase();
    final numValue = int.tryParse(confidence);
    if (numValue != null) {
      if (numValue >= 80) return Colors.green;
      if (numValue >= 50) return Colors.orange;
      return Colors.red;
    }
    switch (lower) {
      case 'high':
      case 'tinggi':
        return Colors.green;
      case 'medium':
      case 'sedang':
        return Colors.orange;
      case 'low':
      case 'rendah':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getProbabilityColor(String? probability) {
    if (probability == null) return Colors.grey;
    final lower = probability.toLowerCase();
    final numValue = int.tryParse(probability);
    if (numValue != null) {
      if (numValue >= 70) return Colors.red;
      if (numValue >= 40) return Colors.orange;
      return Colors.blue;
    }
    switch (lower) {
      case 'high':
      case 'tinggi':
        return Colors.red;
      case 'medium':
      case 'sedang':
        return Colors.orange;
      case 'low':
      case 'rendah':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
