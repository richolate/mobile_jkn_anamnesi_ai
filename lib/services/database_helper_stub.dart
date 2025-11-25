// Stub file for conditional imports
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<String> insertConsultation(Map<String, dynamic> consultation) async {
    throw UnimplementedError();
  }

  Future<List<Map<String, dynamic>>> getAllConsultations() async {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>?> getConsultation(String id) async {
    throw UnimplementedError();
  }

  Future<int> updateConsultation(Map<String, dynamic> consultation) async {
    throw UnimplementedError();
  }

  Future<int> deleteConsultation(String id) async {
    throw UnimplementedError();
  }

  Future<void> insertConsultationAnswer(Map<String, dynamic> answer) async {
    throw UnimplementedError();
  }

  Future<List<Map<String, dynamic>>> getConsultationAnswers(
    String consultationId,
  ) async {
    throw UnimplementedError();
  }

  Future<void> insertDiagnosis(Map<String, dynamic> diagnosis) async {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>?> getDiagnosis(String consultationId) async {
    throw UnimplementedError();
  }

  Future<String> insertImageAnalysis(Map<String, dynamic> analysis) async {
    throw UnimplementedError();
  }

  Future<List<Map<String, dynamic>>> getAllImageAnalyses() async {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>?> getImageAnalysis(String id) async {
    throw UnimplementedError();
  }

  Future<int> deleteImageAnalysis(String id) async {
    throw UnimplementedError();
  }

  Future<void> insertRAGSearch(Map<String, dynamic> search) async {
    throw UnimplementedError();
  }

  Future<List<Map<String, dynamic>>> getAllRAGSearches() async {
    throw UnimplementedError();
  }

  Future<void> deleteAllRAGSearches() async {
    throw UnimplementedError();
  }

  Future<void> close() async {
    throw UnimplementedError();
  }
}
