# 🔧 Perbaikan Error SocketException & Setup Environment Variables

## 📋 Ringkasan Perubahan

Telah dilakukan 2 perbaikan utama:

### 1. ✅ Migrasi API Key ke Environment Variables (.env)
- API Key sekarang disimpan di file `.env` (lebih aman)
- Mudah untuk konfigurasi berbeda per environment (dev/staging/production)
- Mudah untuk deploy ke Vercel dengan environment variables

### 2. ✅ Perbaikan Error Handling untuk Network Issues
- Menambahkan error handling yang lebih baik untuk SocketException
- Pesan error lebih user-friendly dan informatif
- Memberikan solusi konkret saat terjadi masalah koneksi

---

## 🚀 Cara Setup (PENTING!)

### Step 1: Install Dependencies
```bash
cd "path/to/mobile_jkn_anamnesa_ai"
flutter pub get
```

### Step 2: Buat File .env
File `.env` sudah dibuat otomatis dengan API key Anda. Jika belum ada:

```bash
# Copy template
cp .env.example .env

# Edit file .env dan masukkan API key
```

Isi file `.env`:
```env
GEMINI_API_KEY=AIzaSyApj6dOxpOVEA7IEDaAemhBy2vhRj7VWYU
RAG_SERVER_URL=http://localhost:8001
GEMINI_MODEL=gemini-2.0-flash-lite
API_TIMEOUT=120
RAG_TIMEOUT=120
```

### Step 3: Test Run
```bash
flutter run
```

Lihat output di console:
- ✅ **"Configuration loaded successfully"** → Berhasil!
- ⚠️ **"WARNING: GEMINI_API_KEY not configured"** → Periksa file .env

---

## 🌐 Deployment ke Vercel

⚠️ **PENTING:** Lihat dokumentasi lengkap di [VERCEL_DEPLOYMENT.md](VERCEL_DEPLOYMENT.md)

### Option 1: Via Vercel Dashboard (Recommended)

1. Login ke [Vercel Dashboard](https://vercel.com/dashboard)
2. Pilih project Anda
3. Klik **Settings** → **Environment Variables**
4. Tambahkan variabel berikut (WAJIB minimal GEMINI_API_KEY):

| Variable Name | Value | Environments |
|--------------|-------|--------------|
| `GEMINI_API_KEY` | `AIzaSy...` (API key Anda) | Production, Preview, Development |
| `RAG_SERVER_URL` | `https://your-rag-server.com` | Production, Preview, Development |
| `GEMINI_MODEL` | `gemini-2.0-flash-lite` | Production, Preview, Development |
| `API_TIMEOUT` | `120` | Production, Preview, Development |
| `RAG_TIMEOUT` | `120` | Production, Preview, Development |

5. Klik **Save** untuk setiap variabel
6. Redeploy project Anda (Deployments → Redeploy)

💡 **Script build akan otomatis membuat file `.env` dari environment variables ini!**

### Option 2: Via Vercel CLI

```bash
# Install Vercel CLI (jika belum)
npm i -g vercel

# Login
vercel login

# Set environment variables
vercel env add GEMINI_API_KEY
# Paste API key Anda: AIzaSy...

vercel env add RAG_SERVER_URL
# Paste: https://your-rag-server.com

vercel env add GEMINI_MODEL
# Paste: gemini-2.0-flash-lite

# Deploy
vercel --prod
```

### Option 3: Via vercel.json (Tidak Recommended - Kurang Aman)

Jangan simpan API key di `vercel.json` karena akan ter-commit ke Git!

---

## 📱 Build untuk Android/iOS

### Android APK:
```bash
flutter build apk --release \
  --dart-define=GEMINI_API_KEY=AIzaSy... \
  --dart-define=RAG_SERVER_URL=https://your-server.com
```

### Android App Bundle:
```bash
flutter build appbundle --release \
  --dart-define=GEMINI_API_KEY=AIzaSy... \
  --dart-define=RAG_SERVER_URL=https://your-server.com
```

### iOS:
```bash
flutter build ios --release \
  --dart-define=GEMINI_API_KEY=AIzaSy... \
  --dart-define=RAG_SERVER_URL=https://your-server.com
```

---

## 🐛 Troubleshooting Error SocketException

### Error: "Failed host lookup: generativelanguage.googleapis.com"

**Penyebab:**
- Tidak ada koneksi internet
- DNS tidak bisa resolve hostname Google
- Firewall memblokir akses
- Provider internet memblokir Google APIs

**Solusi:**

#### 1. Periksa Koneksi Internet
```bash
# Test ping
ping google.com
ping 8.8.8.8
```

#### 2. Ganti DNS ke Google DNS
**Android:**
1. Settings → Network & Internet → WiFi
2. Tap network yang aktif → Advanced
3. IP Settings: **Static**
4. DNS 1: `8.8.8.8`
5. DNS 2: `8.8.4.4`
6. Save & restart app

**iOS:**
1. Settings → WiFi
2. Tap (i) pada network aktif
3. Configure DNS: **Manual**
4. Add Server: `8.8.8.8` dan `8.8.4.4`
5. Save & restart app

#### 3. Coba Mobile Data
Jika WiFi bermasalah, coba gunakan mobile data

#### 4. Check Firewall/VPN
- Disable VPN jika ada
- Check apakah firewall memblokir akses

#### 5. Restart Device
Kadang simple restart bisa memperbaiki masalah DNS

---

## 🔒 Keamanan

### ✅ File yang SUDAH AMAN (di .gitignore):
- `.env` ← API key Anda
- `.env.local`
- `.env.production`

### ⚠️ JANGAN COMMIT:
- File `.env` dengan API key sebenarnya
- Hardcoded API key di source code

### ✅ BOLEH COMMIT:
- `.env.example` (template tanpa API key)
- Source code (karena API key sudah di-extract)

---

## 📁 File yang Dibuat/Diubah

### File Baru:
1. `.env` - Konfigurasi environment variables
2. `.env.example` - Template konfigurasi
3. `ENV_SETUP.md` - Dokumentasi setup lengkap
4. `TROUBLESHOOTING_SOCKET_ERROR.md` - Panduan troubleshooting (file ini)

### File yang Diubah:
1. `pubspec.yaml` - Menambah dependency `flutter_dotenv`
2. `lib/services/api_config.dart` - Menggunakan environment variables
3. `lib/main.dart` - Initialize dotenv saat app start
4. `lib/services/gemini_service.dart` - Error handling lebih baik
5. `.gitignore` - Menambah `.env` agar tidak ter-commit

---

## ✅ Checklist Verifikasi

Sebelum deploy, pastikan:

- [ ] File `.env` ada dan berisi API key yang valid
- [ ] Run `flutter pub get` berhasil
- [ ] Run `flutter run` tidak ada error
- [ ] Console menampilkan "✅ Configuration loaded successfully"
- [ ] Test fitur SoulMed/Konsultasi berfungsi normal
- [ ] Environment variables sudah diset di Vercel Dashboard
- [ ] File `.env` TIDAK ter-commit ke Git (check dengan `git status`)

---

## 📞 Support

Jika masih ada masalah:

1. **Check console logs** saat run aplikasi
2. **Check network connection** dengan ping/traceroute
3. **Regenerate API key** di https://makersuite.google.com/app/apikey
4. **Test dengan curl**:
   ```bash
   curl -H "Content-Type: application/json" \
        -d '{"contents":[{"parts":[{"text":"Hello"}]}]}' \
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=YOUR_API_KEY"
   ```

---

## 🎉 Selesai!

Aplikasi sekarang:
- ✅ API Key tersimpan aman di environment variables
- ✅ Mudah di-configure untuk berbagai environment
- ✅ Error handling lebih baik dengan pesan yang jelas
- ✅ Siap di-deploy ke Vercel dengan environment variables

**Next Steps:**
1. Test aplikasi di smartphone
2. Setup environment variables di Vercel
3. Deploy dan test di production

Good luck! 🚀
