📱 E-Ticketing Helpdesk App

Aplikasi E-Ticketing Helpdesk berbasis Flutter yang digunakan untuk mengelola laporan, keluhan, dan permintaan bantuan dari user ke tim helpdesk/admin secara terstruktur dan real-time.

🚀 Tech Stack
Frontend
Flutter
Riverpod (State Management)
Material 3 UI
Backend / BaaS
Supabase
Authentication
PostgreSQL Database
Storage (File Upload)
Realtime (opsional)
🧠 Arsitektur

Project ini menggunakan pendekatan Feature-Based Architecture + Clean Separation:

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
│   └── profile/
│
└── main.dart
✨ Penjelasan
core/ → reusable (config, service, theme)
features/ → dipisah per domain (auth, ticket, dll)
data/ → model + repository (logic ke Supabase)
presentation/ → UI + state (Riverpod)
🔑 Fitur Utama
👤 Authentication
Register (Auto create profile)
Login
Logout
Reset Password
🎫 Ticket Management
Create Ticket
Upload Attachment (gambar/file)
View Ticket List
Detail Ticket
Filter & Search
Update Status (admin/helpdesk)
Assign Ticket
💬 Comment System
Tambah komentar
Internal note (khusus helpdesk)
🔔 Notification
Otomatis dibuat saat:
Ticket dibuat
Status berubah
Ada komentar baru
Berbasis database trigger (bukan manual dari Flutter)
👨‍💼 Role System
user
helpdesk
admin
🔄 Flow Sistem
User
Register → Login
Membuat ticket
Melihat status & komentar
Helpdesk/Admin
Melihat semua ticket
Assign ticket
Update status
Memberikan komentar
Sistem otomatis kirim notifikasi
🗄️ Database Design (Ringkasan)
Tabel utama:
profiles
tickets
ticket_comments
ticket_attachments
notifications
Relasi:
User → Profiles
Profiles → Tickets
Tickets → Comments & Attachments
Notifications → User
🔐 Security

Menggunakan Row Level Security (RLS) di Supabase:

User hanya bisa akses datanya sendiri
Admin/helpdesk memiliki akses lebih luas
Semua akses dikontrol via policy (bukan API key)
📦 Setup Project
1. Clone repository
git clone https://github.com/kiimalf/E-Ticketing_Helpdesk.git
cd E-Ticketing_Helpdesk
2. Install dependencies
flutter pub get
3. Setup Supabase
Buat project di Supabase
Jalankan file:
supabase_schema.sql
4. Konfigurasi environment

Isi di file:

lib/core/constants/supabase_config.dart
const supabaseUrl = 'YOUR_URL';
const supabaseAnonKey = 'YOUR_ANON_KEY';
▶️ Run Project
flutter run
🐞 Known Issues
Overflow UI pada beberapa device kecil (sedang diperbaiki)
Upload file bisa gagal jika policy storage belum sesuai
Email confirmation harus aktif / dimatikan sesuai kebutuhan
🎨 Design System
Warna
Primary: Biru (Professional & Trust)
Secondary: Abu / Netral
Status:
Open → Biru
In Progress → Orange
Resolved → Hijau
Closed → Abu
Font
Default Flutter (Material 3)
Hierarki:
Title → Bold
Subtitle → Medium
Body → Regular
UI Style
Clean
Card-based layout
Rounded corner (modern look)
Responsive (mobile-first)
🧩 State Management

Menggunakan Riverpod:

Provider → inject dependency
AsyncNotifier → handle async state (API)
Separation logic & UI
📌 Catatan Penting
Gunakan anon key Supabase (aman untuk frontend)
Jangan expose service_role key
Pastikan RLS aktif
👨‍💻 Author

Nabil Hakim Alfikri
Mahasiswa D4 Teknik Informatika
Universitas Airlangga

📜 License

Project ini dibuat untuk keperluan pembelajaran dan pengembangan akademik.
