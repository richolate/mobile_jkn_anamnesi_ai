import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/api_config.dart';

class SoulMedScreen extends StatefulWidget {
  const SoulMedScreen({Key? key}) : super(key: key);

  @override
  State<SoulMedScreen> createState() => _SoulMedScreenState();
}

class _SoulMedScreenState extends State<SoulMedScreen> {
  final TextEditingController _queryController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final GeminiService _geminiService = GeminiService();

  bool _isLoading = false;
  String _loadingMessage = 'Menganalisis informasi medis...';
  String? _response;
  List<dynamic> _sources = [];
  String? _error;
  List<Map<String, dynamic>> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final searches = await _dbHelper.getAllRAGSearches();
      setState(() {
        _recentSearches = searches.take(5).toList();
      });
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> _performSearch() async {
    if (_queryController.text.trim().isEmpty) {
      setState(() {
        _error = 'Silakan masukkan pertanyaan Anda';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _response = null;
      _sources = [];
      _loadingMessage = 'Menganalisis informasi medis...';
    });

    // Update loading message after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (_isLoading) {
        setState(() {
          _loadingMessage =
              'Memproses data medis dalam jumlah besar, mohon tunggu...';
        });
      }
    });

    try {
      // Try persistent RAG server first
      final response = await _tryPersistentServer(_queryController.text);

      if (response != null) {
        await _handleSuccessResponse(response, usedFallback: false);
      } else {
        // Fallback to Gemini if RAG server unavailable
        setState(() {
          _loadingMessage =
              'Server RAG tidak tersedia, menggunakan Gemini AI...';
        });

        final geminiResponse = await _queryWithGemini(_queryController.text);
        await _handleSuccessResponse(geminiResponse, usedFallback: true);
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = 'Menganalisis informasi medis...';
      });
    }
  }

  Future<Map<String, dynamic>?> _tryPersistentServer(String query) async {
    try {
      // Use configured RAG server URL (can be localhost or cloud)
      final ragUrl = ApiConfig.ragServerUrl;

      final response = await http
          .post(
            Uri.parse('$ragUrl/query'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'query': query,
              'max_docs': 5,
              'context': 'anamnesis',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('RAG server error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> _queryWithGemini(String query) async {
    try {
      final medicalContext =
          '''
Anda adalah asisten medis AI yang memberikan informasi kesehatan umum.
Jawab pertanyaan berikut dengan akurat dan profesional.
Berikan informasi yang lengkap dan mudah dipahami.
Selalu ingatkan bahwa jawaban ini bukan pengganti konsultasi dokter profesional.

Pertanyaan: $query

Jawab dengan format:
- Penjelasan singkat
- Informasi detail
- Disclaimer medis
''';

      final result = await _geminiService.generateSimpleResponse(
        medicalContext,
      );

      return {
        'answer': result,
        'sources': [
          {
            'title': 'Gemini AI (Fallback)',
            'similarity': 1.0,
            'content':
                'Informasi dari Gemini AI karena server RAG tidak tersedia',
          },
        ],
        'fallback': true,
      };
    } catch (e) {
      throw Exception('Gemini fallback failed: $e');
    }
  }

  Future<void> _handleSuccessResponse(
    Map<String, dynamic> data, {
    required bool usedFallback,
  }) async {
    final answer =
        data['answer'] ?? data['response'] ?? 'Tidak ada response dari sistem';
    final sources = data['sources'] ?? data['retrieved_documents'] ?? [];
    final isFallback = data['fallback'] == true;

    setState(() {
      _response = answer;
      _sources = sources;
    });

    // Show info if using fallback
    if (usedFallback && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Menggunakan Gemini AI (Server RAG tidak tersedia)',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    // Save to database
    try {
      await _dbHelper.insertRAGSearch({
        'id': const Uuid().v4(),
        'query': _queryController.text,
        'response': answer,
        'sources': json.encode(sources),
        'context_type': isFallback ? 'gemini_fallback' : 'anamnesis',
        'created_at': DateTime.now().toIso8601String(),
      });
      await _loadRecentSearches();
    } catch (e) {
      print('Error saving search: $e');
    }
  }

  void _useQuickQuery(String query) {
    _queryController.text = query;
    _performSearch();
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Yakin ingin menghapus semua riwayat pencarian?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteAllRAGSearches();
      await _loadRecentSearches();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Riwayat pencarian telah dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade50, Colors.blue.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _response == null && !_isLoading
                    ? _buildWelcomeView()
                    : _buildResultsView(),
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
          colors: [Colors.purple.shade600, Colors.blue.shade600],
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SoulMed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Asisten Medis RAG',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (_recentSearches.isNotEmpty)
                IconButton(
                  onPressed: _clearHistory,
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  tooltip: 'Hapus Riwayat',
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryController,
              decoration: const InputDecoration(
                hintText: 'Misalnya: Apa saja gejala diabetes?',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _performSearch(),
              enabled: !_isLoading,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, size: 20, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Cari', style: TextStyle(color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.purple.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanyakan Apapun',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tentang kesehatan dan medis',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Fitur:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildFeature(
                    Icons.search,
                    'Pencarian cerdas dari 37,000+ dokumen medis',
                  ),
                  _buildFeature(
                    Icons.verified,
                    'Informasi terverifikasi dan akurat',
                  ),
                  _buildFeature(
                    Icons.source,
                    'Sumber referensi untuk setiap jawaban',
                  ),
                  _buildFeature(Icons.speed, 'Respon cepat dan relevan'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Topik Populer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickQueryChip('Apa gejala diabetes?', Icons.bloodtype),
              _buildQuickQueryChip('Cara mengatasi hipertensi', Icons.favorite),
              _buildQuickQueryChip('Gejala flu dan COVID-19', Icons.sick),
              _buildQuickQueryChip(
                'Tips gaya hidup sehat',
                Icons.fitness_center,
              ),
            ],
          ),
          if (_recentSearches.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Pencarian',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _clearHistory,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus Semua'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._recentSearches.map((search) => _buildRecentSearchItem(search)),
          ],
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildQuickQueryChip(String query, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: Colors.purple.shade700),
      label: Text(query),
      onPressed: () => _useQuickQuery(query),
      backgroundColor: Colors.purple.shade50,
      labelStyle: TextStyle(color: Colors.purple.shade700),
    );
  }

  Widget _buildRecentSearchItem(Map<String, dynamic> search) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: Icon(Icons.history, color: Colors.purple.shade700, size: 20),
        ),
        title: Text(
          search['query'],
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDateTime(search['created_at']),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _queryController.text = search['query'];
          setState(() {
            _response = search['response'];
            _sources = json.decode(search['sources'] ?? '[]');
          });
        },
      ),
    );
  }

  Widget _buildResultsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isLoading) _buildLoadingState(),
          if (_response != null && !_isLoading) ...[
            _buildResultCard(),
            if (_sources.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSourcesCard(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _loadingMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _loadingMessage.contains('besar')
                ? 'Sistem sedang memproses 37,000+ dokumen medis.\nProses ini membutuhkan waktu hingga 2 menit.'
                : 'Mencari informasi terkait dari basis data medis...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Hasil Pencarian',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: MarkdownBody(
                data: _response!,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 15, height: 1.6),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                  h1: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  listBullet: const TextStyle(fontSize: 15),
                  code: TextStyle(
                    backgroundColor: Colors.grey.shade200,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourcesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.source, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Sumber Informasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._sources.asMap().entries.map((entry) {
              final index = entry.key;
              final source = entry.value;
              return _buildSourceItem(index + 1, source);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceItem(int index, dynamic source) {
    final title = source['title'] ?? source['file_name'] ?? 'Dokumen $index';
    final preview =
        source['preview'] ?? source['content_preview'] ?? 'Tidak ada preview';
    final score =
        source['relevance_score'] ?? source['similarity_score'] ?? 0.0;
    final category = source['category'] ?? 'general';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(score * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              category,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            preview,
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inHours < 1) return '${diff.inMinutes} menit yang lalu';
      if (diff.inDays < 1) return '${diff.inHours} jam yang lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
