class DashboardStatsModel {
  final int total;
  final int open;
  final int assigned;
  final int inProgress;
  final int resolved;
  final int closed;

  const DashboardStatsModel({
    required this.total,
    required this.open,
    required this.assigned,
    required this.inProgress,
    required this.resolved,
    required this.closed,
  });

  factory DashboardStatsModel.empty() => const DashboardStatsModel(
    total: 0,
    open: 0,
    assigned: 0,
    inProgress: 0,
    resolved: 0,
    closed: 0,
  );

  /// Hitung dari list raw rows (kolom `status` dan `assigned_to`)
  factory DashboardStatsModel.fromRows(List<dynamic> rows) {
    int open = 0, assigned = 0, inProg = 0, resolved = 0, closed = 0;
    for (final row in rows) {
      final map = row as Map<String, dynamic>;
      // Hitung assigned: tiket yang sudah punya assigned_to
      if (map['assigned_to'] != null) {
        assigned++;
      }
      switch (map['status'] as String?) {
        case 'open':
          open++;
          break;
        case 'in_progress':
          inProg++;
          break;
        case 'resolved':
          resolved++;
          break;
        case 'closed':
          closed++;
          break;
      }
    }
    return DashboardStatsModel(
      total: rows.length,
      open: open,
      assigned: assigned,
      inProgress: inProg,
      resolved: resolved,
      closed: closed,
    );
  }
}
