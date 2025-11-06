# 🚀 Setup GitHub Actions untuk Auto-Build APK

## 📋 Langkah-Langkah

### 1️⃣ **Buat Repository di GitHub**

1. Buka https://github.com
2. Klik **New Repository**
3. Nama: `apik-mobile`
4. Description: `APIK Corporation Mobile App`
5. Public atau Private (terserah)
6. **JANGAN** centang "Add README"
7. Klik **Create Repository**

---

### 2️⃣ **Upload Project ke GitHub**

Buka Command Prompt/PowerShell di folder project:

```bash
cd C:\xampp\htdocs\aik46-mobile

# Initialize git
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit - APIK Mobile App"

# Add remote (ganti USERNAME dengan username GitHub Anda)
git remote add origin https://github.com/USERNAME/apik-mobile.git

# Push ke GitHub
git branch -M main
git push -u origin main
```

**Jika diminta login:**
- Username: username GitHub Anda
- Password: gunakan **Personal Access Token** (bukan password biasa)

**Cara buat Personal Access Token:**
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token
3. Centang: `repo`, `workflow`
4. Copy token dan simpan (hanya muncul sekali!)
5. Gunakan token sebagai password saat push

---

### 3️⃣ **GitHub Actions Akan Otomatis Build**

Setelah push, GitHub Actions akan otomatis:
1. ✅ Setup Flutter
2. ✅ Install dependencies
3. ✅ Build APK release
4. ✅ Upload APK sebagai artifact
5. ✅ Create release dengan APK

**Cek progress:**
1. Buka repository di GitHub
2. Klik tab **Actions**
3. Lihat workflow "Build APK" sedang running
4. Tunggu ~5-10 menit

---

### 4️⃣ **Download APK**

#### **Option A: Dari Artifacts (Setiap Build)**
1. Buka tab **Actions**
2. Klik workflow yang sudah selesai (✅ hijau)
3. Scroll ke bawah → **Artifacts**
4. Download **apik-mobile-release.zip**
5. Extract → `app-release.apk`

#### **Option B: Dari Releases (Otomatis)**
1. Buka tab **Releases** (di sidebar kanan)
2. Klik release terbaru (v1.0.1, v1.0.2, dst)
3. Download **app-release.apk** langsung
4. Install ke Android device

---

### 5️⃣ **Install APK ke Android**

1. Transfer APK ke HP Android
2. Buka File Manager
3. Tap file APK
4. Allow "Install from Unknown Sources" jika diminta
5. Install
6. Buka app
7. Login dengan credentials pelanggan

---

## 🔄 Update Aplikasi

Setiap kali Anda ubah code:

```bash
cd C:\xampp\htdocs\aik46-mobile

# Add changes
git add .

# Commit
git commit -m "Update: deskripsi perubahan"

# Push
git push
```

GitHub Actions akan otomatis build APK baru! ✨

---

## 🎯 Keuntungan Metode Ini

✅ **Tidak perlu install Flutter** di PC Anda  
✅ **Tidak perlu Android Studio** (hemat 20GB+)  
✅ **Auto-build** setiap push  
✅ **APK tersedia di GitHub** untuk download  
✅ **Versioning otomatis** (v1.0.1, v1.0.2, dst)  
✅ **Gratis** (GitHub Actions free untuk public repo)  
✅ **CI/CD professional** seperti perusahaan besar  

---

## 📱 Alternative: Online Flutter IDE

Jika ingin edit code tanpa install Flutter:

### **1. DartPad (Online)**
- URL: https://dartpad.dev
- Untuk testing Dart code
- Tidak bisa build APK

### **2. FlutLab (Online Flutter IDE)**
- URL: https://flutlab.io
- Full Flutter IDE di browser
- Bisa build APK online
- Free tier available

### **3. Codemagic (CI/CD)**
- URL: https://codemagic.io
- Alternative GitHub Actions
- Free tier: 500 build minutes/month

---

## 🐛 Troubleshooting

### **Build Failed di GitHub Actions**

1. **Cek Logs:**
   - Actions tab → Klik workflow yang failed
   - Klik job "build"
   - Lihat error message

2. **Common Issues:**
   - ❌ `pubspec.yaml` error → Fix dependencies
   - ❌ Dart version mismatch → Update Flutter version di workflow
   - ❌ Build timeout → Code terlalu besar

### **Tidak Bisa Push ke GitHub**

```bash
# Jika error "failed to push"
git pull origin main --rebase
git push
```

### **Token Expired**

Generate token baru di GitHub Settings → Developer settings

---

## 📊 Build Status Badge

Tambahkan badge di README.md:

```markdown
![Build APK](https://github.com/USERNAME/apik-mobile/workflows/Build%20APK/badge.svg)
```

Ganti `USERNAME` dengan username GitHub Anda.

---

## 🎉 Selesai!

Sekarang Anda bisa:
1. ✅ Edit code di PC (tanpa Flutter)
2. ✅ Push ke GitHub
3. ✅ GitHub auto-build APK
4. ✅ Download APK dari Releases
5. ✅ Install di Android
6. ✅ Test aplikasi

**Hemat 20GB+ storage di PC Anda!** 🚀

---

## 📞 Support

Jika ada masalah:
1. Cek Actions logs di GitHub
2. Cek file `.github/workflows/build-apk.yml`
3. Pastikan semua file sudah ter-commit
4. Cek internet connection

**Happy Coding! 💜**
