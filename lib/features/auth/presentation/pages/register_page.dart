import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/core/theme/app_theme.dart';
import 'package:eticketing_helpdesk/core/widgets/app_widgets.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey       = GlobalKey<FormState>();
  final _nameCtrl      = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _deptCtrl      = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _deptCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).signUp(
          name:       _nameCtrl.text.trim(),
          email:      _emailCtrl.text.trim(),
          password:   _passCtrl.text,
          department: _deptCtrl.text.trim().isEmpty
              ? null
              : _deptCtrl.text.trim(),
        );

    if (!mounted) return;

    final notifier = ref.read(authProvider.notifier);
    final authState = ref.read(authProvider);

    authState.when(
      data: (user) {
        if (user != null) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        }
      },
      error: (e, _) {
        // Bedakan info (konfirmasi email) vs error
        final isInfo = notifier.isInfoMessage;
        _showSnack(notifier.errorMessage ?? e.toString(), isInfo: isInfo);
      },
      loading: () {},
    );
  }

  void _showSnack(String msg, {bool isInfo = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isInfo
          ? AppColors.statusInProgress   // biru untuk info
          : Colors.red.shade700,          // merah untuk error
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: isInfo ? 5 : 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // Teks tombol berubah sesuai fase signup
  String _buttonLabel(SignUpPhase phase) => switch (phase) {
        SignUpPhase.creatingAccount => 'Membuat akun...',
        SignUpPhase.waitingProfile  => 'Menyiapkan profil...',
        SignUpPhase.idle            => 'Daftar',
      };

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final isLoading  = ref.watch(authProvider).isLoading;
    final phase      = ref.watch(signUpPhaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Buat Akun Baru', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text('Isi data diri Anda untuk mendaftar',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 32),

              _field(controller: _nameCtrl, label: 'Nama Lengkap',
                  icon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null),
              const SizedBox(height: 16),

              _field(controller: _emailCtrl, label: 'Email',
                  icon: Icons.email_outlined,
                  type: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  }),
              const SizedBox(height: 16),

              _field(controller: _deptCtrl,
                  label: 'Departemen (opsional)',
                  icon: Icons.business_outlined),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password wajib diisi';
                  if (v.length < 6) return 'Minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (v != _passCtrl.text) return 'Password tidak cocok';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Loading state menampilkan fase yang berbeda
              ElevatedButton(
                onPressed: isLoading ? null : _onSubmit,
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 12),
                          Text(_buttonLabel(phase),
                              style: const TextStyle(color: Colors.white)),
                        ],
                      )
                    : const Text('Daftar'),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sudah punya akun?',
                      style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed:
                        isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Masuk'),
                  ),
                ],
              ),

              // Info proses signup yang butuh waktu
              if (isLoading && phase == SignUpPhase.waitingProfile)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Menyiapkan akun Anda, mohon tunggu...',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
            labelText: label, prefixIcon: Icon(icon)),
        validator: validator,
      );
}
