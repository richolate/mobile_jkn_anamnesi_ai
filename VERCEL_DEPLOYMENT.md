# 🚀 Vercel Deployment Guide

## Error yang Sering Terjadi

### Error: "No file or variants found for asset: .env"

**Penyebab:**
- File `.env` tidak ada di repository (memang sudah di `.gitignore`)
- Flutter build memerlukan file `.env` karena didefinisikan di `pubspec.yaml`
- Environment variables belum di-set di Vercel

**Solusi:**
Script `vercel-build.sh` sudah diupdate untuk membuat file `.env` otomatis dari environment variables Vercel. Anda hanya perlu:

1. ✅ Set environment variables di Vercel Dashboard
2. ✅ Redeploy project

---

## 📋 Setup Environment Variables di Vercel (WAJIB!)

### Langkah-langkah:

#### 1. Login ke Vercel Dashboard
Buka: https://vercel.com/dashboard

#### 2. Pilih Project Anda
Klik project `mobile_jkn_anamnesa_ai`

#### 3. Buka Settings → Environment Variables
Menu di sidebar kiri: **Settings** → **Environment Variables**

#### 4. Tambahkan Variabel Berikut

Klik **Add New** untuk setiap variabel:

##### Variable 1: GEMINI_API_KEY (WAJIB!)
- **Key:** `GEMINI_API_KEY`
- **Value:** `your_actual_api_key_here`
- **Environment:** ✅ Production ✅ Preview ✅ Development
- Klik **Save**

##### Variable 2: RAG_SERVER_URL
- **Key:** `RAG_SERVER_URL`
- **Value:** `https://your-rag-server.com` (atau URL server RAG Anda)
- **Environment:** ✅ Production ✅ Preview ✅ Development
- Klik **Save**

##### Variable 3: GEMINI_MODEL (Optional)
- **Key:** `GEMINI_MODEL`
- **Value:** `gemini-2.0-flash-lite`
- **Environment:** ✅ Production ✅ Preview ✅ Development
- Klik **Save**

##### Variable 4: API_TIMEOUT (Optional)
- **Key:** `API_TIMEOUT`
- **Value:** `120`
- **Environment:** ✅ Production ✅ Preview ✅ Development
- Klik **Save**

##### Variable 5: RAG_TIMEOUT (Optional)
- **Key:** `RAG_TIMEOUT`
- **Value:** `120`
- **Environment:** ✅ Production ✅ Preview ✅ Development
- Klik **Save**

#### 5. Verifikasi
Setelah semua variabel ditambahkan, Anda akan melihat list seperti ini:

```
GEMINI_API_KEY      Production, Preview, Development
RAG_SERVER_URL      Production, Preview, Development
GEMINI_MODEL        Production, Preview, Development
API_TIMEOUT         Production, Preview, Development
RAG_TIMEOUT         Production, Preview, Development
```

#### 6. Redeploy Project
**Cara 1: Via Dashboard**
- Klik **Deployments** (tab paling atas)
- Pilih deployment terakhir yang gagal
- Klik tombol **⋯** (three dots)
- Klik **Redeploy**

**Cara 2: Via Git Push**
```bash
git commit --allow-empty -m "Trigger redeploy with env vars"
git push origin master
```

**Cara 3: Via Vercel CLI**
```bash
vercel --prod
```

---

## 🔧 Cara Kerja Build Script

File `scripts/vercel-build.sh` sekarang:

1. **Membuat file `.env` otomatis** dari environment variables Vercel:
   ```bash
   cat > .env << EOF
   GEMINI_API_KEY=${GEMINI_API_KEY}
   RAG_SERVER_URL=${RAG_SERVER_URL}
   ...
   EOF
   ```

2. **Build Flutter web:**
   ```bash
   flutter build web --release
   ```

3. File `.env` yang dibuat **hanya untuk build**, tidak di-commit ke Git

---

## ✅ Verifikasi Deployment

### Check Build Logs
1. Buka **Deployments** tab
2. Klik deployment terakhir
3. Lihat **Build Logs**

**Sukses jika:**
```
✓ Creating .env file from environment variables...
✓ .env file created:
  GEMINI_API_KEY=AIzaSy...
  RAG_SERVER_URL=https://...
✓ Compiling lib/main.dart for the Web...
✓ Build completed successfully
```

**Gagal jika:**
```
✗ Error detected in pubspec.yaml:
  No file or variants found for asset: .env
```
→ Environment variables belum di-set! Kembali ke langkah 4.

### Test Website
Setelah deploy berhasil:

1. Buka URL production: `https://your-app.vercel.app`
2. Test fitur yang menggunakan Gemini AI (SoulMed, Konsultasi Anamnesis)
3. Check browser console untuk error

**Berhasil jika:**
- ✅ Website loading tanpa error
- ✅ Fitur AI berfungsi normal
- ✅ Tidak ada error di browser console

---

## 🐛 Troubleshooting

### Error: "GEMINI_API_KEY is empty"
**Penyebab:** Environment variable tidak terdeteksi

**Solusi:**
1. Pastikan nama variable PERSIS `GEMINI_API_KEY` (case-sensitive!)
2. Pastikan value tidak ada spasi di awal/akhir
3. Pastikan environment dipilih (Production/Preview/Development)
4. Redeploy setelah save

### Error: Build timeout
**Penyebab:** Build memakan waktu lama

**Solusi:**
- Flutter SDK sudah di-cache, build kedua akan lebih cepat
- Wait sampai selesai (biasanya 2-3 menit)

### Error: Still "No file found for .env"
**Penyebab:** Script belum diupdate

**Solusi:**
1. Pastikan file `scripts/vercel-build.sh` sudah terupdate
2. Check commit terakhir: `git log -1 --oneline`
3. Push ulang jika perlu

---

## 📱 Alternative: Build Lokal + Deploy Manual

Jika masih bermasalah, Anda bisa build lokal:

```bash
# Build lokal
flutter build web --release \
  --dart-define=GEMINI_API_KEY=your_key \
  --dart-define=RAG_SERVER_URL=your_url

# Deploy folder build/web ke Vercel
cd build/web
vercel --prod
```

---

## 🔐 Keamanan

### ✅ Aman:
- Environment variables di Vercel Dashboard (encrypted)
- File `.env` di-generate saat build (temporary)
- File `.env` di `.gitignore` (tidak di-commit)

### ⚠️ Jangan:
- Hardcode API key di source code
- Commit file `.env` ke Git
- Share screenshot environment variables

---

## 📞 Support

Jika masih ada masalah:

1. **Check Build Logs:**
   - Vercel Dashboard → Deployments → Click deployment → Build Logs

2. **Check Environment Variables:**
   - Settings → Environment Variables
   - Pastikan semua ada dan value benar

3. **Test Lokal:**
   ```bash
   flutter build web --release
   ```
   Jika lokal berhasil tapi Vercel gagal = masalah environment variables

4. **Regenerate API Key:**
   - Buat API key baru di https://makersuite.google.com/app/apikey
   - Update di Vercel environment variables
   - Redeploy

---

## ✅ Checklist Deployment

Sebelum deploy:

- [ ] File `scripts/vercel-build.sh` sudah diupdate
- [ ] Git push sudah dilakukan
- [ ] Environment variables sudah di-set di Vercel
- [ ] Semua 5 variabel ada (minimal GEMINI_API_KEY)
- [ ] Environment dipilih untuk Production/Preview/Development

Setelah deploy:

- [ ] Build logs menunjukkan ".env file created"
- [ ] Build completed successfully
- [ ] Website bisa diakses
- [ ] Fitur AI berfungsi
- [ ] Tidak ada error di browser console

---

## 🎉 Selesai!

Dengan setup ini:
- ✅ Environment variables tersimpan aman di Vercel
- ✅ File `.env` dibuat otomatis saat build
- ✅ Tidak perlu commit file `.env` ke Git
- ✅ Easy maintenance (ubah value di Vercel Dashboard)

**Next deployment tinggal:**
```bash
git push origin master
```

Vercel akan otomatis build ulang dengan environment variables yang sudah di-set! 🚀
