# Setup Environment Variables

## 🔑 Konfigurasi API Key

### 1. Setup Local Development

1. **Copy file `.env.example` menjadi `.env`:**
   ```bash
   cp .env.example .env
   ```

2. **Edit file `.env` dan masukkan API Key Anda:**
   ```env
   GEMINI_API_KEY=your_actual_api_key_here
   RAG_SERVER_URL=http://localhost:8001
   ```

3. **Dapatkan Gemini API Key:**
   - Kunjungi: https://makersuite.google.com/app/apikey
   - Login dengan akun Google
   - Klik "Create API Key"
   - Copy API key dan paste ke `.env`

### Step 2: Setup untuk Vercel Deployment

⚠️ **PENTING:** File `.env` tidak di-commit ke Git (ada di `.gitignore`), jadi Anda HARUS setup environment variables di Vercel!

#### Via Vercel Dashboard (Recommended):
1. Login ke [Vercel Dashboard](https://vercel.com/dashboard)
2. Pilih project Anda
3. Klik **Settings** → **Environment Variables**
4. Tambahkan variabel berikut (satu per satu):

| Key | Value | Environment |
|-----|-------|-------------|
| `GEMINI_API_KEY` | `AIzaSy...` (API key Anda) | Production, Preview, Development |
| `RAG_SERVER_URL` | `https://your-rag-server.com` | Production, Preview, Development |
| `GEMINI_MODEL` | `gemini-2.0-flash-lite` | Production, Preview, Development |
| `API_TIMEOUT` | `120` | Production, Preview, Development |
| `RAG_TIMEOUT` | `120` | Production, Preview, Development |

5. Klik **Save** untuk setiap variabel
6. **Redeploy** project Anda (Settings → Deployments → Redeploy)

💡 **Script build (`vercel-build.sh`) akan otomatis membuat file `.env` dari environment variables ini saat build!**

#### Via Vercel CLI:
```bash
# Set untuk production
vercel env add GEMINI_API_KEY production

# Set untuk semua environment
vercel env add GEMINI_API_KEY
```

### 3. Setup untuk Android Build

Edit file `android/app/build.gradle` dan tambahkan:

```gradle
android {
    defaultConfig {
        // ... existing config

        // Load env variables from .env file
        Properties properties = new Properties()
        if (rootProject.file(".env").exists()) {
            properties.load(rootProject.file(".env").newDataInputStream())
        }

        // Set as build config
        buildConfigField "String", "GEMINI_API_KEY", "\"${properties.getProperty('GEMINI_API_KEY', '')}\""
        buildConfigField "String", "RAG_SERVER_URL", "\"${properties.getProperty('RAG_SERVER_URL', 'http://localhost:8001')}\""
    }
}
```

Atau gunakan `--dart-define` saat build:
```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
```

### 4. Setup untuk iOS Build

Tambahkan di `ios/Runner/Info.plist`:

```xml
<key>GeminiApiKey</key>
<string>$(GEMINI_API_KEY)</string>
```

Kemudian build dengan:
```bash
flutter build ios --dart-define=GEMINI_API_KEY=your_key_here
```

## 🔒 Keamanan

### File yang TIDAK boleh di-commit ke Git:
- ✅ `.env` - Sudah ada di `.gitignore`
- ✅ `.env.local`
- ✅ `.env.production`

### File yang BOLEH di-commit:
- ✅ `.env.example` - Template tanpa API key sebenarnya

## 🧪 Testing Configuration

### Check apakah konfigurasi sudah benar:

```bash
# Run app
flutter run

# Lihat output di console:
# ✅ Configuration loaded successfully  -> Sukses
# ⚠️ WARNING: ...                       -> Ada masalah
```

### Validasi API Key:
```dart
// Di code Anda
if (ApiConfig.isConfigured) {
  print('✅ API Key configured');
} else {
  print('❌ API Key missing');
}
```

## 🐛 Troubleshooting

### Error: "GEMINI_API_KEY not configured"
**Solusi:**
1. Pastikan file `.env` ada di root project
2. Pastikan isi file benar (tidak ada typo)
3. Restart aplikasi setelah edit `.env`
4. Jalankan `flutter clean` dan `flutter pub get`

### Error: "Failed host lookup: generativelanguage.googleapis.com"
**Penyebab:** Tidak ada koneksi internet atau DNS bermasalah

**Solusi:**
1. Periksa koneksi internet
2. Coba gunakan DNS Google (8.8.8.8)
3. Restart router/modem
4. Coba gunakan mobile data jika WiFi bermasalah

### Error: "API key not valid"
**Solusi:**
1. Generate API key baru di https://makersuite.google.com/app/apikey
2. Pastikan tidak ada spasi atau karakter invisible
3. Pastikan API key untuk Gemini (bukan API key lain dari Google)

## 📱 Build untuk Production

### Android (APK):
```bash
flutter build apk --release \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
  --dart-define=RAG_SERVER_URL=$RAG_SERVER_URL
```

### Android (App Bundle):
```bash
flutter build appbundle --release \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
  --dart-define=RAG_SERVER_URL=$RAG_SERVER_URL
```

### iOS:
```bash
flutter build ios --release \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
  --dart-define=RAG_SERVER_URL=$RAG_SERVER_URL
```

### Web:
```bash
flutter build web --release \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
  --dart-define=RAG_SERVER_URL=$RAG_SERVER_URL
```

## 🌐 Environment per Platform

Anda bisa menggunakan environment variables berbeda per platform:

```dart
// lib/services/api_config.dart sudah mendukung:
// 1. File .env (priority tertinggi)
// 2. --dart-define (build time)
// 3. Default fallback values
```

## 📋 Checklist Deployment

- [ ] File `.env.example` sudah di-commit
- [ ] File `.env` TIDAK di-commit (ada di `.gitignore`)
- [ ] Environment variables sudah diset di Vercel
- [ ] Test build lokal berhasil
- [ ] Test API key valid dengan run app
- [ ] Dokumentasi sudah update

## 🔗 Referensi

- [Flutter Environment Variables](https://dart.dev/guides/environment-declarations)
- [Vercel Environment Variables](https://vercel.com/docs/concepts/projects/environment-variables)
- [Gemini API Docs](https://ai.google.dev/docs)
