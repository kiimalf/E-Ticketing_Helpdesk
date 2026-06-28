import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/core/services/supabase_service.dart';
import 'package:eticketing_helpdesk/features/auth/data/models/user_model.dart';

class AuthRepository {
  // Akses auth & table melalui SupabaseService saja
  GoTrueClient get _auth => SupabaseService.auth;
  String get _table => SupabaseTables.profiles;

  // ─── Konfigurasi polling ─────────────────────────────────────
  static const int _maxRetries = 8;
  static const Duration _initialDelay = Duration(milliseconds: 300);

  // ─── Stream auth state ────────────────────────────────────────
  Stream<bool> get isSignedInStream =>
      SupabaseService.authStream.map((e) => e.session != null);

  bool get isSignedIn => SupabaseService.isSignedIn;

  // SIGN UP
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    String? department,
  }) async {
    try {
      // Langkah 1: Daftarkan user ke Supabase Auth
      // department dikirim di metadata → trigger yang baca
      final res = await _auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name.trim(),
          'role': 'user',
          // Kirim department jika ada; trigger akan NULLIF('', '') → null
          if (department != null && department.trim().isNotEmpty)
            'department': department.trim(),
        },
      );

      if (res.user == null) {
        // Bisa terjadi jika email confirmation diaktifkan di Supabase
        // dan user belum confirm email-nya
        throw const AppException(
          'Registrasi berhasil! Cek email Anda untuk konfirmasi akun.',
          isInfo: true,
        );
      }

      // Langkah 2: Tunggu trigger selesai insert ke profiles
      // Trigger berjalan async di server — jangan langsung query
      return await _waitForProfile(res.user!.id);
    } on AuthException catch (e) {
      throw AppException(_mapAuthError(e));
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Registrasi gagal: ${_cleanError(e)}');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SIGN IN
  // ─────────────────────────────────────────────────────────────
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) {
        throw const AppException('Email atau password salah.');
      }

      // fetchProfile dengan retry untuk handle cold-start / slow DB
      return await _fetchProfileWithRetry(res.user!.id);
    } on AuthException catch (e) {
      throw AppException(_mapAuthError(e));
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Login gagal: ${_cleanError(e)}');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Abaikan error saat logout — sesi lokal tetap dihapus
    }
  }

  // ─────────────────────────────────────────────────────────────
  // RESET PASSWORD
  // ─────────────────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AppException(_mapAuthError(e));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FETCH PROFILE (dengan retry)
  // ─────────────────────────────────────────────────────────────
  Future<UserModel> fetchProfile(String userId) async {
    return _fetchProfileWithRetry(userId);
  }

  Future<UserModel?> fetchCurrentProfile() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;
    try {
      return await _fetchProfileWithRetry(userId);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE PROFILE
  // ─────────────────────────────────────────────────────────────
  //
  // FIX BUG 4: build Map langsung, tidak perlu dummy UserModel
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? avatarUrl,
    String? department,
  }) async {
    // Bangun payload — hanya field yang diisi
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null && name.trim().isNotEmpty) {
      updates['name'] = name.trim();
    }
    if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl;
    }
    if (department != null) {
      // Kirim null untuk menghapus, string untuk mengisi
      updates['department'] = department.trim().isEmpty
          ? null
          : department.trim();
    }

    // Jika tidak ada yang diubah, cukup fetch ulang
    if (updates.length == 1) return fetchProfile(userId);

    try {
      final data = await SupabaseService.from(
        _table,
      ).update(updates).eq('id', userId).select().single();

      return UserModel.fromMap(data);
    } catch (e) {
      throw AppException('Gagal memperbarui profil: ${_cleanError(e)}');
    }
  }

  // PRIVATE HELPERS
  Future<UserModel> _waitForProfile(String userId) async {
    Duration delay = _initialDelay;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      // Tunggu dulu sebelum query (trigger butuh waktu)
      await Future.delayed(delay);

      try {
        final data = await SupabaseService.from(_table)
            .select()
            .eq('id', userId)
            .maybeSingle(); // maybeSingle() → null jika 0 baris, tidak throw

        if (data != null) {
          return UserModel.fromMap(data);
        }

        // Baris belum ada → naikkan delay (exponential backoff, max 2.4s)
        delay = Duration(
          milliseconds: (delay.inMilliseconds * 2).clamp(0, 2400),
        );
      } catch (e) {
        // Bisa terjadi jika RLS belum siap, atau koneksi sesaat putus
        // Log dan lanjut retry (jangan throw di sini)
        if (attempt == _maxRetries) {
          throw AppException(
            'Profil tidak bisa dibuat setelah $attempt percobaan. '
            'Coba lagi atau hubungi administrator.',
          );
        }
        delay = Duration(
          milliseconds: (delay.inMilliseconds * 2).clamp(0, 2400),
        );
      }
    }

    throw const AppException(
      'Timeout menunggu profil dibuat. '
      'Pastikan koneksi internet stabil dan coba lagi.',
    );
  }

  // ─── Retry fetch untuk signIn dan restore session ─────────────
  Future<UserModel> _fetchProfileWithRetry(String userId) async {
    const maxAttempts = 3;
    Duration delay = const Duration(milliseconds: 300);

    for (int i = 1; i <= maxAttempts; i++) {
      try {
        final data = await SupabaseService.from(_table)
            .select()
            .eq('id', userId)
            .single(); // single() — kita HARAPKAN row ada (untuk login/restore)

        return UserModel.fromMap(data);
      } catch (e) {
        if (i == maxAttempts) {
          throw AppException(
            'Gagal mengambil profil. Coba logout dan login kembali.',
          );
        }
        await Future.delayed(delay);
        delay = Duration(milliseconds: delay.inMilliseconds * 2);
      }
    }

    // Unreachable, tapi Dart membutuhkan return/throw di semua path
    throw const AppException('Gagal mengambil profil.');
  }

  // ─── Terjemahkan AuthException ke pesan bahasa Indonesia ──────
  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid email or password')) {
      return 'Email atau password salah.';
    }
    if (msg.contains('email already registered') ||
        msg.contains('user already registered')) {
      return 'Email sudah terdaftar. Gunakan email lain atau login.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek inbox Anda.';
    }
    if (msg.contains('password should be at least')) {
      return 'Password terlalu pendek. Minimal 6 karakter.';
    }
    if (msg.contains('unable to validate email address')) {
      return 'Format email tidak valid.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Tidak ada koneksi internet. Coba lagi.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa menit.';
    }

    // Fallback: kembalikan pesan asli tapi bersih
    return 'Terjadi kesalahan: ${e.message}';
  }

  // ─── Bersihkan error message dari exception umum ──────────────
  String _cleanError(Object e) {
    final raw = e.toString();
    // Buang prefix "Exception: " yang redundan
    return raw.replaceAll('Exception: ', '').trim();
  }
}

// ─────────────────────────────────────────────────────────────
// AppException — custom exception dengan flag isInfo
// isInfo=true → tampilkan sebagai info (biru), bukan error (merah)
// ─────────────────────────────────────────────────────────────
class AppException implements Exception {
  const AppException(this.message, {this.isInfo = false});

  final String message;
  final bool isInfo;

  @override
  String toString() => message;
}

// ─── Riverpod Provider ────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
