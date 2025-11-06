# APIK Corporation - Mobile App

Aplikasi mobile untuk pelanggan APIK Corporation Internet Service Provider.

## 🚀 Fitur

### ✅ Sudah Diimplementasikan
- **Login Pelanggan** - Login dengan email & password
- **Dashboard** - Lihat ringkasan tagihan dan paket
- **Tagihan** - Lihat daftar tagihan (lunas & belum lunas)
- **Riwayat Pembayaran** - Lihat history pembayaran
- **WiFi Settings** - Ubah SSID & Password WiFi
- **Profile** - Lihat dan edit profil pelanggan

### 🔄 API Endpoints
Base URL: `https://apikcorporation.my.id/api/mobile`

- `POST /login` - Login pelanggan
- `GET /me` - Get user info
- `POST /logout` - Logout
- `GET /dashboard` - Dashboard data
- `GET /tagihan` - List tagihan
- `GET /tagihan/{id}` - Detail tagihan
- `GET /riwayat` - Riwayat pembayaran
- `GET /wifi` - WiFi settings
- `POST /wifi/change-ssid` - Ubah SSID
- `POST /wifi/change-password` - Ubah password WiFi

## 📱 Teknologi

Pilih salah satu framework:

### Option 1: Flutter (Recommended)
- **Framework**: Flutter 3.x
- **State Management**: Provider / Riverpod
- **HTTP Client**: Dio
- **Storage**: SharedPreferences
- **UI**: Material Design 3

### Option 2: React Native
- **Framework**: React Native
- **State Management**: Redux / Context API
- **HTTP Client**: Axios
- **Storage**: AsyncStorage
- **UI**: React Native Paper

### Option 3: Ionic + Angular
- **Framework**: Ionic 7 + Angular
- **HTTP Client**: HttpClient
- **Storage**: Ionic Storage
- **UI**: Ionic Components

## 🛠️ Setup

### Flutter
```bash
# Install Flutter SDK
# https://flutter.dev/docs/get-started/install

# Clone project
cd C:\xampp\htdocs\aik46-mobile

# Install dependencies
flutter pub get

# Run app
flutter run
```

### React Native
```bash
# Install Node.js & React Native CLI
# https://reactnative.dev/docs/environment-setup

# Install dependencies
npm install

# Run app (Android)
npx react-native run-android

# Run app (iOS)
npx react-native run-ios
```

## 📁 Struktur Project

```
aik46-mobile/
├── lib/                    # Flutter source code
│   ├── main.dart
│   ├── config/
│   │   └── api_config.dart
│   ├── models/
│   │   ├── pelanggan.dart
│   │   ├── tagihan.dart
│   │   └── paket.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   └── auth_service.dart
│   ├── providers/
│   │   └── auth_provider.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── tagihan_screen.dart
│   │   ├── riwayat_screen.dart
│   │   ├── wifi_screen.dart
│   │   └── profile_screen.dart
│   └── widgets/
│       ├── custom_button.dart
│       └── custom_textfield.dart
├── assets/
│   └── images/
├── pubspec.yaml
└── README.md
```

## 🔐 Authentication Flow

```
1. User buka app
2. Check token di local storage
3. Jika ada token → Auto login → Dashboard
4. Jika tidak ada → Login Screen
5. User input email & password
6. POST /api/mobile/login
7. Save token ke local storage
8. Navigate ke Dashboard
9. Semua request selanjutnya pakai token di header
```

## 🎨 Design System

### Colors
- Primary: `#501ee6` (Purple)
- Secondary: `#667eea` (Light Purple)
- Success: `#1cc88a` (Green)
- Danger: `#e74a3b` (Red)
- Warning: `#ffc107` (Yellow)
- Background: `#f9f8fc` (Light Gray)
- Text: `#110e1b` (Dark)

### Typography
- Font Family: Manrope, Noto Sans
- Heading: Bold, 28px
- Body: Regular, 16px
- Caption: Regular, 14px

## 📝 Environment Variables

Create `.env` file:
```
API_BASE_URL=https://apikcorporation.my.id/api/mobile
API_TIMEOUT=30000
```

## 🧪 Testing

```bash
# Flutter
flutter test

# React Native
npm test
```

## 📦 Build

### Flutter
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

### React Native
```bash
# Android
cd android && ./gradlew assembleRelease

# iOS
cd ios && xcodebuild -workspace YourApp.xcworkspace -scheme YourApp -configuration Release
```

## 📄 License

Proprietary - APIK Corporation

## 👨‍💻 Developer

APIK Corporation Development Team
