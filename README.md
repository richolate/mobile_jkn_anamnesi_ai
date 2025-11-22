# Mobile JKN# Mobile JKN - Aplikasi Peraga



Aplikasi mobile kesehatan berbasis Flutter dengan fitur AI untuk konsultasi anamnesis dan analisis gambar medis.Aplikasi peraga Mobile JKN untuk demo fitur BPJS Kesehatan.



## 📱 Fitur Utama## Deskripsi



### 1. Anamnesa AIMobile JKN adalah aplikasi mobile yang dikembangkan untuk memudahkan peserta BPJS Kesehatan dalam mengakses berbagai layanan kesehatannya. Aplikasi peraga ini dibuat untuk demo fitur yang akan dikembangkan lebih lanjut.

- Konsultasi anamnesis interaktif dengan AI

- Pertanyaan dinamis berdasarkan keluhan pasien (6-18 pertanyaan)## Fitur

- Input detail untuk pertanyaan tertentu

- Diagnosis otomatis dengan rekomendasi tindakan### 1. Onboarding Screen

- Ekspor hasil konsultasi ke PDF- Tampilan loading saat pertama kali membuka aplikasi

- Animasi splash screen dengan wave pattern

### 2. Analisis Gambar Medis- Logo Mobile JKN

- Upload gambar medis (X-ray, CT scan, MRI, dll)- Auto-navigate ke Homepage setelah 3 detik

- Analisis gambar menggunakan AI (Google Gemini Vision)

- Deteksi temuan normal dan abnormal### 2. Homepage

- Red flags untuk kondisi darurat- Header dengan gradient dan user info

- Rekomendasi tindakan medis- Info status kepesertaan

- Ekspor hasil analisis ke PDF (termasuk gambar)- Card "Antrean Online"

- Menu grid dengan berbagai layanan:

### 3. SoulMed (RAG Chatbot)  - Info Program JKN

- Chatbot kesehatan berbasis RAG (Retrieval-Augmented Generation)  - TELEHEALTH

- Pertanyaan seputar kesehatan umum  - Info Riwayat Pelayanan

- Riwayat pencarian tersimpan  - Bugar (Baru)

- Integrasi dengan server RAG eksternal  - NEW Rehab (Cicilan)

  - Penambahan Peserta

### 4. Riwayat Konsultasi  - Info Peserta

- Tab Anamnesis: Riwayat konsultasi anamnesis lengkap  - SOS

- Tab Analisis Gambar: Riwayat analisis gambar medis  - Info Lokasi Faskes

- Detail lengkap setiap konsultasi  - Perubahan Data Peserta (Baru)

- Cetak ulang PDF  - Pengaduan Layanan JKN

- Hapus riwayat  - Menu Lainnya

- Banner AUTODEBIT IURAN JKN-KIS

### 5. Cari Dokter Terdekat- Bottom Navigation Bar dengan 5 menu:

- Pencarian dokter berdasarkan diagnosis  - Home

- Integrasi Google Maps  - Berita

- Informasi lokasi faskes terdekat  - Kartu

  - FAQ

## 🛠 Teknologi  - Profil



### Framework### 3. Menu Detail Screen

- **Flutter** 3.32.5+- Setiap menu memiliki halaman detail

- **Dart** 3.8.1+- Sementara menampilkan judul menu saja

- Siap untuk dikembangkan lebih lanjut

### Dependencies Utama

```yaml## Teknologi

google_generative_ai: ^0.2.2    # AI (Gemini)

sqflite: ^2.3.0                 # Database lokal### Framework & Dependencies

pdf: ^3.11.1                    # Generate PDF

share_plus: ^10.1.2             # Share PDF- **Flutter**: Framework utama

image_picker: ^1.0.7            # Upload gambar- **Provider**: State management

webview_flutter: ^4.4.2         # WebView- **Google Fonts**: Typography

http: ^1.6.0                    # API calls- **WebView Flutter**: Untuk integrasi React nantinya

```- **Flutter InAppWebView**: WebView advanced untuk React integration

- **Go Router**: Navigation

## 🚀 Setup & Instalasi- **HTTP & Dio**: Network requests

- **Shared Preferences**: Local storage

### Prerequisites- **Flutter SVG**: SVG support

- Flutter SDK 3.32.5 atau lebih baru- **Intl**: Internationalization

- Dart SDK 3.8.1 atau lebih baru

- Android Studio / VS Code### Persiapan untuk React Integration

- Google Gemini API Key

Aplikasi ini sudah dilengkapi dengan dependency untuk integrasi React:

### Langkah Instalasi- `webview_flutter`: WebView dasar

- `flutter_inappwebview`: WebView advanced dengan lebih banyak kontrol

1. **Clone repository**

```bashRencana pengembangan:

git clone <repository-url>1. Salah satu menu di Homepage akan menggunakan React

cd mobile_jkn2. Ketika menu tersebut dibuka, akan load halaman React menggunakan WebView

```3. React app akan dikembangkan terpisah dan di-load melalui WebView



2. **Install dependencies**## Instalasi

```bash

flutter pub get1. Clone repository ini

```2. Install dependencies:

   ```bash

3. **Konfigurasi API Key**   flutter pub get

   ```

Edit file `lib/services/api_config.dart`:3. Jalankan aplikasi:

```dart   ```bash

class ApiConfig {   flutter run

  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';   ```

  static const String ragServerUrl = 'http://your-rag-server:8000';

}## Struktur Folder

```

```

4. **Run aplikasi**lib/

```bash├── main.dart                 # Entry point aplikasi

flutter run├── models/                   # Data models

```│   └── menu_item.dart

├── screens/                  # Screens/Pages

## 📦 Build APK│   ├── onboarding_screen.dart

│   ├── home_screen.dart

### Debug APK (untuk testing)│   └── menu_detail_screen.dart

```bash├── widgets/                  # Reusable widgets

flutter build apk --debug│   └── menu_item_widget.dart

```└── utils/                    # Utilities

APK tersimpan di: `build/app/outputs/flutter-apk/app-debug.apk`    └── app_theme.dart        # Theme & Colors



## 🌐 Demo via Vercel

Gunakan konfigurasi `vercel.json` dan skrip `scripts/vercel-build.sh` yang baru untuk menerbitkan build Flutter Web secara otomatis di Vercel.

### 1. Siapkan lingkungan lokal

- Pastikan Flutter Web aktif: `flutter config --enable-web`
- Uji build sebelum deploy:

```bash
npm run build:web
```

Perintah di atas akan mengunduh Flutter SDK (menggunakan cache `.vercel/cache` bila tersedia) dan menghasilkan artefak di `build/web`.

> ℹ️ **Catatan root warning**: Vercel menjalankan build sebagai user `root`. Skrip `scripts/vercel-build.sh` kini otomatis mengekspor `FLUTTER_ALLOW_ROOT=1`, `CI=true`, dan `FLUTTER_SUPPRESS_ANALYTICS=1` sehingga peringatan “Woah! You appear to be trying to run flutter as root” diabaikan secara aman dan proses build tetap non-interaktif.

### 2. Hubungkan repo ke Vercel

1. Buka [vercel.com](https://vercel.com) dan pilih **Add New Project → Import Git Repository**.
2. Pilih repositori `mobile_jkn_anamnesi_ai` dari GitHub Anda.
3. Pada pengaturan proyek:
  - **Framework preset**: `Other`
  - **Build command**: `npm run vercel-build`
  - **Output directory**: `build/web`
  - **Install command**: biarkan default (`npm install`)
4. Tambahkan Environment Variables penting melalui tab **Settings → Environment Variables**:
  - `GEMINI_API_KEY` → isi dengan API key Google Gemini Anda
  - `RAG_SERVER_URL` → isi dengan endpoint server RAG Anda
5. Klik **Deploy**. Vercel akan menjalankan skrip build dan meng-host hasilnya sebagai aplikasi web statis.

### 3. Kustomisasi build di Vercel

- Secara bawaan skrip akan mengambil Flutter `3.24.3` kanal `stable`. Override versi bila diperlukan:

```bash
FLUTTER_VERSION=3.27.0 FLUTTER_CHANNEL=stable npm run vercel-build
```

- Jika Anda membutuhkan cache bersih pada Vercel, hapus folder `.vercel/cache` melalui dashboard (Project → Settings → Git → Clear Build Cache).

Setelah konfigurasi ini, setiap push ke branch yang terhubung akan otomatis membangun dan menerbitkan demo web terbaru di Vercel.


### Release APK (untuk production)assets/

```bash├── images/                   # Images

flutter build apk --release└── icons/                    # Icons

``````

APK tersimpan di: `build/app/outputs/flutter-apk/app-release.apk`

## Development Roadmap

### Split APK per ABI (ukuran lebih kecil)

```bash### Phase 1 (Current) ✅

flutter build apk --split-per-abi --release- [x] Onboarding screen dengan animasi

```- [x] Homepage dengan UI sesuai desain

Menghasilkan 3 APK:- [x] Menu grid

- `app-armeabi-v7a-release.apk` (ARM 32-bit)- [x] Bottom navigation

- `app-arm64-v8a-release.apk` (ARM 64-bit) - **Paling umum**- [x] Basic navigation antar halaman

- `app-x86_64-release.apk` (Intel 64-bit)

### Phase 2 (Next)

### App Bundle (untuk Google Play Store)- [ ] Implementasi halaman-halaman lainnya (Berita, Kartu, FAQ, Profil)

```bash- [ ] Integrasi React untuk salah satu menu

flutter build appbundle --release- [ ] Setup WebView configuration

```- [ ] React app development untuk menu tertentu

Bundle tersimpan di: `build/app/outputs/bundle/release/app-release.aab`

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
