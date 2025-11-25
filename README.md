# Mobile JKN - Aplikasi Kesehatan AI# Mobile JKN - Aplikasi Kesehatan AI



Aplikasi mobile kesehatan berbasis Flutter dengan fitur AI untuk konsultasi anamnesis dan analisis gambar medis menggunakan Google Gemini.Aplikasi mobile kesehatan berbasis Flutter dengan fitur AI untuk konsultasi anamnesis dan analisis gambar medis menggunakan Google Gemini.



## 🚀 Quick Start## 🚀 Quick Start



### Prerequisites### Prerequisites

- Flutter SDK 3.32.5+- Flutter SDK 3.32.5+

- Dart SDK 3.8.1+- Dart SDK 3.8.1+

- Google Gemini API Key ([Dapatkan di sini](https://makersuite.google.com/app/apikey))- Google Gemini API Key ([Dapatkan di sini](https://makersuite.google.com/app/apikey))



### Instalasi### Instalasi



```bash```bash

# 1. Clone repository# 1. Clone repository

git clone <repository-url>git clone <repository-url>

cd mobile_jkn_anamnesa_aicd mobile_jkn_anamnesa_ai



# 2. Install dependencies# 2. Install dependencies

flutter pub getflutter pub get



# 3. Setup environment variables# 3. Setup environment variables

cp .env.example .envcp .env.example .env

# Edit .env dan isi GEMINI_API_KEY Anda# Edit .env dan isi GEMINI_API_KEY Anda



# 4. Run aplikasi# 4. Run aplikasi

flutter runflutter run

``````



Pastikan di console muncul: `✅ Configuration loaded successfully`Pastikan di console muncul: `✅ Configuration loaded successfully`



## 📱 Fitur Utama### Persiapan untuk React Integration



### 1. Anamnesa AIAplikasi ini sudah dilengkapi dengan dependency untuk integrasi React:

- Konsultasi anamnesis interaktif dengan AI- `webview_flutter`: WebView dasar

- Pertanyaan dinamis (6-18 pertanyaan)

- Diagnosis otomatis dengan rekomendasi- `flutter_inappwebview`: WebView advanced dengan lebih banyak kontrol

- Ekspor hasil ke PDF

1. **Clone repository**

### 2. Analisis Gambar Medis

- Upload gambar medis (X-ray, CT scan, MRI)```bashRencana pengembangan:

- Analisis menggunakan Google Gemini Vision

- Deteksi temuan normal/abnormalgit clone <repository-url>1. Salah satu menu di Homepage akan menggunakan React

- Ekspor hasil analisis ke PDF

cd mobile_jkn2. Ketika menu tersebut dibuka, akan load halaman React menggunakan WebView

### 3. SoulMed (RAG Chatbot)

- Chatbot kesehatan berbasis RAG```3. React app akan dikembangkan terpisah dan di-load melalui WebView

- Riwayat pencarian tersimpan



### 4. Riwayat Konsultasi

- Riwayat anamnesis & analisis gambar2. **Install dependencies**## Instalasi

- Detail lengkap setiap konsultasi

- Cetak ulang PDF```bash



## 🛠️ Tech Stackflutter pub get1. Clone repository ini



- **Flutter** 3.32.5 / **Dart** 3.8.1```2. Install dependencies:

- **google_generative_ai** - AI Gemini

- **sqflite** - Database lokal (mobile)   ```bash

- **shared_preferences** - Storage web

- **pdf** - Generate PDF3. **Konfigurasi API Key**   flutter pub get

- **flutter_dotenv** - Environment variables

   ```

## 📂 Struktur Project

Edit file `lib/services/api_config.dart`:3. Jalankan aplikasi:

```

lib/```dart   ```bash

├── main.dart                    # Entry point

├── models/                      # Data modelsclass ApiConfig {   flutter run

├── screens/                     # Semua halaman UI

│   ├── anamnesa_ai_screen.dart  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';   ```

│   ├── konsultasi_anamnesis_screen.dart

│   ├── analisis_gambar_medis_screen.dart  static const String ragServerUrl = 'http://your-rag-server:8000';

│   ├── soulmed_screen.dart

│   └── riwayat_konsultasi_screen.dart}## Struktur Folder

├── services/                    # Business logic

│   ├── api_config.dart          # Konfigurasi API```

│   ├── gemini_service.dart      # Service Gemini AI

│   ├── database_service.dart    # Conditional export DB```

│   └── pdf_export.dart          # Conditional export PDF

├── widgets/                     # Reusable widgets4. **Run aplikasi**lib/

└── utils/                       # Utilities & constants

``````bash├── main.dart                 # Entry point aplikasi



## 📦 Build & Deployflutter run├── models/                   # Data models



### Build APK```│   └── menu_item.dart

```bash

# Debug├── screens/                  # Screens/Pages

flutter build apk --debug

## 📦 Build APK│   ├── onboarding_screen.dart

# Release

flutter build apk --release│   ├── home_screen.dart



# Split per ABI (lebih kecil)### Debug APK (untuk testing)│   └── menu_detail_screen.dart

flutter build apk --split-per-abi --release

``````bash├── widgets/                  # Reusable widgets



APK tersimpan di: `build/app/outputs/flutter-apk/`flutter build apk --debug│   └── menu_item_widget.dart



### Deploy ke Vercel (Web)```└── utils/                    # Utilities

1. Set environment variables di Vercel Dashboard:

   - `GEMINI_API_KEY` (required)APK tersimpan di: `build/app/outputs/flutter-apk/app-debug.apk`    └── app_theme.dart        # Theme & Colors

   - `RAG_SERVER_URL`

   - `GEMINI_MODEL`

2. Push ke GitHub

3. Vercel auto-deploy menggunakan `scripts/vercel-build.sh`## 🌐 Demo via Vercel



**Platform Support:**Gunakan konfigurasi `vercel.json` dan skrip `scripts/vercel-build.sh` yang baru untuk menerbitkan build Flutter Web secara otomatis di Vercel.

- ✅ Android (native dengan SQLite)

- ✅ iOS (native dengan SQLite)### 1. Siapkan lingkungan lokal

- ✅ Web (SharedPreferences fallback)

- Pastikan Flutter Web aktif: `flutter config --enable-web`

App menggunakan conditional imports untuk support multi-platform.- Uji build sebelum deploy:



## 🔧 Configuration```bash

npm run build:web

### File `.env````

```env

GEMINI_API_KEY=your_gemini_api_keyPerintah di atas (jalan­kan via Git Bash/WSL karena memakai Bash) akan mengunduh Flutter SDK 3.32.5 (kanal stable), menandai cache `.vercel/cache/flutter-<versi>` sebagai `git safe.directory`, lalu menghasilkan artefak di `build/web`.

RAG_SERVER_URL=http://localhost:8001

GEMINI_MODEL=gemini-2.0-flash-lite> ℹ️ **Catatan root & git warning**: Build di Vercel berjalan sebagai user `root`. Skrip `scripts/vercel-build.sh` sudah men-set `FLUTTER_ALLOW_ROOT=1`, `CI=true`, `FLUTTER_SUPPRESS_ANALYTICS=1`, mematikan animasi CLI, serta menjalankan `git config --global --add safe.directory <cache_flutter>`. Jadi pesan “Woah! You appear to be trying to run flutter as root” dan `fatal: detected dubious ownership` tidak lagi menghentikan build.

API_TIMEOUT=120

RAG_TIMEOUT=120### 2. Hubungkan repo ke Vercel

```

1. Buka [vercel.com](https://vercel.com) dan pilih **Add New Project → Import Git Repository**.

### Android Permissions2. Pilih repositori `mobile_jkn_anamnesi_ai` dari GitHub Anda.

Sudah dikonfigurasi di `AndroidManifest.xml`:3. Pada pengaturan proyek:

- ✅ `INTERNET` - Akses internet  - **Framework preset**: `Other`

- ✅ `ACCESS_NETWORK_STATE` - Status network  - **Build command**: `npm run vercel-build`

- ✅ `usesCleartextTraffic` - Allow HTTP  - **Output directory**: `build/web`

  - **Install command**: biarkan default (`npm install`)

## 🐛 Troubleshooting4. Tambahkan Environment Variables penting melalui tab **Settings → Environment Variables** (scope: Production + Preview):

   - `GEMINI_API_KEY` → isi dengan API key Google Gemini Anda

### Build Error   - `RAG_SERVER_URL` → isi dengan endpoint server RAG Anda

```bash   - Opsional: `FLUTTER_VERSION`, `FLUTTER_CHANNEL`, atau `FLUTTER_ARCHIVE` jika ingin mencoba build eksperimen.

flutter clean5. Klik **Deploy**. Vercel akan menjalankan skrip build dan meng-host hasilnya sebagai aplikasi web statis.

flutter pub get

flutter run### 3. Kustomisasi build di Vercel

```

- Secara bawaan skrip akan mengambil Flutter `3.32.5` kanal `stable`. Override versi bila diperlukan:

### API Error

- Pastikan `GEMINI_API_KEY` sudah di-set di `.env````bash

- Check internet connectionFLUTTER_VERSION=3.33.0 FLUTTER_CHANNEL=beta npm run vercel-build

- Regenerate API key jika perlu```



### No Internet di Android- Jika Anda membutuhkan cache bersih pada Vercel, hapus folder `.vercel/cache` melalui dashboard (Project → Settings → Git → Clear Build Cache).

- Uninstall app lama- Bila build gagal di langkah unduh Flutter, cukup redeploy setelah koneksi stabil; cache ~700 MB hanya perlu sekali.

- Build ulang dengan permission terbaru: `flutter build apk --release`- Warning Node versi (`"engines": { "node": ">=18" }`) aman diabaikan karena runtime Vercel sudah berada di Node 18.

- Install APK baru

Setelah konfigurasi ini, setiap push ke branch yang terhubung akan otomatis membangun dan menerbitkan demo web terbaru di Vercel.

### Blank Page di Web/Vercel

- Check Vercel environment variables

- Check browser console (F12) untuk error### Release APK (untuk production)assets/

- Pastikan `GEMINI_API_KEY` sudah di-set di Vercel Dashboard

```bash├── images/                   # Images

Dokumentasi lengkap troubleshooting ada di `FIX_SUMMARY.md`

flutter build apk --release└── icons/                    # Icons

## 📄 Documentation

``````

- **README.md** (ini) - Overview & quick start

- **FIX_SUMMARY.md** - Dokumentasi fix terbaru (permission, web compatibility, security)APK tersimpan di: `build/app/outputs/flutter-apk/app-release.apk`

- **.env.example** - Template environment variables

## Development Roadmap

## 👨‍💻 Development

### Split APK per ABI (ukuran lebih kecil)

### Code Style

```bash```bash### Phase 1 (Current) ✅

# Format code

dart format .flutter build apk --split-per-abi --release- [x] Onboarding screen dengan animasi



# Analyze```- [x] Homepage dengan UI sesuai desain

flutter analyze

```Menghasilkan 3 APK:- [x] Menu grid



### Commit Convention- `app-armeabi-v7a-release.apk` (ARM 32-bit)- [x] Bottom navigation

```

feat: Tambah fitur baru- `app-arm64-v8a-release.apk` (ARM 64-bit) - **Paling umum**- [x] Basic navigation antar halaman

fix: Perbaikan bug

refactor: Refactoring code- `app-x86_64-release.apk` (Intel 64-bit)

docs: Update dokumentasi

```### Phase 2 (Next)



## 📞 Support### App Bundle (untuk Google Play Store)- [ ] Implementasi halaman-halaman lainnya (Berita, Kartu, FAQ, Profil)



Untuk pertanyaan atau masalah:```bash- [ ] Integrasi React untuk salah satu menu

1. Check `FIX_SUMMARY.md` untuk troubleshooting

2. Buat issue di repositoryflutter build appbundle --release- [ ] Setup WebView configuration



---```- [ ] React app development untuk menu tertentu



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
