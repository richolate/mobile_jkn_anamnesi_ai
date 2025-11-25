# Mobile JKN – AI-Powered Health Companion

A mobile health application built with **Flutter** that integrates **AI-driven anamnesis**, **medical image analysis**, and a **RAG-based health chatbot**. Designed to enhance early detection, streamline self-assessment, and support users with credible medical insights.

---

## 🚀 Quick Start

### **Prerequisites**
- Flutter SDK 3.32.5+
- Dart SDK 3.8.1+
- Google Gemini API Key — Obtain from: https://makersuite.google.com/app/apikey

### **Installation**
```bash
git clone https://github.com/richolate/mobile_jkn_anamnesi_ai.git
cd mobile_jkn_anamnesa_ai

flutter pub get

cp .env.example .env
# Insert your GEMINI_API_KEY into the .env file

flutter run
```

---

## 📱 Features

### **🤖 AI Anamnesis System**
- Smart question flow (6–18 questions)
- Automatic symptom interpretation
- Medical recommendations & red flags
- Export anamnesis result to PDF

### **🔬 Medical Image Analysis**
- Supports X-ray, MRI, CT scan, and other medical images
- Vision analysis using Google Gemini
- Abnormality detection with explanations
- PDF report generation with annotated results

### **💬 SoulMed – RAG Health Chatbot**
- Conversational Q&A with Retrieval-Augmented Generation
- Reliable health information
- Stored chat history
- Connects to custom RAG backend server

### **📝 Consultation History**
- View all previous anamnesis and medical-image analyses
- Reopen and export reports
- Delete consultation records

---

## 🛠 Tech Stack

| Category | Technology |
|---------|------------|
| Framework | Flutter 3.32.5 |
| Language | Dart 3.8.1 |
| AI Engine | Google Gemini (Text & Vision) |
| Database | SQLite (mobile) + SharedPreferences |
| PDF Engine | `pdf` package |
| Image Processing | `image_picker` |
| Environment Config | flutter_dotenv |

### Core Dependencies
```yaml
dependencies:
  google_generative_ai: ^0.2.3
  sqflite: ^2.3.0
  shared_preferences: ^2.2.2
  pdf: ^3.11.1
  flutter_dotenv: ^5.2.1
  image_picker: ^1.0.7
  share_plus: ^10.1.2
```

---

## 📂 Project Structure
```
lib/
├── main.dart
├── models/
├── screens/
├── services/
├── widgets/
└── utils/
```
A clean and modular architecture separating logic, UI, database, AI services, and helpers.

---

## 🚧 Build & Deployment

### Android
```bash
flutter build apk --release
flutter build apk --split-per-abi --release
```

### Web (Vercel-ready)
```bash
flutter build web
```

---

## 🔧 Configuration

### Environment Variables (`.env`)
```env
GEMINI_API_KEY=your_api_key_here
RAG_SERVER_URL=http://localhost:8001
GEMINI_MODEL=gemini-2.0-flash-lite
API_TIMEOUT=120
RAG_TIMEOUT=120
```
⚠️ Do **not** commit `.env` to source control.

### Android Network Permissions
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<application android:usesCleartextTraffic="true" />
```

---

## 🐛 Troubleshooting

**Build Issues**
```bash
flutter clean
flutter pub get
```

**API Errors**
- Verify API key
- Check internet connection
- Regenerate API key if necessary

**Web Issues (Vercel)**
- Ensure `.env` is configured properly
- Clear browser cache
- Check browser console logs

---

## 🧪 Development
```bash
dart format .
flutter analyze
flutter test
```

### Commit Convention
- `feat:` new feature
- `fix:` bug fix
- `refactor:` code rework
- `docs:` documentation
- `perf:` performance improvements
- `style:` UI/UX adjustments

---

## 📄 Additional Docs
- `.env.example` – Environment template
- `FIX_SUMMARY.md` – Build & version notes

---

## 📌 License
This project is licensed under the MIT License.

---

For improvements, optimizations, or a more advanced GitHub presentation (badges, release notes, CI/CD setup), feel free to request!