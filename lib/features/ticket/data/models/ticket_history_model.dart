/// Model untuk setiap entry riwayat/log aktivitas tiket.
///
/// Disimpan di tabel `ticket_history` di Supabase, dengan join
/// ke `profiles` untuk mendapatkan nama pelaku.
class TicketHistoryModel {
  final String id;
  final String ticketId;
  final String action; // 'created', 'status_changed', 'assigned', 'comment_added'
  final String? oldValue;
  final String? newValue;
  final String performedBy;
  final String performedByName;
  final DateTime createdAt;

  const TicketHistoryModel({
    required this.id,
    required this.ticketId,
    required this.action,
    this.oldValue,
    this.newValue,
    required this.performedBy,
    required this.performedByName,
    required this.createdAt,
  });

  factory TicketHistoryModel.fromMap(Map<String, dynamic> map) {
    final performer = map['performer'] as Map<String, dynamic>?;
    return TicketHistoryModel(
      id: map['id'] as String,
      ticketId: map['ticket_id'] as String,
      action: map['action'] as String,
      oldValue: map['old_value'] as String?,
      newValue: map['new_value'] as String?,
      performedBy: map['performed_by'] as String,
      performedByName: (performer?['name'] as String?) ?? 'Unknown',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Deskripsi human-readable dari aksi ini
  String get description => switch (action) {
    'created' => 'Tiket dibuat',
    'status_changed' => 'Status diubah dari ${_statusLabel(oldValue)} ke ${_statusLabel(newValue)}',
    'assigned' => 'Tiket ditugaskan ke $newValue',
    'comment_added' => 'Komentar ditambahkan',
    _ => action,
  };

  /// Ikon yang sesuai dengan aksi
  String get actionIcon => switch (action) {
    'created' => 'add_circle',
    'status_changed' => 'sync_alt',
    'assigned' => 'assignment_ind',
    'comment_added' => 'chat_bubble',
    _ => 'info',
  };

  static String _statusLabel(String? dbValue) => switch (dbValue) {
    'open' => 'Open',
    'in_progress' => 'In Progress',
    'resolved' => 'Resolved',
    'closed' => 'Closed',
    _ => dbValue ?? '-',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TicketHistoryModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
