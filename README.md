# 📱 E-Ticketing Helpdesk

Aplikasi helpdesk berbasis **Flutter** untuk mengelola laporan, keluhan, dan permintaan bantuan dari user ke tim helpdesk/admin secara terstruktur dan real-time.

---

## 🚀 Tech Stack

| Layer | Teknologi |
|---|---|
| Frontend | Flutter + Material 3 |
| State Management | Riverpod |
| Backend / BaaS | Supabase |
| Database | PostgreSQL (via Supabase) |
| Auth | Supabase Authentication |
| Storage | Supabase Storage |

---

## 🧠 Arsitektur

Project menggunakan pendekatan **Feature-Based Architecture** dengan pemisahan yang jelas antara layer data dan presentasi.

```
lib/
├── core/
│   ├── constants/
│   ├── services/
│   ├── theme/
│   └── widgets/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── providers/
│   │       └── widgets/
│   │
│   ├── ticket/
│   ├── dashboard/
│   ├── notification/
│   ├── profile/
│   └── settings/
│
└── main.dart
```

**Penjelasan struktur:**

- `core/` → Komponen reusable: config, service, theme
- `features/` → Dipisah per domain (auth, ticket, dll.)
- `data/` → Model + Repository (logic ke Supabase)
- `presentation/` → UI + State Management (Riverpod)

---

## 🔑 Fitur Utama

### 👤 Authentication
- Register (otomatis membuat profil)
- Login & Logout
- Reset Password

### 🎫 Ticket Management
- Buat tiket baru
- Upload lampiran (gambar/file)
- Lihat daftar tiket
- Detail tiket
- Filter & Search
- Update status tiket (admin/helpdesk)
- Assign tiket ke helpdesk

### 💬 Comment System
- Tambah komentar pada tiket
- Internal note (khusus helpdesk)

### 🔔 Notifikasi
- Otomatis dibuat via **database trigger** (bukan manual dari Flutter) saat:
  - Tiket baru dibuat
  - Status tiket berubah
  - Ada komentar baru

### 👨‍💼 Role System

| Role | Akses |
|---|---|
| `user` | Buat & pantau tiket milik sendiri |
| `helpdesk` | Lihat, assign, dan update tiket |
| `admin` | Akses penuh ke semua data |

---

## 🔄 Flow Sistem

**User:**
1. Register → Login
2. Membuat tiket
3. Memantau status & membaca komentar

**Helpdesk / Admin:**
1. Melihat semua tiket masuk
2. Assign tiket ke diri sendiri
3. Update status tiket
4. Memberikan komentar / internal note
5. Sistem otomatis mengirim notifikasi ke user

---

## 🗄️ Database Design

### Tabel Utama

| Tabel | Keterangan |
|---|---|
| `profiles` | Data profil user |
| `tickets` | Data tiket helpdesk |
| `ticket_comments` | Komentar pada tiket |
| `ticket_attachments` | Lampiran tiket |
| `notifications` | Notifikasi per user |
| `ticket_history` | Riwayat aktivitas/perubahan tiket |

### Relasi

```
User (Auth)
  └── Profiles
        └── Tickets
              ├── Ticket Comments
              └── Ticket Attachments

Notifications → User
```

---

## 🔐 Keamanan

Menggunakan **Row Level Security (RLS)** di Supabase:

- User hanya bisa mengakses data miliknya sendiri
- Admin/helpdesk memiliki akses yang lebih luas sesuai role
- Semua akses dikontrol via **policy**, bukan API key

---

## 📦 Setup & Instalasi

### 1. Clone Repository

```bash
git clone https://github.com/kiimalf/E-Ticketing_Helpdesk.git
cd E-Ticketing_Helpdesk
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Setup Supabase

- Buat project baru di [supabase.com](https://supabase.com)
- Jalankan file skema berikut di SQL Editor Supabase:

```
supabase_schema.sql
```

### 4. Konfigurasi Environment

Isi konfigurasi pada file berikut:

```
lib/core/constants/supabase_config.dart
```

```dart
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

> ⚠️ Gunakan **anon key** (aman untuk frontend). Jangan pernah expose `service_role` key.

### 5. Jalankan Aplikasi

```bash
flutter run
```

---

## 🎨 Design System

### Warna Status Tiket

| Status | Warna |
|---|---|
| Open | 🔵 Biru |
| In Progress | 🟠 Orange |
| Resolved | 🟢 Hijau |
| Closed | ⚫ Abu-abu |

### Tipografi

| Elemen | Style |
|---|---|
| Title | Bold |
| Subtitle | Medium |
| Body | Regular |

### UI Style
- Clean & minimal
- Card-based layout
- Rounded corner (modern look)
- Mobile-first & responsive

---

## 🧩 State Management

Menggunakan **Riverpod**:

- `Provider` → Inject dependency
- `AsyncNotifier` → Handle async state (API call)
- Pemisahan yang jelas antara logic dan UI

---

## 👨‍💻 Author

**Nabil Hakim Alfikri** - **434241055**
