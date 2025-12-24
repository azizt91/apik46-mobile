# Firebase Push Notification Implementation Summary

## Overview
Implementasi push notification Firebase untuk aplikasi billing ISP. Notifikasi akan dikirim saat:
1. Tagihan baru dibuat
2. Pengingat pembayaran tanggal 15 (bagi yang belum bayar)
3. Pengingat pembayaran tanggal 20 (bagi yang belum bayar)

---

## Status Implementasi

### ✅ Selesai
- Flutter: Firebase dependencies, service, dan konfigurasi
- Laravel: FCM service, controller, migration, scheduler
- GitHub Actions: Build APK dengan google-services.json dari secrets

### ⏳ Pending
- Jalankan migration di server: `/opt/alt/php82/usr/bin/php artisan migrate`
- Re-enable Firebase di `lib/main.dart` setelah dashboard fix
- Test push notification flow

### 🔧 Bug Fixes (24 Dec 2024)
1. **Token key mismatch** - Fixed: `auth_provider.dart` saves with `'token'`, `customer_repository.dart` now reads with `'token'`
2. **Null safety** - Fixed: Dashboard page now handles null data properly
3. **Debug logging** - Added: Better error messages in customer_repository.dart

---

## File yang Diubah/Ditambah

### Flutter (Mobile App)

| File | Status | Keterangan |
|------|--------|------------|
| `pubspec.yaml` | DIUBAH | Menambahkan dependencies: firebase_core, firebase_messaging, flutter_local_notifications |
| `lib/main.dart` | DIUBAH | Inisialisasi Firebase dan FirebaseNotificationService |
| `lib/config/api_config.dart` | DIUBAH | Menambahkan endpoint FCM register/unregister |
| `lib/services/firebase_notification_service.dart` | BARU | Service untuk handle push notification di Flutter |
| `lib/providers/auth_provider.dart` | DIUBAH | Integrasi FCM token registration saat login/logout |
| `android/build.gradle` | DIUBAH | Menambahkan Google Services classpath |
| `android/app/build.gradle` | DIUBAH | Menambahkan Firebase plugin dan dependencies |
| `android/app/src/main/AndroidManifest.xml` | DIUBAH | Menambahkan permission dan Firebase metadata |
| `android/app/google-services.json` | BARU | Firebase configuration untuk Android |

### Laravel (Backend)

| File | Status | Keterangan |
|------|--------|------------|
| `apik46/composer.json` | DIUBAH | Menambahkan google/apiclient untuk Firebase Admin SDK |
| `apik46/.env` | DIUBAH | Menambahkan FIREBASE_PROJECT_ID dan FIREBASE_CREDENTIALS |
| `apik46/config/services.php` | DIUBAH | Menambahkan konfigurasi Firebase |
| `apik46/routes/api.php` | DIUBAH | Menambahkan route FCM register/unregister |
| `apik46/app/Models/Pelanggan.php` | DIUBAH | Menambahkan fcm_token ke fillable |
| `apik46/app/Services/TagihanService.php` | DIUBAH | Menambahkan pengiriman notifikasi saat tagihan dibuat |
| `apik46/app/Services/FirebaseNotificationService.php` | BARU | Service untuk mengirim push notification via FCM v1 API |
| `apik46/app/Http/Controllers/API/MobileFcmController.php` | BARU | Controller untuk register/unregister FCM token |
| `apik46/app/Console/Commands/SendPaymentReminderNotification.php` | BARU | Artisan command untuk kirim reminder |
| `apik46/app/Console/Kernel.php` | DIUBAH | Menambahkan schedule untuk reminder tanggal 15 dan 20 |
| `apik46/database/migrations/2024_12_24_000001_add_fcm_token_to_pelanggan_table.php` | BARU | Migration untuk kolom fcm_token |
| `apik46/firebase-credentials.json` | BARU | Firebase Admin SDK credentials |

---

## Langkah Setup

### 1. Flutter Setup

```bash
# Di folder Flutter project
flutter pub get
```

Pastikan file `google-services.json` sudah ada di `android/app/`

### 2. Laravel Setup

```bash
# Di folder Laravel (apik46)
composer update

# Jalankan migration
php artisan migrate

# Clear cache
php artisan config:clear
php artisan cache:clear
```

### 3. Firebase Credentials

Copy file `selinggonet-push-notification-firebase-adminsdk-fbsvc-c76dee2c50.json` ke folder Laravel dan rename menjadi `firebase-credentials.json`:

```bash
# Di server hosting
cp selinggonet-push-notification-firebase-adminsdk-fbsvc-c76dee2c50.json apik46/firebase-credentials.json
```

Update `.env` dengan path yang benar:
```
FIREBASE_CREDENTIALS=/path/to/apik46/firebase-credentials.json
```

### 4. Setup Cron Job (Server)

Tambahkan cron job untuk Laravel scheduler:
```bash
* * * * * cd /path/to/apik46 && php artisan schedule:run >> /dev/null 2>&1
```

---

## API Endpoints Baru

### Register FCM Token
```
POST /api/mobile/fcm/register
Authorization: Bearer {token}
Body: { "fcm_token": "..." }
```

### Unregister FCM Token
```
POST /api/mobile/fcm/unregister
Authorization: Bearer {token}
Body: { "fcm_token": "..." }
```

---

## Artisan Commands

### Manual Test Reminder
```bash
# Test kirim reminder tanggal 15
php artisan notification:payment-reminder --date=15

# Test kirim reminder tanggal 20
php artisan notification:payment-reminder --date=20
```

---

## Flow Notifikasi

### 1. Saat Login (Flutter)
```
User Login → Get FCM Token → Register ke Backend → Token disimpan di DB
```

### 2. Saat Tagihan Dibuat (Laravel)
```
Admin Buat Tagihan → TagihanService → FirebaseNotificationService → FCM → Device User
```

### 3. Reminder Otomatis (Laravel Scheduler)
```
Tanggal 15/20 jam 08:00 → SendPaymentReminderNotification → Cek pelanggan belum bayar → Kirim notifikasi
```

---

## Catatan Penting

1. **PENTING: Daftarkan App di Firebase Console**
   - Buka https://console.firebase.google.com/project/selinggonet-push-notification/settings/general
   - Klik "Add app" → Android
   - Package name: `com.apikcorporation.mobile`
   - Download `google-services.json` yang baru dan replace file di `android/app/`

2. **google-services.json** harus ada di `android/app/` untuk Flutter
3. **firebase-credentials.json** harus ada di server Laravel dengan path yang benar di `.env`
4. Pastikan cron job sudah berjalan untuk scheduler Laravel
5. FCM token akan otomatis di-register saat user login di aplikasi Flutter
6. Notifikasi hanya dikirim ke pelanggan yang sudah install aplikasi dan login (punya FCM token)
