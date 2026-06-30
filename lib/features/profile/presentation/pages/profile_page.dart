import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/core/theme/app_theme.dart';

import 'package:eticketing_helpdesk/features/auth/data/repositories/auth_repository.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/providers/auth_provider.dart';
import 'package:eticketing_helpdesk/features/ticket/presentation/providers/ticket_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  // ─── Dialog konfirmasi logout ─────────────────────────────
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  // ─── Dialog reset password ────────────────────────────────
  void _showResetPasswordDialog(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _ResetPasswordDialog(email: email),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final isDark = ref.watch(themeProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final initials = user.name
        .trim()
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header Profil ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage:
                        (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Nama
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Email
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Departemen (opsional)
                  if (user.department != null &&
                      user.department!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      user.department!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // ── Stats Row ─────────────────────────────────
            statsAsync.maybeWhen(
              data: (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    _statItem(context, '${s.total}', 'Total'),
                    _divLine(),
                    _statItem(context, '${s.open}', 'Open'),
                    _divLine(),
                    _statItem(context, '${s.closed}', 'Closed'),
                  ],
                ),
              ),
              orElse: () => const SizedBox(height: 20),
            ),

            const Divider(height: 1),
            const SizedBox(height: 4),

            // ── SEKSI: Pengaturan ──────────────────────────
            _sectionLabel(context, 'Pengaturan'),

            // Dark mode toggle
            SwitchListTile(
              value: isDark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
              secondary: _tileIcon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              ),
              title: const Text('Mode Tampilan'),
              subtitle: Text(isDark ? 'Mode Gelap' : 'Mode Terang'),
              activeThumbColor: AppColors.primary,
            ),

            const Divider(height: 1, indent: 56),

            _settingTile(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifikasi',
              sub: 'Kelola preferensi notifikasi',
              onTap: () {}, // TODO: navigate ke halaman notif settings
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),

            // ── SEKSI: Akun ────────────────────────────────
            _sectionLabel(context, 'Akun'),

            if (user.role == UserRole.admin) ...[
              _settingTile(
                context,
                icon: Icons.manage_accounts_outlined,
                title: 'Manajemen Pengguna',
                sub: 'Kelola data admin, helpdesk, dan user',
                onTap: () => Navigator.pushNamed(context, AppRoutes.users),
              ),
              const Divider(height: 1, indent: 56),
            ],

            // ── Reset Password ────────────────
            _settingTile(
              context,
              icon: Icons.lock_reset_rounded,
              title: 'Reset Password',
              sub: 'Kirim link reset ke email Anda',
              onTap: () => _showResetPasswordDialog(context, ref, user.email),
            ),

            const Divider(height: 1, indent: 56),

            _settingTile(
              context,
              icon: Icons.info_outline_rounded,
              title: 'Tentang Aplikasi',
              sub: '${AppStrings.appName} ${AppStrings.appVersion}',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: AppStrings.appName,
                applicationVersion: AppStrings.appVersion,
                applicationLegalese: '© 2026 ${AppStrings.university}',
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ── Tombol Logout ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context, ref),
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Widget helpers ───────────────────────────────────────

  Widget _statItem(BuildContext context, String val, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            val,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _divLine() => Container(
    height: 36,
    width: 1,
    color: Colors.grey.withValues(alpha: 0.25),
  );

  Widget _sectionLabel(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontSize: 11,
      ),
    ),
  );

  Widget _tileIcon(IconData icon) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: AppColors.primary, size: 20),
  );

  Widget _settingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String sub,
    VoidCallback? onTap,
  }) => ListTile(
    leading: _tileIcon(icon),
    title: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(
      sub,
      style: Theme.of(context).textTheme.bodySmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _ResetPasswordDialog extends ConsumerStatefulWidget {
  const _ResetPasswordDialog({required this.email});
  final String email;

  @override
  ConsumerState<_ResetPasswordDialog> createState() =>
      _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<_ResetPasswordDialog> {
  bool _loading = false;
  bool _sent = false;

  Future<void> _sendReset() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      await ref.read(authRepositoryProvider).resetPassword(widget.email);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _sent = true;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal mengirim email. Coba lagi.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── State: Email berhasil dikirim ──────────────────────
    if (_sent) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.statusResolved.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                size: 48,
                color: AppColors.statusResolved,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Email Terkirim!',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Link reset password telah dikirim ke:\n${widget.email}\n\n'
              'Buka email dan ikuti instruksi untuk memperbarui password Anda.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mengerti'),
            ),
          ),
        ],
      );
    }

    // ── State: Konfirmasi pengiriman ───────────────────────
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Reset Password',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Link reset password akan dikirim ke:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              widget.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Setelah menekan "Kirim", buka email Anda dan ikuti link yang diberikan.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _sendReset,
          style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text('Kirim'),
        ),
      ],
    );
  }
}
