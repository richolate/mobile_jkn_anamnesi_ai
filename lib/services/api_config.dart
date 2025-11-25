import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Load environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print('Warning: Could not load .env file: $e');
      print('Using fallback configuration');
    }
  }

  // Gemini API Key - Loaded from .env file or dart-define
  // Get your API key from: https://makersuite.google.com/app/apikey
  static String get geminiApiKey {
    // Priority: dart-define (web build) > .env file (mobile)
    const compileTime = String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: '',
    );
    if (compileTime.isNotEmpty) return compileTime;

    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  // RAG Server Endpoint - Loaded from .env file or dart-define
  // Options:
  // 1. Local development: 'http://localhost:8001'
  // 2. Cloud Run: 'https://rag-medical-api-xxxxx.run.app'
  // 3. Railway: 'https://rag-medical-api.railway.app'
  // 4. Vercel: 'https://your-rag-api.vercel.app'
  //
  // FALLBACK: If RAG server unavailable, app will use Gemini AI automatically
  static String get ragServerUrl {
    const compileTime = String.fromEnvironment(
      'RAG_SERVER_URL',
      defaultValue: '',
    );
    if (compileTime.isNotEmpty) return compileTime;

    return dotenv.env['RAG_SERVER_URL'] ?? 'http://localhost:8001';
  }

  // Model Configuration
  static String get geminiModel {
    const compileTime = String.fromEnvironment(
      'GEMINI_MODEL',
      defaultValue: '',
    );
    if (compileTime.isNotEmpty) return compileTime;

    return dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.0-flash-lite';
  }

  // Timeouts
  static int get apiTimeout {
    const compileTime = String.fromEnvironment('API_TIMEOUT', defaultValue: '');
    if (compileTime.isNotEmpty) {
      return int.tryParse(compileTime) ?? 120;
    }

    final timeout = dotenv.env['API_TIMEOUT'] ?? '120';
    return int.tryParse(timeout) ?? 120;
  }

  static int get ragTimeout {
    const compileTime = String.fromEnvironment('RAG_TIMEOUT', defaultValue: '');
    if (compileTime.isNotEmpty) {
      return int.tryParse(compileTime) ?? 120;
    }

    final timeout = dotenv.env['RAG_TIMEOUT'] ?? '120';
    return int.tryParse(timeout) ?? 120;
  }

  // Image Analysis Configuration
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];

  // Validation
  static bool get isConfigured {
    return geminiApiKey.isNotEmpty;
  }

  static String get configStatus {
    if (!isConfigured) {
      return 'ERROR: GEMINI_API_KEY not configured. Please set it in .env file or environment variables.';
    }
    return 'Configuration loaded successfully';
  }
}
