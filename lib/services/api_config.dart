class ApiConfig {
  // Gemini API Key - IMPORTANT: Ganti dengan API key Anda
  // Get your API key from: https://makersuite.google.com/app/apikey
  static const String geminiApiKey =
      'AIzaSyAHKfMuktkmIk7_rjXVaiOAX8s1gBF8igU'; // GANTI DENGAN API KEY ANDA

  // RAG Server Endpoint
  // Options:
  // 1. Local development: 'http://localhost:8001'
  // 2. Cloud Run: 'https://rag-medical-api-xxxxx.run.app'
  // 3. Railway: 'https://rag-medical-api.railway.app'
  // 4. Hugging Face: 'https://huggingface.co/spaces/[user]/rag-medical/api'
  //
  // FALLBACK: If RAG server unavailable, app will use Gemini AI automatically
  static const String ragServerUrl = 'http://localhost:8001';

  // Model Configuration
  static const String geminiModel = 'gemini-2.0-flash-lite';

  // Timeouts
  static const int apiTimeout = 120; // seconds
  static const int ragTimeout = 120; // seconds

  // Image Analysis Configuration
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];
}
