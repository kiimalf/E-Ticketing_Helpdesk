import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/core/services/supabase_service.dart';
import 'package:eticketing_helpdesk/features/auth/data/models/user_model.dart';
import 'package:eticketing_helpdesk/features/auth/data/repositories/auth_repository.dart';

// ─── SharedPreferences Provider ───────────────────────────────
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPrefsProvider in main()');
});

// ─── Theme Provider ───────────────────────────────────────────
final themeProvider = NotifierProvider<ThemeNotifier, bool>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPrefsProvider).getBool(PrefKeys.isDark) ?? false;

  Future<void> toggle() async {
    state = !state;
    await ref.read(sharedPrefsProvider).setBool(PrefKeys.isDark, state);
  }
}

// ─── Auth Sign-Up Phase State ─────────────────────────────────
enum SignUpPhase {
  idle,
  creatingAccount, // sedang panggil auth.signUp()
  waitingProfile, // menunggu trigger & polling profiles
}

final signUpPhaseProvider = NotifierProvider<SignUpPhaseNotifier, SignUpPhase>(
  SignUpPhaseNotifier.new,
);

class SignUpPhaseNotifier extends Notifier<SignUpPhase> {
  @override
  SignUpPhase build() => SignUpPhase.idle;

  void setPhase(SignUpPhase phase) => state = phase;
}

// ─── Auth Provider ─────────────────────────────────────────────
final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<UserModel?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<UserModel?> build() async {
    // Restore sesi yang ada (auto-refresh token Supabase)
    if (!SupabaseService.isSignedIn) return null;

    // fetchCurrentProfile sudah handle retry internal
    // Tidak throw → kembalikan null jika gagal (user akan redirect ke login)
    return _repo.fetchCurrentProfile();
  }

  // ─── Sign In ─────────────────────────────────────────────────
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo
          .signIn(email: email, password: password)
          .then((u) => u as UserModel?),
    );
  }

  // ─── Sign Up ─────────────────────────────────────────────────
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? department,
  }) async {
    state = const AsyncLoading();

    ref
        .read(signUpPhaseProvider.notifier)
        .setPhase(SignUpPhase.creatingAccount);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (state.isLoading) {
        ref
            .read(signUpPhaseProvider.notifier)
            .setPhase(SignUpPhase.waitingProfile);
      }
    });

    state = await AsyncValue.guard(
      () => _repo
          .signUp(
            name: name,
            email: email,
            password: password,
            department: department,
          )
          .then((u) => u as UserModel?),
    );

    // Reset fase setelah selesai (sukses atau error)
    ref.read(signUpPhaseProvider.notifier).setPhase(SignUpPhase.idle);
  }

  // ─── Sign Out ─────────────────────────────────────────────────
  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncData(null);
  }

  // ─── Refresh Profile ──────────────────────────────────────────
  Future<void> refresh() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    try {
      final profile = await _repo.fetchProfile(userId);
      state = AsyncData(profile);
    } catch (_) {
      // Gagal refresh → biarkan state lama, jangan logout paksa
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────
  UserModel? get currentUser => state.value;
  bool get isAuthenticated => state.value != null;
  bool get isLoading => state.isLoading;

  /// Jika error adalah AppException.isInfo → true (bukan error merah)
  bool get isInfoMessage {
    final err = state.error;
    if (err is AppException) return err.isInfo;
    return false;
  }

  /// Pesan error yang bersih untuk ditampilkan di UI
  String? get errorMessage {
    final err = state.error;
    if (err == null) return null;
    if (err is AppException) return err.message;
    return err.toString().replaceAll('Exception: ', '');
  }
}
