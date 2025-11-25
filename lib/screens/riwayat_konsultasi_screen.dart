import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import '../services/database_service.dart';
import '../services/pdf_export.dart';

class RiwayatKonsultasiScreen extends StatefulWidget {
  const RiwayatKonsultasiScreen({Key? key}) : super(key: key);

  @override
  State<RiwayatKonsultasiScreen> createState() =>
      _RiwayatKonsultasiScreenState();
}

class _RiwayatKonsultasiScreenState extends State<RiwayatKonsultasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Map<String, dynamic>> _anamnesisHistory = [];
  List<Map<String, dynamic>> _imageAnalysisHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final anamnesis = await _db.getAllConsultations();
      final imageAnalysis = await _db.getAllImageAnalyses();

      setState(() {
        _anamnesisHistory = anamnesis;
        _imageAnalysisHistory = imageAnalysis;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Konsultasi'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.medical_information), text: 'Anamnesis'),
            Tab(icon: Icon(Icons.image), text: 'Analisis Gambar'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildAnamnesisTab(), _buildImageAnalysisTab()],
            ),
    );
  }

  Widget _buildAnamnesisTab() {
    if (_anamnesisHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.medical_information_outlined,
        message: 'Belum ada riwayat konsultasi anamnesis',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _anamnesisHistory.length,
        itemBuilder: (context, index) {
          final consultation = _anamnesisHistory[index];
          return _buildAnamnesisCard(consultation);
        },
      ),
    );
  }

  Widget _buildImageAnalysisTab() {
    if (_imageAnalysisHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.image_not_supported_outlined,
        message: 'Belum ada riwayat analisis gambar medis',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _imageAnalysisHistory.length,
        itemBuilder: (context, index) {
          final analysis = _imageAnalysisHistory[index];
          return _buildImageAnalysisCard(analysis);
        },
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnamnesisCard(Map<String, dynamic> consultation) {
    final createdAt = DateTime.parse(consultation['created_at']);
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    Map<String, dynamic>? diagnosis;
    try {
      if (consultation['diagnosis'] != null) {
        diagnosis = json.decode(consultation['diagnosis']);
      }
    } catch (e) {
      print('Error parsing diagnosis: $e');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAnamnesisDetail(consultation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.medical_information,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diagnosis != null &&
                                  diagnosis['primaryDiagnosis'] != null
                              ? (diagnosis['primaryDiagnosis']['name'] ??
                                    diagnosis['primaryDiagnosis']['diagnosis'] ??
                                    'Konsultasi Anamnesis')
                              : 'Konsultasi Anamnesis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormatter.format(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'print') {
                        _printAnamnesisPdf(consultation);
                      } else if (value == 'delete') {
                        _deleteConsultation(consultation['id']);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'print',
                        child: Row(
                          children: [
                            Icon(Icons.print, size: 20),
                            SizedBox(width: 8),
                            Text('Cetak PDF'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.healing,
                'Keluhan',
                consultation['main_complaint'] ?? 'N/A',
              ),
              const SizedBox(height: 8),
              if (diagnosis != null && diagnosis['primaryDiagnosis'] != null)
                _buildInfoRow(
                  Icons.medical_services,
                  'Diagnosis',
                  diagnosis['primaryDiagnosis']['name'] ??
                      diagnosis['primaryDiagnosis']['diagnosis'] ??
                      'N/A',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageAnalysisCard(Map<String, dynamic> analysis) {
    final createdAt = DateTime.parse(analysis['created_at']);
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    Map<String, dynamic>? analysisResult;
    try {
      if (analysis['analysis_result'] != null) {
        analysisResult = json.decode(analysis['analysis_result']);
      }
    } catch (e) {
      print('Error parsing analysis result: $e');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showImageAnalysisDetail(analysis),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.image,
                      color: Colors.green[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analysisResult != null &&
                                  analysisResult['primaryDiagnosis'] != null
                              ? (analysisResult['primaryDiagnosis']['diagnosis']
                                        ?.toString() ??
                                    'Analisis Gambar Medis')
                              : 'Analisis Gambar Medis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormatter.format(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'print') {
                        _printImageAnalysisPdf(analysis);
                      } else if (value == 'delete') {
                        _deleteImageAnalysis(analysis['id']);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'print',
                        child: Row(
                          children: [
                            Icon(Icons.print, size: 20),
                            SizedBox(width: 8),
                            Text('Cetak PDF'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              if (analysisResult != null && analysisResult['imageType'] != null)
                _buildInfoRow(
                  Icons.category,
                  'Jenis',
                  analysisResult['imageType'].toString(),
                ),
              const SizedBox(height: 8),
              if (analysisResult != null &&
                  analysisResult['primaryDiagnosis'] != null)
                _buildInfoRow(
                  Icons.medical_services,
                  'Diagnosis',
                  analysisResult['primaryDiagnosis']['diagnosis']?.toString() ??
                      'N/A',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey[800], fontSize: 13),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAnamnesisDetail(Map<String, dynamic> consultation) {
    Map<String, dynamic>? diagnosis;
    List<Map<String, dynamic>> questionsAndAnswers = [];
    Map<String, dynamic>? recommendations;

    try {
      if (consultation['diagnosis'] != null) {
        diagnosis = json.decode(consultation['diagnosis']);
        if (diagnosis!['recommendations'] != null) {
          recommendations = diagnosis['recommendations'];
        }
      }
      if (consultation['questions_and_answers'] != null) {
        final parsed = json.decode(consultation['questions_and_answers']);
        questionsAndAnswers = List<Map<String, dynamic>>.from(parsed);
      }
    } catch (e) {
      print('Error parsing consultation data: $e');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medical_information,
                      color: Colors.blue[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Detail Konsultasi Anamnesis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Keluhan Utama
              _buildDetailSection(
                'Keluhan Utama',
                consultation['main_complaint'] ?? 'N/A',
                Icons.healing,
                Colors.red,
              ),

              // Mulai Gejala
              if (consultation['symptom_start_date'] != null) ...[
                const SizedBox(height: 16),
                _buildDetailSection(
                  'Mulai Gejala',
                  DateFormat(
                    'dd MMMM yyyy',
                  ).format(DateTime.parse(consultation['symptom_start_date'])),
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ],

              // Q&A
              if (questionsAndAnswers.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Hasil Anamnesis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 12),
                ...questionsAndAnswers.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final qa = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q$index: ${qa['question']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A: ${qa['answer']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              // Diagnosis
              if (diagnosis != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Diagnosis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
                const SizedBox(height: 12),
                if (diagnosis['primaryDiagnosis'] != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diagnosis['primaryDiagnosis']['name'] ??
                              diagnosis['primaryDiagnosis']['diagnosis'] ??
                              'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (diagnosis['primaryDiagnosis']['description'] !=
                            null) ...[
                          const SizedBox(height: 8),
                          Text(
                            diagnosis['primaryDiagnosis']['description'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],

              // Recommendations
              if (recommendations != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Rekomendasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                const SizedBox(height: 12),

                // Immediate Actions
                if (recommendations['immediateActions'] != null) ...[
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
                            Icon(
                              Icons.flash_on,
                              size: 18,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tindakan Segera',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...((recommendations['immediateActions'] as List).map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $action',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Follow Up
                if (recommendations['followUp'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tindak Lanjut',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...((recommendations['followUp'] as List).map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $action',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Specialist Referral
                if (recommendations['specialistReferral'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.medical_services,
                              size: 18,
                              color: Colors.purple[700],
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Rujukan Spesialis',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jenis: ${recommendations['specialistReferral']['type'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Urgensi: ${recommendations['specialistReferral']['urgency'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // Print Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _printAnamnesisPdf(consultation);
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Cetak Laporan PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageAnalysisDetail(Map<String, dynamic> analysis) {
    Map<String, dynamic> analysisResult = {};

    try {
      if (analysis['analysis_result'] != null) {
        analysisResult = json.decode(analysis['analysis_result']);
      }
    } catch (e) {
      print('Error parsing analysis result: $e');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.image,
                      color: Colors.green[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Detail Analisis Gambar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Display Image if available
              if (analysis['image_path'] != null) ...[
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(analysis['image_path']),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Gambar tidak dapat dimuat',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Description
              if (analysis['image_description'] != null) ...[
                _buildDetailSection(
                  'Deskripsi',
                  analysis['image_description'],
                  Icons.description,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
              ],

              // Image Type
              if (analysisResult['imageType'] != null) ...[
                _buildDetailSection(
                  'Jenis Gambar',
                  analysisResult['imageType'].toString(),
                  Icons.category,
                  Colors.purple,
                ),
                const SizedBox(height: 16),
              ],

              // Diagnosis
              if (analysisResult['primaryDiagnosis'] != null) ...[
                Text(
                  'Diagnosis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysisResult['primaryDiagnosis']['diagnosis']
                                ?.toString() ??
                            'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (analysisResult['primaryDiagnosis']['reasoning'] !=
                          null) ...[
                        const SizedBox(height: 8),
                        Text(
                          analysisResult['primaryDiagnosis']['reasoning']
                              .toString(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Findings
              if (analysisResult['findings'] != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Temuan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 12),

                // Normal Findings
                if (analysisResult['findings'] != null &&
                    analysisResult['findings']['normal'] != null) ...[
                  Builder(
                    builder: (context) {
                      final findings = analysisResult['findings'] as Map?;
                      final normalFindings = findings?['normal'];
                      if (normalFindings is List && normalFindings.isNotEmpty) {
                        return Column(
                          children: [
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
                                        size: 18,
                                        color: Colors.green[700],
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Temuan Normal',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...normalFindings.map(
                                    (finding) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '• $finding',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],

                // Abnormal Findings
                if (analysisResult['findings']['abnormal'] != null) ...[
                  Builder(
                    builder: (context) {
                      final abnormalFindings =
                          analysisResult['findings']?['abnormal'];
                      if (abnormalFindings is List &&
                          abnormalFindings.isNotEmpty) {
                        return Container(
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
                                  Icon(
                                    Icons.warning,
                                    size: 18,
                                    color: Colors.orange[700],
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Temuan Abnormal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...abnormalFindings.map(
                                (finding) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• $finding',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ],

              // Red Flags
              if (analysisResult['redFlags'] != null) ...[
                Builder(
                  builder: (context) {
                    final redFlags = analysisResult['redFlags'];
                    if (redFlags is List && redFlags.isNotEmpty) {
                      return Column(
                        children: [
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red[300]!,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.error,
                                      size: 20,
                                      color: Colors.red[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tanda Bahaya',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.red[900],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...redFlags.map(
                                  (flag) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '⚠️ $flag',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.red[900],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],

              // Recommendations
              if (analysisResult['recommendations'] != null) ...[
                Builder(
                  builder: (context) {
                    final recommendations = analysisResult['recommendations'];
                    if (recommendations is List && recommendations.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            'Rekomendasi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                ...recommendations.map(
                                  (rec) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '• ',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        Expanded(
                                          child: Text(
                                            rec.toString(),
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
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
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Print Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _printImageAnalysisPdf(analysis);
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Cetak Laporan PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
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
          Text(
            content,
            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  Future<void> _printAnamnesisPdf(Map<String, dynamic> consultation) async {
    try {
      Map<String, dynamic>? diagnosis;
      List<Map<String, dynamic>> questionsAndAnswers = [];

      if (consultation['diagnosis'] != null) {
        diagnosis = json.decode(consultation['diagnosis']);
      }
      if (consultation['questions_and_answers'] != null) {
        final parsed = json.decode(consultation['questions_and_answers']);
        questionsAndAnswers = List<Map<String, dynamic>>.from(parsed);
      }

      await PdfService.generateAnamnesisPdf(
        consultationId: consultation['id'],
        mainComplaint: consultation['main_complaint'] ?? '',
        symptomStartDate: consultation['symptom_start_date'] ?? '',
        questionsAndAnswers: questionsAndAnswers,
        diagnosis: diagnosis ?? {},
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  Future<void> _printImageAnalysisPdf(Map<String, dynamic> analysis) async {
    try {
      Map<String, dynamic>? analysisResult;

      if (analysis['analysis_result'] != null) {
        analysisResult = json.decode(analysis['analysis_result']);
      }

      await PdfService.generateImageAnalysisPdf(
        analysisId: analysis['id'],
        imageDescription: analysis['image_description'],
        analysisResult: analysisResult ?? {},
        imagePath: analysis['image_path'], // Sertakan path gambar
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  Future<void> _deleteConsultation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Konsultasi?'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus riwayat konsultasi ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.deleteConsultation(id);
        _loadHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konsultasi berhasil dihapus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteImageAnalysis(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Analisis?'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus riwayat analisis ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.deleteImageAnalysis(id);
        _loadHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analisis berhasil dihapus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
