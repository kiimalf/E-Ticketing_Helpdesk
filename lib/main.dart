import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/core/services/supabase_service.dart';
import 'package:eticketing_helpdesk/core/theme/app_theme.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/providers/auth_provider.dart';

// ── Pages ─────────────────────────────────────────────────────
import 'package:eticketing_helpdesk/features/auth/presentation/pages/splash_page.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/pages/login_page.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/pages/register_page.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:eticketing_helpdesk/features/ticket/presentation/pages/ticket_detail_page.dart';
import 'package:eticketing_helpdesk/features/ticket/presentation/pages/create_ticket_page.dart';
import 'package:eticketing_helpdesk/features/user/presentation/pages/user_list_page.dart';
import 'package:eticketing_helpdesk/features/user/presentation/pages/user_form_page.dart';
import 'package:eticketing_helpdesk/features/auth/data/models/user_model.dart';
import 'package:eticketing_helpdesk/main_shell.dart';

// ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Supabase (satu kali via SupabaseService)
  await SupabaseService.initialize();

  // 2. Inisialisasi SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Inject SharedPreferences ke dalam provider graph
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const HelpdeskApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
class HelpdeskApp extends ConsumerWidget {
  const HelpdeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Animasi slide dari kanan ke kiri
    Widget page;

    switch (settings.name) {
      case AppRoutes.splash:
        page = const SplashPage();
        break;
      case AppRoutes.login:
        page = const LoginPage();
        break;
      case AppRoutes.register:
        page = const RegisterPage();
        break;
      case AppRoutes.forgotPassword:
        page = const ForgotPasswordPage();
        break;
      case AppRoutes.dashboard:
        page = const MainShell();
        break;
      case AppRoutes.createTicket:
        page = const CreateTicketPage();
        break;
      case AppRoutes.ticketDetail:
        final id = settings.arguments as String?;
        page = id != null ? TicketDetailPage(ticketId: id) : const MainShell();
        break;
      case AppRoutes.users:
        page = const UserListPage();
        break;
      case AppRoutes.userForm:
        final user = settings.arguments as UserModel?;
        page = UserFormPage(user: user);
        break;
      default:
        page = const SplashPage();
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 260),
    );
  }
}
