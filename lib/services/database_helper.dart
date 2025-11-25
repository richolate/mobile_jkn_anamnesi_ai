import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Mobile/Desktop implementation with SQLite
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('anamnesa_mobile.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDocDir.path, filePath);

    return await openDatabase(
      dbPath,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add symptom_start_date column if upgrading from version 1
      await db.execute(
        'ALTER TABLE consultations ADD COLUMN symptom_start_date TEXT',
      );
    }
    if (oldVersion < 3) {
      // Add columns for full data storage
      await db.execute(
        'ALTER TABLE consultations ADD COLUMN main_complaint TEXT',
      );
      await db.execute(
        'ALTER TABLE consultations ADD COLUMN questions_and_answers TEXT',
      );
      await db.execute('ALTER TABLE consultations ADD COLUMN diagnosis TEXT');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';

    // Tabel untuk Konsultasi Anamnesis (UPDATED with symptom_start_date)
    await db.execute('''
CREATE TABLE consultations (
  id $idType,
  original_complaint $textType,
  symptom_start_date $textNullable,
  questions_asked $intType,
  total_questions $intType,
  status $textType,
  main_complaint $textNullable,
  questions_and_answers $textNullable,
  diagnosis $textNullable,
  created_at $textType,
  updated_at $textType
)
''');

    // Tabel untuk Jawaban Konsultasi
    await db.execute('''
CREATE TABLE consultation_answers (
  id $idType,
  consultation_id $textType,
  question $textType,
  answer $textType,
  question_index $intType,
  detailed_answer $textNullable,
  created_at $textType,
  FOREIGN KEY (consultation_id) REFERENCES consultations (id) ON DELETE CASCADE
)
''');

    // Tabel untuk Diagnosis
    await db.execute('''
CREATE TABLE diagnoses (
  id $idType,
  consultation_id $textType,
  diagnosis_name $textType,
  probability $textNullable,
  description $textNullable,
  recommendations $textNullable,
  specialist_recommendation $textNullable,
  created_at $textType,
  FOREIGN KEY (consultation_id) REFERENCES consultations (id) ON DELETE CASCADE
)
''');

    // Tabel untuk Analisis Gambar Medis
    await db.execute('''
CREATE TABLE image_analyses (
  id $idType,
  image_path $textType,
  image_description $textNullable,
  analysis_result $textType,
  diagnosis $textNullable,
  recommendations $textNullable,
  specialist_recommendation $textNullable,
  created_at $textType
)
''');

    // Tabel untuk RAG Search History (UPDATED - not chat)
    await db.execute('''
CREATE TABLE rag_searches (
  id $idType,
  query $textType,
  response $textType,
  sources $textNullable,
  context_type $textType,
  created_at $textType
)
''');

    // Tabel untuk Health Logs
    await db.execute('''
CREATE TABLE health_logs (
  id $idType,
  consultation_id $textNullable,
  log_date $textType,
  symptoms $textNullable,
  severity $textNullable,
  notes $textNullable,
  created_at $textType,
  FOREIGN KEY (consultation_id) REFERENCES consultations (id) ON DELETE SET NULL
)
''');
  }

  // ==========================================
  // CONSULTATIONS CRUD
  // ==========================================

  Future<String> insertConsultation(Map<String, dynamic> consultation) async {
    final db = await database;
    await db.insert('consultations', consultation);
    return consultation['id'] as String;
  }

  Future<Map<String, dynamic>?> getConsultation(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'consultations',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllConsultations() async {
    final db = await database;
    return await db.query('consultations', orderBy: 'created_at DESC');
  }

  Future<int> updateConsultation(Map<String, dynamic> consultation) async {
    final db = await database;
    return await db.update(
      'consultations',
      consultation,
      where: 'id = ?',
      whereArgs: [consultation['id']],
    );
  }

  Future<int> deleteConsultation(String id) async {
    final db = await database;
    return await db.delete('consultations', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // CONSULTATION ANSWERS CRUD
  // ==========================================

  Future<void> insertConsultationAnswer(Map<String, dynamic> answer) async {
    final db = await database;
    await db.insert('consultation_answers', answer);
  }

  Future<List<Map<String, dynamic>>> getConsultationAnswers(
    String consultationId,
  ) async {
    final db = await database;
    return await db.query(
      'consultation_answers',
      where: 'consultation_id = ?',
      whereArgs: [consultationId],
      orderBy: 'question_index ASC',
    );
  }

  Future<int> deleteAnswersByConsultation(String consultationId) async {
    final db = await database;
    return await db.delete(
      'consultation_answers',
      where: 'consultation_id = ?',
      whereArgs: [consultationId],
    );
  }

  // ==========================================
  // DIAGNOSES CRUD
  // ==========================================

  Future<void> insertDiagnosis(Map<String, dynamic> diagnosis) async {
    final db = await database;
    await db.insert('diagnoses', diagnosis);
  }

  Future<Map<String, dynamic>?> getDiagnosis(String consultationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'diagnoses',
      where: 'consultation_id = ?',
      whereArgs: [consultationId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllDiagnoses() async {
    final db = await database;
    return await db.query('diagnoses', orderBy: 'created_at DESC');
  }

  Future<int> deleteDiagnosis(String id) async {
    final db = await database;
    return await db.delete('diagnoses', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // IMAGE ANALYSES CRUD
  // ==========================================

  Future<String> insertImageAnalysis(Map<String, dynamic> analysis) async {
    final db = await database;
    await db.insert('image_analyses', analysis);
    return analysis['id'] as String;
  }

  Future<Map<String, dynamic>?> getImageAnalysis(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'image_analyses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllImageAnalyses() async {
    final db = await database;
    return await db.query('image_analyses', orderBy: 'created_at DESC');
  }

  Future<int> deleteImageAnalysis(String id) async {
    final db = await database;
    return await db.delete('image_analyses', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // RAG SEARCHES CRUD (UPDATED)
  // ==========================================

  Future<int> insertRAGSearch(Map<String, dynamic> search) async {
    final db = await database;
    return await db.insert('rag_searches', search);
  }

  Future<List<Map<String, dynamic>>> getAllRAGSearches() async {
    final db = await database;
    return await db.query(
      'rag_searches',
      orderBy: 'created_at DESC',
      limit: 50,
    );
  }

  Future<int> deleteAllRAGSearches() async {
    final db = await database;
    return await db.delete('rag_searches');
  }

  // ==========================================
  // HEALTH LOGS CRUD
  // ==========================================

  Future<int> insertHealthLog(Map<String, dynamic> log) async {
    final db = await database;
    return await db.insert('health_logs', log);
  }

  Future<List<Map<String, dynamic>>> getHealthLogsByConsultation(
    String consultationId,
  ) async {
    final db = await database;
    return await db.query(
      'health_logs',
      where: 'consultation_id = ?',
      whereArgs: [consultationId],
      orderBy: 'log_date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllHealthLogs() async {
    final db = await database;
    return await db.query('health_logs', orderBy: 'log_date DESC');
  }

  Future<int> deleteHealthLog(String id) async {
    final db = await database;
    return await db.delete('health_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('consultations');
    await db.delete('consultation_answers');
    await db.delete('diagnoses');
    await db.delete('image_analyses');
    await db.delete('rag_searches');
    await db.delete('health_logs');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
