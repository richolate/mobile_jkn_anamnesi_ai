import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/pdf_export.dart';

class KonsultasiAnamnesisScreen extends StatefulWidget {
  const KonsultasiAnamnesisScreen({Key? key}) : super(key: key);

  @override
  State<KonsultasiAnamnesisScreen> createState() =>
      _KonsultasiAnamnesisScreenState();
}

class _KonsultasiAnamnesisScreenState extends State<KonsultasiAnamnesisScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final GeminiService _geminiService = GeminiService();

  // View State
  _ViewState _currentView = _ViewState.initial;

  // Initial View Data
  final TextEditingController _complaintController = TextEditingController();
  DateTime? _symptomStartDate;

  // Question View Data
  int _currentQuestionIndex = 0;
  Map<String, dynamic>? _currentQuestion;
  List<Map<String, dynamic>> _allQuestions = [];
  List<Map<String, dynamic>> _potentialDiagnoses = [];
  String? _selectedAnswer;
  final TextEditingController _detailedAnswerController =
      TextEditingController();
  String _consultationId = '';
  int _totalQuestions = 5;
  List<Map<String, dynamic>> _answersGiven = [];

  // Final Diagnosis Data
  Map<String, dynamic>? _finalDiagnosis;

  // Loading State
  bool _isLoading = false;
  String _loadingMessage = '';

  @override
  void dispose() {
    _complaintController.dispose();
    _detailedAnswerController.dispose();
    super.dispose();
  }

  // ==========================================
  // INITIAL VIEW - Complaint Input
  // ==========================================

  Future<void> _submitComplaint() async {
    if (_complaintController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon masukkan keluhan Anda')),
      );
      return;
    }

    if (_symptomStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih kapan gejala mulai dirasakan'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Menganalisis keluhan Anda...';
    });

    try {
      // Generate initial questions from bank
      final result = await _geminiService.generateInitialQuestionsFromBank(
        complaint: _complaintController.text,
      );

      if (result['success'] == true) {
        setState(() {
          _consultationId = const Uuid().v4();
          _currentQuestion = result['firstQuestion'];
          _allQuestions = List<Map<String, dynamic>>.from(
            result['allQuestions'] ?? [],
          );
          _potentialDiagnoses = List<Map<String, dynamic>>.from(
            result['potentialDiagnoses'] ?? [],
          );
          _totalQuestions = result['totalQuestions'] ?? 5;
          _currentQuestionIndex = 0;
          _currentView = _ViewState.questions;
        });

        // Save consultation to database
        await _dbHelper.insertConsultation({
          'id': _consultationId,
          'original_complaint': _complaintController.text,
          'symptom_start_date': _symptomStartDate!.toIso8601String(),
          'questions_asked': 0,
          'total_questions': _totalQuestions,
          'status': 'in_progress',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        throw Exception('Gagal generate pertanyaan');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectSymptomStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _symptomStartDate = picked;
      });
    }
  }

  // ==========================================
  // QUESTION VIEW - Q&A Process
  // ==========================================

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null || _selectedAnswer!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih salah satu jawaban')),
      );
      return;
    }

    // Validate detailed input if required
    if (_shouldShowDetailedInput() &&
        _detailedAnswerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi detail tambahan yang diminta'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Memproses jawaban...';
    });

    try {
      // Build full answer with detailed input if provided
      String fullAnswer = _selectedAnswer!;
      String? detailedAnswer;

      if (_detailedAnswerController.text.trim().isNotEmpty) {
        detailedAnswer = _detailedAnswerController.text.trim();
        fullAnswer += ' (Detail: $detailedAnswer)';
      }

      // Save answer
      final answerId = const Uuid().v4();
      await _dbHelper.insertConsultationAnswer({
        'id': answerId,
        'consultation_id': _consultationId,
        'question': _currentQuestion!['question'],
        'answer': fullAnswer,
        'question_index': _currentQuestionIndex,
        'detailed_answer': detailedAnswer,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Add to answers list
      _answersGiven.add({
        'question': _currentQuestion!['question'],
        'answer': fullAnswer,
        'questionIndex': _currentQuestionIndex,
        'detailedAnswer': detailedAnswer,
      });

      // Update consultation
      await _dbHelper.updateConsultation({
        'id': _consultationId,
        'questions_asked': _currentQuestionIndex + 1,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Check if this was the last question
      if (_currentQuestionIndex + 1 >= _totalQuestions) {
        // Generate final diagnosis
        await _generateFinalDiagnosis();
      } else {
        // Get next question
        final nextResult = await _geminiService.getNextQuestion(
          allQuestions: _allQuestions,
          currentIndex: _currentQuestionIndex + 1,
          totalQuestions: _totalQuestions,
        );

        if (nextResult['success'] == true) {
          setState(() {
            _currentQuestionIndex++;
            _currentQuestion = nextResult['nextQuestion'];
            _selectedAnswer = null;
            _detailedAnswerController.clear();
          });
        } else {
          throw Exception('Gagal mendapatkan pertanyaan berikutnya');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==========================================
  // FINAL DIAGNOSIS VIEW
  // ==========================================

  Future<void> _generateFinalDiagnosis() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Menganalisis hasil konsultasi...';
    });

    try {
      final result = await _geminiService.generateFinalDiagnosis(
        originalComplaint: _complaintController.text,
        symptomStartDate: _symptomStartDate?.toIso8601String(),
        answersGiven: _answersGiven,
        potentialDiagnoses: _potentialDiagnoses,
      );

      if (result['success'] == true) {
        final diagnosis = result['diagnosis'];

        setState(() {
          _finalDiagnosis = diagnosis;
          _currentView = _ViewState.finalDiagnosis;
        });

        // Save diagnosis to database
        await _dbHelper.insertDiagnosis({
          'id': const Uuid().v4(),
          'consultation_id': _consultationId,
          'diagnosis_name': diagnosis['primaryDiagnosis']['name'],
          'probability': diagnosis['primaryDiagnosis']['confidence'].toString(),
          'description': json.encode(diagnosis),
          'recommendations': json.encode(diagnosis['recommendations']),
          'specialist_recommendation':
              diagnosis['recommendations']?['specialistReferral']?['type'],
          'created_at': DateTime.now().toIso8601String(),
        });

        // Get all answers from database
        final answers = await _dbHelper.getConsultationAnswers(_consultationId);
        List<Map<String, dynamic>> qaList = answers
            .map(
              (answer) => {
                'question': answer['question'],
                'answer': answer['answer'],
              },
            )
            .toList();

        // Update consultation with full data
        await _dbHelper.updateConsultation({
          'id': _consultationId,
          'status': 'completed',
          'main_complaint': _complaintController.text,
          'questions_and_answers': json.encode(qaList),
          'diagnosis': json.encode(diagnosis),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        throw Exception('Gagal generate diagnosis');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchMaps(String specialistType) async {
    try {
      // Ganti query untuk lebih relevan dengan diagnosis
      final primaryDiagnosis =
          _finalDiagnosis?['primaryDiagnosis']?['name'] ?? specialistType;
      final query = Uri.encodeComponent(
        'Dokter spesialis $specialistType untuk $primaryDiagnosis terdekat dari saya',
      );
      final mapsUrl = Uri.parse('geo:0,0?q=$query');
      final webUrl = Uri.parse('https://www.google.com/maps/search/$query');

      if (await canLaunchUrl(mapsUrl)) {
        await launchUrl(mapsUrl);
      } else if (await canLaunchUrl(webUrl)) {
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

  Future<void> _downloadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Membuat laporan PDF...';
      });

      // Get all answers
      final answers = await _dbHelper.getConsultationAnswers(_consultationId);
      final qaList = answers
          .map(
            (answer) => {
              'question': answer['question'],
              'answer': answer['answer'],
            },
          )
          .toList();

      await PdfService.generateAnamnesisPdf(
        consultationId: _consultationId,
        mainComplaint: _complaintController.text,
        symptomStartDate: _symptomStartDate?.toIso8601String() ?? '',
        questionsAndAnswers: qaList,
        diagnosis: _finalDiagnosis ?? {},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF berhasil dibuat dan siap dibagikan!'),
            backgroundColor: Colors.green,
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
          _isLoading = false;
        });
      }
    }
  }

  void _startNewConsultation() {
    setState(() {
      _currentView = _ViewState.initial;
      _complaintController.clear();
      _symptomStartDate = null;
      _currentQuestionIndex = 0;
      _currentQuestion = null;
      _allQuestions = [];
      _potentialDiagnoses = [];
      _selectedAnswer = null;
      _consultationId = '';
      _totalQuestions = 5;
      _answersGiven = [];
      _finalDiagnosis = null;
    });
  }

  // ==========================================
  // BUILD UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.green.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading ? _buildLoadingView() : _buildCurrentView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.green.shade600],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konsultasi Anamnesis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tanya jawab untuk diagnosis akurat',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (_currentView == _ViewState.questions)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentQuestionIndex + 1}/$_totalQuestions',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (_currentView == _ViewState.questions) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _totalQuestions,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_loadingMessage, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case _ViewState.initial:
        return _buildInitialView();
      case _ViewState.questions:
        return _buildQuestionView();
      case _ViewState.finalDiagnosis:
        return _buildFinalDiagnosisView();
    }
  }

  Widget _buildInitialView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.medical_services,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mulai Konsultasi',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Ceritakan keluhan Anda',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Bagaimana cara kerja konsultasi ini?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  _buildHowItWorksStep(1, 'Ceritakan keluhan kesehatan Anda'),
                  _buildHowItWorksStep(
                    2,
                    'Jawab beberapa pertanyaan anamnesis',
                  ),
                  _buildHowItWorksStep(3, 'Dapatkan analisis dan rekomendasi'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ceritakan Keluhan Anda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Jelaskan gejala atau keluhan kesehatan yang Anda alami',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _complaintController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText:
                          'Contoh: Saya mengalami sakit kepala yang berlangsung 3 hari, disertai mual dan pusing...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Kapan Gejala Mulai Dirasakan?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih tanggal kapan gejala pertama kali muncul',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectSymptomStartDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _symptomStartDate == null
                                  ? 'Pilih tanggal'
                                  : _formatDate(_symptomStartDate!),
                              style: TextStyle(
                                fontSize: 15,
                                color: _symptomStartDate == null
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
                          if (_symptomStartDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_getDaysSince(_symptomStartDate!)} hari',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Mulai Konsultasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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

  Widget _buildHowItWorksStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // Helper to determine if detailed input should be shown
  bool _shouldShowDetailedInput() {
    if (_currentQuestion == null || _selectedAnswer == null) {
      return false;
    }

    final requiresDetail = _currentQuestion!['requiresDetailedInput'] == true;
    if (!requiresDetail) return false;

    final negatives = ['tidak', 'belum', 'tidak ada', 'tidak pernah'];
    final hasNegative = negatives.any(
      (negative) => _selectedAnswer!.toLowerCase().contains(negative),
    );

    if (hasNegative) return false;

    final triggers = [
      'ya',
      'iya',
      'ada',
      'pernah',
      'sedang',
      'menggunakan',
      'mengonsumsi',
      'memiliki',
      'mengalami',
    ];

    return triggers.any(
      (trigger) => _selectedAnswer!.toLowerCase().contains(trigger),
    );
  }

  Widget _buildQuestionView() {
    if (_currentQuestion == null) {
      return const Center(child: Text('Tidak ada pertanyaan'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Pertanyaan ${_currentQuestionIndex + 1}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${((_currentQuestionIndex + 1) / _totalQuestions * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentQuestion!['question'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentQuestion!['importance'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pilih Jawaban:',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...(_currentQuestion!['options'] as List).map((option) {
                    final isSelected = _selectedAnswer == option;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedAnswer = option;
                            // Clear detailed answer if switching to option that doesn't require detail
                            if (!_shouldShowDetailedInput()) {
                              _detailedAnswerController.clear();
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade50
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue.shade600
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  color: isSelected
                                      ? Colors.blue.shade600
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.blue.shade700
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Detailed Input Field (shows when answer requires detail and user selects 'Ya')
                  if (_shouldShowDetailedInput()) ...[
                    const SizedBox(height: 20),
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedSlide(
                        offset: Offset.zero,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade50,
                            border: Border(
                              left: BorderSide(
                                color: Colors.yellow.shade700,
                                width: 4,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.edit_note,
                                color: Colors.yellow.shade800,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Mohon berikan detail lebih lanjut untuk diagnosis yang lebih akurat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.yellow.shade900,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _currentQuestion!['detailPrompt'] ??
                                    'Detail tambahan:',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '*',
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _detailedAnswerController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                _currentQuestion!['detailExample'] ??
                                'Tuliskan detail lengkap di sini...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade600,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Tips: Semakin detail informasi yang Anda berikan, semakin akurat diagnosis dan rekomendasi yang diberikan.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedAnswer == null ? null : _submitAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentQuestionIndex + 1 >= _totalQuestions
                                ? 'Selesaikan Konsultasi'
                                : 'Lanjut Pertanyaan Berikutnya',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentQuestionIndex + 1 >= _totalQuestions
                                ? Icons.check_circle
                                : Icons.arrow_forward,
                            color: Colors.white,
                          ),
                        ],
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

  Widget _buildFinalDiagnosisView() {
    if (_finalDiagnosis == null) {
      return const Center(child: Text('Tidak ada diagnosis'));
    }

    final primaryDx = _finalDiagnosis!['primaryDiagnosis'];
    final diffDx = _finalDiagnosis!['differentialDiagnoses'] ?? [];
    final recommendations = _finalDiagnosis!['recommendations'];
    final redFlags = _finalDiagnosis!['redFlags'] ?? [];
    final patientEd = _finalDiagnosis!['patientEducation'] ?? [];
    final specialist = recommendations?['specialistReferral'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konsultasi Selesai',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Berikut hasil analisis lengkap',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary Diagnosis
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.medical_services,
                          color: Colors.red.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Diagnosis Utama',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getConfidenceColor(primaryDx['confidence']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${primaryDx['confidence']}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    primaryDx['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (primaryDx['icd10Code'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ICD-10: ${primaryDx['icd10Code']}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    primaryDx['description'],
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.analytics,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Analisis Medis',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          primaryDx['reasoning'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Differential Diagnoses
          if (diffDx.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.list_alt, color: Colors.orange, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Diagnosis Diferensial',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...diffDx.map((dx) => _buildDifferentialItem(dx)),
                  ],
                ),
              ),
            ),
          ],

          // Recommendations
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.recommend, color: Colors.green, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Rekomendasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (recommendations?['immediate'] != null) ...[
                    _buildRecommendationSection(
                      'Tindakan Segera',
                      recommendations['immediate'],
                      Colors.red.shade100,
                      Icons.emergency,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (recommendations?['followUp'] != null) ...[
                    _buildRecommendationSection(
                      'Tindakan Lanjutan',
                      recommendations['followUp'],
                      Colors.orange.shade100,
                      Icons.schedule,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (recommendations?['lifestyle'] != null) ...[
                    _buildRecommendationSection(
                      'Perubahan Gaya Hidup',
                      recommendations['lifestyle'],
                      Colors.green.shade100,
                      Icons.fitness_center,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (recommendations?['medications'] != null) ...[
                    _buildRecommendationSection(
                      'Rekomendasi Obat',
                      recommendations['medications'],
                      Colors.blue.shade100,
                      Icons.medication,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Specialist Referral & Find Doctor Button
          if (specialist != null && specialist['needed'] == true) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_hospital,
                          color: Colors.purple.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Rujukan Spesialis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Spesialis: ${specialist['type']}',
                                  style: const TextStyle(
                                    fontSize: 15,
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
                                  color: _getUrgencyColor(
                                    specialist['urgency'],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  specialist['urgency']
                                      .toString()
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            specialist['reason'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchMaps(specialist['type']),
                        icon: const Icon(
                          Icons.map,
                        ), // Warna akan mengikuti foregroundColor
                        label: const Text(
                          'Cari Dokter Terdekat',
                        ), // Warna akan mengikuti foregroundColor
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.purple.shade600, // Warna Background Tombol
                          foregroundColor: Colors
                              .white, // <--- Warna Ikon dan Teks menjadi Putih
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Red Flags
          if (redFlags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.red.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tanda Bahaya - Perhatian!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...redFlags.map(
                      (flag) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error,
                              color: Colors.red.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                flag,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red.shade900,
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
            ),
          ],

          // Patient Education
          if (patientEd.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.school, color: Colors.blue, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Edukasi Pasien',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...patientEd.map(
                      (edu) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                edu,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Disclaimer
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.yellow.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _finalDiagnosis!['disclaimer'] ??
                        'Ini adalah analisis AI dan bukan pengganti konsultasi langsung dengan dokter profesional.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Download PDF Button
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Download Laporan PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Action Buttons
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _startNewConsultation,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.blue.shade600, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Konsultasi Baru'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDifferentialItem(Map<String, dynamic> dx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dx['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${dx['probability']}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          if (dx['icd10Code'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'ICD-10: ${dx['icd10Code']}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            dx['reasoning'],
            style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection(
    String title,
    List<dynamic> items,
    Color bgColor,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(item, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(int confidence) {
    if (confidence >= 80) return Colors.green.shade600;
    if (confidence >= 60) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'segera':
        return Colors.red.shade600;
      case 'rutin':
        return Colors.orange.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int _getDaysSince(DateTime date) {
    return DateTime.now().difference(date).inDays;
  }
}

enum _ViewState { initial, questions, finalDiagnosis }
