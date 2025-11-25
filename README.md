# Mobile JKN - Aplikasi Kesehatan AI# Mobile JKN - Aplikasi Kesehatan AI# Mobile JKN - Aplikasi Kesehatan AI



> Aplikasi mobile kesehatan berbasis Flutter dengan fitur AI untuk konsultasi anamnesis dan analisis gambar medis menggunakan Google Gemini.



[![Flutter](https://img.shields.io/badge/Flutter-3.32.5-blue.svg)](https://flutter.dev/)Aplikasi mobile kesehatan berbasis Flutter dengan fitur AI untuk konsultasi anamnesis dan analisis gambar medis menggunakan Google Gemini.Aplikasi mobile kesehatan berbasis Flutter dengan fitur AI untuk konsultasi anamnesis dan analisis gambar medis menggunakan Google Gemini.

[![Dart](https://img.shields.io/badge/Dart-3.8.1-blue.svg)](https://dart.dev/)



---

## 🚀 Quick Start## 🚀 Quick Start

## 📋 Daftar Isi



- [Quick Start](#-quick-start)

- [Fitur Utama](#-fitur-utama)### Prerequisites### Prerequisites

- [Tech Stack](#️-tech-stack)

- [Struktur Project](#-struktur-project)- Flutter SDK 3.32.5+- Flutter SDK 3.32.5+

- [Build & Deploy](#-build--deploy)

- [Configuration](#-configuration)- Dart SDK 3.8.1+- Dart SDK 3.8.1+

- [Troubleshooting](#-troubleshooting)

- [Development](#-development)- Google Gemini API Key ([Dapatkan di sini](https://makersuite.google.com/app/apikey))- Google Gemini API Key ([Dapatkan di sini](https://makersuite.google.com/app/apikey))



---



## 🚀 Quick Start### Instalasi### Instalasi



### Prerequisites



- **Flutter SDK** 3.32.5 atau lebih baru```bash```bash

- **Dart SDK** 3.8.1 atau lebih baru

- **Google Gemini API Key** - [Dapatkan di sini](https://makersuite.google.com/app/apikey)# 1. Clone repository# 1. Clone repository



### Instalasigit clone <repository-url>git clone <repository-url>



```bashcd mobile_jkn_anamnesa_aicd mobile_jkn_anamnesa_ai

# 1. Clone repository

git clone https://github.com/richolate/mobile_jkn_anamnesi_ai.git

cd mobile_jkn_anamnesa_ai

# 2. Install dependencies# 2. Install dependencies

# 2. Install dependencies

flutter pub getflutter pub getflutter pub get



# 3. Setup environment variables

cp .env.example .env

# Edit .env dan isi GEMINI_API_KEY dengan API key Anda# 3. Setup environment variables# 3. Setup environment variables



# 4. Run aplikasicp .env.example .envcp .env.example .env

flutter run

```# Edit .env dan isi GEMINI_API_KEY Anda# Edit .env dan isi GEMINI_API_KEY Anda



✅ **Verifikasi:** Pastikan di console muncul `✅ Configuration loaded successfully`



---# 4. Run aplikasi# 4. Run aplikasi



## 📱 Fitur Utamaflutter runflutter run



### 1. 🤖 Anamnesa AI``````

- Konsultasi anamnesis interaktif dengan AI

- Pertanyaan dinamis berdasarkan keluhan (6-18 pertanyaan)

- Diagnosis otomatis dengan rekomendasi tindakan

- Ekspor hasil konsultasi ke PDFPastikan di console muncul: `✅ Configuration loaded successfully`Pastikan di console muncul: `✅ Configuration loaded successfully`



### 2. 🔬 Analisis Gambar Medis

- Upload gambar medis (X-ray, CT scan, MRI, dll)

- Analisis menggunakan Google Gemini Vision AI## 📱 Fitur Utama### Persiapan untuk React Integration

- Deteksi temuan normal dan abnormal

- Red flags untuk kondisi darurat

- Ekspor hasil analisis ke PDF (termasuk gambar)

### 1. Anamnesa AIAplikasi ini sudah dilengkapi dengan dependency untuk integrasi React:

### 3. 💬 SoulMed (RAG Chatbot)

- Chatbot kesehatan berbasis RAG (Retrieval-Augmented Generation)- Konsultasi anamnesis interaktif dengan AI- `webview_flutter`: WebView dasar

- Pertanyaan seputar kesehatan umum

- Riwayat pencarian tersimpan- Pertanyaan dinamis (6-18 pertanyaan)

- Integrasi dengan server RAG eksternal

- Diagnosis otomatis dengan rekomendasi- `flutter_inappwebview`: WebView advanced dengan lebih banyak kontrol

### 4. 📝 Riwayat Konsultasi

- Tab Anamnesis: Riwayat konsultasi lengkap- Ekspor hasil ke PDF

- Tab Analisis Gambar: Riwayat analisis medis

- Detail lengkap setiap konsultasi1. **Clone repository**

- Cetak ulang PDF kapan saja

- Hapus riwayat yang tidak diperlukan### 2. Analisis Gambar Medis



---- Upload gambar medis (X-ray, CT scan, MRI)```bashRencana pengembangan:



## 🛠️ Tech Stack- Analisis menggunakan Google Gemini Vision



| Kategori | Teknologi |- Deteksi temuan normal/abnormalgit clone <repository-url>1. Salah satu menu di Homepage akan menggunakan React

|----------|-----------|

| **Framework** | Flutter 3.32.5 / Dart 3.8.1 |- Ekspor hasil analisis ke PDF

| **AI Engine** | Google Generative AI (Gemini) |

| **Database (Mobile)** | SQLite |cd mobile_jkn2. Ketika menu tersebut dibuka, akan load halaman React menggunakan WebView

| **Storage (Web)** | SharedPreferences |

| **PDF Generation** | pdf package |### 3. SoulMed (RAG Chatbot)

| **Environment Config** | flutter_dotenv |

| **Image Handling** | image_picker |- Chatbot kesehatan berbasis RAG```3. React app akan dikembangkan terpisah dan di-load melalui WebView

| **HTTP Client** | http |

- Riwayat pencarian tersimpan

### Dependencies Utama



```yaml

dependencies:### 4. Riwayat Konsultasi

  google_generative_ai: ^0.2.3  # AI Gemini

  sqflite: ^2.3.0               # Database mobile- Riwayat anamnesis & analisis gambar2. **Install dependencies**## Instalasi

  shared_preferences: ^2.2.2    # Storage web

  pdf: ^3.11.1                  # Generate PDF- Detail lengkap setiap konsultasi

  flutter_dotenv: ^5.2.1        # Environment variables

  image_picker: ^1.0.7          # Upload gambar- Cetak ulang PDF```bash

  share_plus: ^10.1.2           # Share PDF

```



---## 🛠️ Tech Stackflutter pub get1. Clone repository ini



## 📂 Struktur Project



```- **Flutter** 3.32.5 / **Dart** 3.8.1```2. Install dependencies:

mobile_jkn_anamnesa_ai/

│- **google_generative_ai** - AI Gemini

├── lib/

│   ├── main.dart                           # Entry point aplikasi- **sqflite** - Database lokal (mobile)   ```bash

│   │

│   ├── models/                             # Data models- **shared_preferences** - Storage web

│   │   ├── consultation.dart

│   │   ├── image_analysis.dart- **pdf** - Generate PDF3. **Konfigurasi API Key**   flutter pub get

│   │   └── menu_item.dart

│   │- **flutter_dotenv** - Environment variables

│   ├── screens/                            # UI Screens

│   │   ├── onboarding_screen.dart          # Splash screen   ```

│   │   ├── home_screen.dart                # Homepage

│   │   ├── anamnesa_ai_screen.dart         # Menu Anamnesa AI## 📂 Struktur Project

│   │   ├── konsultasi_anamnesis_screen.dart # Konsultasi

│   │   ├── analisis_gambar_medis_screen.dart # Analisis gambarEdit file `lib/services/api_config.dart`:3. Jalankan aplikasi:

│   │   ├── soulmed_screen.dart             # RAG Chatbot

│   │   ├── riwayat_konsultasi_screen.dart  # Riwayat```

│   │   └── menu_detail_screen.dart         # Detail menu

│   │lib/```dart   ```bash

│   ├── services/                           # Business Logic

│   │   ├── api_config.dart                 # Konfigurasi API├── main.dart                    # Entry point

│   │   ├── gemini_service.dart             # Service Gemini AI

│   │   ├── database_service.dart           # Conditional export DB├── models/                      # Data modelsclass ApiConfig {   flutter run

│   │   ├── database_helper.dart            # SQLite (mobile)

│   │   ├── database_helper_web.dart        # Web fallback├── screens/                     # Semua halaman UI

│   │   ├── pdf_export.dart                 # Conditional export PDF

│   │   ├── pdf_service.dart                # PDF generator (mobile)│   ├── anamnesa_ai_screen.dart  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';   ```

│   │   └── pdf_service_web.dart            # PDF web fallback

│   ││   ├── konsultasi_anamnesis_screen.dart

│   ├── widgets/                            # Reusable Widgets

│   │   ├── menu_item_widget.dart│   ├── analisis_gambar_medis_screen.dart  static const String ragServerUrl = 'http://your-rag-server:8000';

│   │   └── news_card_widget.dart

│   ││   ├── soulmed_screen.dart

│   └── utils/                              # Utilities

│       ├── app_theme.dart                  # Theme & colors│   └── riwayat_konsultasi_screen.dart}## Struktur Folder

│       └── app_constants.dart              # Constants

│├── services/                    # Business logic

├── assets/                                 # Assets

│   ├── images/                             # Images│   ├── api_config.dart          # Konfigurasi API```

│   └── icons/                              # Icons

││   ├── gemini_service.dart      # Service Gemini AI

├── android/                                # Android config

├── ios/                                    # iOS config│   ├── database_service.dart    # Conditional export DB```

├── web/                                    # Web config

││   └── pdf_export.dart          # Conditional export PDF

├── .env                                    # Environment variables (JANGAN COMMIT!)

├── .env.example                            # Template .env├── widgets/                     # Reusable widgets4. **Run aplikasi**lib/

├── pubspec.yaml                            # Dependencies

└── README.md                               # Dokumentasi ini└── utils/                       # Utilities & constants

```

``````bash├── main.dart                 # Entry point aplikasi

---



## 📦 Build & Deploy

## 📦 Build & Deployflutter run├── models/                   # Data models

### Build untuk Android



```bash

# Debug APK (untuk testing)### Build APK```│   └── menu_item.dart

flutter build apk --debug

```bash

# Release APK (untuk production)

flutter build apk --release# Debug├── screens/                  # Screens/Pages



# Split APK per ABI (ukuran lebih kecil)flutter build apk --debug

flutter build apk --split-per-abi --release

```## 📦 Build APK│   ├── onboarding_screen.dart



📁 **Output:** `build/app/outputs/flutter-apk/`# Release



**Split APK menghasilkan:**flutter build apk --release│   ├── home_screen.dart

- `app-armeabi-v7a-release.apk` (ARM 32-bit)

- `app-arm64-v8a-release.apk` (ARM 64-bit) - **Paling umum**

- `app-x86_64-release.apk` (Intel 64-bit)

# Split per ABI (lebih kecil)### Debug APK (untuk testing)│   └── menu_detail_screen.dart

### Deploy ke Vercel (Web Platform)

flutter build apk --split-per-abi --release

**Step 1:** Set Environment Variables di [Vercel Dashboard](https://vercel.com)

`````````bash├── widgets/                  # Reusable widgets

Settings → Environment Variables → Add:

- GEMINI_API_KEY (required)

- RAG_SERVER_URL

- GEMINI_MODELAPK tersimpan di: `build/app/outputs/flutter-apk/`flutter build apk --debug│   └── menu_item_widget.dart

- API_TIMEOUT

- RAG_TIMEOUT

```

### Deploy ke Vercel (Web)```└── utils/                    # Utilities

**Step 2:** Push ke GitHub

```bash1. Set environment variables di Vercel Dashboard:

git add .

git commit -m "Deploy to Vercel"   - `GEMINI_API_KEY` (required)APK tersimpan di: `build/app/outputs/flutter-apk/app-debug.apk`    └── app_theme.dart        # Theme & Colors

git push origin master

```   - `RAG_SERVER_URL`



**Step 3:** Vercel auto-deploy menggunakan `scripts/vercel-build.sh`   - `GEMINI_MODEL`



### Platform Support2. Push ke GitHub



| Platform | Database | PDF Export | Status |3. Vercel auto-deploy menggunakan `scripts/vercel-build.sh`## 🌐 Demo via Vercel

|----------|----------|------------|--------|

| **Android** | SQLite | File I/O | ✅ Full Support |

| **iOS** | SQLite | File I/O | ✅ Full Support |

| **Web** | SharedPreferences | Blob Download | ✅ Full Support |**Platform Support:**Gunakan konfigurasi `vercel.json` dan skrip `scripts/vercel-build.sh` yang baru untuk menerbitkan build Flutter Web secara otomatis di Vercel.



> App menggunakan **conditional imports** untuk support multi-platform- ✅ Android (native dengan SQLite)



---- ✅ iOS (native dengan SQLite)### 1. Siapkan lingkungan lokal



## 🔧 Configuration- ✅ Web (SharedPreferences fallback)



### File `.env`- Pastikan Flutter Web aktif: `flutter config --enable-web`



Buat file `.env` di root project dengan isi:App menggunakan conditional imports untuk support multi-platform.- Uji build sebelum deploy:



```env

# Google Gemini API

GEMINI_API_KEY=your_gemini_api_key_here## 🔧 Configuration```bash



# RAG Server (optional)npm run build:web

RAG_SERVER_URL=http://localhost:8001

### File `.env````

# Model Configuration

GEMINI_MODEL=gemini-2.0-flash-lite```env



# Timeout Settings (seconds)GEMINI_API_KEY=your_gemini_api_keyPerintah di atas (jalan­kan via Git Bash/WSL karena memakai Bash) akan mengunduh Flutter SDK 3.32.5 (kanal stable), menandai cache `.vercel/cache/flutter-<versi>` sebagai `git safe.directory`, lalu menghasilkan artefak di `build/web`.

API_TIMEOUT=120

RAG_TIMEOUT=120RAG_SERVER_URL=http://localhost:8001

```

GEMINI_MODEL=gemini-2.0-flash-lite> ℹ️ **Catatan root & git warning**: Build di Vercel berjalan sebagai user `root`. Skrip `scripts/vercel-build.sh` sudah men-set `FLUTTER_ALLOW_ROOT=1`, `CI=true`, `FLUTTER_SUPPRESS_ANALYTICS=1`, mematikan animasi CLI, serta menjalankan `git config --global --add safe.directory <cache_flutter>`. Jadi pesan “Woah! You appear to be trying to run flutter as root” dan `fatal: detected dubious ownership` tidak lagi menghentikan build.

⚠️ **PENTING:** File `.env` sudah ada di `.gitignore` - jangan commit API key!

API_TIMEOUT=120

### Android Permissions

RAG_TIMEOUT=120### 2. Hubungkan repo ke Vercel

Sudah dikonfigurasi di `android/app/src/main/AndroidManifest.xml`:

```

```xml

<uses-permission android:name="android.permission.INTERNET" />1. Buka [vercel.com](https://vercel.com) dan pilih **Add New Project → Import Git Repository**.

<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<application android:usesCleartextTraffic="true">### Android Permissions2. Pilih repositori `mobile_jkn_anamnesi_ai` dari GitHub Anda.

```

Sudah dikonfigurasi di `AndroidManifest.xml`:3. Pada pengaturan proyek:

---

- ✅ `INTERNET` - Akses internet  - **Framework preset**: `Other`

## 🐛 Troubleshooting

- ✅ `ACCESS_NETWORK_STATE` - Status network  - **Build command**: `npm run vercel-build`

### Build Error

- ✅ `usesCleartextTraffic` - Allow HTTP  - **Output directory**: `build/web`

```bash

flutter clean  - **Install command**: biarkan default (`npm install`)

flutter pub get

flutter run## 🐛 Troubleshooting4. Tambahkan Environment Variables penting melalui tab **Settings → Environment Variables** (scope: Production + Preview):

```

   - `GEMINI_API_KEY` → isi dengan API key Google Gemini Anda

### API Error / Connection Failed

### Build Error   - `RAG_SERVER_URL` → isi dengan endpoint server RAG Anda

**Solusi:**

1. ✅ Pastikan `GEMINI_API_KEY` sudah di-set di `.env````bash   - Opsional: `FLUTTER_VERSION`, `FLUTTER_CHANNEL`, atau `FLUTTER_ARCHIVE` jika ingin mencoba build eksperimen.

2. ✅ Check koneksi internet

3. ✅ Regenerate API key jika perlu di [Google AI Studio](https://makersuite.google.com/app/apikey)flutter clean5. Klik **Deploy**. Vercel akan menjalankan skrip build dan meng-host hasilnya sebagai aplikasi web statis.



### No Internet Connection di Androidflutter pub get



**Problem:** App tidak bisa akses internet meskipun ada koneksiflutter run### 3. Kustomisasi build di Vercel



**Solusi:**```

1. Uninstall aplikasi lama

2. Build ulang: `flutter build apk --release`- Secara bawaan skrip akan mengambil Flutter `3.32.5` kanal `stable`. Override versi bila diperlukan:

3. Install APK baru ke smartphone

4. Pastikan permission `INTERNET` sudah ada di manifest### API Error



### Blank Page / Gray Screen di Web/Vercel- Pastikan `GEMINI_API_KEY` sudah di-set di `.env````bash



**Solusi:**- Check internet connectionFLUTTER_VERSION=3.33.0 FLUTTER_CHANNEL=beta npm run vercel-build

1. ✅ Set environment variables di Vercel Dashboard

2. ✅ Check browser console (F12) untuk error- Regenerate API key jika perlu```

3. ✅ Redeploy dari Vercel dashboard

4. ✅ Clear browser cache



### Gradle Build Failed### No Internet di Android- Jika Anda membutuhkan cache bersih pada Vercel, hapus folder `.vercel/cache` melalui dashboard (Project → Settings → Git → Clear Build Cache).



```bash- Uninstall app lama- Bila build gagal di langkah unduh Flutter, cukup redeploy setelah koneksi stabil; cache ~700 MB hanya perlu sekali.

cd android

./gradlew clean- Build ulang dengan permission terbaru: `flutter build apk --release`- Warning Node versi (`"engines": { "node": ">=18" }`) aman diabaikan karena runtime Vercel sudah berada di Node 18.

cd ..

flutter clean- Install APK baru

flutter pub get

flutter build apkSetelah konfigurasi ini, setiap push ke branch yang terhubung akan otomatis membangun dan menerbitkan demo web terbaru di Vercel.

```

### Blank Page di Web/Vercel

📖 **Dokumentasi lengkap:** Lihat `FIX_SUMMARY.md` untuk troubleshooting detail

- Check Vercel environment variables

---

- Check browser console (F12) untuk error### Release APK (untuk production)assets/

## 👨‍💻 Development

- Pastikan `GEMINI_API_KEY` sudah di-set di Vercel Dashboard

### Code Style

```bash├── images/                   # Images

```bash

# Format codeDokumentasi lengkap troubleshooting ada di `FIX_SUMMARY.md`

dart format .

flutter build apk --release└── icons/                    # Icons

# Analyze code

flutter analyze## 📄 Documentation



# Run tests``````

flutter test

```- **README.md** (ini) - Overview & quick start



### Commit Convention- **FIX_SUMMARY.md** - Dokumentasi fix terbaru (permission, web compatibility, security)APK tersimpan di: `build/app/outputs/flutter-apk/app-release.apk`



```- **.env.example** - Template environment variables

feat: Tambah fitur baru

fix: Perbaikan bug## Development Roadmap

refactor: Refactoring code

docs: Update dokumentasi## 👨‍💻 Development

style: Perubahan styling

perf: Performance improvement### Split APK per ABI (ukuran lebih kecil)

test: Tambah/update tests

```### Code Style



### Best Practices```bash```bash### Phase 1 (Current) ✅



- ✅ Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)# Format code

- ✅ Gunakan `const` untuk widget yang tidak berubah

- ✅ Hindari `print()` di production, gunakan loggerdart format .flutter build apk --split-per-abi --release- [x] Onboarding screen dengan animasi

- ✅ Tambahkan error handling untuk semua API calls

- ✅ Test di real device sebelum release



---# Analyze```- [x] Homepage dengan UI sesuai desain



## 📄 Dokumentasiflutter analyze



| File | Deskripsi |```Menghasilkan 3 APK:- [x] Menu grid

|------|-----------|

| `README.md` | Overview & quick start guide (file ini) |

| `FIX_SUMMARY.md` | Troubleshooting lengkap untuk issues umum |

| `.env.example` | Template environment variables |### Commit Convention- `app-armeabi-v7a-release.apk` (ARM 32-bit)- [x] Bottom navigation

| `CLEANUP_SUMMARY.md` | History cleanup dokumentasi |

```

---

feat: Tambah fitur baru- `app-arm64-v8a-release.apk` (ARM 64-bit) - **Paling umum**- [x] Basic navigation antar halaman

## 📞 Support & Contact

fix: Perbaikan bug

Untuk pertanyaan atau masalah:

refactor: Refactoring code- `app-x86_64-release.apk` (Intel 64-bit)

1. 📖 Baca dokumentasi di `FIX_SUMMARY.md`

2. 🐛 Buat [issue di GitHub](https://github.com/richolate/mobile_jkn_anamnesi_ai/issues)docs: Update dokumentasi

3. 📧 Hubungi tim developer

```### Phase 2 (Next)

---



## 📜 License

## 📞 Support### App Bundle (untuk Google Play Store)- [ ] Implementasi halaman-halaman lainnya (Berita, Kartu, FAQ, Profil)

Aplikasi ini dibuat untuk keperluan demo dan pembelajaran BPJS Kesehatan.



---

Untuk pertanyaan atau masalah:```bash- [ ] Integrasi React untuk salah satu menu

<div align="center">

1. Check `FIX_SUMMARY.md` untuk troubleshooting

**Mobile JKN** - Aplikasi Kesehatan Digital 🏥

2. Buat issue di repositoryflutter build appbundle --release- [ ] Setup WebView configuration

Made with ❤️ using Flutter



[⬆ Back to Top](#mobile-jkn---aplikasi-kesehatan-ai)

---```- [ ] React app development untuk menu tertentu

</div>



**Mobile JKN** - Aplikasi Kesehatan Digital 🏥Bundle tersimpan di: `build/app/outputs/bundle/release/app-release.aab`


### Phase 3 (Future)

## 📂 Struktur Project- [ ] API integration

- [ ] Authentication

```- [ ] Real data dari backend

mobile_jkn/- [ ] Push notifications

├── lib/- [ ] Offline mode

│   ├── main.dart                          # Entry point

│   ├── models/## Versi

│   │   └── menu_item.dart                 # Data model

│   ├── screens/**v4.14.0** - Aplikasi Peraga Demo

│   │   ├── onboarding_screen.dart         # Splash screen

│   │   ├── home_screen.dart               # Homepage## Catatan Pengembangan

│   │   ├── anamnesa_ai_screen.dart        # Menu anamnesa AI

│   │   ├── konsultasi_anamnesis_screen.dart  # Konsultasi anamnesis### React Integration Plan

│   │   ├── analisis_gambar_medis_screen.dart # Analisis gambar

│   │   ├── soulmed_screen.dart            # RAG chatbotUntuk mengintegrasikan React ke dalam salah satu menu:

│   │   ├── riwayat_konsultasi_screen.dart # Riwayat

│   │   ├── react_webview_screen.dart      # WebView untuk React1. **Develop React App** secara terpisah

│   │   └── menu_detail_screen.dart        # Detail menu lainnya2. **Build React App** untuk production

│   ├── services/3. **Host** React app (bisa local atau remote)

│   │   ├── api_config.dart                # Konfigurasi API4. **Gunakan WebView** di Flutter untuk load React app

│   │   ├── gemini_service.dart            # Service Gemini AI5. **Setup communication** antara Flutter dan React menggunakan:

│   │   ├── database_helper.dart           # SQLite helper   - JavaScript channels

│   │   ├── pdf_service.dart               # Generate PDF   - PostMessage API

│   │   └── anamnesis_questions_bank.dart  # Bank pertanyaan   - Deep linking

│   ├── widgets/

│   │   ├── menu_item_widget.dart          # Widget menu cardContoh implementasi WebView:

│   │   └── news_card_widget.dart          # Widget berita

│   └── utils/```dart

│       ├── app_theme.dart                 # Theme configimport 'package:flutter_inappwebview/flutter_inappwebview.dart';

│       └── app_constants.dart             # Constants

├── assets/class ReactMenuScreen extends StatelessWidget {

│   ├── images/                            # Gambar  @override

│   ├── icons/                             # Icons  Widget build(BuildContext context) {

│   └── mobile_jkn.webp                    # App icon    return InAppWebView(

├── android/                               # Android config      initialUrlRequest: URLRequest(

├── ios/                                   # iOS config        url: Uri.parse('http://localhost:3000'), // React app URL

└── pubspec.yaml                           # Dependencies      ),

```      onWebViewCreated: (controller) {

        // Setup communication channel

## 🔧 Konfigurasi      },

      onLoadStop: (controller, url) {

### Database        // React app loaded

SQLite database otomatis dibuat di first run dengan struktur:      },

- **consultations**: Data konsultasi anamnesis    );

- **image_analyses**: Data analisis gambar  }

- **recent_searches**: Riwayat pencarian SoulMed}

```

### Assets

Letakkan file asset di folder:## License

- `assets/images/` - Gambar (logo, ilustrasi)

- `assets/icons/` - IconsAplikasi ini dibuat untuk keperluan demo dan pembelajaran.

- `assets/icons/mobile_jkn.webp` - Icon aplikasi

## Contact

Daftarkan di `pubspec.yaml`:

```yamlUntuk pertanyaan lebih lanjut mengenai pengembangan aplikasi ini, silakan hubungi tim developer.

flutter:
  assets:
    - assets/images/
    - assets/icons/
    - assets/icons/mobile_jkn.webp
```

### App Icon
Untuk mengubah icon aplikasi, edit:
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

Atau gunakan package `flutter_launcher_icons`:
```bash
flutter pub add dev:flutter_launcher_icons
flutter pub run flutter_launcher_icons
```

## 🧪 Testing

### Run tests
```bash
flutter test
```

### Run dengan hot reload
```bash
flutter run --debug
```

## 📱 Install di Smartphone

### Cara 1: Install langsung via USB
1. Aktifkan **Developer Options** & **USB Debugging** di smartphone
2. Sambungkan smartphone ke komputer
3. Run: `flutter install`

### Cara 2: Install APK manual
1. Build APK: `flutter build apk --release`
2. Transfer file `app-release.apk` ke smartphone
3. Install APK di smartphone
4. Izinkan "Install from Unknown Sources" jika diminta

### Cara 3: Kirim APK via shareit/bluetooth
1. Build APK
2. Buka folder: `build/app/outputs/flutter-apk/`
3. Share file APK ke smartphone
4. Install di smartphone

## 🐛 Troubleshooting

### Error: Gradle build failed
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Error: API key tidak valid
Pastikan API key Gemini sudah dikonfigurasi di `lib/services/api_config.dart`

### Error: Database tidak terbuat
Uninstall aplikasi dan install ulang untuk reset database

### Performance lambat
1. Build dengan `--release` mode
2. Enable R8/ProGuard untuk minify code
3. Gunakan `--split-per-abi` untuk ukuran APK lebih kecil

## 📄 License

Aplikasi peraga untuk demo fitur BPJS Kesehatan.

## 👨‍💻 Development

### Code Style
- Gunakan `dart format` untuk formatting
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Hindari print() di production, gunakan logger

### Commit Convention
```
feat: Tambah fitur baru
fix: Perbaikan bug
refactor: Refactoring code
docs: Update dokumentasi
style: Perubahan styling
perf: Performance improvement
```

### Future Development
- [ ] Integrasi dengan backend BPJS
- [ ] Push notification
- [ ] Offline mode
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Unit tests & integration tests

## 📞 Support

Untuk pertanyaan atau masalah, silakan buat issue di repository ini.

---

**Mobile JKN** - Aplikasi Kesehatan Digital 🏥
