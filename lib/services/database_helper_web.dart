// Web implementation using SharedPreferences as storage
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  
  DatabaseHelper._init();

  // Consultation methods
  Future<String> insertConsultation(Map<String, dynamic> consultation) async {
    final prefs = await SharedPreferences.getInstance();
    final consultations = await getAllConsultations();
    consultations.add(consultation);
    
    await prefs.setString(
      'consultations',
      jsonEncode(consultations),
    );
    
    return consultation['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getAllConsultations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('consultations');
    
    if (data == null) return [];
    
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getConsultation(String id) async {
    final consultations = await getAllConsultations();
    
    try {
      return consultations.firstWhere((c) => c['id'] == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> updateConsultation(Map<String, dynamic> consultation) async {
    final prefs = await SharedPreferences.getInstance();
    final consultations = await getAllConsultations();
    
    final index = consultations.indexWhere((c) => c['id'] == consultation['id']);
    
    if (index != -1) {
      consultations[index] = consultation;
      await prefs.setString(
        'consultations',
        jsonEncode(consultations),
      );
      return 1;
    }
    
    return 0;
  }

  Future<int> deleteConsultation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final consultations = await getAllConsultations();
    
    consultations.removeWhere((c) => c['id'] == id);
    
    await prefs.setString(
      'consultations',
      jsonEncode(consultations),
    );
    
    // Also delete related answers and diagnoses
    await _deleteRelatedData('consultation_answers', id);
    await _deleteRelatedData('diagnoses', id);
    
    return 1;
  }

  // Consultation Answer methods
  Future<void> insertConsultationAnswer(Map<String, dynamic> answer) async {
    final prefs = await SharedPreferences.getInstance();
    final answers = await _getDataList('consultation_answers');
    answers.add(answer);
    
    await prefs.setString(
      'consultation_answers',
      jsonEncode(answers),
    );
  }

  Future<List<Map<String, dynamic>>> getConsultationAnswers(
      String consultationId) async {
    final answers = await _getDataList('consultation_answers');
    return answers.where((a) => a['consultation_id'] == consultationId).toList();
  }

  // Diagnosis methods
  Future<void> insertDiagnosis(Map<String, dynamic> diagnosis) async {
    final prefs = await SharedPreferences.getInstance();
    final diagnoses = await _getDataList('diagnoses');
    diagnoses.add(diagnosis);
    
    await prefs.setString(
      'diagnoses',
      jsonEncode(diagnoses),
    );
  }

  Future<Map<String, dynamic>?> getDiagnosis(String consultationId) async {
    final diagnoses = await _getDataList('diagnoses');
    
    try {
      return diagnoses.firstWhere((d) => d['consultation_id'] == consultationId);
    } catch (e) {
      return null;
    }
  }

  // Image Analysis methods
  Future<String> insertImageAnalysis(Map<String, dynamic> analysis) async {
    final prefs = await SharedPreferences.getInstance();
    final analyses = await _getDataList('image_analyses');
    analyses.add(analysis);
    
    await prefs.setString(
      'image_analyses',
      jsonEncode(analyses),
    );
    
    return analysis['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getAllImageAnalyses() async {
    return await _getDataList('image_analyses');
  }

  Future<Map<String, dynamic>?> getImageAnalysis(String id) async {
    final analyses = await _getDataList('image_analyses');
    
    try {
      return analyses.firstWhere((a) => a['id'] == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> deleteImageAnalysis(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final analyses = await _getDataList('image_analyses');
    
    analyses.removeWhere((a) => a['id'] == id);
    
    await prefs.setString(
      'image_analyses',
      jsonEncode(analyses),
    );
    
    return 1;
  }

  // Helper methods
  Future<List<Map<String, dynamic>>> _getDataList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(key);
    
    if (data == null) return [];
    
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> _deleteRelatedData(String key, String consultationId) async {
    final prefs = await SharedPreferences.getInstance();
    final dataList = await _getDataList(key);
    
    dataList.removeWhere((item) => item['consultation_id'] == consultationId);
    
    await prefs.setString(
      key,
      jsonEncode(dataList),
    );
  }

  // RAG Search methods
  Future<void> insertRAGSearch(Map<String, dynamic> search) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = await _getDataList('rag_searches');
    searches.add(search);
    
    await prefs.setString(
      'rag_searches',
      jsonEncode(searches),
    );
  }

  Future<List<Map<String, dynamic>>> getAllRAGSearches() async {
    return await _getDataList('rag_searches');
  }

  Future<void> deleteAllRAGSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rag_searches');
  }

  Future<void> close() async {
    // No-op for web implementation
  }
}
