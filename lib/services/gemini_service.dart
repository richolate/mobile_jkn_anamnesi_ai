import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'api_config.dart';
import 'anamnesis_questions_bank.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    // Validate API Key
    if (ApiConfig.geminiApiKey.isEmpty) {
      throw Exception(
        'Gemini API Key tidak ditemukan. '
        'Pastikan file .env sudah dibuat dan berisi GEMINI_API_KEY yang valid.',
      );
    }

    _model = GenerativeModel(
      model: ApiConfig.geminiModel,
      apiKey: ApiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
  }

  // Helper method to handle network errors with better messages
  String _getErrorMessage(dynamic error) {
    // Check for network errors (works on both mobile and web)
    final errorString = error.toString();
    
    if (errorString.contains('SocketException') || 
        errorString.contains('Failed host lookup') ||
        errorString.contains('NetworkException') ||
        errorString.contains('XMLHttpRequest error')) {
      return 'Tidak dapat terhubung ke server Gemini AI.\n\n'
          'Kemungkinan penyebab:\n'
          '• Tidak ada koneksi internet\n'
          '• DNS tidak dapat menyelesaikan hostname\n'
          '• API Gemini sedang down\n'
          '• Firewall memblokir koneksi\n\n'
          'Solusi untuk Android:\n'
          '• Pastikan permission INTERNET sudah diaktifkan\n'
          '• Coba ganti DNS ke 8.8.8.8 (Google DNS)\n'
          '• Restart aplikasi dan coba lagi\n\n'
          'Solusi untuk Web:\n'
          '• Periksa koneksi internet browser\n'
          '• Check browser console untuk error detail\n'
          '• Pastikan environment variables sudah di-set di Vercel';
    } else if (errorString.contains('API key')) {
      return 'API Key tidak valid atau tidak ditemukan.\n\n'
          'Solusi:\n'
          '• Periksa file .env dan pastikan GEMINI_API_KEY sudah diisi\n'
          '• Dapatkan API key baru di: https://makersuite.google.com/app/apikey';
    }
    return 'Terjadi kesalahan: $errorString';
  }

  // ==========================================
  // ANAMNESIS - INITIAL QUESTIONS FROM BANK
  // ==========================================

  Future<Map<String, dynamic>> generateInitialQuestionsFromBank({
    required String complaint,
  }) async {
    try {
      // Calculate dynamic question count based on complaint length
      final questionCount = AnamnesisQuestionsBank.calculateQuestionCount(
        complaint,
      );

      // Get all questions from bank
      final allQuestions = AnamnesisQuestionsBank.getAllQuestions();

      // Create prompt for AI to SELECT relevant questions from bank
      final prompt =
          '''
Anda adalah sistem AI medis yang membantu memilih pertanyaan anamnesis yang paling relevan.

Keluhan pasien: "$complaint"

Anda memiliki bank 36 pertanyaan anamnesis terstruktur dari 10 kategori:
1. Identifikasi Pasien & Faktor Risiko (4 pertanyaan)
2. Detail Keluhan Utama / HPI (6 pertanyaan)
3. Riwayat Penyakit Dahulu (3 pertanyaan)
4. Riwayat Pengobatan (2 pertanyaan)
5. Riwayat Keluarga (2 pertanyaan)
6. Riwayat Sosial & Lingkungan (3 pertanyaan)
7. Pola Hidup dan Kebiasaan (5 pertanyaan)
8. Review of Systems / ROS (6 pertanyaan)
9. Riwayat Reproduksi (3 pertanyaan)
10. Validasi dan Prioritas (2 pertanyaan)

Bank Pertanyaan Tersedia:
${allQuestions.map((q) => '''
Nomor: ${q.questionNumber}
Kategori: ${q.category}
Pertanyaan: ${q.question}
Opsi: ${q.options.join(', ')}
Pentingnya: ${q.importance}
---''').join('\n')}

TUGAS ANDA:
Pilih TEPAT $questionCount pertanyaan yang PALING RELEVAN untuk keluhan "${complaint}".

ATURAN PEMILIHAN BERDASARKAN JUMLAH PERTANYAAN:
- Jika $questionCount >= 18: Keluhan SANGAT MINIM → Pilih dari SEMUA 10 kategori (anamnesis lengkap)
  * WAJIB mencakup: identifikasi_pasien (2-3), detail_keluhan (4-5), riwayat_dahulu (2), riwayat_obat (2), 
    riwayat_keluarga (1-2), sosial_lingkungan (2), pola_hidup (2-3), review_systems (2-3), reproduksi (1), validasi (1)
- Jika $questionCount >= 12: Keluhan MINIM → Fokus pada 7-8 kategori utama
  * Prioritas: detail_keluhan, identifikasi_pasien, review_systems, riwayat_dahulu, pola_hidup, riwayat_obat
- Jika $questionCount >= 8: Keluhan CUKUP → Fokus pada 5-6 kategori penting
  * Prioritas: detail_keluhan, identifikasi_pasien, review_systems, riwayat_dahulu
- Jika $questionCount < 8: Keluhan LENGKAP → Fokus pada 3-4 kategori validasi
  * Prioritas: detail_keluhan (validasi), review_systems (skrining), validasi

ATURAN UMUM:
1. Pertanyaan harus logis dan berurutan (mulai dari identifikasi → detail keluhan → riwayat → validasi)
2. WAJIB pilih dari bank pertanyaan yang disediakan (nomor 1-36)
3. Untuk pertanyaan dengan requiresDetailedInput, pastikan relevan dengan keluhan

Output JSON format:
{
  "selectedQuestions": [
    {
      "questionNumber": <nomor dari bank 1-36>,
      "category": "<kategori pertanyaan>"
    }
  ],
  "potentialDiagnoses": [
    {
      "name": "<nama diagnosis potensial>",
      "probability": "<tinggi/sedang/rendah>",
      "reasoning": "<alasan mengapa diagnosis ini mungkin>"
    }
  ]
}

Berikan HANYA JSON, tanpa penjelasan tambahan.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      // Parse JSON response
      final jsonText = responseText
          .replaceAll(RegExp(r'```json\n?|\n?```'), '')
          .trim();
      final jsonData = json.decode(jsonText);

      // Map selected question numbers to actual questions from bank
      final selectedQuestionNumbers = (jsonData['selectedQuestions'] as List)
          .map((q) => q['questionNumber'] as int)
          .toList();

      final selectedQuestions = selectedQuestionNumbers
          .map(
            (num) => allQuestions.firstWhere(
              (q) => q.questionNumber == num,
              orElse: () => allQuestions[0], // Fallback
            ),
          )
          .toList();

      // Get first question
      final firstQuestion = selectedQuestions.isNotEmpty
          ? {
              'question': selectedQuestions[0].question,
              'options': selectedQuestions[0].options,
              'questionType': selectedQuestions[0].questionType,
              'importance': selectedQuestions[0].importance,
              'category': selectedQuestions[0].category,
              'requiresDetailedInput':
                  selectedQuestions[0].requiresDetailedInput,
              'detailPrompt': selectedQuestions[0].detailPrompt,
              'detailExample': selectedQuestions[0].detailExample,
            }
          : _getFallbackQuestion(1);

      return {
        'success': true,
        'firstQuestion': firstQuestion,
        'allQuestions': selectedQuestions
            .map(
              (q) => {
                'question': q.question,
                'options': q.options,
                'questionType': q.questionType,
                'importance': q.importance,
                'category': q.category,
                'requiresDetailedInput': q.requiresDetailedInput,
                'detailPrompt': q.detailPrompt,
                'detailExample': q.detailExample,
              },
            )
            .toList(),
        'potentialDiagnoses': jsonData['potentialDiagnoses'] ?? [],
        'totalQuestions': questionCount,
      };
    } catch (e) {
      print('❌ Error generating questions from bank: ${_getErrorMessage(e)}');

      // Rethrow with user-friendly message for critical network errors
      final errorString = e.toString();
      if (errorString.contains('SocketException') || 
          errorString.contains('Failed host lookup') ||
          errorString.contains('NetworkException') ||
          errorString.contains('XMLHttpRequest error')) {
        throw Exception(_getErrorMessage(e));
      }

      // Fallback: use prioritized questions directly
      final questionCount = AnamnesisQuestionsBank.calculateQuestionCount(
        complaint,
      );
      final questions = AnamnesisQuestionsBank.getPrioritizedQuestions(
        questionCount,
      );

      return {
        'success': true,
        'firstQuestion': {
          'question': questions[0].question,
          'options': questions[0].options,
          'questionType': questions[0].questionType,
          'importance': questions[0].importance,
          'category': questions[0].category,
          'requiresDetailedInput': questions[0].requiresDetailedInput,
          'detailPrompt': questions[0].detailPrompt,
          'detailExample': questions[0].detailExample,
        },
        'allQuestions': questions
            .map(
              (q) => {
                'question': q.question,
                'options': q.options,
                'questionType': q.questionType,
                'importance': q.importance,
                'category': q.category,
                'requiresDetailedInput': q.requiresDetailedInput,
                'detailPrompt': q.detailPrompt,
                'detailExample': q.detailExample,
              },
            )
            .toList(),
        'potentialDiagnoses': [
          {
            'name': 'Kondisi yang memerlukan evaluasi lebih lanjut',
            'probability': 'sedang',
            'reasoning':
                'Berdasarkan keluhan awal, diperlukan informasi tambahan',
          },
        ],
        'totalQuestions': questionCount,
      };
    }
  }

  // ==========================================
  // ANAMNESIS - GET NEXT QUESTION (from pre-selected list)
  // ==========================================

  Future<Map<String, dynamic>> getNextQuestion({
    required List<Map<String, dynamic>> allQuestions,
    required int currentIndex,
    required int totalQuestions,
  }) async {
    try {
      if (currentIndex >= allQuestions.length ||
          currentIndex >= totalQuestions) {
        return {'success': false, 'error': 'No more questions available'};
      }

      final nextQuestion = allQuestions[currentIndex];

      return {
        'success': true,
        'nextQuestion': nextQuestion,
        'isLastQuestion': currentIndex + 1 >= totalQuestions,
        'progress': {'current': currentIndex + 1, 'total': totalQuestions},
      };
    } catch (e) {
      print('Error getting next question: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==========================================
  // ANAMNESIS - FINAL DIAGNOSIS
  // ==========================================

  Future<Map<String, dynamic>> generateFinalDiagnosis({
    required String originalComplaint,
    required String? symptomStartDate,
    required List<Map<String, dynamic>> answersGiven,
    required List<Map<String, dynamic>> potentialDiagnoses,
  }) async {
    try {
      // Calculate days since symptoms started
      String durationInfo = '';
      if (symptomStartDate != null && symptomStartDate.isNotEmpty) {
        try {
          final startDate = DateTime.parse(symptomStartDate);
          final daysSince = DateTime.now().difference(startDate).inDays;
          durationInfo =
              '\nDurasi gejala: $daysSince hari (mulai ${_formatDate(startDate)})';
        } catch (e) {
          durationInfo = '';
        }
      }

      final prompt =
          '''
Anda adalah dokter AI profesional yang melakukan analisis diagnosis berdasarkan anamnesis lengkap.

KELUHAN AWAL:
"$originalComplaint"$durationInfo

KEMUNGKINAN DIAGNOSIS AWAL:
${potentialDiagnoses.map((d) => '- ${d['name']} (${d['probability']}): ${d['reasoning']}').join('\n')}

HASIL ANAMNESIS LENGKAP:
${answersGiven.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final qa = entry.value;
            return 'Q$index: ${qa['question']}\nA$index: ${qa['answer']}';
          }).join('\n\n')}

TUGAS ANDA:
Berikan diagnosis final yang komprehensif dan profesional berdasarkan semua informasi di atas.

Output HARUS dalam format JSON berikut:
{
  "primaryDiagnosis": {
    "name": "<nama diagnosis utama>",
    "icd10Code": "<kode ICD-10 jika ada>",
    "confidence": <0-100>,
    "description": "<penjelasan lengkap kondisi>",
    "reasoning": "<analisis medis yang mendukung diagnosis ini>"
  },
  "differentialDiagnoses": [
    {
      "name": "<diagnosis alternatif>",
      "icd10Code": "<kode ICD-10>",
      "probability": <0-100>,
      "reasoning": "<mengapa ini mungkin>"
    }
  ],
  "recommendations": {
    "immediate": [
      "<tindakan segera yang harus dilakukan>"
    ],
    "followUp": [
      "<tindakan lanjutan>"
    ],
    "lifestyle": [
      "<perubahan gaya hidup>"
    ],
    "medications": [
      "<rekomendasi obat (umum)>"
    ],
    "specialistReferral": {
      "needed": true/false,
      "type": "<jenis spesialis jika diperlukan>",
      "urgency": "<segera/rutin/opsional>",
      "reason": "<alasan rujukan>"
    }
  },
  "redFlags": [
    "<tanda bahaya yang perlu diwaspadai>"
  ],
  "patientEducation": [
    "<edukasi untuk pasien>"
  ],
  "estimatedRecoveryDays": <perkiraan hari pemulihan>,
  "disclaimer": "Ini adalah analisis AI dan bukan pengganti konsultasi langsung dengan dokter profesional."
}

PENTING:
- Berikan analisis medis yang akurat dan profesional
- Gunakan istilah medis yang jelas
- Sertakan kode ICD-10 yang sesuai
- Rekomendasi harus praktis dan aman
- Jika kondisi serius, tekankan pentingnya konsultasi dokter

Berikan HANYA JSON, tanpa penjelasan tambahan.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      // Parse JSON
      final jsonText = responseText
          .replaceAll(RegExp(r'```json\n?|\n?```'), '')
          .trim();
      final jsonData = json.decode(jsonText);

      return {'success': true, 'diagnosis': jsonData};
    } catch (e) {
      print('Error generating final diagnosis: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==========================================
  // IMAGE ANALYSIS
  // ==========================================

  Future<Map<String, dynamic>> analyzeImage({
    required String base64Image,
    String? description,
  }) async {
    try {
      final visionModel = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: ApiConfig.geminiApiKey,
      );

      final prompt =
          '''
Anda adalah AI medis spesialis analisis gambar medis. Analisis gambar berikut dengan detail.

${description != null && description.isNotEmpty ? 'Deskripsi dari pengguna: "$description"\n' : ''}

TUGAS ANALISIS:
1. Identifikasi jenis gambar medis (X-ray, CT, MRI, foto klinis, dll)
2. Analisis temuan visual yang terlihat
3. Berikan interpretasi medis profesional
4. Sarankan diagnosis potensial
5. Rekomendasikan tindakan lanjutan

Gunakan metode Chain of Thought untuk analisis:
- Step 1: Identifikasi modalitas dan area anatomi
- Step 2: Observasi temuan normal
- Step 3: Identifikasi abnormalitas jika ada
- Step 4: Analisis diferensial diagnosis
- Step 5: Kesimpulan dan rekomendasi

Output JSON format:
{
  "imageType": "<jenis gambar medis>",
  "anatomicalArea": "<area anatomi yang difoto>",
  "findings": {
    "normal": ["<temuan normal>"],
    "abnormal": ["<temuan abnormal jika ada>"]
  },
  "diagnosis": {
    "primary": "<diagnosis utama>",
    "confidence": <0-100>,
    "reasoning": "<penjelasan analisis>"
  },
  "differentialDiagnoses": [
    {
      "name": "<diagnosis alternatif>",
      "probability": <0-100>,
      "reasoning": "<mengapa mungkin>"
    }
  ],
  "recommendations": {
    "immediate": ["<tindakan segera>"],
    "followUp": ["<pemeriksaan lanjutan>"],
    "specialist": "<spesialis yang dirujuk>"
  },
  "redFlags": ["<tanda bahaya>"],
  "patientEducation": ["<edukasi pasien>"],
  "disclaimer": "Analisis AI ini bukan pengganti evaluasi profesional medis."
}

Berikan HANYA JSON.
''';

      final imagePart = DataPart('image/jpeg', base64Decode(base64Image));
      final response = await visionModel.generateContent([
        Content.multi([TextPart(prompt), imagePart]),
      ]);

      final responseText = response.text ?? '';
      final jsonText = responseText
          .replaceAll(RegExp(r'```json\n?|\n?```'), '')
          .trim();
      final jsonData = json.decode(jsonText);

      // Transform to match expected structure
      return {
        'imageType': jsonData['imageType'] ?? 'Gambar Medis',
        'anatomicalArea': jsonData['anatomicalArea'],
        'findings': jsonData['findings'],
        'primaryDiagnosis': {
          'diagnosis':
              jsonData['diagnosis']?['primary'] ?? 'Tidak dapat ditentukan',
          'confidence': (jsonData['diagnosis']?['confidence'] ?? 0)
              .toString()
              .toUpperCase(),
          'reasoning': jsonData['diagnosis']?['reasoning'] ?? '',
        },
        'differentialDiagnoses':
            (jsonData['differentialDiagnoses'] as List?)
                ?.map(
                  (d) => {
                    'name': d['name'],
                    'probability': d['probability'],
                    'reasoning': d['reasoning'],
                  },
                )
                .toList() ??
            [],
        'recommendations': {
          'immediate': jsonData['recommendations']?['immediate'] ?? [],
          'followUp': jsonData['recommendations']?['followUp'] ?? [],
          'specialistReferral':
              jsonData['recommendations']?['specialist'] ?? 'Dokter Umum',
        },
        'redFlags': jsonData['redFlags'] ?? [],
        'patientEducation': jsonData['patientEducation'] ?? [],
        'disclaimer':
            jsonData['disclaimer'] ??
            '⚠️ Hasil ini bukan diagnosis final. Segera konsultasikan dengan dokter untuk pemeriksaan lebih lanjut.',
      };
    } catch (e) {
      print('Error analyzing image: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================

  Map<String, dynamic> _getFallbackQuestion(int questionNumber) {
    final questions = [
      {
        'question':
            'Bagaimana intensitas gejala yang Anda rasakan pada skala 1-10?',
        'options': [
          'Ringan (1-3)',
          'Sedang (4-6)',
          'Berat (7-8)',
          'Sangat berat (9-10)',
        ],
        'questionType': 'multiple_choice',
        'importance':
            'Tingkat intensitas membantu menentukan tingkat keparahan kondisi',
        'category': 'detail_keluhan',
        'requiresDetailedInput': false,
        'detailPrompt': null,
        'detailExample': null,
      },
      {
        'question':
            'Apakah ada anggota keluarga yang pernah mengalami kondisi serupa?',
        'options': [
          'Ya, orang tua',
          'Ya, saudara kandung',
          'Ya, keluarga lain',
          'Tidak ada',
        ],
        'questionType': 'multiple_choice',
        'importance': 'Riwayat keluarga dapat mengindikasikan faktor genetik',
        'category': 'riwayat_keluarga',
        'requiresDetailedInput': true,
        'detailPrompt': 'Sebutkan anggota keluarga dan penyakit yang dimiliki',
        'detailExample': 'Contoh: Ayah - diabetes, Ibu - hipertensi',
      },
    ];

    // Ensure valid index
    final index = questionNumber - 1;
    if (index >= 0 && index < questions.length) {
      return questions[index];
    }
    return questions[0];
  }

  // Simple text generation for general queries (used by SoulMed fallback)
  Future<String> generateSimpleResponse(String prompt) async {
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Maaf, tidak dapat menghasilkan respons';
    } catch (e) {
      print('Error generating simple response: $e');
      return 'Terjadi kesalahan dalam menghasilkan respons: ${e.toString()}';
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
}
