import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Czonfig
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://duwspyezthyhixdtzztz.supabase.co';

  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String serviceRoleKey = 'YOUR_SUPABASE_SERVICE_ROLE_KEY';
}

// ─── Service ──────────────────────────────────────────────────
class SupabaseService {
  SupabaseService._();

  /// Inisialisasi — dipanggil sekali di main()
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      debug: false, // set true saat development
    );
  }

  // ─── Singleton client ───────────────────────────────────────
  static SupabaseClient get client => Supabase.instance.client;

  // ─── Auth shortcuts ─────────────────────────────────────────
  static GoTrueClient get auth => client.auth;
  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => client.auth.currentUser?.id;
  static bool get isSignedIn => client.auth.currentUser != null;
  static Stream<AuthState> get authStream => client.auth.onAuthStateChange;

  // ─── Database shortcuts ─────────────────────────────────────
  /// Shortcut ke Supabase PostgREST query builder
  static SupabaseQueryBuilder from(String table) => client.from(table);

  // ─── Storage shortcuts ───────────────────────────────────────
  static StorageFileApi bucket(String bucketName) =>
      client.storage.from(bucketName);

  /// Mengambil public URL sebuah file dari storage
  static String getPublicUrl(String bucket, String path) =>
      client.storage.from(bucket).getPublicUrl(path);
}

// ─── Riverpod Provider ────────────────────────────────────────
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService._();
});

/// Provider untuk raw SupabaseClient — digunakan di repository
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseService.client;
});
