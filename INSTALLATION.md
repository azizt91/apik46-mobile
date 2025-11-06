# 📱 Instalasi & Setup APIK Mobile App

## 🔧 Prerequisites

### 1. Install Flutter SDK
```bash
# Download Flutter SDK dari:
https://docs.flutter.dev/get-started/install/windows

# Extract ke C:\flutter

# Tambahkan ke PATH:
C:\flutter\bin
```

### 2. Install Android Studio
```bash
# Download dari:
https://developer.android.com/studio

# Install Android SDK
# Install Android Emulator
```

### 3. Verifikasi Instalasi
```bash
flutter doctor
```

Output yang diharapkan:
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain
[✓] Android Studio
[✓] VS Code (optional)
[✓] Connected device
```

---

## 📦 Setup Project

### 1. Navigate ke Project Directory
```bash
cd C:\xampp\htdocs\aik46-mobile
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Konfigurasi API Base URL

Edit file `.env`:
```
API_BASE_URL=https://apikcorporation.my.id/api/mobile
API_TIMEOUT=30000
```

Atau edit `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'https://apikcorporation.my.id/api/mobile';
```

**Untuk Testing Lokal:**
- Android Emulator: `http://10.0.2.2/apik46/public/api/mobile`
- iOS Simulator: `http://localhost/apik46/public/api/mobile`
- Real Device: `http://192.168.x.x/apik46/public/api/mobile` (ganti dengan IP komputer Anda)

---

## 🚀 Running the App

### 1. Start Emulator/Device

**Android Emulator:**
```bash
# List available emulators
flutter emulators

# Start emulator
flutter emulators --launch <emulator_id>
```

**Real Device:**
- Enable USB Debugging di Settings > Developer Options
- Connect via USB
- Verify: `flutter devices`

### 2. Run App
```bash
# Run in debug mode
flutter run

# Run in release mode
flutter run --release

# Run on specific device
flutter run -d <device_id>
```

### 3. Hot Reload
Saat app running, tekan:
- `r` - Hot reload
- `R` - Hot restart
- `q` - Quit

---

## 🔨 Build APK

### Debug APK
```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Split APK (Smaller size)
```bash
flutter build apk --split-per-abi --release
```
Output:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit x86)

---

## 📱 Install APK ke Device

### Via USB
```bash
# Install debug APK
flutter install

# Install specific APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Via File Transfer
1. Copy APK ke device
2. Buka File Manager di device
3. Tap APK file
4. Allow "Install from Unknown Sources"
5. Install

---

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Run with Coverage
```bash
flutter test --coverage
```

---

## 🐛 Troubleshooting

### 1. "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### 2. "Unable to connect to API"
- Cek API Base URL di `api_config.dart`
- Pastikan server Laravel running
- Cek firewall/antivirus
- Untuk emulator, gunakan `10.0.2.2` bukan `localhost`

### 3. "Certificate verification failed"
Untuk testing dengan self-signed certificate, tambahkan di `api_service.dart`:
```dart
(_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
  client.badCertificateCallback = (cert, host, port) => true;
  return client;
};
```

### 4. "Hot reload not working"
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📁 Project Structure

```
aik46-mobile/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── config/
│   │   └── api_config.dart       # API configuration
│   ├── models/
│   │   ├── pelanggan.dart        # Pelanggan model
│   │   └── tagihan.dart          # Tagihan model
│   ├── services/
│   │   ├── api_service.dart      # API calls
│   │   └── auth_service.dart     # Auth storage
│   ├── providers/
│   │   └── auth_provider.dart    # State management
│   └── screens/
│       ├── login_screen.dart     # Login page
│       ├── dashboard_screen.dart # Dashboard
│       ├── tagihan_screen.dart   # Tagihan list
│       └── profile_screen.dart   # Profile page
├── android/                      # Android config
├── ios/                          # iOS config
├── assets/                       # Images, fonts
├── pubspec.yaml                  # Dependencies
└── .env                          # Environment variables
```

---

## 🔐 Login Credentials

Gunakan credentials pelanggan yang ada di database:

**Example:**
- Email: `copur@gmail.com`
- Password: `mdcsFbo`

---

## 📞 Support

Jika ada masalah:
1. Check `flutter doctor`
2. Check API server status
3. Check logs: `flutter logs`
4. Contact developer team

---

## 🎉 Success!

Jika semua berjalan lancar, Anda akan melihat:
1. ✅ Splash screen dengan logo APIK
2. ✅ Login screen
3. ✅ Dashboard dengan data pelanggan
4. ✅ Menu tagihan, profil, dll

**Happy Coding! 🚀**
