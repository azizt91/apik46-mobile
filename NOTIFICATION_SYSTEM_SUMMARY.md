# Notification System Implementation Summary

## Overview
Sistem notifikasi in-app untuk menampilkan notifikasi tagihan dan reminder kepada pelanggan.

---

## File yang Ditambah/Diubah

### Laravel (Backend)

| File | Status | Keterangan |
|------|--------|------------|
| `apik46/database/migrations/2024_12_25_000001_create_mobile_notifications_table.php` | **BARU** | Migration untuk tabel notifikasi |
| `apik46/app/Models/MobileNotification.php` | **BARU** | Model notifikasi |
| `apik46/app/Http/Controllers/API/MobileNotificationController.php` | **BARU** | Controller untuk API notifikasi |
| `apik46/routes/api.php` | **DIUBAH** | Menambahkan routes notifikasi |
| `apik46/app/Services/TagihanService.php` | **DIUBAH** | Menambahkan pembuatan notifikasi saat tagihan dibuat |

### Flutter (Mobile App)

| File | Status | Keterangan |
|------|--------|------------|
| `lib/core/constants/api_constants.dart` | **DIUBAH** | Menambahkan endpoint notifikasi |
| `lib/data/repositories/notification_repository.dart` | **BARU** | Repository untuk API notifikasi |
| `lib/data/providers/notification_provider.dart` | **BARU** | Provider untuk state notifikasi |
| `lib/features/customer/notifications/presentation/pages/notification_page.dart` | **BARU** | Halaman daftar notifikasi |
| `lib/features/customer/dashboard/presentation/pages/customer_dashboard_page.dart` | **DIUBAH** | Menambahkan icon notifikasi dengan badge |
| `lib/core/router/app_router.dart` | **DIUBAH** | Menambahkan route notifikasi |

---

## API Endpoints Baru

| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/api/mobile/notifications` | Ambil semua notifikasi |
| GET | `/api/mobile/notifications/unread-count` | Ambil jumlah notifikasi belum dibaca |
| POST | `/api/mobile/notifications/{id}/read` | Tandai satu notifikasi sudah dibaca |
| POST | `/api/mobile/notifications/read-all` | Tandai semua notifikasi sudah dibaca |

---

## Database Schema

### Tabel: `mobile_notifications`

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| id_pelanggan | string | ID pelanggan |
| title | string | Judul notifikasi |
| body | text | Isi notifikasi |
| type | string | Tipe: info, tagihan, reminder, promo |
| data | json | Data tambahan (tagihan_id, dll) |
| is_read | boolean | Status sudah dibaca |
| read_at | timestamp | Waktu dibaca |
| created_at | timestamp | Waktu dibuat |
| updated_at | timestamp | Waktu diupdate |

---

## Langkah Setup di Server

```bash
cd ~/laravel

# Jalankan migration
/opt/alt/php82/usr/bin/php artisan migrate

# Clear cache
/opt/alt/php82/usr/bin/php artisan config:clear
/opt/alt/php82/usr/bin/php artisan cache:clear
```

---

## Fitur

1. **Icon Notifikasi dengan Badge**
   - Muncul di header dashboard
   - Menampilkan jumlah notifikasi belum dibaca
   - Badge merah dengan angka

2. **Halaman Notifikasi**
   - Daftar semua notifikasi
   - Notifikasi belum dibaca ditandai dengan dot biru
   - Tap untuk tandai sudah dibaca
   - Tombol "Tandai Semua" untuk mark all as read
   - Pull to refresh

3. **Notifikasi Otomatis**
   - Dibuat saat tagihan baru di-generate
   - (Opsional) Bisa ditambahkan untuk reminder tanggal 15/20

---

## Flow

```
Admin buat tagihan → TagihanService → 
  1. Simpan tagihan ke DB
  2. Simpan notifikasi ke mobile_notifications
  3. Kirim push notification (FCM) jika ada token

User buka app → Dashboard → 
  1. Fetch unread count
  2. Tampilkan badge di icon notifikasi

User tap icon notifikasi →
  1. Buka halaman notifikasi
  2. Fetch semua notifikasi
  3. Tap notifikasi → mark as read → badge berkurang
```
