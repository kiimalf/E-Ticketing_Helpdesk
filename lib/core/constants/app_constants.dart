const String kPackageName = 'eticketing_helpdesk';

// ─── Named Routes ─────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String ticketList = '/tickets';
  static const String ticketDetail = '/ticket-detail';
  static const String createTicket = '/tickets/create';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String history = '/history';
  static const String users = '/users';
  static const String userForm = '/user-form';
}

// ─── SharedPreferences Keys ───────────────────────────────────
class PrefKeys {
  PrefKeys._();
  static const String isDark = 'pref_is_dark';
  static const String userId = 'pref_user_id';
  static const String userEmail = 'pref_user_email';
}

// ─── Supabase Table Names ─────────────────────────────────────
class SupabaseTables {
  SupabaseTables._();
  static const String profiles = 'profiles';
  static const String tickets = 'tickets';
  static const String comments = 'ticket_comments';
  static const String attachments = 'ticket_attachments';
  static const String notifications = 'notifications';
}

// ─── Supabase Storage Buckets ─────────────────────────────────
class SupabaseBuckets {
  SupabaseBuckets._();
  static const String ticketAttachments = 'ticket-attachments';
}

// ─── App Strings ──────────────────────────────────────────────
class AppStrings {
  AppStrings._();
  static const String appName = 'HelpDesk';
  static const String appVersion = 'v1.0.0';
  static const String appTagline = 'E-Ticketing System';
  static const String university =
      'DIV Teknik Informatika — Universitas Airlangga';
}

// ─── Enums ────────────────────────────────────────────────────
enum UserRole { user, helpdesk, admin }

enum TicketStatus { open, inProgress, resolved, closed }

enum TicketPriority { low, medium, high, critical }

enum NotificationType {
  ticketCreated,
  statusUpdated,
  newComment,
  ticketAssigned,
}

// ─── Enum Extensions ──────────────────────────────────────────
extension UserRoleX on UserRole {
  String get label => switch (this) {
    UserRole.user => 'Pengguna',
    UserRole.helpdesk => 'Helpdesk',
    UserRole.admin => 'Administrator',
  };

  static UserRole fromString(String? v) => switch (v) {
    'helpdesk' => UserRole.helpdesk,
    'admin' => UserRole.admin,
    _ => UserRole.user,
  };
}

extension TicketStatusX on TicketStatus {
  String get label => switch (this) {
    TicketStatus.open => 'Open',
    TicketStatus.inProgress => 'In Progress',
    TicketStatus.resolved => 'Resolved',
    TicketStatus.closed => 'Closed',
  };

  String get dbValue => switch (this) {
    TicketStatus.open => 'open',
    TicketStatus.inProgress => 'in_progress',
    TicketStatus.resolved => 'resolved',
    TicketStatus.closed => 'closed',
  };

  static TicketStatus fromString(String? v) => switch (v) {
    'in_progress' => TicketStatus.inProgress,
    'resolved' => TicketStatus.resolved,
    'closed' => TicketStatus.closed,
    _ => TicketStatus.open,
  };
}

extension TicketPriorityX on TicketPriority {
  String get label => switch (this) {
    TicketPriority.low => 'Low',
    TicketPriority.medium => 'Medium',
    TicketPriority.high => 'High',
    TicketPriority.critical => 'Critical',
  };

  static TicketPriority fromString(String? v) => switch (v) {
    'low' => TicketPriority.low,
    'high' => TicketPriority.high,
    'critical' => TicketPriority.critical,
    _ => TicketPriority.medium,
  };
}

extension NotificationTypeX on NotificationType {
  String get dbValue => switch (this) {
    NotificationType.ticketCreated => 'ticket_created',
    NotificationType.statusUpdated => 'status_updated',
    NotificationType.newComment => 'new_comment',
    NotificationType.ticketAssigned => 'ticket_assigned',
  };

  static NotificationType fromString(String? v) => switch (v) {
    'status_updated' => NotificationType.statusUpdated,
    'new_comment' => NotificationType.newComment,
    'ticket_assigned' => NotificationType.ticketAssigned,
    _ => NotificationType.ticketCreated,
  };
}

// ─── Ticket Categories ────────────────────────────────────────
const List<String> kTicketCategories = [
  'Email & Komunikasi',
  'Hardware',
  'Software & Aplikasi',
  'Jaringan & Konektivitas',
  'Akses & Akun',
  'Sistem & Server',
  'Lainnya',
];
