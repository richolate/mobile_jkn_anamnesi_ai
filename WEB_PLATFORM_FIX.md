# Perubahan untuk Mendukung Web Platform

## Masalah
Aplikasi mengalami error `MissingPluginException` ketika di-deploy ke Vercel karena menggunakan plugin native yang tidak didukung di web:
- `path_provider` - Untuk akses file system native
- `sqflite` - Database SQLite native
- `dart:io` - I/O operations yang spesifik untuk mobile/desktop

## Solusi
Implementasi **conditional exports** untuk memisahkan kode mobile dan web:

### 1. Database Service
**File yang dibuat:**
- `lib/services/database_helper.dart` - Implementasi SQLite untuk mobile/desktop (existing)
- `lib/services/database_helper_web.dart` - Implementasi SharedPreferences untuk web (baru)
- `lib/services/database_helper_stub.dart` - Stub interface (baru)
- `lib/services/database_service.dart` - Conditional export (baru)

**Cara kerja:**
```dart
// database_service.dart
export 'database_helper_stub.dart'
    if (dart.library.io) 'database_helper.dart'      // Mobile/Desktop
    if (dart.library.html) 'database_helper_web.dart'; // Web
```

**Perubahan di screens:**
```dart
// Sebelum
import '../services/database_helper.dart';

// Sesudah
import '../services/database_service.dart';
```

### 2. PDF Service
**File yang dibuat:**
- `lib/services/pdf_service.dart` - Implementasi dengan File I/O untuk mobile (existing)
- `lib/services/pdf_service_web.dart` - Implementasi dengan web download untuk web (baru)
- `lib/services/pdf_export.dart` - Conditional export (baru)

**Cara kerja:**
```dart
// pdf_export.dart
export 'pdf_service.dart'
    if (dart.library.html) 'pdf_service_web.dart';
```

**Perubahan di screens:**
```dart
// Sebelum
import '../services/pdf_service.dart';

// Sesudah
import '../services/pdf_export.dart';
```

### 3. Perbedaan Implementasi

#### Database (Mobile vs Web)
| Mobile/Desktop | Web |
|----------------|-----|
| SQLite database | SharedPreferences (JSON) |
| File system storage | Browser local storage |
| Relational queries | In-memory filtering |

#### PDF (Mobile vs Web)
| Mobile/Desktop | Web |
|----------------|-----|
| Save to temp directory | Download via blob |
| Share via native sheet | Browser download dialog |
| Uses path_provider | Uses dart:html |

## Testing
Untuk memastikan aplikasi berjalan dengan baik:

### Test Mobile
```bash
flutter run -d android
# atau
flutter run -d ios
```

### Test Web (Local)
```bash
flutter run -d chrome
# atau
flutter run -d edge
```

### Build Web (Production)
```bash
flutter build web --release
```

## Deploy ke Vercel
File konfigurasi `vercel.json` sudah diatur dengan benar:
```json
{
  "version": 2,
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/static-build",
      "config": {
        "distDir": "build/web"
      }
    }
  ]
}
```

Pastikan `package.json` memiliki script build:
```json
{
  "scripts": {
    "build": "flutter build web --release"
  }
}
```

## Catatan Penting
1. **Image Picker di Web**: Plugin `image_picker` memiliki implementasi web, jadi tetap bisa digunakan
2. **WebView**: `flutter_inappwebview` mungkin memerlukan konfigurasi tambahan untuk web
3. **Data Persistence**: Data di web disimpan di browser local storage, akan hilang jika user clear browser data
4. **Performance**: Web version mungkin sedikit lebih lambat karena menggunakan JSON storage

## Troubleshooting
Jika masih ada error:
1. Clear flutter cache: `flutter clean`
2. Get dependencies: `flutter pub get`
3. Build ulang: `flutter build web --release`
4. Periksa console browser untuk error JavaScript
