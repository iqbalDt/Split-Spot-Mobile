<p align="center">
  <img src="https://img.icons8.com/fluency/96/receipt-approved.png" width="80" alt="SplitSpot Logo"/>
</p>

<h1 align="center">SplitSpot</h1>

<p align="center">
  <em>Split bills, not friendships.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth-FFCA28?logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey" alt="Platform"/>
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"/>
</p>

---

## 📖 Tentang

**SplitSpot** adalah aplikasi _split bill_ berbasis Flutter yang memudahkan pembagian tagihan secara adil di antara teman, keluarga, atau rekan kerja. Aplikasi ini mendukung pembagian berdasarkan item yang dipesan masing-masing peserta, perhitungan pajak global, serta integrasi pembayaran QRIS.

---

## ✨ Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 🔐 **Autentikasi** | Login/Register dengan Email & Password, Google Sign-In, Email Verification, dan Forgot Password |
| 📋 **Buat Event** | Buat event split bill dengan nama, lokasi, tanggal, dan link Google Maps |
| 👥 **Kelola Peserta** | Tambahkan peserta dengan nama & nomor telepon, serta tentukan peran Admin (penanggung jawab) |
| 🍕 **Item-Based Splitting** | Tambahkan menu/item beserta harga, lalu assign peserta yang memesan setiap item |
| 💰 **Perhitungan Otomatis** | Perhitungan split bill otomatis dengan dukungan pajak global proporsional |
| 📱 **QRIS Payment** | Generate QRIS code untuk pembayaran digital via Xendit API |
| ✅ **Payment Tracking** | Toggle status pembayaran tiap peserta, auto-complete event saat semua sudah bayar |
| 📊 **Riwayat Event** | Lihat event yang sudah selesai di tab Activity, dengan opsi hapus (swipe-to-delete) |
| 🔔 **Notifikasi Cerdas** | Notifikasi otomatis untuk peserta yang belum membayar, dengan filter kategori dan urgency |
| 👤 **Profil Lengkap** | Edit profil, upload foto via Cloudinary, kelola rekening & e-wallet |
| 🔒 **Privasi & Keamanan** | Ubah password, hapus akun, pengaturan privasi |
| 🎨 **Premium UI** | Desain modern light-green theme dengan animasi halus dan micro-interactions |

---

## 🏗️ Arsitektur Project

```
lib/
├── main.dart                     # Entry point aplikasi
├── firebase_options.dart         # Konfigurasi Firebase (auto-generated)
│
├── models/                       # Data models & business logic
│   ├── participant_model.dart    # Model Participant & MenuItem
│   └── bill_calculator.dart      # Logika perhitungan split bill & pajak
│
├── screens/                      # UI Screens
│   ├── splash_screen.dart        # Splash screen dengan animasi
│   ├── login_screen.dart         # Login (Email + Google)
│   ├── register_screen.dart      # Registrasi akun baru
│   ├── dashboard_screen.dart     # Main dashboard dengan bottom navigation
│   ├── home_screen.dart          # Daftar event aktif
│   ├── activity_screen.dart      # Riwayat event selesai
│   ├── notification_screen.dart  # Notifikasi pembayaran
│   ├── profile_screen.dart       # Halaman profil user
│   ├── create_event_screen.dart  # Form buat event baru (Step 1)
│   ├── participants_screen.dart  # Tambah peserta (Step 2)
│   ├── items_screen.dart         # Tambah item/menu (Step 3)
│   ├── result_screen.dart        # Hasil split bill (Step 4)
│   ├── event_detail_screen.dart  # Detail event + QRIS + payment toggle
│   ├── edit_profile_screen.dart  # Edit profil user
│   ├── rekening_screen.dart      # Kelola rekening & e-wallet
│   ├── notification_settings_screen.dart  # Pengaturan notifikasi
│   ├── privacy_security_screen.dart       # Privasi & keamanan
│   └── help_support_screen.dart           # Bantuan & dukungan
│
├── services/                     # External services
│   └── cloudinary_service.dart   # Upload gambar ke Cloudinary
│
└── theme/                        # Design system
    └── app_theme.dart            # Warna, gradien, shadow, dan komponen tema
```

---

## 🔄 Alur Pembuatan Event

```
┌──────────────┐    ┌──────────────────┐    ┌──────────────┐    ┌──────────────┐
│   Step 1     │    │     Step 2       │    │   Step 3     │    │   Step 4     │
│  Detail      │───▶│  Tambah          │───▶│  Tambah      │───▶│  Hasil       │
│  Event       │    │  Peserta         │    │  Item/Menu   │    │  Split Bill  │
│              │    │                  │    │              │    │              │
│ • Nama       │    │ • Nama peserta   │    │ • Nama item  │    │ • Bill per   │
│ • Lokasi     │    │ • No. telepon    │    │ • Harga      │    │   peserta    │
│ • Tanggal    │    │ • Peran admin    │    │ • Qty        │    │ • Pajak      │
│ • Maps link  │    │                  │    │ • Assign     │    │ • Simpan     │
└──────────────┘    └──────────────────┘    └──────────────┘    └──────────────┘
```

---

## 🧮 Sistem Perhitungan Pajak

SplitSpot menggunakan **Global Tax Model** — pajak dihitung sekali di level total tagihan, bukan per item:

```
1. Subtotal    = Σ (item.price × item.quantity)
2. Tax Amount  = Subtotal × (taxPercent / 100)
3. Total       = Subtotal + Tax Amount
4. Per Peserta = (pesertaSubtotal / subtotal) × taxAmount + pesertaSubtotal
```

> Pajak didistribusikan secara proporsional berdasarkan porsi masing-masing peserta.

---

## 🛠️ Tech Stack

| Teknologi | Kegunaan |
|-----------|----------|
| **Flutter** | Framework UI cross-platform |
| **Dart** | Bahasa pemrograman |
| **Firebase Auth** | Autentikasi (Email, Google Sign-In) |
| **Cloud Firestore** | Database real-time |
| **Cloudinary** | Upload & hosting foto profil |
| **Xendit API** | Generate QRIS untuk pembayaran digital |
| **Google Fonts** | Typography (Poppins) |
| **SharedPreferences** | Penyimpanan lokal (dismissed notifications) |

---

## 🚀 Cara Menjalankan

### Prasyarat

- Flutter SDK `^3.x` terinstall ([panduan install](https://docs.flutter.dev/get-started/install))
- Akun Firebase project yang sudah dikonfigurasi
- Android Studio / VS Code

### Setup

```bash
# 1. Clone repository
git clone https://github.com/iqbalDt/Split-Spot-Mobile.git
cd Split-Spot-Mobile

# 2. Install dependencies
flutter pub get

# 3. Jalankan aplikasi
flutter run
```

### Konfigurasi Firebase

1. Buat project di [Firebase Console](https://console.firebase.google.com/)
2. Aktifkan **Authentication** (Email/Password + Google)
3. Aktifkan **Cloud Firestore**
4. Update Firestore Security Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /events/{eventId} {
      allow create: if request.auth != null;
      allow read, update, delete: if request.auth != null 
        && resource.data.createdBy == request.auth.uid;
    }
  }
}
```

5. Download `google-services.json` (Android) dan letakkan di `android/app/`
6. Jalankan `flutterfire configure` jika perlu regenerate `firebase_options.dart`

---

## 📦 Dependencies

```yaml
dependencies:
  firebase_core: ^4.7.0
  firebase_auth: ^6.4.0
  cloud_firestore: ^6.3.0
  google_sign_in: ^6.2.2
  url_launcher: ^6.3.2
  http: ^1.6.0
  image_picker: ^1.2.2
  shared_preferences: ^2.2.3
  qr_flutter: ^4.1.0
  google_fonts: ^6.1.0
```

---

## 📱 Screenshots

> _Coming soon — tambahkan screenshot aplikasi di sini._

<!--
Uncomment dan ganti path setelah menambahkan screenshot:

| Home | Detail Event | QRIS Payment |
|------|-------------|--------------|
| ![Home](screenshots/home.png) | ![Detail](screenshots/detail.png) | ![QRIS](screenshots/qris.png) |
-->

---

## 👨‍💻 Developer

**Iqbal** — [@iqbalDt](https://github.com/iqbalDt)

---

## 📄 License

Project ini dibuat untuk keperluan pribadi dan edukasi.

---

<p align="center">
  <sub>Made with ❤️ using Flutter</sub>
</p>
