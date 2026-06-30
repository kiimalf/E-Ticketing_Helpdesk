import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/core/theme/app_theme.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // ── SEKSI: Tampilan ──────────────────────────────
          _sectionLabel(context, 'Tampilan'),

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

          // ── SEKSI: Notifikasi ────────────────────────────
          _sectionLabel(context, 'Notifikasi'),

          _settingTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifikasi Push',
            sub: 'Terima pemberitahuan tiket baru dan update',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeThumbColor: AppColors.primary,
            ),
          ),

          const Divider(height: 1, indent: 56),

          _settingTile(
            context,
            icon: Icons.email_outlined,
            title: 'Notifikasi Email',
            sub: 'Terima ringkasan harian via email',
            trailing: Switch(
              value: false,
              onChanged: (_) {},
              activeThumbColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // ── SEKSI: Tentang ───────────────────────────────
          _sectionLabel(context, 'Tentang'),

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

          const Divider(height: 1, indent: 56),

          _settingTile(
            context,
            icon: Icons.description_outlined,
            title: 'Kebijakan Privasi',
            sub: 'Baca kebijakan privasi kami',
            onTap: () {},
          ),

          const Divider(height: 1, indent: 56),

          _settingTile(
            context,
            icon: Icons.gavel_rounded,
            title: 'Syarat & Ketentuan',
            sub: 'Baca syarat dan ketentuan',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // ── Info versi di bawah ──────────────────────────
          Center(
            child: Column(
              children: [
                Text(
                  '${AppStrings.appName} ${AppStrings.appVersion}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.university,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Widget helpers ───────────────────────────────────────
  Widget _sectionLabel(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
    Widget? trailing,
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
    trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
