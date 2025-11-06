# ⚡ Quick Start - APIK Mobile App

## 🎯 Untuk PC dengan Storage Terbatas (7GB)

Anda **TIDAK PERLU** install Flutter atau Android Studio!

---

## 📦 Yang Anda Butuhkan

1. ✅ **Git** (untuk upload ke GitHub)
2. ✅ **GitHub Account** (gratis)
3. ✅ **Android Phone** (untuk test APK)

---

## 🚀 Langkah Cepat (5 Menit)

### 1️⃣ Install Git (Jika Belum Ada)

Download: https://git-scm.com/download/win

Install dengan default settings.

---

### 2️⃣ Upload ke GitHub

Buka **Command Prompt** atau **PowerShell**:

```bash
# Masuk ke folder project
cd C:\xampp\htdocs\aik46-mobile

# Initialize git
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit"

# Login ke GitHub dan buat repository baru bernama: apik-mobile

# Add remote (ganti YOUR_USERNAME dengan username GitHub Anda)
git remote add origin https://github.com/YOUR_USERNAME/apik-mobile.git

# Push
git branch -M main
git push -u origin main
```

**Saat diminta password, gunakan Personal Access Token:**
1. GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Centang: `repo`, `workflow`
4. Copy token
5. Paste sebagai password

---

### 3️⃣ Tunggu Build Selesai

1. Buka repository di GitHub
2. Klik tab **Actions**
3. Lihat workflow "Build APK" sedang running ⏳
4. Tunggu ~5-10 menit sampai selesai ✅

---

### 4️⃣ Download APK

**Option A: Dari Releases (Recommended)**
1. Klik tab **Releases** (sidebar kanan)
2. Klik release terbaru (v1.0.1)
3. Download **app-release.apk**

**Option B: Dari Artifacts**
1. Tab **Actions** → Klik workflow yang selesai
2. Scroll ke bawah → **Artifacts**
3. Download **apik-mobile-release.zip**
4. Extract → `app-release.apk`

---

### 5️⃣ Install di Android

1. Transfer APK ke HP
2. Buka File Manager
3. Tap APK
4. Allow "Unknown Sources"
5. Install
6. Buka app
7. Login:
   - Email: `copur@gmail.com`
   - Password: `mdcsFbo`

---

## 🔄 Update Aplikasi

Setiap kali edit code:

```bash
cd C:\xampp\htdocs\aik46-mobile
git add .
git commit -m "Update fitur X"
git push
```

GitHub akan auto-build APK baru! ✨

---

## 📊 Storage Comparison

| Method | Storage Required |
|--------|------------------|
| **Install Flutter + Android Studio** | ~25GB |
| **GitHub Actions (This Method)** | ~100MB (Git only) |

**Hemat 24.9GB!** 🎉

---

## 🎨 Edit Code

Anda bisa edit code dengan:

1. **VS Code** (Lightweight, ~200MB)
   - Download: https://code.visualstudio.com
   - Install extension: Flutter, Dart

2. **Notepad++** (Super lightweight, ~10MB)
   - Download: https://notepad-plus-plus.org

3. **Online IDE: FlutLab**
   - URL: https://flutlab.io
   - Edit & build di browser
   - Tidak perlu install apapun

---

## 🐛 Troubleshooting

### Build Failed di GitHub?

1. Cek **Actions** tab → Klik workflow failed
2. Lihat error message
3. Fix error di code
4. Push lagi

### Tidak Bisa Push?

```bash
git pull origin main --rebase
git push
```

### APK Tidak Bisa Install?

- Enable "Unknown Sources" di Settings
- Atau Settings → Security → Install unknown apps → Allow

---

## 📱 Test Credentials

```
Email: copur@gmail.com
Password: mdcsFbo
```

---

## 🎉 Selesai!

Sekarang Anda punya:
- ✅ Mobile app yang bisa di-build tanpa Flutter
- ✅ Auto-build APK di GitHub
- ✅ Hemat 25GB storage
- ✅ Professional CI/CD setup

**Total waktu: 5-10 menit!** ⚡

---

## 📞 Need Help?

1. Cek `GITHUB_SETUP.md` untuk detail lengkap
2. Cek Actions logs di GitHub
3. Pastikan semua file ter-commit

**Happy Coding! 💜**
